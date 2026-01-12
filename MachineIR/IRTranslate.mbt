///|
pub fn Module::translate_llvm_module(
  self : Self,
  llvm_mod : @IR.Module,
) -> Unit raise MIRError {
  self.llvm_mod = Some(llvm_mod)

  // Step 1: Translate global values
  self.translate_global_values(llvm_mod)

  // Step 2: Translate functions
  for func_pair in llvm_mod.functions {
    let (_, func) = func_pair
    if func.isDeclaration() {
      self.external_functions.set(func.getName().unwrap(), func)
    } else {
      let fname = func.getName().unwrap()
      let is_external = func.linkage.val is External
      let is_variadic = func.fty.isVarArg
      let f = self.add_function(fname, [], is_external, is_variadic~)
      f.translate_llvm_function(func)
    }
  }
}

///|
pub fn Module::translate_global_values(
  self : Self,
  llvm_mod : @IR.Module,
) -> Unit raise MIRError {
  let data_layout = llvm_mod.getDataLayout()
  for global_name, gv in llvm_mod.globals {
    match gv.asGlobalValueEnum() {
      Function(_) => ()
      GlobalVariable({ initializer: None, initializerTy, .. }) => {
        let size = data_layout
          .getTypeAllocSize(initializerTy)
          .reinterpret_as_uint()
        let _ = self.add_global_zero_data(global_name, size)

      }
      GlobalVariable({ initializer: Some(initializer), .. }) =>
        self.translate_llvm_global_constant(global_name, initializer)
      GlobalConstant({ value, .. }) =>
        self.translate_llvm_global_constant(global_name, value)
    }
  }
}

///|
pub fn Module::translate_llvm_global_constant(
  self : Self,
  global_name : String,
  global_constant : &@IR.Constant,
) -> Unit raise MIRError {
  let gv = match global_constant.asConstantEnum() {
    ConstantString({ data, .. }) =>
      self.add_global_string(label=global_name, content=data)
    _ =>
      // Check if this is a zeroinitializer constant
      if is_zero_initializer(global_constant) {
        let size = get_constant_size(global_constant)
        self.add_global_zero_data(global_name, size)
      } else {
        let data = llvm_global_constant_to_data(global_constant)
        self.add_global_data(global_name, data)
      }
  }
  let _ = gv

}

///|
/// Check if a constant is a zeroinitializer
pub fn is_zero_initializer(constant : &@IR.Constant) -> Bool {
  match constant.asConstantEnum() {
    ConstantArray({ data: Left(const_arr), .. }) => {
      // Check if all elements are zero
      for item in const_arr {
        if !is_zero_initializer(item) {
          return false
        }
      }
      true
    }
    ConstantStruct({ elements, .. }) => {
      // Check if all elements are zero
      for element in elements {
        if !is_zero_initializer(element) {
          return false
        }
      }
      true
    }
    ConstantInt(c) => c.getValueAsInt64() == 0
    ConstantFP(c) => c.getValue() == 0.0
    ConstantPointerNull(_) => true
    _ => false
  }
}

///|
/// Get the size of a constant in bytes
pub fn get_constant_size(constant : &@IR.Constant) -> UInt {
  match constant.asConstantEnum() {
    ConstantArray({ data: Left(const_arr), vty, .. }) => {
      let element_size = get_type_size(vty.getElementType())
      let count = const_arr.length()
      element_size * count.reinterpret_as_uint()
    }
    ConstantStruct({ elements, .. }) => {
      let mut total_size : UInt = 0
      for element in elements {
        total_size = total_size + get_constant_size(element)
      }
      total_size
    }
    ConstantInt(c) => get_type_size(c.getIntegerType())
    ConstantFP(c) => get_type_size(c.getFPType())
    ConstantPointerNull(_) => 8 // 64-bit pointer
    _ => 0
  }
}

///|
/// Get the size of a type in bytes
pub fn get_type_size(ty : &@IR.Type) -> UInt {
  // This is a simplified implementation
  // In a real implementation, we would need to handle all type kinds
  match ty.asTypeEnum() {
    Int1Type(_) => 1
    Int8Type(_) => 1
    Int16Type(_) => 2
    Int32Type(_) => 4
    Int64Type(_) => 8
    FloatType(_) => 4
    DoubleType(_) => 8
    PointerType(_) => 8 // 64-bit pointer
    ArrayType(arr_ty) => {
      let element_size = get_type_size(arr_ty.getElementType())
      let count = arr_ty.getElementCount()
      element_size * count.reinterpret_as_uint()
    }
    StructType(_) =>
      // For struct types, we need to get the size from the data layout
      // This is a simplified implementation
      0
    _ => 0
  }
}

///|
pub fn llvm_global_constant_to_data(
  global_constant : &@IR.Constant,
) -> Array[GlobalValueData] raise MIRError {
  match global_constant.asConstantEnum() {
    ConstantInt({ vty, value, .. }) =>
      match vty.asIntegerTypeEnum() {
        Int1Type(_) => [Byte(value.to_byte())]
        Int8Type(_) => [Byte(value.to_byte())]
        Int16Type(_) => [Half(value.to_uint16())]
        Int32Type(_) => [Word(value.to_int().reinterpret_as_uint())]
        Int64Type(_) => [Quad(value.reinterpret_as_uint64())]
      }
    ConstantFP({ vty, value, .. }) =>
      match vty.asFPTypeEnum() {
        FloatType(_) => {
          let bits = Float::from_double(value).reinterpret_as_uint()
          [Word(bits)]
        }
        DoubleType(_) => {
          let bits = value.reinterpret_as_uint64()
          [Quad(bits)]
        }
        ty =>
          raise IRTranslateError(
            "Unsupported floating point type \{ty} in global constant.",
          )
      }
    ConstantPointerNull(_) => [Quad(0)]
    ConstantArray({ data: Left(const_arr), .. }) => {
      let data : Array[GlobalValueData] = Array::new()
      for item in const_arr {
        let item_data = llvm_global_constant_to_data(item)
        data.append(item_data)
      }
      data
    }
    ConstantArray({ data: Right(Int8Array(arr)), .. }) => {
      let length = arr.length()
      let Int8Array(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        data.push(Byte(arr[i].to_byte()))
      }
      data
    }
    ConstantArray({ data: Right(UInt8Array(arr)), .. }) => {
      let length = arr.length()
      let UInt8Array(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        let UInt8(byte) = arr[i]
        data.push(Byte(byte))
      }
      data
    }
    ConstantArray({ data: Right(Int16Array(arr)), .. }) => {
      let length = arr.length()
      let Int16Array(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        data.push(Half(arr[i].reinterpret_as_uint16()))
      }
      data
    }
    ConstantArray({ data: Right(UInt16Array(arr)), .. }) => {
      let length = arr.length()
      let UInt16Array(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        data.push(Half(arr[i]))
      }
      data
    }
    ConstantArray({ data: Right(Int32Array(arr)), .. }) => {
      let length = arr.length()
      let Int32Array(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        data.push(Word(arr[i].reinterpret_as_uint()))
      }
      data
    }
    ConstantArray({ data: Right(UInt32Array(arr)), .. }) => {
      let length = arr.length()
      let UInt32Array(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        data.push(Word(arr[i]))
      }
      data
    }
    ConstantArray({ data: Right(Int64Array(arr)), .. }) => {
      let length = arr.length()
      let Int64Array(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        data.push(Quad(arr[i].reinterpret_as_uint64()))
      }
      data
    }
    ConstantArray({ data: Right(UInt64Array(arr)), .. }) => {
      let length = arr.length()
      let UInt64Array(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        data.push(Quad(arr[i]))
      }
      data
    }
    ConstantArray({ data: Right(FloatArray(arr)), .. }) => {
      let length = arr.length()
      let FloatArray(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        let bits = arr[i].reinterpret_as_uint()
        data.push(Word(bits))
      }
      data
    }
    ConstantArray({ data: Right(DoubleArray(arr)), .. }) => {
      let length = arr.length()
      let DoubleArray(arr) = arr
      let data : Array[GlobalValueData] = Array::new()
      for i in 0..<length {
        let bits = arr[i].reinterpret_as_uint64()
        data.push(Quad(bits))
      }
      data
    }
    ConstantStruct({ elements, .. }) => {
      let data : Array[GlobalValueData] = Array::new()
      for element in elements {
        let element_data = llvm_global_constant_to_data(element)
        data.append(element_data)
      }
      data
    }
    _ => raise IRTranslateError("Unsupported constant type in global constant.")
  }
}

///|
pub fn Function::translate_llvm_function(
  self : Self,
  llvm_func : @IR.Function,
) -> Unit raise MIRError {
  self.llvm_func = Some(llvm_func)

  // Step 1: Traverse llvm basic blocks in Reverse Post-Order
  let llvm_machine_bbs = self.traverse_llvm_basic_blocks()

  // Step 2: Translate parameters
  self.translate_params()

  // Step 3: Traverse all llvm instructions (for binding values to registers)
  self.traverse_llvm_instructions(llvm_func)

  // Step 4: Translate each basic block
  for pair in llvm_machine_bbs {
    let (llvm_bb, machine_bb) = pair
    machine_bb.translate_llvm_basic_block(llvm_bb)
  }
  if self.terminal_blocks.is_empty() {
    self.terminal_blocks.push(self.body.last().unwrap())
  }

  // Step 5: Phi Elimination
  self.phi_elimination()
}

///|
#callsite(autofill(loc))
pub fn Function::translate_params(self : Self, loc~ : SourceLoc) -> Unit {
  guard self.llvm_func is Some(llvm_func) else {
    let msg =
      $|Fatal Error happened in \{loc}
      $|LLVM function is not set for Function \{self.name}
    println(msg)
    panic()
  }
  fn pattern_of_llvm_arg(arg : @IR.Argument) {
    match arg.getType().isIEEELikeFPTy() {
      true => F
      false => I
    }
  }

  let arg_patterns = llvm_func.arguments.map(pattern_of_llvm_arg)
  self.set_params_by_patterns(arg_patterns)
  let entry_bb = self.get_entry_block().unwrap()
  let buiilder = IRBuilder::new(self, entry_bb)
  let arg_len = llvm_func.arguments.length()
  let param_len = self.params.length()
  let min_len = if arg_len < param_len { arg_len } else { param_len }
  for i in 0..<min_len {
    let arg = llvm_func.arguments[i]
    let param = self.params[i]
    // Get the actual type size from LLVM argument type
    let arg_ty = arg.getType()
    let data_size = match arg_ty.asTypeEnum() {
      Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | FloatType(_) =>
        32
      Int64Type(_) | PointerType(_) | DoubleType(_) => 64
      _ => 64 // Default to 64 for other types
    }
    if param is IRegister(r) {
      let tmp = self.new_virtual_reg()
      let move_inst = buiilder.build_imove(data_size, dst=tmp, src=r) catch {
        _ => abort("")
      }
      entry_bb.push(move_inst)
      self.value_map.set(arg, IRegister(tmp))
      continue
    }
    if param is FRegister(r) {
      let tmp = self.new_virtual_freg()
      let move_inst = buiilder.build_fmove(data_size, dst=tmp, src=r) catch {
        _ => abort("")
      }
      entry_bb.push(move_inst)
      self.value_map.set(arg, FRegister(tmp))
      continue
    }
    let is_fp = arg.getType().isIEEELikeFPTy()
    guard param is Mem(base, offset)
    if is_fp {
      let tmp = self.new_virtual_freg()
      let load_inst = buiilder.build_loadf(data_size, dst=tmp, base~, offset~) catch {
        _ => abort("")
      }
      entry_bb.push(load_inst)
      self.value_map.set(arg, FRegister(tmp))
    } else {
      let tmp = self.new_virtual_reg()
      let load_inst = buiilder.build_loadi(data_size, dst=tmp, base~, offset~) catch {
        _ => abort("")
      }
      entry_bb.push(load_inst)
      self.value_map.set(arg, IRegister(tmp))
    }
  }
}

///|
#callsite(autofill(loc))
pub fn Function::traverse_llvm_basic_blocks(
  self : Self,
  loc~ : SourceLoc,
) -> Array[(@IR.BasicBlock, BasicBlock)] {
  guard self.llvm_func is Some(llvm_func) else {
    let msg =
      $|Fatal Error happened in \{loc}
      $|LLVM function is not set for Function \{self.name}
    println(msg)
    panic()
  }
  let sorted_bbs = sort_llvm_basick_block(llvm_func)
  let llvm_machine_bbs : Array[(@IR.BasicBlock, BasicBlock)] = Array::new()
  for llvm_bb in sorted_bbs {
    let label = match llvm_bb.getName() {
      Some(n) => n
      None => "\{self.name}_L\{self.bbmap.length()}"
    }
    let machine_bb = BasicBlock::new(self, label)
    self.body.push(machine_bb)
    self.value_map.set(llvm_bb, Label(label))
    self.bbmap.set(label, machine_bb)
    llvm_machine_bbs.push((llvm_bb, machine_bb))
  }
  llvm_machine_bbs
}

///|
fn sort_llvm_basick_block(llvm_func : @IR.Function) -> Array[@IR.BasicBlock] {
  let basic_blocks : Array[@IR.BasicBlock] = Array::new()
  let entry_bb = llvm_func.getEntryBlock().unwrap()
  fn dfs(bb : @IR.BasicBlock, visited : Set[@IR.BasicBlock]) -> Unit {
    if visited.contains(bb) {
      return
    }
    visited.add(bb)
    for succ in bb.getSuccessors().rev_iter() {
      dfs(succ, visited)
    }
    basic_blocks.push(bb)
  }

  dfs(entry_bb, Set::new())
  basic_blocks.rev()
}

///|
fn Function::traverse_llvm_instructions(
  self : Self,
  llvm_func : @IR.Function,
) -> Unit raise MIRError {
  let llvm_mod = llvm_func.getModule()
  let data_layout = llvm_mod.getDataLayout()
  for llvm_inst in llvm_func.instIter() {
    self.visit_llvm_inst(llvm_inst, data_layout)
  }
}

///|
fn Function::visit_llvm_inst(
  self : Function,
  llvm_inst : &@IR.Instruction,
  data_layout : @IR.DataLayout,
) -> Unit raise MIRError {
  match llvm_inst.asInstEnum() {
    AllocaInst({ data_ty, align, .. }) => {
      let data_size = data_layout.getTypeAllocSize(data_ty).to_int64()
      let align = align.to_int64()
      let var_stack_loc = self.extend_var_stack(data_size, align)
      self.bind_llvm_value_to_mem(llvm_inst, FramePtrPrim, -var_stack_loc)
    }
    _ => {
      // Skip instructions whose results are never used (dead code)
      if llvm_inst.user_empty() && !(llvm_inst.asValueEnum() is CallInst(_)) {
        return
      }
      let llvm_ty = llvm_inst.getType()
      match llvm_ty.asTypeEnum() {
        Int1Type(_)
        | Int8Type(_)
        | Int16Type(_)
        | Int32Type(_)
        | Int64Type(_)
        | PointerType(_) => {
          let dst = self.new_virtual_reg()
          self.bind_llvm_value_to_register(llvm_inst, dst)
        }
        FloatType(_) | DoubleType(_) => {
          let dst = self.new_virtual_freg()
          self.bind_llvm_value_to_fregister(llvm_inst, dst)
        }
        VoidType(_) => ()
        StructType(_) | ArrayType(_) =>
          self.bind_struct_or_array_value_to_mem_group(
            llvm_inst, llvm_ty, data_layout,
          )
        _ =>
          raise IRTranslateError(
            "Cannot bind LLVM instruction type \{llvm_ty} to a register, inst is \{llvm_inst}",
          )
      }
    }
  }
}

///|
fn Function::bind_struct_or_array_value_to_mem_group(
  self : Function,
  llvm_inst : &@IR.Instruction,
  ty : &@IR.Type,
  data_layout : @IR.DataLayout,
) -> Unit raise MIRError {
  guard llvm_inst.asInstEnum() is LoadInst(load_inst) else {
    raise IRTranslateError(
      "Struct value binding only supports LoadInst, got \{llvm_inst}",
    )
  }
  let { ptr, .. } = load_inst
  let ptr_op = if self.get_operand_from_llvm_value(ptr) is Some(op) {
    op
  } else {
    guard ptr.tryAsInst() is Some(ptr_inst) else {
      raise IRTranslateError(
        "Struct LoadInst pointer is not found in value_map",
      )
    }
    self.visit_llvm_inst(ptr_inst, data_layout)
    guard self.get_operand_from_llvm_value(ptr) is Some(op) else {
      raise IRTranslateError(
        "Struct LoadInst pointer is not found in value_map after visiting",
      )
    }
    op
  }
  // Handle both IRegister and MemLoc cases
  // For MemLoc, we just use the base register and add the offset to all offsets
  let (base, base_offset) = match ptr_op {
    IRegister(r) => (r, 0L)
    MemLoc(base_reg, offset) => (base_reg, offset)
    _ =>
      raise IRTranslateError(
        "Struct LoadInst pointer is not a register or memory location, it is \{ptr_op}",
      )
  }
  let relative_offsets = match ty.asTypeEnum() {
    StructType(sty) =>
      self.bind_struct_value_to_mem_group(base, 0L, sty, data_layout)
    ArrayType(aty) =>
      self.bind_array_value_to_mem_group(base, 0L, aty, data_layout)
    _ =>
      raise IRTranslateError(
        "Type \{ty} is not struct or array for struct/array value binding",
      )
  }
  // Add base_offset to all relative offsets to get absolute offsets
  let offsets = relative_offsets.map(fn(offset) { base_offset + offset })
  let op = MemGroup(base, offsets)
  self.value_map.set(llvm_inst, op)
}

///|
fn Function::bind_struct_value_to_mem_group(
  self : Function,
  base : IRegister,
  offset : Int64,
  sty : @IR.StructType,
  data_layout : @IR.DataLayout,
) -> Array[Int64] raise MIRError {
  let { elements: element_types, .. } = sty
  let offsets : Array[Int64] = Array::new()
  for i, ety in element_types {
    let this_offset = data_layout.getStructTypeOffset(sty, i)
    let this_offset = this_offset.to_int64() + offset
    offsets.push(this_offset)
    let nested_offsets = match ety.asTypeEnum() {
      StructType(nested_sty) =>
        self.bind_struct_value_to_mem_group(
          base, this_offset, nested_sty, data_layout,
        )
      ArrayType(nested_aty) =>
        self.bind_array_value_to_mem_group(
          base, this_offset, nested_aty, data_layout,
        )
      _ => []
    }
    offsets.append(nested_offsets)
  }
  offsets
}

///|
fn Function::bind_array_value_to_mem_group(
  self : Function,
  base : IRegister,
  offset : Int64,
  aty : @IR.ArrayType,
  data_layout : @IR.DataLayout,
) -> Array[Int64] raise MIRError {
  let element_type = aty.getElementType()
  let element_size = data_layout.getTypeAllocSize(element_type).to_int64()
  let count = aty.getElementCount()
  let offsets : Array[Int64] = Array::new()
  for i in 0..<count {
    let this_offset = offset + i.to_int64() * element_size
    offsets.push(this_offset)
    let nested_offsets = match element_type.asTypeEnum() {
      StructType(nested_sty) =>
        self.bind_struct_value_to_mem_group(
          base, this_offset, nested_sty, data_layout,
        )
      ArrayType(nested_aty) =>
        self.bind_array_value_to_mem_group(
          base, this_offset, nested_aty, data_layout,
        )
      _ => []
    }
    offsets.append(nested_offsets)
  }
  offsets
}

///|
pub fn BasicBlock::translate_llvm_basic_block(
  self : Self,
  llvm_bb : @IR.BasicBlock,
) -> Unit raise MIRError {
  let func = self.parent
  let builder = IRBuilder::new(func, self)
  for inst in llvm_bb.instIter() {
    let insts = translate_llvm_inst(inst, builder)
    insts.each(i => self.push(i))
  }
}

///|
pub fn translate_llvm_inst(
  llvm_inst : &@IR.Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let func = builder.func
  let llvm_mod = llvm_inst.getModule()
  let data_layout = llvm_mod.getDataLayout()
  match llvm_inst.asInstEnum() {
    // AllocaInst has been handled in traverse_llvm_instructions
    AllocaInst(_) => []
    LoadInst(load_inst) =>
      translate_llvm_load_inst(load_inst, builder, func, data_layout)
    StoreInst(store_inst) =>
      translate_llvm_store_inst(store_inst, builder, func, data_layout)
    FNegInst(fneg_inst) =>
      translate_llvm_fneg_inst(fneg_inst, builder, func, data_layout)
    BinaryInst(binary_inst) =>
      translate_llvm_binary_inst(binary_inst, builder, func, data_layout)
    ICmpInst(icmp_inst) =>
      translate_llvm_icmp_inst(icmp_inst, builder, func, data_layout)
    FCmpInst(fcmp_inst) =>
      translate_llvm_fcmp_inst(fcmp_inst, builder, func, data_layout)
    BranchInst(branch_inst) =>
      translate_llvm_branch_inst(branch_inst, builder, func, data_layout)
    SwitchInst(switch_inst) =>
      translate_llvm_switch_inst(switch_inst, builder, func, data_layout)
    CastInst(cast_inst) =>
      translate_llvm_cast_inst(cast_inst, builder, func, data_layout)
    GetElementPtrInst(gep_inst) =>
      translate_llvm_gep_inst(gep_inst, builder, func, data_layout)
    SelectInst(select_inst) =>
      translate_llvm_select_inst(select_inst, builder, func, data_layout)
    ReturnInst(ret_inst) => translate_llvm_return_inst(ret_inst, builder, func)
    CallInst(call_inst) => translate_llvm_call_inst(call_inst, builder, func)
    PHINode(phi_node) => translate_llvm_phi_node(phi_node, func)
    ExtractValueInst(_) =>
      raise IRTranslateError(
        "Translation for LLVM instruction \{llvm_inst} is not implemented",
      )
    InsertValueInst(_) =>
      raise IRTranslateError(
        "Translation for LLVM instruction \{llvm_inst} is not implemented",
      )
  }
}

///|
pub fn translate_llvm_load_inst(
  llvm_inst : @IR.LoadInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  let { vty, ptr, .. } = llvm_inst
  guard func.get_operand_from_llvm_value(ptr) is Some(ptr_op) else {
    raise IRTranslateError("LoadInst: pointer operand not found in value_map")
  }
  let (base, offset, minsts) : (IRegister, Int64, Array[Instruction]) = match
    ptr_op {
    MemLoc(base, offset) => (base, offset, [])
    IRegister(r) => (r, 0L, [])
    Label(label) => {
      let tmp = func.new_virtual_reg()
      let inst = builder.build_load_addr(tmp, label)
      (tmp, 0L, [inst])
    }
    _ =>
      raise IRTranslateError(
        "LoadInst: pointer operand is not a memory address or integer register, it is \{ptr_op}, ptr is \{ptr}",
      )
  }
  let data_size = data_layout.getTypeAllocSizeInBits(vty)
  guard func.get_operand_from_llvm_value(llvm_inst) is Some(dst_op) else {
    // If the destination operand is not found, it means this load instruction
    // was skipped because its result is never used (dead code)
    return []
  }
  let minst = match dst_op {
    MemGroup(_) => return minsts // Will be handled in store.
    IRegister(dst) => builder.build_loadi(data_size, dst~, base~, offset~)
    FRegister(dst) => builder.build_loadf(data_size, dst~, base~, offset~)
    dst_op =>
      raise IRTranslateError(
        "LoadInst: destination operand is not an integer or floating-point register: \{dst_op}",
      )
  }
  minsts.push(minst)
  minsts
}

///|
/// IRTranslate from LLVM IR to MoonMIR for StoreInst.
pub fn translate_llvm_store_inst(
  llvm_inst : @IR.StoreInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  let { value, ptr, .. } = llvm_inst
  guard func.get_operand_from_llvm_value(value) is Some(src_op) else {
    raise IRTranslateError("StoreInst: value operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(ptr) is Some(ptr_op) else {
    raise IRTranslateError("StoreInst: pointer operand not found in value_map")
  }
  let (base, offset, minsts) : (IRegister, Int64, Array[Instruction]) = match
    ptr_op {
    MemLoc(base, offset) => (base, offset, [])
    IRegister(r) => (r, 0L, [])
    Label(label) => {
      let tmp = func.new_virtual_reg()
      let inst = builder.build_load_addr(tmp, label)
      (tmp, 0L, [inst])
    }
    _ =>
      raise IRTranslateError(
        "StoreInst: pointer operand is not a memory address or integer register",
      )
  }
  let data_size = data_layout.getTypeAllocSizeInBits(value.getType())
  let store_insts = match src_op {
    IRegister(src) => [builder.build_storei(data_size, src~, base~, offset~)]
    FRegister(src) => [builder.build_storef(data_size, src~, base~, offset~)]
    Imm(src) => {
      let tmp = func.new_virtual_reg()
      [
        builder.build_imove_imm(data_size, dst=tmp, src~),
        builder.build_storei(data_size, src=tmp, base~, offset~),
      ]
    }
    FImm(src) => {
      let tmp = func.new_virtual_freg()
      [
        builder.build_fmove_imm(data_size, dst=tmp, src~),
        builder.build_storef(data_size, src=tmp, base~, offset~),
      ]
    }
    Label(label) => {
      let tmp = func.new_virtual_reg()
      [
        builder.build_load_addr(tmp, label),
        builder.build_storei(data_size, src=tmp, base~, offset~),
      ]
    }
    MemLoc(src_base, src_offset) => {
      // MemLoc as a value means it's a pointer/address value
      // Compute the address (src_base + src_offset) and store that address
      let tmp = func.new_virtual_reg()
      if src_offset == 0L {
        // Just move the base register
        [
          builder.build_imove(64, dst=tmp, src=src_base),
          builder.build_storei(data_size, src=tmp, base~, offset~),
        ]
      } else {
        // Compute address: tmp = src_base + src_offset
        [
          builder.build_ibinary_imm(
            Add,
            64,
            dst=tmp,
            src1=src_base,
            src2=src_offset,
          ),
          builder.build_storei(data_size, src=tmp, base~, offset~),
        ]
      }
    }
    MemGroup(src_base, offsets) => {
      minsts.append(
        translate_multiple_load_store(
          llvm_inst, builder, func, data_layout, src_base, offsets, base, offset,
        ),
      )
      return minsts
    }
    src_op =>
      raise IRTranslateError(
        "StoreInst: value operand is not a register, immediate, or label: \{src_op}",
      )
  }
  minsts.append(store_insts)
  minsts
}

///|
fn translate_multiple_load_store(
  _llvm_inst : @IR.StoreInst,
  builder : IRBuilder,
  func : Function,
  _data_layout : @IR.DataLayout,
  src_base : IRegister,
  src_offsets : Array[Int64],
  dst_base : IRegister,
  dst_base_offset : Int64,
) -> Array[Instruction] raise MIRError {
  let minsts : Array[Instruction] = Array::new()

  // The src_offsets array contains absolute offsets relative to src_base
  // We need to extract the relative field offsets and apply them to the destination
  guard src_offsets.length() > 0 else { return minsts }
  let src_base_offset = src_offsets[0]

  // For each field in the struct/array
  for src_offset in src_offsets {
    // Calculate the field's relative offset
    let field_offset = src_offset - src_base_offset

    // Load the value from source location (src_base + src_offset)
    let temp_reg = func.new_virtual_reg()
    let load_inst = builder.build_loadi(
      32,
      dst=temp_reg,
      base=src_base,
      offset=src_offset,
    )
    minsts.push(load_inst)

    // Store the value to destination location (dst_base + dst_base_offset + field_offset)
    let dst_offset = dst_base_offset + field_offset
    let store_inst = builder.build_storei(
      32,
      src=temp_reg,
      base=dst_base,
      offset=dst_offset,
    )
    minsts.push(store_inst)
  }
  minsts
}

///|
/// IRTranslate from LLVM IR to MoonMIR for Int or Float binary instructions.
pub fn translate_llvm_binary_inst(
  llvm_inst : @IR.BinaryInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  if llvm_inst.getType().isIEEELikeFPTy() {
    translate_llvm_float_binary_inst(llvm_inst, builder, func, data_layout)
  } else {
    translate_llvm_int_binary_inst(llvm_inst, builder, func, data_layout)
  }
}

///|
/// IRTranslate from LLVM IR to MIR for floating-point BinaryInst
pub fn translate_llvm_float_binary_inst(
  llvm_inst : @IR.BinaryInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  let { opcode, lhs, rhs, .. } = llvm_inst
  let data_size = data_layout.getTypeAllocSizeInBits(llvm_inst.getType())
  let binop = match opcode {
    FAdd => FAdd
    FSub => FSub
    FMul => FMul
    FDiv => FDiv
    FRem => FRem
    _ => raise IRTranslateError("Unsupported floating-point binary opcode")
  }
  guard func.get_operand_from_llvm_value(lhs) is Some(lhs_op) else {
    raise IRTranslateError("BinaryInst: lhs operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(rhs) is Some(rhs_op) else {
    raise IRTranslateError("BinaryInst: rhs operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(llvm_inst) is Some(dst_op) else {
    return []
  }
  guard dst_op is FRegister(dst) else {
    raise IRTranslateError(
      "BinaryInst: destination operand is not a floating-point register",
    )
  }
  match (lhs_op, rhs_op) {
    (FRegister(src1), FRegister(src2)) =>
      [builder.build_fbinary(binop, data_size, dst~, src1~, src2~)]
    (FRegister(src1), FImm(f)) => {
      let ireg = func.new_virtual_reg()
      let src2 = func.new_virtual_freg()
      [
        match data_size {
          32 =>
            builder.build_imove_imm(
              data_size,
              dst=ireg,
              src=Float::from_double(f).reinterpret_as_int().to_int64(),
            )
          _ =>
            builder.build_imove_imm(
              data_size,
              dst=ireg,
              src=f.reinterpret_as_int64(),
            )
        },
        builder.build_fmove_from_ireg(data_size, dst=src2, src=ireg),
        builder.build_fbinary(binop, data_size, dst~, src1~, src2~),
      ]
    }
    (FImm(f), FRegister(src2)) => {
      let src1 = func.new_virtual_freg()
      let ireg = func.new_virtual_reg()
      let move_imm = match data_size {
        32 =>
          builder.build_imove_imm(
            data_size,
            dst=ireg,
            src=Float::from_double(f).reinterpret_as_int().to_int64(),
          )
        _ =>
          builder.build_imove_imm(
            data_size,
            dst=ireg,
            src=f.reinterpret_as_int64(),
          )
      }
      [
        move_imm,
        builder.build_fmove_from_ireg(data_size, dst=src1, src=ireg),
        builder.build_fbinary(binop, data_size, dst~, src1~, src2~),
      ]
    }
    (FImm(f1), FImm(f2)) => {
      let f = match binop {
        FAdd => f1 + f2
        FSub => f1 - f2
        FMul => f1 * f2
        FDiv => f1 / f2
        FRem => f1 % f2
      }
      let ireg = func.new_virtual_reg()
      let move_imm = match data_size {
        32 =>
          builder.build_imove_imm(
            data_size,
            dst=ireg,
            src=Float::from_double(f).reinterpret_as_int().to_int64(),
          )
        _ =>
          builder.build_imove_imm(
            data_size,
            dst=ireg,
            src=f.reinterpret_as_int64(),
          )
      }
      [move_imm, builder.build_fmove_from_ireg(data_size, dst~, src=ireg)]
    }
    (lhs_op, rhs_op) =>
      raise IRTranslateError(
        "Unsupported operand types for float binary operation, \{lhs_op}, \{rhs_op}",
      )
  }
}

///|
///
/// IRTranslate from LLVM IR to MIR for Int BinaryInst
pub fn translate_llvm_int_binary_inst(
  llvm_inst : @IR.BinaryInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  let { opcode, lhs, rhs, .. } = llvm_inst
  let data_size = data_layout.getTypeAllocSizeInBits(llvm_inst.getType())
  let binop = match opcode {
    Add => Add
    Sub => Sub
    Mul => Mul
    UDiv | SDiv => Div
    URem | SRem => Rem
    And => And
    Or => Or
    Xor => Xor
    Shl => Shl
    LShr => LShr
    AShr => AShr
    _ => raise IRTranslateError("Unsupported integer binary opcode")
  }
  guard func.get_operand_from_llvm_value(lhs) is Some(lhs_op) else {
    raise IRTranslateError("BinaryInst: lhs operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(rhs) is Some(rhs_op) else {
    raise IRTranslateError("BinaryInst: rhs operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(llvm_inst) is Some(dst_op) else {
    return []
  }
  guard dst_op is IRegister(dst) else {
    raise IRTranslateError(
      "BinaryInst: destination operand is not an integer register",
    )
  }
  match (lhs_op, rhs_op) {
    (IRegister(src1), IRegister(src2)) =>
      [builder.build_ibinary(binop, data_size, dst~, src1~, src2~)]
    (IRegister(src1), Imm(src2)) =>
      [builder.build_ibinary_imm(binop, data_size, dst~, src1~, src2~)]
    (Imm(src1), IRegister(src2)) if binop.is_commutative() =>
      [builder.build_ibinary_imm(binop, data_size, dst~, src1=src2, src2=src1)] // swap
    (Imm(src1_imm), IRegister(src2)) => {
      let src1 = func.new_virtual_reg()
      [
        builder.build_imove_imm(data_size, dst=src1, src=src1_imm),
        builder.build_ibinary(binop, data_size, dst~, src1~, src2~),
      ]
    }
    (Imm(src1), Imm(src2)) => {
      let src = match binop {
        Add => src1 + src2
        Sub => src1 - src2
        Mul => src1 * src2
        Div => src1 / src2
        Rem => src1 % src2
        And => src1 & src2
        Or => src1 | src2
        Xor => src1 ^ src2
        Shl => src1 << src2.to_int()
        LShr =>
          (src1.reinterpret_as_uint64() >> src2.to_int()).reinterpret_as_int64()
        AShr => src1 >> src2.to_int()
      }
      [builder.build_imove_imm(data_size, dst~, src~)]
    }
    (lhs_op, rhs_op) =>
      raise IRTranslateError(
        "Unsupported operand types for integer binary operation: \{lhs_op}, \{rhs_op}",
      )
  }
}

///|
///
/// IRTranslate from LLVM IR to MoonMIR for FNegInst
pub fn translate_llvm_fneg_inst(
  llvm_inst : @IR.FNegInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  let { operand, .. } = llvm_inst
  guard func.get_operand_from_llvm_value(operand) is Some(src_op) else {
    raise IRTranslateError("FNegInst: operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(llvm_inst) is Some(dst_op) else {
    return []
  }
  guard dst_op is FRegister(dst) else {
    raise IRTranslateError(
      "FNegInst: destination operand is not a floating-point register",
    )
  }
  let data_size = data_layout.getTypeAllocSizeInBits(llvm_inst.getType())
  match src_op {
    FRegister(src) => [builder.build_fneg(data_size, dst~, src~)]
    FImm(f) => {
      let ireg = func.new_virtual_reg()
      let src = func.new_virtual_freg()
      // Convert double bit representation to appropriate type
      let bit_value = match data_size {
        32 => {
          // Convert double to float bit representation
          let float_val = Float::from_double(f)
          float_val.reinterpret_as_int().to_int64()
        }
        64 => f.reinterpret_as_int64()
        _ => f.reinterpret_as_int64()
      }
      [
        builder.build_imove_imm(data_size, dst=ireg, src=bit_value),
        builder.build_fmove_from_ireg(data_size, dst=src, src=ireg),
        builder.build_fneg(data_size, dst~, src~),
      ]
    }
    src_op =>
      raise IRTranslateError(
        "FNegInst: operand is not a memory address, floating-point register, or immediate value: \{src_op}",
      )
  }
}

///|
/// IRTranslate from LLVM IR to MoonMIR for ICmpInst.
pub fn translate_llvm_icmp_inst(
  llvm_inst : @IR.ICmpInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  // If the ICmpInst is only used by a BranchInst,
  // we do not generate a separate instruction for it.
  let inst_users = llvm_inst.getUsers().unwrap()
  if inst_users.length() == 1 && inst_users[0].asValueEnum() is BranchInst(_) {
    return []
  }
  let { predicate, lhs, rhs, .. } = llvm_inst
  let opcode : ICmpOpCode = match predicate {
    EQ => Eq
    NE => Ne
    SGT => Gt
    SGE => Ge
    SLT => Lt
    SLE => Le
    UGT => Gtu
    UGE => Geu
    ULT => Ltu
    ULE => Leu
  }
  guard func.get_operand_from_llvm_value(lhs) is Some(lhs_op) else {
    raise IRTranslateError("ICmpInst: lhs operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(rhs) is Some(rhs_op) else {
    raise IRTranslateError("ICmpInst: rhs operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(llvm_inst) is Some(dst_op) else {
    return []
  }
  guard dst_op is IRegister(dst) else {
    raise IRTranslateError(
      "ICmpInst: destination operand is not an integer register",
    )
  }
  let data_size = data_layout.getTypeAllocSizeInBits(lhs.getType())
  match (lhs_op, rhs_op) {
    (IRegister(src1), IRegister(src2)) =>
      [builder.build_icmp(opcode, data_size, dst~, src1~, src2~)]
    (IRegister(src1), Imm(src2_imm)) => {
      let src2 = func.new_virtual_reg()
      [
        builder.build_imove_imm(data_size, dst=src2, src=src2_imm),
        builder.build_icmp(opcode, data_size, dst~, src1~, src2~),
      ]
    }
    (Imm(src1_imm), IRegister(src2)) => {
      let src1 = func.new_virtual_reg()
      [
        builder.build_imove_imm(data_size, dst=src1, src=src1_imm),
        builder.build_icmp(opcode, data_size, dst~, src1~, src2~),
      ]
    }
    (Imm(src1), Imm(src2)) => {
      let src = match opcode {
        Eq => if src1 == src2 { 1L } else { 0L }
        Ne => if src1 != src2 { 1L } else { 0L }
        Gt => if src1 > src2 { 1L } else { 0L }
        Ge => if src1 >= src2 { 1L } else { 0L }
        Lt => if src1 < src2 { 1L } else { 0L }
        Le => if src1 <= src2 { 1L } else { 0L }
        Gtu =>
          if src1.reinterpret_as_uint64() > src2.reinterpret_as_uint64() {
            1L
          } else {
            0L
          }
        Geu =>
          if src1.reinterpret_as_uint64() >= src2.reinterpret_as_uint64() {
            1L
          } else {
            0L
          }
        Ltu =>
          if src1.reinterpret_as_uint64() < src2.reinterpret_as_uint64() {
            1L
          } else {
            0L
          }
        Leu =>
          if src1.reinterpret_as_uint64() <= src2.reinterpret_as_uint64() {
            1L
          } else {
            0L
          }
      }
      [builder.build_imove_imm(data_size, dst~, src~)]
    }
    opcode =>
      raise IRTranslateError(
        "Unsupported operand types for integer comparison: \{opcode}",
      )
  }
}

///|
pub fn translate_llvm_fcmp_inst(
  llvm_inst : @IR.FCmpInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  guard func.get_operand_from_llvm_value(llvm_inst) is Some(dst_op) else {
    return []
  }
  guard dst_op is IRegister(dst) else {
    raise IRTranslateError(
      "FCmpInst: destination operand is not an integer register",
    )
  }
  let { predicate, lhs, rhs, .. } = llvm_inst
  match predicate {
    FALSE => return [builder.build_imove_imm(64, dst~, src=0L)]
    TRUE => return [builder.build_imove_imm(64, dst~, src=1L)]
    _ => ()
  }
  let opcode : FCmpOpCode = match predicate {
    OEQ => Feq
    OGT => Fgt
    OGE => Fge
    OLT => Flt
    OLE => Fle
    ONE => Fne
    UEQ => Feq // unordered or equal
    UGT => Fgt // unordered or greater than
    UGE => Fge // unordered or greater than or equal
    ULT => Flt // unordered or less than
    ULE => Fle // unordered or less than or equal
    UNE => Fne // unordered or not equal
    _ =>
      raise IRTranslateError("Unsupported floating-point comparison predicate")
  }
  guard func.get_operand_from_llvm_value(lhs) is Some(lhs_op) else {
    raise IRTranslateError("FCmpInst: lhs operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(rhs) is Some(rhs_op) else {
    raise IRTranslateError("FCmpInst: rhs operand not found in value_map")
  }
  let data_size = data_layout.getTypeAllocSizeInBits(lhs.getType())
  match (lhs_op, rhs_op) {
    (FRegister(src1), FRegister(src2)) =>
      [builder.build_fcmp(opcode, data_size, dst~, src1~, src2~)]
    (FRegister(src1), FImm(f)) => {
      let ireg = func.new_virtual_reg()
      let src2 = func.new_virtual_freg()
      [
        builder.build_imove_imm(
          data_size,
          dst=ireg,
          src=f.reinterpret_as_int64(),
        ),
        builder.build_fmove_from_ireg(data_size, dst=src2, src=ireg),
        builder.build_fcmp(opcode, data_size, dst~, src1~, src2~),
      ]
    }
    (FImm(f1), FRegister(src2)) => {
      let src1 = func.new_virtual_freg()
      let ireg = func.new_virtual_reg()
      [
        builder.build_imove_imm(
          data_size,
          dst=ireg,
          src=f1.reinterpret_as_int64(),
        ),
        builder.build_fmove_from_ireg(data_size, dst=src1, src=ireg),
        builder.build_fcmp(opcode, data_size, dst~, src1~, src2~),
      ]
    }
    (FImm(f1), FImm(f2)) => {
      let src = match opcode {
        Feq => if f1 == f2 { 1L } else { 0L }
        Fne => if f1 != f2 { 1L } else { 0L }
        Fgt => if f1 > f2 { 1L } else { 0L }
        Fge => if f1 >= f2 { 1L } else { 0L }
        Flt => if f1 < f2 { 1L } else { 0L }
        Fle => if f1 <= f2 { 1L } else { 0L }
      }
      [builder.build_imove_imm(data_size, dst~, src~)]
    }
    (lhs_op, rhs_op) =>
      raise IRTranslateError(
        "Unsupported operand types for floating-point comparison: \{lhs_op}, \{rhs_op}",
      )
  }
}

///|
pub fn translate_llvm_branch_inst(
  llvm_inst : @IR.BranchInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  match llvm_inst.condition {
    Some(_) =>
      translate_llvm_conditional_branch(llvm_inst, builder, func, data_layout)
    None => translate_llvm_unconditional_branch(llvm_inst, builder, func)
  }
}

///|
/// IRTranslate from LLVM IR to MoonMIR for conditional BranchInst.
pub fn translate_llvm_conditional_branch(
  llvm_inst : @IR.BranchInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  guard llvm_inst
    is {
      condition: Some(cond),
      trueBlock: Some(truebb),
      falseBlock: Some(falsebb),
      ..,
    } else {
    raise IRTranslateError("BranchInst: Invalid conditional branch instruction")
  }
  guard func.get_operand_from_llvm_value(truebb) is Some(true_op) else {
    raise IRTranslateError(
      "BranchInst: trueBlock operand not found in value_map",
    )
  }
  guard func.get_operand_from_llvm_value(falsebb) is Some(false_op) else {
    raise IRTranslateError(
      "BranchInst: falseBlock operand not found in value_map",
    )
  }
  guard true_op is Label(true_label) else {
    raise IRTranslateError("BranchInst: trueBlock operand is not a label")
  }
  guard false_op is Label(false_label) else {
    raise IRTranslateError("BranchInst: falseBlock operand is not a label")
  }
  // Push the successors and predecessors
  let machine_true_bb = func.bbmap.get(true_label).unwrap()
  let machine_false_bb = func.bbmap.get(false_label).unwrap()
  let current_bb = builder.bb
  machine_true_bb.preds.push(current_bb)
  machine_false_bb.preds.push(current_bb)
  current_bb.succs.push(machine_true_bb)
  current_bb.succs.push(machine_false_bb)
  if !(cond.asValueEnum() is ICmpInst(_)) {
    guard func.get_operand_from_llvm_value(cond) is Some(cond_op) else {
      raise IRTranslateError(
        "BranchInst: condition operand not found in value_map",
      )
    }
    match cond_op {
      IRegister(lhs) => {
        let minst = builder.build_branch_imm(
          Bne,
          64,
          lhs~,
          rhs=0L,
          true_label~,
          false_label~,
        )
        return [minst]
      }
      Imm(val) => {
        // Handle constant condition: branch to true_label if non-zero, false_label if zero
        let target_label = if val != 0L { true_label } else { false_label }
        return [builder.build_jmp(target_label~)]
      }
      _ =>
        raise IRTranslateError(
          "BranchInst: condition operand is not an integer register or immediate, it is \{cond_op}",
        )
    }
  }

  //
  let cmp_users = cond.getUsers().unwrap()
  let cmp_only_used_in_branch = cmp_users.length() == 1 &&
    cmp_users[0].asValueEnum() is BranchInst(_)

  // If the comparison instruction is not only used in this branch,
  // generate Bne directly.
  if !cmp_only_used_in_branch {
    guard func.get_operand_from_llvm_value(cond) is Some(cond_op) else {
      raise IRTranslateError(
        "BranchInst: condition operand not found in value_map",
      )
    }
    match cond_op {
      IRegister(lhs) => {
        let minst = builder.build_branch_imm(
          Bne,
          64,
          lhs~,
          rhs=0L,
          true_label~,
          false_label~,
        )
        return [minst]
      }
      Imm(val) => {
        // Handle constant condition: branch to true_label if non-zero, false_label if zero
        let target_label = if val != 0L { true_label } else { false_label }
        return [builder.build_jmp(target_label~)]
      }
      _ =>
        raise IRTranslateError(
          "BranchInst: condition operand is not an integer register or immediate, it is \{cond_op}",
        )
    }
  }

  // If the comparison instruction only used in this branch,
  // generate breach with the comparison.
  guard cond.asValueEnum() is ICmpInst({ predicate, lhs, rhs, .. })
  let opcode = match predicate {
    EQ => Beq
    NE => Bne
    SGT => Bgt
    SGE => Bge
    SLT => Blt
    SLE => Ble
    UGT => Bgtu
    UGE => Bgeu
    ULT => Bltu
    ULE => Bleu
  }
  guard func.get_operand_from_llvm_value(lhs) is Some(lhs_op) else {
    raise IRTranslateError("BranchInst: lhs operand not found in value_map")
  }
  guard func.get_operand_from_llvm_value(rhs) is Some(rhs_op) else {
    raise IRTranslateError("BranchInst: rhs operand not found in value_map")
  }
  let data_size = data_layout.getTypeAllocSizeInBits(lhs.getType())
  match (lhs_op, rhs_op) {
    (IRegister(lhs), IRegister(rhs)) =>
      [
        builder.build_branch(
          opcode,
          data_size,
          lhs~,
          rhs~,
          true_label~,
          false_label~,
        ),
      ]
    (IRegister(lhs), Imm(rhs)) =>
      [
        builder.build_branch_imm(
          opcode,
          data_size,
          lhs~,
          rhs~,
          true_label~,
          false_label~,
        ),
      ]
    (Imm(lhs_imm), IRegister(rhs)) => {
      let lhs = func.new_virtual_reg()
      [
        builder.build_imove_imm(data_size, dst=lhs, src=lhs_imm),
        builder.build_branch(
          opcode,
          data_size,
          lhs~,
          rhs~,
          true_label~,
          false_label~,
        ),
      ]
    }
    (Imm(lhs), Imm(rhs)) => {
      let take_true_branch = match opcode {
        Beq => lhs == rhs
        Bne => lhs != rhs
        Bgt => lhs > rhs
        Bge => lhs >= rhs
        Blt => lhs < rhs
        Ble => lhs <= rhs
        Bgtu => lhs.reinterpret_as_uint64() > rhs.reinterpret_as_uint64()
        Bgeu => lhs.reinterpret_as_uint64() >= rhs.reinterpret_as_uint64()
        Bltu => lhs.reinterpret_as_uint64() < rhs.reinterpret_as_uint64()
        // Bleu
        _ => lhs.reinterpret_as_uint64() <= rhs.reinterpret_as_uint64()
      }
      let target_label = if take_true_branch { true_label } else { false_label }
      [builder.build_jmp(target_label~)]
    }
    (lhs_op, rhs_op) =>
      raise IRTranslateError(
        "Unsupported operand types for integer comparison in BranchInst: \{lhs_op}, \{rhs_op}",
      )
  }
}

///|
/// IRTranslate from LLVM IR to MoonMIR for unconditional BranchInst.
pub fn translate_llvm_unconditional_branch(
  llvm_inst : @IR.BranchInst,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  guard llvm_inst
    is { condition: None, trueBlock: Some(targetBB), falseBlock: None, .. } else {
    raise IRTranslateError(
      "BranchInst: Invalid unconditional branch instruction",
    )
  }
  guard func.get_operand_from_llvm_value(targetBB) is Some(target_op) else {
    raise IRTranslateError(
      "BranchInst: trueBlock operand not found in value_map",
    )
  }
  guard target_op is Label(target_label) else {
    raise IRTranslateError("BranchInst: trueBlock operand is not a label")
  }
  let machine_target_bb = func.bbmap.get(target_label).unwrap()
  let current_bb = builder.bb
  machine_target_bb.preds.push(current_bb)
  current_bb.succs.push(machine_target_bb)
  let minst = builder.build_jmp(target_label~)
  [minst]
}

///|
pub fn translate_llvm_switch_inst(
  llvm_inst : @IR.SwitchInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  let { condition, defaultDest, cases, .. } = llvm_inst

  // Get the condition operand
  guard func.get_operand_from_llvm_value(condition) is Some(cond_op) else {
    raise IRTranslateError(
      "SwitchInst: condition operand not found in value_map",
    )
  }
  guard cond_op is IRegister(cond_reg) else {
    raise IRTranslateError(
      "SwitchInst: condition operand is not an integer register",
    )
  }

  // Get the default destination label
  guard func.get_operand_from_llvm_value(defaultDest) is Some(default_op) else {
    raise IRTranslateError(
      "SwitchInst: defaultDest operand not found in value_map",
    )
  }
  guard default_op is Label(default_label) else {
    raise IRTranslateError("SwitchInst: defaultDest operand is not a label")
  }

  // Get the data size for comparison
  let data_size = data_layout.getTypeAllocSizeInBits(condition.getType())

  // Setup successors and predecessors for the current basic block
  let current_bb = builder.bb
  let machine_default_bb = func.bbmap.get(default_label).unwrap()

  // If there are no cases, just jump to default
  if cases.length() == 0 {
    machine_default_bb.preds.push(current_bb)
    current_bb.succs.push(machine_default_bb)
    let jmp_inst = builder.build_jmp(target_label=default_label)
    return [jmp_inst]
  }

  // For each case destination, setup successors and predecessors
  for case in cases {
    let (_, case_dest) = case
    guard func.get_operand_from_llvm_value(case_dest) is Some(case_op) else {
      raise IRTranslateError(
        "SwitchInst: case destination operand not found in value_map",
      )
    }
    guard case_op is Label(case_label) else {
      raise IRTranslateError(
        "SwitchInst: case destination operand is not a label",
      )
    }
    let machine_case_bb = func.bbmap.get(case_label).unwrap()
    machine_case_bb.preds.push(current_bb)
    current_bb.succs.push(machine_case_bb)
  }

  // Generate instructions in the current basic block
  let minsts : Array[Instruction] = Array::new()

  // Strategy: Generate a chain of basic blocks, each checking one case
  // The first case is checked in the current basic block
  let mut prev_bb = current_bb
  for i, case in cases {
    let (case_value, case_dest) = case
    let case_imm = case_value.getValueAsInt64()
    guard func.get_operand_from_llvm_value(case_dest) is Some(case_op) else {
      raise IRTranslateError(
        "SwitchInst: case destination operand not found in value_map",
      )
    }
    guard case_op is Label(case_label) else {
      raise IRTranslateError(
        "SwitchInst: case destination operand is not a label",
      )
    }

    // Determine the false label (where to go if this case doesn't match)
    let false_label = if i + 1 < cases.length() {
      // Create a new basic block for the next case check
      "\{func.name}_switch\{llvm_inst.uid}_check\{i + 1}"
    } else {
      // Last case, jump to default if it doesn't match
      default_label
    }

    // Generate beq instruction in the current/previous basic block
    let curr_builder = IRBuilder::new(func, prev_bb)
    let inst = curr_builder.build_branch_imm(
      Beq,
      data_size,
      lhs=cond_reg,
      rhs=case_imm,
      true_label=case_label,
      false_label~,
    )

    // Add instruction to the appropriate basic block
    if i == 0 {
      // First case: add to the return array
      minsts.push(inst)
    } else {
      // Subsequent cases: add directly to the new basic block
      prev_bb.push(inst)
    }

    // Create a new basic block for the next case check (if not the last case)
    if i + 1 < cases.length() {
      let next_check_label = "\{func.name}_switch\{llvm_inst.uid}_check\{i + 1}"
      let next_check_bb = func.append_basic_block(next_check_label)

      // Setup the predecessor for the next check block
      next_check_bb.preds.push(prev_bb)
      prev_bb.succs.push(next_check_bb)

      // Update prev_bb for the next iteration
      prev_bb = next_check_bb
    } else {
      // Last case: setup default as successor
      machine_default_bb.preds.push(prev_bb)
      prev_bb.succs.push(machine_default_bb)
    }
  }
  minsts
}

///|
pub fn translate_llvm_cast_inst(
  llvm_inst : @IR.CastInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  let { opcode, from_val, to_ty, .. } = llvm_inst
  guard func.get_operand_from_llvm_value(from_val) is Some(from_op) else {
    raise IRTranslateError("CastInst: source operand not found in value_map")
  }
  let from_ty_size = data_layout.getTypeAllocSizeInBits(from_val.getType())
  let to_ty_size = data_layout.getTypeAllocSizeInBits(to_ty)
  guard func.get_operand_from_llvm_value(llvm_inst) is Some(dst_op) else {
    return []
  }
  match opcode {
    Trunc =>
      translate_trunc(from_ty_size, to_ty_size, from_op, dst_op, builder, func)
    SExt =>
      translate_sext(from_ty_size, to_ty_size, from_op, dst_op, builder, func)
    ZExt =>
      translate_zext(from_ty_size, to_ty_size, from_op, dst_op, builder, func)
    FPTrunc =>
      translate_fptrunc(
        from_ty_size, to_ty_size, from_op, dst_op, builder, func,
      )
    FPExt =>
      translate_fpext(from_ty_size, to_ty_size, from_op, dst_op, builder, func)
    UIToFP =>
      translate_uitofp(from_ty_size, to_ty_size, from_op, dst_op, builder, func)
    SIToFP =>
      translate_sitofp(from_ty_size, to_ty_size, from_op, dst_op, builder, func)
    FPToUI =>
      translate_fptoui(from_ty_size, to_ty_size, from_op, dst_op, builder, func)
    FPToSI =>
      translate_fptosi(from_ty_size, to_ty_size, from_op, dst_op, builder, func)
    PtrToInt => translate_bitcast(64, from_op, dst_op, builder, func)
    IntToPtr => translate_bitcast(64, from_op, dst_op, builder, func)
    BitCast => translate_bitcast(from_ty_size, from_op, dst_op, builder, func)
  }
}

///|
pub fn translate_trunc(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (IRegister(dst), IRegister(src)) =>
      [builder.build_trunc(from_ty_size~, to_ty_size~, dst~, src~)]
    (IRegister(dst), Imm(src_imm)) => {
      let src = func.new_virtual_reg()
      [
        builder.build_imove_imm(from_ty_size, dst=src, src=src_imm),
        builder.build_trunc(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "Trunc: Unsupported operand types for truncation, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_sext(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (IRegister(dst), IRegister(src)) =>
      [builder.build_sext(from_ty_size~, to_ty_size~, dst~, src~)]
    (IRegister(dst), Imm(src_imm)) => {
      let src = func.new_virtual_reg()
      [
        builder.build_imove_imm(from_ty_size, dst=src, src=src_imm),
        builder.build_sext(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "SExt: Unsupported operand types for sign extension, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_zext(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (IRegister(dst), IRegister(src)) =>
      [builder.build_zext(from_ty_size~, to_ty_size~, dst~, src~)]
    (IRegister(dst), Imm(src_imm)) => {
      let src = func.new_virtual_reg()
      [
        builder.build_imove_imm(from_ty_size, dst=src, src=src_imm),
        builder.build_zext(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "ZExt: Unsupported operand types for zero extension, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_fptrunc(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (FRegister(dst), FRegister(src)) =>
      [builder.build_fptrunc(from_ty_size~, to_ty_size~, dst~, src~)]
    (FRegister(dst), FImm(src_imm)) => {
      let src = func.new_virtual_freg()
      let ireg = func.new_virtual_reg()
      [
        builder.build_imove_imm(
          from_ty_size,
          dst=ireg,
          src=src_imm.reinterpret_as_int64(),
        ),
        builder.build_fmove_from_ireg(from_ty_size, dst=src, src=ireg),
        builder.build_fptrunc(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "FPTrunc: Unsupported operand types for floating-point truncation, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_fpext(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (FRegister(dst), FRegister(src)) =>
      [builder.build_fpext(from_ty_size~, to_ty_size~, dst~, src~)]
    (FRegister(dst), FImm(src_imm)) => {
      let src = func.new_virtual_freg()
      let ireg = func.new_virtual_reg()
      [
        builder.build_imove_imm(
          from_ty_size,
          dst=ireg,
          src=src_imm.reinterpret_as_int64(),
        ),
        builder.build_fmove_from_ireg(from_ty_size, dst=src, src=ireg),
        builder.build_fpext(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "FPExt: Unsupported operand types for floating-point extension, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_uitofp(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (FRegister(dst), IRegister(src)) =>
      [builder.build_ui_to_fp(from_ty_size~, to_ty_size~, dst~, src~)]
    (FRegister(dst), Imm(src_imm)) => {
      let src = func.new_virtual_reg()
      [
        builder.build_imove_imm(from_ty_size, dst=src, src=src_imm),
        builder.build_ui_to_fp(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "UIToFP: Unsupported operand types for unsigned integer to floating-point conversion, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_sitofp(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (FRegister(dst), IRegister(src)) =>
      [builder.build_si_to_fp(from_ty_size~, to_ty_size~, dst~, src~)]
    (FRegister(dst), Imm(src_imm)) => {
      let src = func.new_virtual_reg()
      [
        builder.build_imove_imm(from_ty_size, dst=src, src=src_imm),
        builder.build_si_to_fp(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "SIToFP: Unsupported operand types for signed integer to floating-point conversion, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_fptoui(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (IRegister(dst), FRegister(src)) =>
      [builder.build_fp_to_ui(from_ty_size~, to_ty_size~, dst~, src~)]
    (IRegister(dst), FImm(src_imm)) => {
      let src = func.new_virtual_freg()
      let ireg = func.new_virtual_reg()
      [
        builder.build_imove_imm(
          from_ty_size,
          dst=ireg,
          src=src_imm.reinterpret_as_int64(),
        ),
        builder.build_fmove_from_ireg(from_ty_size, dst=src, src=ireg),
        builder.build_fp_to_ui(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "FPToUI: Unsupported operand types for floating-point to unsigned integer conversion, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_fptosi(
  from_ty_size : Int,
  to_ty_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (IRegister(dst), FRegister(src)) =>
      [builder.build_fp_to_si(from_ty_size~, to_ty_size~, dst~, src~)]
    (IRegister(dst), FImm(src_imm)) => {
      let src = func.new_virtual_freg()
      let ireg = func.new_virtual_reg()
      [
        builder.build_imove_imm(
          from_ty_size,
          dst=ireg,
          src=src_imm.reinterpret_as_int64(),
        ),
        builder.build_fmove_from_ireg(from_ty_size, dst=src, src=ireg),
        builder.build_fp_to_si(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "FPToSI: Unsupported operand types for floating-point to signed integer conversion, got \{dst_op}, \{from_op}",
      )
  }
}

// MIR has no bitcast instruction
// Use Move, FMoveI, IMoveF, Load, Store, etc. to implement BitCast

///|
pub fn translate_bitcast(
  data_size : Int,
  from_op : Operand,
  dst_op : Operand,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  match (dst_op, from_op) {
    (IRegister(dst), IRegister(src)) =>
      [builder.build_imove(data_size, dst~, src~)]
    (IRegister(dst), Imm(src_imm)) =>
      [builder.build_imove_imm(data_size, dst~, src=src_imm)]
    (FRegister(dst), FRegister(src)) =>
      [builder.build_fmove(data_size, dst~, src~)]
    (FRegister(dst), FImm(src_imm)) => {
      let ireg = func.new_virtual_reg()
      [
        builder.build_imove_imm(
          data_size,
          dst=ireg,
          src=src_imm.reinterpret_as_int64(),
        ),
        builder.build_fmove_from_ireg(data_size, dst~, src=ireg),
      ]
    }
    (FRegister(dst), IRegister(src)) =>
      [builder.build_fmove_from_ireg(data_size, dst~, src~)]
    (IRegister(dst), FRegister(src)) =>
      [builder.build_fmove_to_ireg(data_size, dst~, src~)]
    (FRegister(dst), Imm(src_imm)) => {
      let ireg = func.new_virtual_reg()
      [
        builder.build_imove_imm(data_size, dst=ireg, src=src_imm),
        builder.build_fmove_from_ireg(data_size, dst~, src=ireg),
      ]
    }
    (IRegister(dst), FImm(src_imm)) => {
      let freg = func.new_virtual_freg()
      [
        builder.build_imove_imm(
          data_size,
          dst~,
          src=src_imm.reinterpret_as_int64(),
        ),
        builder.build_fmove_to_ireg(data_size, dst~, src=freg),
      ]
    }
    (dst_op, from_op) =>
      raise IRTranslateError(
        "BitCast: Unsupported operand types for bitcast, got \{dst_op}, \{from_op}",
      )
  }
}

///|
pub fn translate_llvm_gep_inst(
  llvm_inst : @IR.GetElementPtrInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  let { ptr, indices, pointeeType, .. } = llvm_inst
  guard func.get_operand_from_llvm_value(ptr) is Some(ptr_op) else {
    raise IRTranslateError(
      "GetElementPtrInst: pointer operand not found in value_map",
    )
  }
  guard func.get_operand_from_llvm_value(llvm_inst) is Some(dst_op) else {
    // If the destination operand is not found, it means this GEP instruction
    // was skipped because its result is never used (dead code)
    return []
  }
  guard dst_op is IRegister(ptr_reg) else {
    raise IRTranslateError(
      "GetElementPtrInst: destination operand is not an integer register",
    )
  }
  let minsts : Array[Instruction] = []
  match ptr_op {
    IRegister(r) => {
      let inst = builder.build_imove(64, dst=ptr_reg, src=r)
      minsts.push(inst)
    }
    MemLoc(base, 0L) => {
      let inst = builder.build_imove(64, dst=ptr_reg, src=base)
      minsts.push(inst)
    }
    MemLoc(base, offset) => {
      let inst = builder.build_ibinary_imm(
        Add,
        64,
        dst=ptr_reg,
        src1=base,
        src2=offset,
      )
      minsts.push(inst)
    }
    Label(label) => {
      let inst = builder.build_load_addr(ptr_reg, label)
      minsts.push(inst)
    }
    op =>
      raise IRTranslateError(
        "GetElementPtrInst: unsupported pointer operand type: \{op}",
      )
  }
  let indices_ops : Array[Operand] = []
  for idx_val in indices {
    guard func.get_operand_from_llvm_value(idx_val) is Some(idx_op) else {
      raise IRTranslateError(
        "GetElementPtrInst: index operand not found in value_map",
      )
    }
    indices_ops.push(idx_op)
  }
  guard indices_ops is [first_idx_op, .. indices_ops]
  match first_idx_op {
    Imm(0) => ()
    Imm(i) => {
      let offset = data_layout.getTypeAllocSize(pointeeType).to_int64() * i
      let inst = builder.build_ibinary_imm(
        Add,
        64,
        dst=ptr_reg,
        src1=ptr_reg,
        src2=offset,
      )
      minsts.push(inst)
    }
    IRegister(idx_r) => {
      let offset = data_layout.getTypeAllocSize(pointeeType).to_int64()
      let scaled_idx = func.new_virtual_reg()
      let inst1 = builder.build_ibinary_imm(
        Mul,
        64,
        dst=scaled_idx,
        src1=idx_r,
        src2=offset,
      )
      let inst2 = builder.build_ibinary(
        Add,
        64,
        dst=ptr_reg,
        src1=ptr_reg,
        src2=scaled_idx,
      )
      minsts..push(inst1)..push(inst2)
    }
    _ =>
      raise IRTranslateError(
        "GetElementPtrInst: unsupported first index operand in GEP translation",
      )
  }
  loop (pointeeType.asTypeEnum(), indices_ops) {
    (_, []) => break
    (_, [Imm(0)]) => break
    (ArrayType({ elementType, .. }), [Imm(0), .. rest_indices]) =>
      continue (elementType.asTypeEnum(), rest_indices)
    (ArrayType({ elementType, .. }), [Imm(i), .. rest_indices]) => {
      let elem_size = data_layout.getTypeAllocSize(elementType).to_int64()
      let offset = elem_size * i
      let inst = builder.build_ibinary_imm(
        Add,
        64,
        dst=ptr_reg,
        src1=ptr_reg,
        src2=offset,
      )
      minsts.push(inst)
      continue (elementType.asTypeEnum(), rest_indices)
    }
    (ArrayType({ elementType, .. }), [IRegister(idx_r), .. rest_indices]) => {
      let offset = data_layout.getTypeAllocSize(elementType).to_int64()
      let scaled_idx = func.new_virtual_reg()
      let inst1 = builder.build_ibinary_imm(
        Mul,
        64,
        dst=scaled_idx,
        src1=idx_r,
        src2=offset,
      )
      let inst2 = builder.build_ibinary(
        Add,
        64,
        dst=ptr_reg,
        src1=ptr_reg,
        src2=scaled_idx,
      )
      minsts.push(inst1)
      minsts.push(inst2)
      continue (elementType.asTypeEnum(), rest_indices)
    }
    (StructType({ elements, .. }), [Imm(0), .. rest_indices]) => {
      guard elements.get(0) is Some(elem_type) else {
        raise IRTranslateError("GetElementPtrInst: StructType has no elements")
      }
      continue (elem_type.asTypeEnum(), rest_indices)
    }
    (StructType({ elements, .. } as sty), [Imm(i), .. rest_indices]) => {
      let i_int = i.to_int()
      guard elements.get(i_int) is Some(elem_type) else {
        raise IRTranslateError(
          "GetElementPtrInst: StructType index out of bounds",
        )
      }
      let offset = data_layout.getStructTypeOffset(sty, i_int)
      let offset = offset.to_int64()
      let inst = builder.build_ibinary_imm(
        Add,
        64,
        dst=ptr_reg,
        src1=ptr_reg,
        src2=offset,
      )
      minsts.push(inst)
      continue (elem_type.asTypeEnum(), rest_indices)
    }
    (t, indices) =>
      raise IRTranslateError(
        "GetElementPtrInst: unsupported type or indices in GEP translation: \{t}, \{indices}",
      )
  }
  minsts
}

///|
pub fn translate_llvm_select_inst(
  llvm_inst : @IR.SelectInst,
  builder : IRBuilder,
  func : Function,
  data_layout : @IR.DataLayout,
) -> Array[Instruction] raise MIRError {
  raise IRTranslateError("SelectInst translation not implemented yet")
  ignore(llvm_inst)
  ignore(builder)
  ignore(func)
  ignore(data_layout)
  []
}

///|
pub fn translate_llvm_return_inst(
  llvm_inst : @IR.ReturnInst,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  func.terminal_blocks.push(builder.bb)
  let { retVal, .. } = llvm_inst
  guard retVal is Some(retVal) else {
    let minst = builder.build_ret()
    return [minst]
  }
  // Check if return type is void
  if retVal.getType().asTypeEnum() is VoidType(_) {
    let minst = builder.build_ret()
    return [minst]
  }
  guard func.get_operand_from_llvm_value(retVal) is Some(ret_op) else {
    raise IRTranslateError(
      "ReturnInst: return value operand not found in value_map",
    )
  }
  match ret_op {
    IRegister(ret) if !(ret is AReg(0)) => {
      let minst = builder.build_imove(64, dst=AReg(0), src=ret)
      return [minst, builder.build_ret()]
    }
    IRegister(_) => [builder.build_ret()]
    FRegister(ret) if !(ret is FAReg(0)) => {
      let minst = builder.build_fmove(64, dst=FAReg(0), src=ret)
      return [minst, builder.build_ret()]
    }
    FRegister(_) => [builder.build_ret()]
    Imm(ret) => {
      let minst = builder.build_imove_imm(64, dst=AReg(0), src=ret)
      return [minst, builder.build_ret()]
    }
    FImm(ret) => {
      let ireg = func.new_virtual_reg()
      let freg = func.new_virtual_freg()
      [
        builder.build_imove_imm(64, dst=ireg, src=ret.reinterpret_as_int64()),
        builder.build_fmove_from_ireg(64, dst=freg, src=ireg),
        builder.build_fmove(64, dst=FAReg(0), src=freg),
        builder.build_ret(),
      ]
    }
    Label(label) => {
      let minst = builder.build_load_addr(AReg(0), label)
      [minst, builder.build_ret()]
    }
    ret_op =>
      raise IRTranslateError(
        "ReturnInst: Unsupported operand type for return value \{ret_op}",
      )
  }
}

///|
/// IRTranslate from LLVM IR to MoonMIR for CallInst.
pub fn translate_llvm_call_inst(
  llvm_inst : @IR.CallInst,
  builder : IRBuilder,
  func : Function,
) -> Array[Instruction] raise MIRError {
  let { callee, args, .. } = llvm_inst
  let { num_arg_regs, num_arg_fregs, arch_name, .. } = func.mod.arch_config

  // Handle both direct function calls and indirect function pointer calls
  let (is_indirect_call, callee_op, callee_name_opt) : (Bool, Operand?, String?) = match
    callee {
    Left(llvm_func) => {
      let name = llvm_func.getName().unwrap()
      (false, None, Some(name))
    }
    Right(func_ptr) => {
      // Function pointer call - get the operand for the function pointer
      guard func.get_operand_from_llvm_value(func_ptr) is Some(op) else {
        raise IRTranslateError(
          "CallInst: function pointer operand not found in value_map",
        )
      }
      match op {
        IRegister(_) => (true, Some(op), None)
        _ =>
          raise IRTranslateError(
            "CallInst: function pointer must be in an integer register, got \{op}",
          )
      }
    }
  }

  // Check if the callee is a variadic function
  // For indirect calls, we cannot determine if it's variadic, so assume non-variadic
  let is_variadic_call = llvm_inst.getFunctionType().isVarArg

  // For AArch64 variadic functions, arguments after the first one should be on stack only
  // The first argument (format string) still goes in register x0
  let is_aarch64_variadic = is_variadic_call && arch_name == "aarch64"
  let mut call_ireg_cnt = 0
  let mut call_freg_cnt = 0
  let mut variadic_stack_offset = 0L // Stack offset for variadic arguments
  let minsts : Array[Instruction] = Array::new()
  for arg_idx, arg in args {
    guard func.get_operand_from_llvm_value(arg) is Some(arg_op) else {
      raise IRTranslateError(
        "CallInst: argument operand not found in value_map",
      )
    }
    let arg_is_fp = arg.getType().isIEEELikeFPTy()

    // For AArch64 variadic functions, arguments after index 0 go on stack only
    let force_stack = is_aarch64_variadic && arg_idx > 0
    match (arg_op, arg_is_fp) {
      (IRegister(src), false) if !force_stack && call_ireg_cnt < num_arg_regs => {
        let dst = AReg(call_ireg_cnt)
        let inst = builder.build_imove(64, dst~, src~)
        if src != dst {
          minsts.push(inst)
        }
        call_ireg_cnt += 1
      }
      (IRegister(src), false) if force_stack => {
        // For variadic functions on AArch64, put on stack at variadic_stack_offset
        let _ = func.extend_var_stack(8L, 8L)
        let inst = builder.build_storei(
          64,
          src~,
          base=StackPtr,
          offset=variadic_stack_offset,
        )
        minsts.push(inst)
        variadic_stack_offset += 8
      }
      (IRegister(src), false) => {
        let _ = func.extend_var_stack(8L, 8L)
        let stack_offset = 8L * (call_ireg_cnt - num_arg_regs).to_int64()
        let inst = builder.build_storei(
          64,
          src~,
          base=StackPtr,
          offset=stack_offset,
        )
        minsts.push(inst)
        call_ireg_cnt += 1
      }
      (FRegister(src), true) if call_freg_cnt < num_arg_fregs => {
        let dst = FAReg(call_freg_cnt)
        // Get the argument type width
        let arg_ty = arg.getType()
        let arg_width = match arg_ty.asTypeEnum() {
          FloatType(_) => 32
          DoubleType(_) => 64
          _ => 64 // Default to 64 for other types
        }
        let inst = builder.build_fmove(arg_width, dst~, src~)
        if src != dst {
          minsts.push(inst)
        }
        call_freg_cnt += 1
      }
      (FRegister(src), true) => {
        let _ = func.extend_var_stack(8L, 8L)
        let stack_offset = 8L * (call_freg_cnt - num_arg_fregs).to_int64()
        let inst = builder.build_storef(
          64,
          src~,
          base=StackPtr,
          offset=stack_offset,
        )
        minsts.push(inst)
        call_freg_cnt += 1
      }
      (Imm(src), false) if !force_stack && call_ireg_cnt < num_arg_regs => {
        let dst = AReg(call_ireg_cnt)
        let inst = builder.build_imove_imm(64, dst~, src~)
        minsts.push(inst)
        call_ireg_cnt += 1
      }
      (Imm(src), false) if force_stack => {
        // For variadic functions on AArch64, put on stack at variadic_stack_offset
        let _ = func.extend_var_stack(8L, 8L)
        let vreg = func.new_virtual_reg()
        let inst1 = builder.build_imove_imm(64, dst=vreg, src~)
        let inst2 = builder.build_storei(
          64,
          src=vreg,
          base=StackPtr,
          offset=variadic_stack_offset,
        )
        minsts.push(inst1)
        minsts.push(inst2)
        variadic_stack_offset += 8
      }
      (Imm(src), false) => {
        let _ = func.extend_var_stack(8L, 8L)
        let stack_offset = 8L * (call_ireg_cnt - num_arg_regs).to_int64()
        let vreg = func.new_virtual_reg()
        let inst1 = builder.build_imove_imm(64, dst=vreg, src~)
        let inst2 = builder.build_storei(
          64,
          src=vreg,
          base=StackPtr,
          offset=stack_offset,
        )
        minsts.push(inst1)
        minsts.push(inst2)
        call_ireg_cnt += 1
      }
      (FImm(src), true) if call_freg_cnt < num_arg_fregs => {
        let dst = FAReg(call_freg_cnt)
        // Get the argument type width
        let arg_ty = arg.getType()
        let arg_width = match arg_ty.asTypeEnum() {
          FloatType(_) => 32
          DoubleType(_) => 64
          _ => 64 // Default to 64 for other types
        }
        let ireg = func.new_virtual_reg()
        // Convert double bit representation to appropriate type
        let bit_value = match arg_width {
          32 => {
            // Convert double to float bit representation
            let float_val = Float::from_double(src)
            float_val.reinterpret_as_int().to_int64()
          }
          64 => src.reinterpret_as_int64()
          _ => src.reinterpret_as_int64()
        }
        let inst1 = builder.build_imove_imm(arg_width, dst=ireg, src=bit_value)
        let inst2 = builder.build_fmove_from_ireg(arg_width, dst~, src=ireg)
        minsts.push(inst1)
        minsts.push(inst2)
        call_freg_cnt += 1
      }
      (FImm(src), true) => {
        let _ = func.extend_var_stack(8L, 8L)
        let stack_offset = 8L * (call_freg_cnt - num_arg_fregs).to_int64()
        let ireg = func.new_virtual_reg()
        let inst1 = builder.build_imove_imm(
          64,
          dst=ireg,
          src=src.reinterpret_as_int64(),
        )
        let inst2 = builder.build_storei(
          64,
          src=ireg,
          base=StackPtr,
          offset=stack_offset,
        )
        minsts.push(inst1)
        minsts.push(inst2)
        call_freg_cnt += 1
      }
      (Label(label), false) if !force_stack && call_ireg_cnt < num_arg_regs => {
        let dst = AReg(call_ireg_cnt)
        let inst = builder.build_load_addr(dst, label)
        minsts.push(inst)
        call_ireg_cnt += 1
      }
      (Label(label), false) if force_stack => {
        // For variadic functions on AArch64, put on stack at variadic_stack_offset
        let _ = func.extend_var_stack(8L, 8L)
        let vreg = func.new_virtual_reg()
        let inst1 = builder.build_load_addr(vreg, label)
        let inst2 = builder.build_storei(
          64,
          src=vreg,
          base=StackPtr,
          offset=variadic_stack_offset,
        )
        minsts.push(inst1)
        minsts.push(inst2)
        variadic_stack_offset += 8
      }
      (Label(label), false) => {
        let _ = func.extend_var_stack(8L, 8L)
        let stack_offset = 8L * (call_ireg_cnt - num_arg_regs).to_int64()
        let vreg = func.new_virtual_reg()
        let inst1 = builder.build_load_addr(vreg, label)
        let inst2 = builder.build_storei(
          64,
          src=vreg,
          base=StackPtr,
          offset=stack_offset,
        )
        minsts.push(inst1)
        minsts.push(inst2)
        call_ireg_cnt += 1
      }
      (MemLoc(base, 0L), false) if !force_stack && call_ireg_cnt < num_arg_regs => {
        let dst = AReg(call_ireg_cnt)
        let inst = builder.build_imove(64, dst~, src=base)
        minsts.push(inst)
        call_ireg_cnt += 1
      }
      (MemLoc(base, 0L), false) if force_stack => {
        // For variadic functions on AArch64, put on stack at variadic_stack_offset
        let _ = func.extend_var_stack(8L, 8L)
        let inst = builder.build_storei(
          64,
          src=base,
          base=StackPtr,
          offset=variadic_stack_offset,
        )
        minsts.push(inst)
        variadic_stack_offset += 8
      }
      (MemLoc(base, offset), false) if !force_stack &&
        call_ireg_cnt < num_arg_regs => {
        let dst = AReg(call_ireg_cnt)
        let vreg = func.new_virtual_reg()
        let inst1 = builder.build_ibinary_imm(
          Add,
          64,
          dst=vreg,
          src1=base,
          src2=offset,
        )
        let inst2 = builder.build_imove(64, dst~, src=vreg)
        minsts.push(inst1)
        minsts.push(inst2)
        call_ireg_cnt += 1
      }
      (MemLoc(base, offset), false) if force_stack => {
        // For variadic functions on AArch64, put on stack at variadic_stack_offset
        let _ = func.extend_var_stack(8L, 8L)
        let vreg = func.new_virtual_reg()
        let inst1 = builder.build_ibinary_imm(
          Add,
          64,
          dst=vreg,
          src1=base,
          src2=offset,
        )
        let inst2 = builder.build_storei(
          64,
          src=vreg,
          base=StackPtr,
          offset=variadic_stack_offset,
        )
        minsts.push(inst1)
        minsts.push(inst2)
        variadic_stack_offset += 8
      }
      (MemLoc(base, 0L), false) => {
        let _ = func.extend_var_stack(8L, 8L)
        let stack_offset = 8L * (call_ireg_cnt - num_arg_regs).to_int64()
        let inst = builder.build_storei(
          64,
          src=base,
          base=StackPtr,
          offset=stack_offset,
        )
        minsts.push(inst)
        call_ireg_cnt += 1
      }
      (MemLoc(base, offset), false) => {
        let _ = func.extend_var_stack(8L, 8L)
        let stack_offset = 8L * (call_ireg_cnt - num_arg_regs).to_int64()
        let vreg = func.new_virtual_reg()
        let inst1 = builder.build_ibinary_imm(
          Add,
          64,
          dst=vreg,
          src1=base,
          src2=offset,
        )
        let inst2 = builder.build_storei(
          64,
          src=vreg,
          base=StackPtr,
          offset=stack_offset,
        )
        minsts.push(inst1)
        minsts.push(inst2)
        call_ireg_cnt += 1
      }
      arg_op =>
        raise IRTranslateError(
          "CallInst: Unsupported argument operand type: \{arg_op}",
        )
    }
  }

  // Generate the call instruction
  let call_inst = match (is_indirect_call, callee_op, callee_name_opt) {
    (false, _, Some(callee_name)) => builder.build_call(callee_name)
    (true, Some(op), _) =>
      // For indirect calls, create a Call instruction with the function pointer register as the first use
      Instruction::new(Call, [], [op], builder.bb)
    _ =>
      raise IRTranslateError(
        "CallInst: invalid state in call instruction generation",
      )
  }

  // Add argument registers to the call instruction uses
  for i = 0; i < call_ireg_cnt && i < num_arg_regs; i = i + 1 {
    call_inst.uses.push(IRegister(AReg(i)))
  }
  for i = 0; i < call_freg_cnt && i < num_arg_fregs; i = i + 1 {
    call_inst.uses.push(FRegister(FAReg(i)))
  }
  minsts.push(call_inst)
  if !(llvm_inst.getType().asTypeEnum() is VoidType(_)) {
    guard func.get_operand_from_llvm_value(llvm_inst) is Some(ret_op) else {
      return []
    }
    // Get the return type width
    let ret_ty = llvm_inst.getType()
    let ret_width = match ret_ty.asTypeEnum() {
      Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | FloatType(_) =>
        32
      Int64Type(_) | PointerType(_) | DoubleType(_) => 64
      _ => 64 // Default to 64 for other types
    }
    match ret_op {
      IRegister(dst) => {
        let inst = builder.build_imove(ret_width, dst~, src=AReg(0))
        minsts.push(inst)
        // need extra inst `move v, fa0` to avoid fa0 being used after call
        let tmp_freg = func.new_virtual_freg()
        let mv_fa0 = builder.build_fmove(64, dst=tmp_freg, src=FAReg(0))
        minsts.push(mv_fa0)
      }
      FRegister(dst) => {
        let inst = builder.build_fmove(ret_width, dst~, src=FAReg(0))
        minsts.push(inst)
        // need extra inst `move v, a0` to avoid a0 being used after call
        let tmp_reg = func.new_virtual_reg()
        let mv_a0 = builder.build_imove(64, dst=tmp_reg, src=AReg(0))
        minsts.push(mv_a0)
      }
      _ => ()
    }
  } else {
    // Even the call inst has no return value, still need a move from a0/fa0
    // Why we do that?
    // Because we need to ensure in register allocation phase
    // others varible not use a0/fa0 after the call instruction
    let tmp_reg = func.new_virtual_reg()
    let tmp_freg = func.new_virtual_freg()
    let mv_a0 = builder.build_imove(64, dst=tmp_reg, src=AReg(0))
    let mv_fa0 = builder.build_fmove(64, dst=tmp_freg, src=FAReg(0))
    minsts.push(mv_a0)
    minsts.push(mv_fa0)
  }
  minsts
}

///|
pub fn translate_llvm_phi_node(
  llvm_inst : @IR.PHINode,
  func : Function,
) -> Array[Instruction] raise MIRError {
  let { incomings, .. } = llvm_inst
  for imcoming in incomings {
    let (value, llvm_bb) = imcoming
    guard func.get_operand_from_llvm_value(value) is Some(value_op) else {
      raise IRTranslateError(
        "PHINode: incoming value operand not found in value_map",
      )
    }
    guard func.get_operand_from_llvm_value(llvm_bb) is Some(bb_op) else {
      raise IRTranslateError(
        "PHINode: incoming basic block operand not found in value_map",
      )
    }
    guard bb_op is Label(bb_label) else {
      raise IRTranslateError(
        "PHINode: incoming basic block operand is not a label",
      )
    }
    let machine_bb = func.bbmap.get(bb_label).unwrap()
    machine_bb.phi_nodes.push((llvm_inst, value_op))
  }
  []
}

///|
pub fn Function::phi_elimination(func : Self) -> Unit raise MIRError {
  func.body.each(bb => bb.phi_elimination())
}

///|
pub fn BasicBlock::phi_elimination(self : Self) -> Unit raise MIRError {
  let func = self.parent
  let data_layout = func.llvm_func.unwrap().getDataLayout()
  let builder = IRBuilder::new(func, self)
  for pair in self.phi_nodes {
    let (llvm_phi_node, value_op) = pair
    guard func.get_operand_from_llvm_value(llvm_phi_node) is Some(dst_op) else {
      raise IRTranslateError(
        "PHINode: destination operand not found in value_map",
      )
    }
    let data_size = data_layout.getTypeAllocSizeInBits(llvm_phi_node.getType())
    match (dst_op, value_op) {
      (IRegister(dst), IRegister(src)) => {
        let inst = builder.build_imove(data_size, dst~, src~)
        self.push_inst_before_terminator(inst)
      }
      (IRegister(dst), Imm(src)) => {
        let inst = builder.build_imove_imm(data_size, dst~, src~)
        self.push_inst_before_terminator(inst)
      }
      (FRegister(dst), FRegister(src)) => {
        let inst = builder.build_fmove(data_size, dst~, src~)
        self.push_inst_before_terminator(inst)
      }
      (FRegister(dst), FImm(src)) => {
        let inst = builder.build_fmove_imm(data_size, dst~, src~)
        self.push_inst_before_terminator(inst)
      }
      phi =>
        raise IRTranslateError(
          "PHINode: Unsupported operand types for phi elimination \{phi}",
        )
    }
  }
}
