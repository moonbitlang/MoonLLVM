// =======================================================
// AllocaInst
// =======================================================

///|
/// Alloca Instruction allocates memory on the stack for a variable.
///
/// **Note**:
/// 
/// Use `IRBuilder::createAlloca` to create an `AllocaInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let void_ty = ctx.getVoidTy()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(void_ty, [])
///
/// let fval = mod.addFunction(fty, "foo")
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let inst = builder.createAlloca(i32_ty, name="var1")
/// 
/// inspect(inst, content = "  %var1 = alloca i32, align 4")
/// ```
pub struct AllocaInst {
  uid : UInt64
  vty : &Type
  users : Array[&User]
  mut name : String?
  parent : Function
  data_ty : &Type
  align : Align
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn AllocaInst::new(
  data_ty : &Type,
  parent : Function,
  addressSpace~ : AddressSpace,
  name~ : String?,
) -> AllocaInst {
  let uid = valueUIDAssigner.assign()
  let vty = data_ty.getContext().getPtrTy(addressSpace~)
  let align = parent.getDataLayout().getAlignment(data_ty)
  //let inst_base = InstBase::new()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  AllocaInst::{
    uid,
    vty,
    users: [],
    name,
    parent,
    data_ty,
    align,
    bb,
    prev,
    next,
  }
}

///|
/// AllocaInst is one of `Value`.
pub impl Value for AllocaInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let void_ty = ctx.getVoidTy()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(void_ty, [])
///
/// let fval = mod.addFunction(fty, "foo")
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let inst = builder.createAlloca(i32_ty)
/// inspect(inst.getValueRepr(), content = "%0")
///
/// inst.setName("var1")
/// inspect(inst.getValueRepr(), content = "%var1")
/// ```
pub impl Value for AllocaInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for AllocaInst with asValueEnum(self) {
  AllocaInst(self)
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let void_ty = ctx.getVoidTy()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(void_ty, [])
///
/// let fval = mod.addFunction(fty, "foo")
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let inst = builder.createAlloca(i32_ty)
/// inspect(inst.getName(), content = "None")
///
/// inst.setName("var1")
/// inspect(inst.getName(), content = "Some(\"var1\")")
/// ```
pub impl Value for AllocaInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let void_ty = ctx.getVoidTy()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(void_ty, [])
///
/// let fval = mod.addFunction(fty, "foo")
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let inst = builder.createAlloca(i32_ty)
/// inspect(inst.getName(), content = "None")
///
/// inst.setName("var1")
/// inspect(inst.getName(), content = "Some(\"var1\")")
/// ```
pub impl Value for AllocaInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `AllocaInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `AllocaInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `AllocaInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for AllocaInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for AllocaInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl Instruction for AllocaInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for AllocaInst with asInstEnum(self) {
  AllocaInst(self)
}

///|
pub impl Instruction for AllocaInst with getParent(self) {
  self.parent
}

///|
pub impl UnaryInst for AllocaInst with asUnaryInstEnum(self) {
  AllocaInst(self)
}

///|
pub impl Show for AllocaInst with output(self, logger) {
  let repr = self.getValueRepr()
  logger.write_string("  \{repr} = alloca \{self.data_ty}, \{self.align}")
}

// =======================================================
// LoadInst
// =======================================================

///|
pub(all) enum AtomicOrdering {
  NotAtomic
  Unordered
  Monotonic
  Acquire
  Release
  AcquireRelease
  SequentiallyConsistent
} derive(Hash, Eq)

///|
pub impl Show for AtomicOrdering with output(self, logger) {
  let str = match self {
    NotAtomic => ""
    Unordered => "unordered"
    Monotonic => "monotonic"
    Acquire => "acquire"
    Release => "release"
    AcquireRelease => "acquire_release"
    SequentiallyConsistent => "sequentially_consistent"
  }
  logger.write_string(str)
}

///|
/// LoadInst is an instruction that loads a value from a pointer.
///
/// **Note**:
///
/// Use `IRBuilder::createLoad` to create a `LoadInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let ptr_ty = ctx.getPtrTy()
/// let i32_ty = ctx.getInt32Ty()
///
/// let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
/// let fval = mod.addFunction(fty, "load_an_integer")
///
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let ptr = fval.getArg(0).unwrap()
/// ptr.setName("arg0")
///
/// let val = builder.createLoad(i32_ty, ptr, name="val")
/// let _ = builder.createRet(val)
/// inspect(val, content = "  %val = load i32, ptr %arg0, align 4")
/// ```
pub(all) struct LoadInst {
  // --- ValueBase ---

  // Unique identifier
  uid : UInt64

  // Type of the value
  vty : &Type

  // Users of this value
  users : Array[&User]

  // Name of the value
  mut name : String?

  // --- UserBase ---

  // Pointer which this instruction loads from.
  ptr : &Value
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]

  // --- LoadInst ---
  isVolatile : Bool
  atomicOrdering : AtomicOrdering
  align : Align
}

///|
fn LoadInst::new(
  load_ty : &Type,
  ptr : &Value,
  isVolatile : Bool,
  atomicOrdering : AtomicOrdering,
  parent : Function,
  name~ : String?,
) -> LoadInst {
  let vty = load_ty
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let align = parent.getDataLayout().getAlignment(load_ty)
  let uid = valueUIDAssigner.assign()
  let inst = LoadInst::{
    uid,
    vty,
    name,
    users: [],
    ptr,
    parent,
    bb,
    prev,
    next,
    isVolatile,
    atomicOrdering,
    align,
  }
  ptr.addUser(inst)
  inst
}

///|
pub impl Value for LoadInst with asValueEnum(self) {
  LoadInst(self)
}

///|
pub impl Value for LoadInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let ptr_ty = ctx.getPtrTy()
/// let i32_ty = ctx.getInt32Ty()
///
/// let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
/// let fval = mod.addFunction(fty, "load_an_integer")
/// let bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(bb)
/// let ptr = fval.getArg(0).unwrap()
///
/// let val = builder.createLoad(i32_ty, ptr)
/// inspect(val.getValueRepr(), content = "%1")
///
/// val.setName("val")
/// inspect(val.getValueRepr(), content = "%val")
/// ```
pub impl Value for LoadInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let ptr_ty = ctx.getPtrTy()
/// let i32_ty = ctx.getInt32Ty()
///
/// let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
/// let fval = mod.addFunction(fty, "load_an_integer")
/// let bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(bb)
/// let ptr = fval.getArg(0).unwrap()
///
/// let val = builder.createLoad(i32_ty, ptr)
/// inspect(val.getName(), content = "None")
///
/// val.setName("val")
/// inspect(val.getName(), content = "Some(\"val\")")
/// ```
pub impl Value for LoadInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let ptr_ty = ctx.getPtrTy()
/// let i32_ty = ctx.getInt32Ty()
///
/// let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
/// let fval = mod.addFunction(fty, "load_an_integer")
/// let bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(bb)
/// let ptr = fval.getArg(0).unwrap()
///
/// let val = builder.createLoad(i32_ty, ptr)
/// inspect(val.getName(), content = "None")
///
/// val.setName("val")
/// inspect(val.getName(), content = "Some(\"val\")")
/// ```
pub impl Value for LoadInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `LoadInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `LoadInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `LoadInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
/// Remove the name of the instruction.
pub impl Value for LoadInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().removeSymbol(name)
      self.name = None
    }
  }
}

///|
pub impl Value for LoadInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for LoadInst with asUserEnum(self) {
  LoadInst(self)
}

///|
pub impl User for LoadInst with getUserBase(self) {
  UserBase::{ operands: [self.ptr] }
}

///|
pub impl Instruction for LoadInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for LoadInst with asInstEnum(self) {
  LoadInst(self)
}

///|
pub impl Instruction for LoadInst with getParent(self) {
  self.parent
}

///|
pub impl UnaryInst for LoadInst with asUnaryInstEnum(self) {
  LoadInst(self)
}

///|
pub impl Show for LoadInst with output(self, logger) {
  let align = self.align
  let repr = self.getValueRepr()
  let ptr_repr = self.ptr.getValueRepr()
  let load_ty = self.getType()
  let str = match (self.isVolatile, self.atomicOrdering) {
    (true, _) =>
      "  \{repr} = load volatile \{load_ty}, ptr \{ptr_repr}, \{align}"
    (false, NotAtomic) =>
      "  \{repr} = load \{load_ty}, ptr \{ptr_repr}, \{align}"
    (false, _) =>
      "  \{repr} = load atomic \{load_ty}, ptr \{ptr_repr} \{self.atomicOrdering}, \{align}"
  }
  logger.write_string(str)
}

// =======================================================
// StoreInst
// =======================================================

///|
/// StoreInst is an instruction that stores a value to a pointer.
///
/// **Note**:
///
/// Use `IRBuilder::createStore` to create a `StoreInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
/// 
/// let ptr_ty = ctx.getPtrTy()
/// let i32_ty = ctx.getInt32Ty()
/// let void_ty = ctx.getVoidTy()
/// 
/// let fty = ctx.getFunctionType(void_ty, [ptr_ty, i32_ty])
/// let fval = mod.addFunction(fty, "store_an_integer")
/// 
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
/// 
/// let ptr = fval.getArg(0).unwrap()
/// ptr.setName("arg0")
/// 
/// let value = fval.getArg(1).unwrap()
/// value.setName("value")
/// 
/// let s = builder.createStore(value, ptr)
///
/// inspect(s, content = "  store i32 %value, ptr %arg0, align 4")
/// ```
pub struct StoreInst {
  // --- ValueBase ---

  // Unique identifier
  uid : UInt64

  // Type of the value
  vty : &Type

  // --- UserBase ---
  value : &Value
  ptr : &Value
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]

  // --- StoreInst ---
  isVolatile : Bool
  atomicOrdering : AtomicOrdering
  align : Align
}

///|
fn StoreInst::new(
  value : &Value,
  ptr : &Value,
  isVolatile : Bool,
  atomicOrdering : AtomicOrdering,
  parent : Function,
) -> StoreInst {
  let ctx = value.getContext()
  let uid = valueUIDAssigner.assign()
  let value_ty = value.getType()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let align = parent.getDataLayout().getAlignment(value_ty)
  let inst = StoreInst::{
    uid,
    vty: ctx.getVoidTy(),
    value,
    ptr,
    parent,
    bb,
    prev,
    next,
    isVolatile,
    atomicOrdering,
    align,
  }
  value.addUser(inst)
  ptr.addUser(inst)
  inst
}

///|
/// Get the value operand of the store instruction.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
/// 
/// let ptr_ty = ctx.getPtrTy()
/// let i32_ty = ctx.getInt32Ty()
/// let void_ty = ctx.getVoidTy()
/// 
/// let fty = ctx.getFunctionType(void_ty, [ptr_ty, i32_ty])
/// let fval = mod.addFunction(fty, "store_an_integer")
/// 
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
/// 
/// let ptr = fval.getArg(0).unwrap()
/// ptr.setName("arg0")
/// 
/// let val1 = fval.getArg(1).unwrap()
/// let const_42 = ctx.getConstInt32(42)
/// let val2 = builder.createNSWAdd(val1, const_42, name="value")
/// 
/// let s = builder.createStore(val2, ptr)
///
/// inspect(s.getValueOperand(), content = "  %value = add nsw i32 %0, 42")
/// ```
pub fn StoreInst::getValueOperand(self : StoreInst) -> &Value {
  self.value
}

///|
/// Get the pointer operand of the store instruction.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
/// 
/// let void_ty = ctx.getVoidTy()
/// 
/// let fty = ctx.getFunctionType(void_ty, [])
/// let fval = mod.addFunction(fty, "store_an_integer")
/// 
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let alloca = builder.createAlloca(ctx.getInt32Ty(), name="ptr")
/// let const42 = ctx.getConstInt32(42)
///
/// let s = builder.createStore(const42, alloca)
///
/// inspect(s.getPointerOperand(), content = "  %ptr = alloca i32, align 4")
/// ```
pub fn StoreInst::getPointerOperand(self : StoreInst) -> &Value {
  self.ptr
}

///|
pub impl Value for StoreInst with asValueEnum(self) {
  StoreInst(self)
}

///|
pub impl Value for StoreInst with getValueRepr(_) {
  ""
}

///|
pub impl Value for StoreInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: [] }
}

///|
/// StoreInst has no name, calling `getName` will always return `None`.
pub impl Value for StoreInst with getName(self) {
  ignore(self)
  None
}

///|
/// StoreInst has no name, calling `setName` will always fail with an error.
pub impl Value for StoreInst with setName(_, _) {
  let msg = "Calling always failed function `StoreInst::setName`. " +
    "Set name for StoreInst is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for StoreInst with removeName(_) {
  ()
}

///|
pub impl Value for StoreInst with getNameOrSlot(_) {
  None
}

///|
pub impl User for StoreInst with asUserEnum(self) {
  StoreInst(self)
}

///|
pub impl User for StoreInst with getUserBase(self) {
  UserBase::{ operands: [self.value, self.ptr] }
}

///|
pub impl Instruction for StoreInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for StoreInst with asInstEnum(self) {
  StoreInst(self)
}

///|
pub impl Instruction for StoreInst with getParent(self) {
  self.parent
}

///|
pub impl Show for StoreInst with output(self, logger) {
  let align = self.align
  let value = self.getValueOperand()
  let ptr = self.getPointerOperand()
  let value_ty = value.getType()
  let value_repr = value.getValueRepr()
  let ptr_repr = ptr.getValueRepr()
  let str = match (self.isVolatile, self.atomicOrdering) {
    (true, _) =>
      "  store volatile \{value_ty} \{value_repr}, ptr \{ptr_repr}, \{align}"
    (false, NotAtomic) =>
      "  store \{value_ty} \{value_repr}, ptr \{ptr_repr}, \{align}"
    (false, _) =>
      "  store atomic \{value_ty} \{value_repr}, ptr \{ptr_repr} \{self.atomicOrdering}, \{align}"
  }
  logger.write_string(str)
}

// =======================================================
// BinaryInstructions
// =======================================================

///|
pub enum BinaryOps {
  // Standard binary operators.
  Add
  FAdd
  Sub
  FSub
  Mul
  FMul
  SDiv
  UDiv
  FDiv
  URem
  SRem
  FRem

  // Logical operators
  Shl
  LShr
  AShr
  And
  Or
  Xor
} derive(Hash, Eq)

///|
pub impl Show for BinaryOps with output(self, logger) {
  let str = match self {
    Add => "add"
    FAdd => "fadd"
    Sub => "sub"
    FSub => "fsub"
    Mul => "mul"
    FMul => "fmul"
    SDiv => "sdiv"
    UDiv => "udiv"
    FDiv => "fdiv"
    URem => "urem"
    SRem => "srem"
    FRem => "frem"
    Shl => "shl"
    LShr => "lshr"
    AShr => "ashr"
    And => "and"
    Or => "or"
    Xor => "xor"
  }
  logger.write_string(str)
}

///|
pub enum BinaryOpFlags {

  // Only add, sub, mul, and shl
  // could have NoUnsignedWrap and NoSignedWrap flags.
  NoUnsignedWrap
  NoSignedWrap

  // only sdiv, udiv, ashr, lshr
  // could have Exact flag.
  Exact

  // Only Or could have Disjoint flag.
  //Disjoint
} derive(Hash, Eq)

///|
pub impl Show for BinaryOpFlags with output(self, logger) {
  let str = match self {
    NoUnsignedWrap => "nuw"
    NoSignedWrap => "nsw"
    Exact => "exact"
    //Disjoint => "disjoint"
  }
  logger.write_string(str)
}

///|
pub(all) enum FastMathFlag {
  AllowReassoc
  NoNaNs
  NoInfs
  NoSignedZeros
  AllowReciprocal
  AllowContract
  ApproxFunc
} derive(Hash, Eq)

///|
pub impl Show for FastMathFlag with output(self, logger) {
  let str = match self {
    AllowReassoc => "reassoc"
    NoNaNs => "nnan"
    NoInfs => "ninf"
    NoSignedZeros => "nsz"
    AllowReciprocal => "arcp"
    AllowContract => "contract"
    ApproxFunc => "afn"
  }
  logger.write_string(str)
}

///| BinaryInst represents a binary operation instruction that performs arithmetic or logical operations on two operands.
///
/// **Note**:
///
/// Use `IRBuilder::createAdd`, `IRBuilder::createSub`, `IRBuilder::createMul`, etc. to create binary instructions.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "binary_ops_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
///
/// let add = builder.createAdd(arg1, arg2, name="sum")
/// inspect(add, content = "  %sum = add i32 %0, %1")
/// assert_true(add.asValueEnum() is BinaryInst(_))
///
/// let sub = builder.createSub(arg1, arg2, name="diff")
/// inspect(sub, content = "  %diff = sub i32 %0, %1")
///
/// let mul = builder.createMul(arg1, arg2, name="product")
/// inspect(mul, content = "  %product = mul i32 %0, %1")
///
/// let and_result = builder.createAnd(arg1, arg2, name="and_result")
/// inspect(and_result, content = "  %and_result = and i32 %0, %1")
///
/// let or_result = builder.createOr(arg1, arg2, name="or_result")
/// inspect(or_result, content = "  %or_result = or i32 %0, %1")
///
/// let xor_result = builder.createXor(arg1, arg2, name="xor_result")
/// inspect(xor_result, content = "  %xor_result = xor i32 %0, %1")
/// ```

///|
pub struct BinaryInst {
  // --- ValueBase ---

  // Unique identifier
  uid : UInt64

  // Type of the value
  vty : &Type

  // Users of this value
  users : Array[&User]

  // Name of the value
  mut name : String?

  // --- UserBase ---
  lhs : &Value
  rhs : &Value
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]

  // --- BinaryInst ---
  opcode : BinaryOps
  flags : Set[BinaryOpFlags]
  fast_math_flags : Set[FastMathFlag]
}

///|
fn BinaryInst::newStandardOp(
  opcode : BinaryOps,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name~ : String?,
  flags : Set[BinaryOpFlags],
) -> BinaryInst {
  guard opcode
    is (Add
    | Sub
    | Mul
    | SDiv
    | UDiv
    | SRem
    | URem
    | And
    | Or
    | Xor
    | Shl
    | LShr
    | AShr) else {
    llvm_unreachable(
      "Should not call BinaryInst::newStandardOp with opcode \{opcode}",
    )
  }
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy
  guard lhsTy.tryAsIntTypeEnum() is Some(_)
  let vty = lhsTy
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = BinaryInst::{
    uid,
    vty,
    lhs,
    rhs,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode,
    flags,
    fast_math_flags: Set::new(),
  }
  lhs.addUser(inst)
  rhs.addUser(inst)
  inst
}

///|
fn BinaryInst::newFPMathOp(
  opcode : BinaryOps,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name~ : String?,
  fast_math_flags : Set[FastMathFlag],
) -> BinaryInst {
  guard opcode is (FAdd | FSub | FMul | FDiv | FRem) else {
    llvm_unreachable(
      "Should not call BinaryInst::newFPMathOp with opcode \{opcode}",
    )
  }
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy
  guard lhsTy.tryAsFPTypeEnum() is Some(_)
  let uid = valueUIDAssigner.assign()
  let vty = lhsTy
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = BinaryInst::{
    uid,
    vty,
    lhs,
    rhs,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode,
    flags: Set::new(),
    fast_math_flags,
  }
  lhs.addUser(inst)
  rhs.addUser(inst)
  inst
}

///|
pub impl Value for BinaryInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for BinaryInst with asValueEnum(self) {
  BinaryInst(self)
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "binary_ops_demo")
/// let bb = fval.addBasicBlock(name="entry")
///
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let add = builder.createAdd(arg1, arg2)
///
/// inspect(add.getValueRepr(), content = "%2")
///
/// add.setName("sum")
/// inspect(add.getValueRepr(), content = "%sum")
/// ```
pub impl Value for BinaryInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "binary_ops_demo")
/// let bb = fval.addBasicBlock(name="entry")
///
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let add = builder.createAdd(arg1, arg2)
///
/// inspect(add.getName(), content = "None")
///
/// add.setName("sum")
/// inspect(add.getName(), content = "Some(\"sum\")")
/// ```
pub impl Value for BinaryInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "binary_ops_demo")
/// let bb = fval.addBasicBlock(name="entry")
///
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let add = builder.createAdd(arg1, arg2)
///
/// inspect(add.getName(), content = "None")
///
/// add.setName("sum")
/// inspect(add.getName(), content = "Some(\"sum\")")
/// ```
pub impl Value for BinaryInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `BinaryInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `BinaryInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `BinaryInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for BinaryInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for BinaryInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for BinaryInst with asUserEnum(self) {
  BinaryInst(self)
}

///|
pub impl User for BinaryInst with getUserBase(self) {
  UserBase::{ operands: [self.lhs, self.rhs] }
}

///|
pub impl Instruction for BinaryInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for BinaryInst with asInstEnum(self) {
  BinaryInst(self)
}

///|
pub impl Instruction for BinaryInst with getParent(self) {
  self.parent
}

///|
pub impl Show for BinaryInst with output(self, logger) {
  let ty = self.getType()
  let repr = self.getValueRepr()
  let lhs_repr = self.lhs.getValueRepr()
  let rhs_repr = self.rhs.getValueRepr()
  let flags_str = self.flags.iter().map(f => "\{f}").join(" ")
  let flags_str = if flags_str.is_empty() { "" } else { " " + flags_str }
  let fast_math_flags_str = self.fast_math_flags
    .iter()
    .map(f => "\{f}")
    .join(" ")
  let fast_math_flags_str = if fast_math_flags_str.is_empty() {
    ""
  } else {
    " " + fast_math_flags_str
  }
  let flags_str = flags_str + fast_math_flags_str
  logger.write_string(
    "  \{repr} = \{self.opcode}\{flags_str} \{ty} \{lhs_repr}, \{rhs_repr}",
  )
}

// =======================================================
// ICmpInst
// =======================================================

///|
pub(all) enum IntPredicate {
  /// equal
  EQ
  /// not equal
  NE
  /// unsigned greater than
  UGT
  /// unsigned greater or equal
  UGE
  /// unsigned less than
  ULT
  /// unsigned less or equal
  ULE
  /// signed greater than
  SGT
  /// signed greater or equal
  SGE
  /// signed less than
  SLT
  /// signed less or equal
  SLE
}

///|
pub impl Show for IntPredicate with output(self, logger) {
  let s = match self {
    EQ => "icmp eq"
    NE => "icmp ne"
    UGT => "icmp ugt"
    UGE => "icmp uge"
    ULT => "icmp ult"
    ULE => "icmp ule"
    SGT => "icmp sgt"
    SGE => "icmp sge"
    SLT => "icmp slt"
    SLE => "icmp sle"
  }
  logger.write_string(s)
}

///|
/// ICmpInst represents an integer comparison instruction that compares two integer values.
///
/// **Note**:
///
/// Use `IRBuilder::createICmp` to create an `ICmpInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "icmp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
///
/// let eq_cmp = builder.createICmp(EQ, arg1, arg2, name="eq_cmp")
/// inspect(eq_cmp, content = "  %eq_cmp = icmp eq i32 %0, %1")
/// assert_true(eq_cmp.asValueEnum() is ICmpInst(_))
///
/// let ne_cmp = builder.createICmp(NE, arg1, arg2, name="ne_cmp")
/// inspect(ne_cmp, content = "  %ne_cmp = icmp ne i32 %0, %1")
///
/// let sgt_cmp = builder.createICmp(SGT, arg1, arg2, name="sgt_cmp")
/// inspect(sgt_cmp, content = "  %sgt_cmp = icmp sgt i32 %0, %1")
///
/// let ugt_cmp = builder.createICmp(UGT, arg1, arg2, name="ugt_cmp")
/// inspect(ugt_cmp, content = "  %ugt_cmp = icmp ugt i32 %0, %1")
/// ```
pub struct ICmpInst {
  uid : UInt64
  vty : Int1Type
  lhs : &Value
  rhs : &Value
  mut name : String?
  parent : Function
  users : Array[&User]

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  predicate : IntPredicate
}

///|
fn ICmpInst::new(
  predicate : IntPredicate,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name~ : String?,
) -> ICmpInst {
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy
  guard lhsTy.tryAsIntTypeEnum() is Some(_)
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getInt1Ty()
  let inst = ICmpInst::{
    uid,
    vty,
    lhs,
    rhs,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    predicate,
  }
  lhs.addUser(inst)
  rhs.addUser(inst)
  inst
}

///|
pub impl Value for ICmpInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getParent().getContext().getInt1Ty(),
    users: self.users,
  }
}

///|
pub impl Value for ICmpInst with asValueEnum(self) {
  ICmpInst(self)
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "icmp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let eq_cmp = builder.createICmp(EQ, arg1, arg2)
///
/// inspect(eq_cmp.getValueRepr(), content = "%2")
///
/// eq_cmp.setName("eq_cmp")
/// inspect(eq_cmp.getValueRepr(), content = "%eq_cmp")
/// ```
pub impl Value for ICmpInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "icmp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let eq_cmp = builder.createICmp(EQ, arg1, arg2)
///
/// inspect(eq_cmp.getName(), content = "None")
///
/// eq_cmp.setName("eq_cmp")
/// inspect(eq_cmp.getName(), content = "Some(\"eq_cmp\")")
/// ```
pub impl Value for ICmpInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "icmp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let eq_cmp = builder.createICmp(EQ, arg1, arg2)
///
/// inspect(eq_cmp.getName(), content = "None")
///
/// eq_cmp.setName("eq_cmp")
/// inspect(eq_cmp.getName(), content = "Some(\"eq_cmp\")")
/// ```
pub impl Value for ICmpInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `ICmpInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `ICmpInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `ICmpInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for ICmpInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for ICmpInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for ICmpInst with asUserEnum(self) {
  ICmpInst(self)
}

///|
pub impl User for ICmpInst with getUserBase(self) {
  UserBase::{ operands: [self.lhs, self.rhs] }
}

///|
pub impl Instruction for ICmpInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for ICmpInst with asInstEnum(self) {
  InstEnum::ICmpInst(self)
}

///|
pub impl Instruction for ICmpInst with getParent(self) {
  self.parent
}

///|
impl Show for ICmpInst with output(self, logger) {
  let lhs_ty = self.lhs.getType()
  let repr = self.getValueRepr()
  let lhs_repr = self.lhs.getValueRepr()
  let rhs_repr = self.rhs.getValueRepr()
  logger.write_string(
    "  \{repr} = \{self.predicate} \{lhs_ty} \{lhs_repr}, \{rhs_repr}",
  )
}

// =======================================================
// FCmpInst
// =======================================================

///|
pub(all) enum FloatPredicate {
  /// Always false (always folded)
  FALSE
  /// True if ordered and equal
  OEQ
  /// True if ordered and greater than
  OGT
  /// True if ordered and greater than or equal
  OGE
  /// True if ordered and less than
  OLT
  /// True if ordered and less than or equal
  OLE
  /// True if ordered and operands are unequal
  ONE
  /// True if ordered (no nans)
  ORD
  /// True if unordered: isnan(X) | isnan(Y)
  UNO
  /// True if unordered or equal
  UEQ
  /// True if unordered or greater than
  UGT
  /// True if unordered, greater than, or equal
  UGE
  /// True if unordered or less than
  ULT
  /// True if unordered, less than, or equal
  ULE
  /// True if unordered or not equal
  UNE
  /// Always true (always folded)
  TRUE
}

///|
pub impl Show for FloatPredicate with output(self, logger) {
  let s = match self {
    FALSE => "fcmp false"
    OEQ => "fcmp oeq"
    OGT => "fcmp ogt"
    OGE => "fcmp oge"
    OLT => "fcmp olt"
    OLE => "fcmp ole"
    ONE => "fcmp one"
    ORD => "fcmp ord"
    UNO => "fcmp uno"
    UEQ => "fcmp ueq"
    UGT => "fcmp ugt"
    UGE => "fcmp uge"
    ULT => "fcmp ult"
    ULE => "fcmp ule"
    UNE => "fcmp une"
    TRUE => "fcmp true"
  }
  logger.write_string(s)
}

///|
/// FCmpInst represents a floating-point comparison instruction that compares two floating-point values.
///
/// **Note**:
///
/// Use `IRBuilder::createFCmp` to create an `FCmpInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "fcmp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
///
/// let oeq_cmp = builder.createFCmp(OEQ, arg1, arg2, name="oeq_cmp")
/// inspect(oeq_cmp, content = "  %oeq_cmp = fcmp oeq float %0, %1")
/// assert_true(oeq_cmp.asValueEnum() is FCmpInst(_))
///
/// let ogt_cmp = builder.createFCmp(OGT, arg1, arg2, name="ogt_cmp")
/// inspect(ogt_cmp, content = "  %ogt_cmp = fcmp ogt float %0, %1")
///
/// let olt_cmp = builder.createFCmp(OLT, arg1, arg2, name="olt_cmp")
/// inspect(olt_cmp, content = "  %olt_cmp = fcmp olt float %0, %1")
///
/// let uno_cmp = builder.createFCmp(UNO, arg1, arg2, name="uno_cmp")
/// inspect(uno_cmp, content = "  %uno_cmp = fcmp uno float %0, %1")
/// ```
pub struct FCmpInst {
  uid : UInt64
  vty : Int1Type
  lhs : &Value
  rhs : &Value
  mut name : String?
  parent : Function
  users : Array[&User]

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  predicate : FloatPredicate
}

///|
fn FCmpInst::new(
  predicate : FloatPredicate,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name~ : String?,
) -> FCmpInst {
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy
  guard lhsTy.tryAsFPTypeEnum() is Some(_)
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getInt1Ty()
  let inst = FCmpInst::{
    uid,
    vty,
    lhs,
    rhs,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    predicate,
  }
  lhs.addUser(inst)
  rhs.addUser(inst)
  inst
}

///|
pub impl Value for FCmpInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "fcmp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let oeq_cmp = builder.createFCmp(OEQ, arg1, arg2)
///
/// inspect(oeq_cmp.getValueRepr(), content = "%2")
///
/// oeq_cmp.setName("oeq_cmp")
/// inspect(oeq_cmp.getValueRepr(), content = "%oeq_cmp")
/// ```
pub impl Value for FCmpInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for FCmpInst with asValueEnum(self) {
  FCmpInst(self)
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "fcmp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let oeq_cmp = builder.createFCmp(OEQ, arg1, arg2)
///
/// inspect(oeq_cmp.getName(), content = "None")
///
/// oeq_cmp.setName("oeq_cmp")
/// inspect(oeq_cmp.getName(), content = "Some(\"oeq_cmp\")")
/// ```
pub impl Value for FCmpInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "fcmp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let oeq_cmp = builder.createFCmp(OEQ, arg1, arg2)
///
/// inspect(oeq_cmp.getName(), content = "None")
///
/// oeq_cmp.setName("oeq_cmp")
/// inspect(oeq_cmp.getName(), content = "Some(\"oeq_cmp\")")
/// ```
pub impl Value for FCmpInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `FCmpInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `FCmpInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `FCmpInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for FCmpInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for FCmpInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for FCmpInst with asUserEnum(self) {
  FCmpInst(self)
}

///|
pub impl User for FCmpInst with getUserBase(self) {
  UserBase::{ operands: [self.lhs, self.rhs] }
}

///|
pub impl Instruction for FCmpInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for FCmpInst with asInstEnum(self) {
  FCmpInst(self)
}

///|
pub impl Instruction for FCmpInst with getParent(self) {
  self.parent
}

///|
pub impl Show for FCmpInst with output(self, logger) {
  let lhs_ty = self.lhs.getType()
  let repr = self.getValueRepr()
  let lhs_repr = self.lhs.getValueRepr()
  let rhs_repr = self.rhs.getValueRepr()
  logger.write_string(
    "  \{repr} = \{self.predicate} \{lhs_ty} \{lhs_repr}, \{rhs_repr}",
  )
}

// =======================================================
// CastInst
// =======================================================

///|
pub(all) enum CastOps {
  Trunc
  ZExt
  SExt
  FPTrunc
  FPExt
  UIToFP
  SIToFP
  FPToUI
  FPToSI
  PtrToInt
  IntToPtr
  BitCast
  //AddrSpaceCast
} derive(Hash, Eq)

///|
pub impl Show for CastOps with output(self, logger) {
  let str = match self {
    Trunc => "trunc"
    ZExt => "zext"
    SExt => "sext"
    FPTrunc => "fptrunc"
    FPExt => "fpext"
    UIToFP => "uitofp"
    SIToFP => "sitofp"
    FPToUI => "fptoui"
    FPToSI => "fptosi"
    PtrToInt => "ptrtoint"
    IntToPtr => "inttoptr"
    BitCast => "bitcast"
    //AddrSpaceCast => "addrspacecast"
  }
  logger.write_string(str)
}

///|
/// CastInst represents a type conversion instruction that converts a value from one type to another.
///
/// **Note**:
///
/// Use `IRBuilder::createTrunc`, `IRBuilder::createZExt`, `IRBuilder::createSExt`, etc. to create cast instructions.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let i64_ty = ctx.getInt64Ty()
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///
/// let fval = mod.addFunction(fty, "cast_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
///
/// let trunc = builder.createTrunc(arg, i32_ty, name="truncated")
/// inspect(trunc, content = "  %truncated = trunc i64 %0 to i32")
/// assert_true(trunc.asValueEnum() is CastInst(_))
///
/// let zext = builder.createZExt(trunc, i64_ty, name="extended")
/// inspect(zext, content = "  %extended = zext i32 %truncated to i64")
///
/// let bitcast = builder.createBitCast(trunc, f32_ty, name="bits")
/// inspect(bitcast, content = "  %bits = bitcast i32 %truncated to float")
/// ```
pub struct CastInst {
  uid : UInt64
  to_ty : &Type
  from_val : &Value
  mut name : String?
  parent : Function
  users : Array[&User]

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  opcode : CastOps
}

///|
fn CastInst::newTrunc(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  guard from_val.getType().tryAsIntTypeEnum() is Some(from_ty)
  guard from_ty.getBitWidth() > to_ty.getBitWidth()
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: Trunc,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newZExt(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  guard from_val.getType().tryAsIntTypeEnum() is Some(from_ty)
  guard from_ty.getBitWidth() < to_ty.getBitWidth()
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: ZExt,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newSExt(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: SExt,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newFPTrunc(
  from_val : &Value,
  to_ty : &FPType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: FPTrunc,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newFPExt(
  from_val : &Value,
  to_ty : &FPType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: FPExt,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newUIToFP(
  from_val : &Value,
  to_ty : &FPType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: UIToFP,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newFPToUI(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: FPToUI,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newSIToFP(
  from_val : &Value,
  to_ty : &FPType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: SIToFP,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newFPToSI(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: FPToSI,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newPtrToInt(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: PtrToInt,
  }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newIntToPtr(
  from_val : &Value,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let to_ty = from_val.getContext().getPtrTy()
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: IntToPtr,
  }
  from_val.addUser(inst)
  inst
}

///|
/// REVIEW: Currently bitcast is only allowed between primitive types.
/// while in real cpp llvm, bitcast can be used to cast between aggregate types.
fn CastInst::newBitCast(
  from_val : &Value,
  to_ty : &PrimitiveType,
  parent : Function,
  name~ : String?,
) -> CastInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CastInst::{
    uid,
    to_ty,
    from_val,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
    opcode: BitCast,
  }
  from_val.addUser(inst)
  inst
}

///|
pub impl Value for CastInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.to_ty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let i64_ty = ctx.getInt64Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///
/// let fval = mod.addFunction(fty, "cast_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let trunc = builder.createTrunc(arg, i32_ty)
///
/// inspect(trunc.getValueRepr(), content = "%1")
///
/// trunc.setName("truncated")
/// inspect(trunc.getValueRepr(), content = "%truncated")
/// ```
pub impl Value for CastInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for CastInst with asValueEnum(self) {
  CastInst(self)
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let i64_ty = ctx.getInt64Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///
/// let fval = mod.addFunction(fty, "cast_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let trunc = builder.createTrunc(arg, i32_ty)
///
/// inspect(trunc.getName(), content = "None")
///
/// trunc.setName("truncated")
/// inspect(trunc.getName(), content = "Some(\"truncated\")")
/// ```
pub impl Value for CastInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let i64_ty = ctx.getInt64Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///
/// let fval = mod.addFunction(fty, "cast_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let trunc = builder.createTrunc(arg, i32_ty)
///
/// inspect(trunc.getName(), content = "None")
///
/// trunc.setName("truncated")
/// inspect(trunc.getName(), content = "Some(\"truncated\")")
/// ```
pub impl Value for CastInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `CastInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `CastInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `CastInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for CastInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for CastInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for CastInst with asUserEnum(self) {
  CastInst(self)
}

///|
pub impl User for CastInst with getUserBase(self) {
  UserBase::{ operands: [self.from_val] }
}

///|
pub impl UnaryInst for CastInst with asUnaryInstEnum(self) {
  CastInst(self)
}

///|
pub impl Instruction for CastInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for CastInst with asInstEnum(self) {
  CastInst(self)
}

///|
pub impl Instruction for CastInst with getParent(self) {
  self.parent
}

///|
pub impl Show for CastInst with output(self, logger) {
  let repr = self.getValueRepr()
  let to_ty = self.to_ty
  let from_ty = self.from_val.getType()
  let from_val_repr = self.from_val.getValueRepr()
  logger.write_string(
    "  \{repr} = \{self.opcode} \{from_ty} \{from_val_repr} to \{to_ty}",
  )
}

// =======================================================
// GetElementPtrInst
// =======================================================

///|
/// GetElementPtrInst represents a getelementptr instruction that calculates the address of a sub-element of an aggregate object.
///
/// **Note**:
///
/// Use `IRBuilder::createGEP` to create a `GetElementPtrInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let array_ty = ctx.getArrayType(i32_ty, 10)
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(ptr_ty, [ptr_ty])
///
/// let fval = mod.addFunction(fty, "gep_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
/// let zero = ctx.getConstInt32(0)
/// let two = ctx.getConstInt32(2)
///
/// builder.setInsertPoint(bb)
/// let gep = builder.createGEP(arg, array_ty, [zero, two], name="elem_ptr", inbounds=true)
///
/// inspect(gep, content = "  %elem_ptr = getelementptr inbounds [10 x i32], ptr %0, i32 0, i32 2")
/// assert_true(gep.asValueEnum() is GetElementPtrInst(_))
/// ```
pub struct GetElementPtrInst {
  uid : UInt64
  vty : PointerType
  users : Array[&User]
  ptr : &Value
  indices : Array[&Value]
  mut name : String?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  isInbounds : Bool
  pointeeType : &Type
}

///|
fn GetElementPtrInst::new(
  ptr : &Value,
  pointeeType : &Type,
  indices : Array[&Value],
  isInbounds : Bool,
  parent : Function,
  name~ : String?,
) -> GetElementPtrInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getPtrTy()
  let inst = GetElementPtrInst::{
    uid,
    vty,
    users: [],
    ptr,
    indices,
    name,
    parent,
    bb,
    prev,
    next,
    isInbounds,
    pointeeType,
  }
  ptr.addUser(inst)
  indices.each(idx => idx.addUser(inst))
  inst
}

///|
pub impl Value for GetElementPtrInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let array_ty = ctx.getArrayType(i32_ty, 10)
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(ptr_ty, [ptr_ty])
///
/// let fval = mod.addFunction(fty, "gep_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
/// let zero = ctx.getConstInt32(0)
/// let two = ctx.getConstInt32(2)
///
/// builder.setInsertPoint(bb)
/// let gep = builder.createGEP(arg, array_ty, [zero, two])
///
/// inspect(gep.getValueRepr(), content = "%1")
///
/// gep.setName("elem_ptr")
/// inspect(gep.getValueRepr(), content = "%elem_ptr")
/// ```
pub impl Value for GetElementPtrInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for GetElementPtrInst with asValueEnum(self) {
  GetElementPtrInst(self)
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let array_ty = ctx.getArrayType(i32_ty, 10)
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(ptr_ty, [ptr_ty])
///
/// let fval = mod.addFunction(fty, "gep_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
/// let zero = ctx.getConstInt32(0)
/// let two = ctx.getConstInt32(2)
///
/// builder.setInsertPoint(bb)
/// let gep = builder.createGEP(arg, array_ty, [zero, two])
///
/// inspect(gep.getName(), content = "None")
///
/// gep.setName("elem_ptr")
/// inspect(gep.getName(), content = "Some(\"elem_ptr\")")
/// ```
pub impl Value for GetElementPtrInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let array_ty = ctx.getArrayType(i32_ty, 10)
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(ptr_ty, [ptr_ty])
///
/// let fval = mod.addFunction(fty, "gep_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
/// let zero = ctx.getConstInt32(0)
/// let two = ctx.getConstInt32(2)
///
/// builder.setInsertPoint(bb)
/// let gep = builder.createGEP(arg, array_ty, [zero, two])
///
/// inspect(gep.getName(), content = "None")
///
/// gep.setName("elem_ptr")
/// inspect(gep.getName(), content = "Some(\"elem_ptr\")")
/// ```
pub impl Value for GetElementPtrInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `GetElementPtrInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `GetElementPtrInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `GetElementPtrInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for GetElementPtrInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for GetElementPtrInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for GetElementPtrInst with asUserEnum(self) {
  GetElementPtrInst(self)
}

///|
pub impl User for GetElementPtrInst with getUserBase(self) {
  UserBase::{ operands: [self.ptr] + self.indices }
}

///|
pub impl Instruction for GetElementPtrInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for GetElementPtrInst with asInstEnum(self) {
  InstEnum::GetElementPtrInst(self)
}

///|
pub impl Instruction for GetElementPtrInst with getParent(self) {
  self.parent
}

///|
pub impl Show for GetElementPtrInst with output(self, logger) {
  let repr = self.getValueRepr()
  let ptr_repr = self.ptr.getValueRepr()
  let indices_reprs = Array::new()
  self.indices.each(index => indices_reprs.push(
    "\{index.getType()} \{index.getValueRepr()}",
  ))
  let indices_repr = if indices_reprs.length() > 0 {
    ", " + indices_reprs.join(", ")
  } else {
    ""
  }
  let inbounds_str = if self.isInbounds { " inbounds" } else { "" }
  logger.write_string(
    "  \{repr} = getelementptr\{inbounds_str} \{self.pointeeType}, ptr \{ptr_repr}\{indices_repr}",
  )
}

// =======================================================
// SelectInst
// =======================================================

///|
/// SelectInst represents a select instruction that chooses between two values based on a boolean condition.
///
/// **Note**:
///
/// Use `IRBuilder::createSelect` to create a `SelectInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i1_ty = ctx.getInt1Ty()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "select_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let cond = fval.getArg(0).unwrap()
/// let true_val = fval.getArg(1).unwrap()
/// let false_val = fval.getArg(2).unwrap()
///
/// builder.setInsertPoint(bb)
/// let select = builder.createSelect(cond, true_val, false_val, name="result")
///
/// inspect(select, content = "  %result = select i1 %0, i32 %1, i32 %2")
/// assert_true(select.asValueEnum() is SelectInst(_))
/// ```
pub struct SelectInst {
  uid : UInt64
  users : Array[&User]
  vty : &Type
  condition : &Value
  trueValue : &Value
  falseValue : &Value
  mut name : String?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn SelectInst::new(
  condition : &Value,
  trueValue : &Value,
  falseValue : &Value,
  parent : Function,
  name~ : String?,
) -> SelectInst {
  let vty = trueValue.getType()
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = SelectInst::{
    uid,
    vty,
    condition,
    trueValue,
    falseValue,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
  }
  condition.addUser(inst)
  trueValue.addUser(inst)
  falseValue.addUser(inst)
  inst
}

///|
pub fn SelectInst::getCondition(self : SelectInst) -> &Value {
  self.condition
}

///|
pub fn SelectInst::getTrueValue(self : SelectInst) -> &Value {
  self.trueValue
}

///|
pub fn SelectInst::getFalseValue(self : SelectInst) -> &Value {
  self.falseValue
}

///|
pub impl Value for SelectInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i1_ty = ctx.getInt1Ty()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "select_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let cond = fval.getArg(0).unwrap()
/// let true_val = fval.getArg(1).unwrap()
/// let false_val = fval.getArg(2).unwrap()
///
/// builder.setInsertPoint(bb)
/// let select = builder.createSelect(cond, true_val, false_val)
///
/// inspect(select.getValueRepr(), content = "%3")
///
/// select.setName("result")
/// inspect(select.getValueRepr(), content = "%result")
/// ```
pub impl Value for SelectInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for SelectInst with asValueEnum(self) {
  SelectInst(self)
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i1_ty = ctx.getInt1Ty()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "select_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let cond = fval.getArg(0).unwrap()
/// let true_val = fval.getArg(1).unwrap()
/// let false_val = fval.getArg(2).unwrap()
///
/// builder.setInsertPoint(bb)
/// let select = builder.createSelect(cond, true_val, false_val)
///
/// inspect(select.getName(), content = "None")
///
/// select.setName("result")
/// inspect(select.getName(), content = "Some(\"result\")")
/// ```
pub impl Value for SelectInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i1_ty = ctx.getInt1Ty()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "select_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let cond = fval.getArg(0).unwrap()
/// let true_val = fval.getArg(1).unwrap()
/// let false_val = fval.getArg(2).unwrap()
///
/// builder.setInsertPoint(bb)
/// let select = builder.createSelect(cond, true_val, false_val)
///
/// inspect(select.getName(), content = "None")
///
/// select.setName("result")
/// inspect(select.getName(), content = "Some(\"result\")")
/// ```
pub impl Value for SelectInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `SelectInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `SelectInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `SelectInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for SelectInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for SelectInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for SelectInst with asUserEnum(self) {
  SelectInst(self)
}

///|
pub impl User for SelectInst with getUserBase(self) {
  UserBase::{ operands: [self.condition, self.trueValue, self.falseValue] }
}

///|
pub impl Instruction for SelectInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for SelectInst with asInstEnum(self) {
  InstEnum::SelectInst(self)
}

///|
pub impl Instruction for SelectInst with getParent(self) {
  self.parent
}

///|
pub impl Show for SelectInst with output(self, logger) {
  let repr = self.getValueRepr()
  let condition = self.getCondition()
  let trueValue = self.getTrueValue()
  let falseValue = self.getFalseValue()
  let condition_repr = condition.getValueRepr()
  let trueValue_repr = trueValue.getValueRepr()
  let falseValue_repr = falseValue.getValueRepr()
  let condition_ty = condition.getType()
  let value_ty = trueValue.getType()
  logger.write_string(
    "  \{repr} = select \{condition_ty} \{condition_repr}, \{value_ty} \{trueValue_repr}, \{value_ty} \{falseValue_repr}",
  )
}

// =======================================================
// ReturnInst
// =======================================================

///|
/// ReturnInst represents a return instruction that terminates the current function and optionally returns a value.
///
/// **Note**:
///
/// Use `IRBuilder::createRet` or `IRBuilder::createRetVoid` to create a `ReturnInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let void_ty = ctx.getVoidTy()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "return_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let ret = builder.createRet(arg)
///
/// inspect(ret, content = "  ret i32 %0")
/// assert_true(ret.asValueEnum() is ReturnInst(_))
///
/// let void_fty = ctx.getFunctionType(void_ty, [])
/// let void_fval = mod.addFunction(void_fty, "void_return_demo")
/// let void_bb = void_fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(void_bb)
/// let void_ret = builder.createRetVoid()
///
/// inspect(void_ret, content = "  ret void")
/// ```
pub struct ReturnInst {
  uid : UInt64
  vty : VoidType
  retVal : &Value?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn ReturnInst::new(retVal : &Value?, parent : Function) -> ReturnInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getVoidTy()
  let inst = ReturnInst::{ uid, vty, retVal, parent, bb, prev, next }
  if retVal is Some(val) {
    val.addUser(inst)
  }
  inst
}

///|
pub impl Value for ReturnInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty, // ReturnInst does not have a value type
    users: [],
  }
}

///|
pub impl Value for ReturnInst with asValueEnum(self) {
  ReturnInst(self)
}

///|
pub impl Value for ReturnInst with getValueRepr(_) {
  ""
}

///|
pub impl Value for ReturnInst with getName(_) {
  None
}

///|
pub impl Value for ReturnInst with setName(_, _) {
  let msg = "Calling always failed function `ReturnInst::setName`. " +
    "Set name for ReturnInst is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for ReturnInst with removeName(_) {
  ()
}

///|
pub impl Value for ReturnInst with getNameOrSlot(_) {
  None
}

///|
pub impl User for ReturnInst with asUserEnum(self) {
  ReturnInst(self)
}

///|
pub impl User for ReturnInst with getUserBase(self) {
  let operands : Array[&Value] = match self.retVal {
    Some(val) => [val]
    None => []
  }
  UserBase::{ operands, }
}

///|
pub impl Instruction for ReturnInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for ReturnInst with asInstEnum(self) {
  ReturnInst(self)
}

///|
pub impl Instruction for ReturnInst with getParent(self) {
  self.parent
}

///|
pub impl Show for ReturnInst with output(self, logger) {
  let retStr = match self.retVal {
    Some(val) => "\{val.getType()} \{val.getValueRepr()}"
    None => "void"
  }
  logger.write_string("  ret \{retStr}")
}

// =======================================================
// BranchInst
// =======================================================

///|
/// BranchInst represents a branch instruction that transfers control flow to different basic blocks.
///
/// **Note**:
///
/// Use `IRBuilder::createBr` for unconditional branches or `IRBuilder::createCondBr` for conditional branches.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i1_ty = ctx.getInt1Ty()
/// let void_ty = ctx.getVoidTy()
/// let fty = ctx.getFunctionType(void_ty, [i1_ty])
///
/// let fval = mod.addFunction(fty, "branch_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let true_bb = fval.addBasicBlock(name="true_branch")
/// let false_bb = fval.addBasicBlock(name="false_branch")
/// let cond = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(entry_bb)
/// let cond_br = builder.createCondBr(cond, true_bb, false_bb)
///
/// inspect(cond_br, content = "  br i1 %0, label %true_branch, label %false_branch")
/// assert_true(cond_br.asValueEnum() is BranchInst(_))
///
/// builder.setInsertPoint(true_bb)
/// let uncond_br = builder.createBr(false_bb)
///
/// inspect(uncond_br, content = "  br label %false_branch")
/// ```
pub struct BranchInst {
  // --- ValueBase ---

  // Unique identifier
  uid : UInt64
  vty : VoidType
  condition : &Value?
  trueBlock : BasicBlock?
  falseBlock : BasicBlock?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn BranchInst::newConditional(
  condition : &Value,
  trueBlock : BasicBlock,
  falseBlock : BasicBlock,
  parent : Function,
) -> BranchInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getVoidTy()
  let inst = BranchInst::{
    uid,
    vty,
    condition: Some(condition),
    trueBlock: Some(trueBlock),
    falseBlock: Some(falseBlock),
    parent,
    bb,
    prev,
    next,
  }
  condition.addUser(inst)
  trueBlock.addUser(inst)
  falseBlock.addUser(inst)
  inst
}

///|
fn BranchInst::newUnconditional(
  targetBlock : BasicBlock,
  parent : Function,
) -> BranchInst {
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let uid = valueUIDAssigner.assign()
  let vty = parent.getContext().getVoidTy()
  let inst = BranchInst::{
    uid,
    vty,
    condition: None,
    trueBlock: Some(targetBlock),
    falseBlock: None,
    parent,
    bb,
    prev,
    next,
  }
  targetBlock.addUser(inst)
  inst
}

///|
pub fn BranchInst::getNumSuccessors(self : Self) -> Int {
  match self.condition {
    Some(_) => 2 // conditional branch
    None => 1 // unconditional branch
  }
}

///|
pub fn BranchInst::getSuccessor(self : BranchInst, idx : Int) -> BasicBlock? {
  match idx {
    0 => self.trueBlock
    1 => self.falseBlock
    _ => None
  }
}

///|
pub fn BranchInst::isConditional(self : BranchInst) -> Bool {
  match self.condition {
    Some(_) => true
    None => false
  }
}

///|
pub fn BranchInst::isUnconditional(self : BranchInst) -> Bool {
  match self.condition {
    Some(_) => false
    None => true
  }
}

///|
pub impl Value for BranchInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getParent().getContext().getVoidTy(), // BranchInst does not have a value type
    users: [],
  }
}

///|
pub impl Value for BranchInst with asValueEnum(self) {
  BranchInst(self)
}

///|
pub impl Value for BranchInst with getValueRepr(_) {
  ""
}

///|
pub impl Value for BranchInst with getName(_) {
  None
}

///|
pub impl Value for BranchInst with setName(_, _) {
  let msg = "Calling always failed function `ReturnInst::setName`. " +
    "Set name for ReturnInst is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for BranchInst with removeName(_) {
  ()
}

///|
pub impl Value for BranchInst with getNameOrSlot(_) {
  None
}

///|
pub impl User for BranchInst with asUserEnum(self) {
  BranchInst(self)
}

///|
pub impl User for BranchInst with getUserBase(self) {
  let operands : Array[&Value] = []
  match self.condition {
    Some(cond) => operands.push(cond)
    None => ()
  }
  match self.trueBlock {
    Some(block) => operands.push(block)
    None => ()
  }
  match self.falseBlock {
    Some(block) => operands.push(block)
    None => ()
  }
  UserBase::{ operands, }
}

///|
pub impl Instruction for BranchInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for BranchInst with asInstEnum(self) {
  InstEnum::BranchInst(self)
}

///|
pub impl Instruction for BranchInst with getParent(self) {
  self.parent
}

///|
pub impl Show for BranchInst with output(self, logger) {
  if self.isConditional() {
    let condition_repr = self.condition.unwrap().getValueRepr()
    let true_block_repr = self.trueBlock.unwrap().getValueRepr()
    let false_block_repr = self.falseBlock.unwrap().getValueRepr()
    logger.write_string(
      "  br \{self.condition.unwrap().getType()} \{condition_repr}, label \{true_block_repr}, label \{false_block_repr}",
    )
  } else {
    let target_block_repr = self.trueBlock.unwrap().getValueRepr()
    logger.write_string("  br label \{target_block_repr}")
  }
}

// =======================================================
// Switch Inst
// =======================================================

///|
/// SwitchInst represents a switch instruction that transfers control to one of many basic blocks based on an integer value.
///
/// **Note**:
///
/// Use `IRBuilder::createSwitch` to create a `SwitchInst`, then use `SwitchInst::addCase` to add individual cases.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let void_ty = ctx.getVoidTy()
/// let fty = ctx.getFunctionType(void_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "switch_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let case1_bb = fval.addBasicBlock(name="case1")
/// let case2_bb = fval.addBasicBlock(name="case2")
/// let default_bb = fval.addBasicBlock(name="default")
/// let value = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(entry_bb)
/// let switch = builder.createSwitch(value, default_bb)
/// let case_val1 = ctx.getConstInt32(1)
/// let case_val2 = ctx.getConstInt32(2)
/// switch.addCase(case_val1, case1_bb)
/// switch.addCase(case_val2, case2_bb)
///
/// let expect = 
///   #|  switch i32 %0, label %default [
///   #|    i32 1, label %case1
///   #|    i32 2, label %case2
///   #|  ]
///
/// inspect(switch, content = expect)
/// assert_true(switch.asValueEnum() is SwitchInst(_))
/// ```
pub struct SwitchInst {
  uid : UInt64
  vty : VoidType
  condition : &Value
  defaultDest : BasicBlock
  cases : Array[(ConstantInt, BasicBlock)]
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn SwitchInst::new(
  cond : &Value,
  defaultDest : BasicBlock,
  parent : Function,
) -> SwitchInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getVoidTy()
  let inst = SwitchInst::{
    uid,
    vty,
    condition: cond,
    defaultDest,
    cases: [],
    parent,
    bb,
    prev,
    next,
  }
  cond.addUser(inst)
  defaultDest.addUser(inst)
  inst
}

///|
pub fn SwitchInst::getCondition(self : Self) -> &Value {
  self.condition
}

///|
pub fn SwitchInst::getDefaultDest(self : Self) -> BasicBlock {
  self.defaultDest
}

///|
pub fn SwitchInst::getNumCases(self : Self) -> Int {
  self.cases.length()
}

///|
/// Get a case from the switch instruction by index.
///
/// **Note**:
///
/// Returns `None` if the index is out of bounds. Use `SwitchInst::getNumCases` to get the total number of cases.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let void_ty = ctx.getVoidTy()
/// let fty = ctx.getFunctionType(void_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "switch_case_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let case1_bb = fval.addBasicBlock(name="case1")
/// let case2_bb = fval.addBasicBlock(name="case2")
/// let default_bb = fval.addBasicBlock(name="default")
/// let value = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(entry_bb)
/// let switch = builder.createSwitch(value, default_bb)
/// let case_val1 = ctx.getConstInt32(1)
/// let case_val2 = ctx.getConstInt32(2)
/// switch.addCase(case_val1, case1_bb)
/// switch.addCase(case_val2, case2_bb)
///
/// inspect(switch.getNumCases(), content = "2")
/// inspect(switch.getCase(0).unwrap().0.getValueRepr(), content = "1")
/// inspect(switch.getCase(0).unwrap().1.getValueRepr(), content = "%case1")
/// inspect(switch.getCase(1).unwrap().0.getValueRepr(), content = "2")
/// inspect(switch.getCase(1).unwrap().1.getValueRepr(), content = "%case2")
/// inspect(switch.getCase(2), content = "None")
/// ```
pub fn SwitchInst::getCase(
  self : Self,
  idx : Int,
) -> (ConstantInt, BasicBlock)? {
  self.cases.get(idx)
}

///|
/// Add a case to the switch instruction.
///
/// **Note**:
///
/// The case condition must be a constant integer with the same type as the switch condition.
/// Will raise `LLVMValueError` if there is a type mismatch between the case condition and switch condition.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let void_ty = ctx.getVoidTy()
/// let fty = ctx.getFunctionType(void_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "switch_addcase_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let case1_bb = fval.addBasicBlock(name="case1")
/// let case2_bb = fval.addBasicBlock(name="case2")
/// let case3_bb = fval.addBasicBlock(name="case3")
/// let default_bb = fval.addBasicBlock(name="default")
/// let value = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(entry_bb)
/// let switch = builder.createSwitch(value, default_bb)
///
/// // Add multiple cases
/// let case_val1 = ctx.getConstInt32(1)
/// let case_val2 = ctx.getConstInt32(2)
/// let case_val3 = ctx.getConstInt32(3)
/// switch.addCase(case_val1, case1_bb)
/// switch.addCase(case_val2, case2_bb)
/// switch.addCase(case_val3, case3_bb)
///
/// inspect(switch.getNumCases(), content = "3")
/// assert_true(switch.getCase(0).unwrap().0.getValueRepr() == "1")
/// assert_true(switch.getCase(1).unwrap().0.getValueRepr() == "2")
/// assert_true(switch.getCase(2).unwrap().0.getValueRepr() == "3")
/// ```
pub fn SwitchInst::addCase(
  self : Self,
  cond : ConstantInt,
  dest : BasicBlock,
) -> Unit raise LLVMValueError {
  guard self.getCondition().getType().tryAsIntTypeEnum() is Some(intTy)
  guard cond.getType().tryAsIntTypeEnum() is Some(case_cond_ty) else {
    let msg = "SwitchInst case condition type mismatch: " +
      "expected integer type, got \{cond.getType()}"
    raise LLVMValueError(msg)
  }
  guard intTy == case_cond_ty else {
    let msg = "SwitchInst case condition type mismatch: " +
      "expected \{intTy}, got \{case_cond_ty}"
    raise LLVMValueError(msg)
  }
  self.cases.push((cond, dest))
  cond.addUser(self)
  dest.addUser(self)
  match self.getBasicBlock() {
    Some(bb) => dest.preds.push(bb)
    None => ()
  }
}

///|
pub impl Value for SwitchInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty, // SwitchInst does not have a value type
    users: [],
  }
}

///|
pub impl Value for SwitchInst with asValueEnum(self) {
  SwitchInst(self)
}

///|
pub impl Value for SwitchInst with getValueRepr(_) {
  ""
}

///|
pub impl Value for SwitchInst with getName(_) {
  None
}

///|
pub impl Value for SwitchInst with setName(_, _) {
  let msg = "Calling always failed function `SwitchInst::setName`. " +
    "Set name for SwitchInst is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for SwitchInst with removeName(_) {
  ()
}

///|
pub impl Value for SwitchInst with getNameOrSlot(_) {
  None
}

///|
pub impl User for SwitchInst with asUserEnum(self) {
  SwitchInst(self)
}

///|
pub impl User for SwitchInst with getUserBase(self) {
  let operands : Array[&Value] = [self.condition, self.defaultDest]
  self.cases.each(case => {
    operands.push(case.0) // case condition
    operands.push(case.1) // case destination
  })
  UserBase::{
    operands: [self.condition, self.defaultDest] +
    self.cases.map(case => case.1),
  }
}

///|
pub impl Instruction for SwitchInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for SwitchInst with asInstEnum(self) {
  InstEnum::SwitchInst(self)
}

///|
pub impl Instruction for SwitchInst with getParent(self) {
  self.parent
}

///|
pub impl Show for SwitchInst with output(self, logger) {
  let condition = self.getCondition()
  let condition_ty = condition.getType()

  // Format condition value
  let condition_repr = condition.getValueRepr()

  // Format default destination
  let default_dest = self.getDefaultDest()
  let default_dest_repr = default_dest.getValueRepr()

  // Start with the switch statement
  logger.write_string(
    "  switch \{condition_ty} \{condition_repr}, label \{default_dest_repr} [",
  )

  // Add each case
  let num_cases = self.getNumCases()
  for i = 0; i < num_cases; i = i + 1 {
    if self.getCase(i) is Some((case_value, case_dest)) {
      let case_dest_repr = case_dest.getValueRepr()
      logger.write_string(
        "\n    \{condition_ty} \{case_value.getValueRepr()}, label \{case_dest_repr}",
      )
    }
  }

  // Close the switch statement
  logger.write_string("\n  ]")
}

// =======================================================
// PHINode
// =======================================================

///|
/// PHINode represents a PHI node instruction that selects a value based on the predecessor basic block.
///
/// **Note**:
///
/// Use `IRBuilder::createPHI` to create a `PHINode`, then use `PHINode::addIncoming` to add incoming values.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block_bb = fval.addBasicBlock(name="block")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
/// phi.addIncoming(val1, entry_bb)
/// phi.addIncoming(val2, block_bb)
///
/// inspect(phi, content = "  %result = phi i32 [ 10, %entry ], [ 20, %block ]")
/// assert_true(phi.asValueEnum() is PHINode(_))
/// ```
pub struct PHINode {
  uid : UInt64
  vty : &Type
  users : Array[&User]
  mut name : String?
  incomings : Array[(&Value, BasicBlock)]
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn PHINode::new(vty : &Type, parent : Function, name~ : String?) -> PHINode {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  PHINode::{ uid, vty, users: [], name, incomings: [], parent, bb, prev, next }
}

///|
/// Get the number of incoming values in the PHI node.
///
/// **Note**:
///
/// Returns the total count of incoming value-block pairs added to this PHI node.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_num_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block1_bb = fval.addBasicBlock(name="block1")
/// let block2_bb = fval.addBasicBlock(name="block2")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
/// let val3 = ctx.getConstInt32(30)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
///
/// inspect(phi.getNumIncomingValues(), content = "0")
///
/// phi.addIncoming(val1, entry_bb)
/// inspect(phi.getNumIncomingValues(), content = "1")
///
/// phi.addIncoming(val2, block1_bb)
/// phi.addIncoming(val3, block2_bb)
/// inspect(phi.getNumIncomingValues(), content = "3")
/// ```
pub fn PHINode::getNumIncomingValues(self : PHINode) -> Int {
  self.incomings.length()
}

///|
/// Get the incoming value at the specified index.
///
/// **Note**:
///
/// Returns `None` if the index is out of bounds. Use `PHINode::getNumIncomingValues` to get the valid range.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_value_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block_bb = fval.addBasicBlock(name="block")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
/// phi.addIncoming(val1, entry_bb)
/// phi.addIncoming(val2, block_bb)
///
/// inspect(phi.getIncomingValue(0).unwrap().getValueRepr(), content = "10")
/// inspect(phi.getIncomingValue(1).unwrap().getValueRepr(), content = "20")
/// inspect(phi.getIncomingValue(2), content = "None")
/// ```
pub fn PHINode::getIncomingValue(self : PHINode, idx : Int) -> &Value? {
  match self.incomings.get(idx) {
    Some((value, _)) => Some(value)
    None => None
  }
}

///|
/// Get the incoming basic block at the specified index.
///
/// **Note**:
///
/// Returns `None` if the index is out of bounds. Use `PHINode::getNumIncomingValues` to get the valid range.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_block_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block_bb = fval.addBasicBlock(name="block")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
/// phi.addIncoming(val1, entry_bb)
/// phi.addIncoming(val2, block_bb)
///
/// inspect(phi.getIncomingBlock(0).unwrap().getValueRepr(), content = "%entry")
/// inspect(phi.getIncomingBlock(1).unwrap().getValueRepr(), content = "%block")
/// inspect(phi.getIncomingBlock(2), content = "None")
/// ```
pub fn PHINode::getIncomingBlock(self : PHINode, idx : Int) -> BasicBlock? {
  match self.incomings.get(idx) {
    Some((_, block)) => Some(block)
    None => None
  }
}

///|
/// Get the incoming value-block pair at the specified index.
///
/// **Note**:
///
/// Returns `None` if the index is out of bounds. This is a convenience method that returns both the value and block together.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_incoming_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block_bb = fval.addBasicBlock(name="block")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
/// phi.addIncoming(val1, entry_bb)
/// phi.addIncoming(val2, block_bb)
///
/// let (value0, block0) = phi.getIncoming(0).unwrap()
/// inspect(value0.getValueRepr(), content = "10")
/// inspect(block0.getValueRepr(), content = "%entry")
///
/// let (value1, block1) = phi.getIncoming(1).unwrap()
/// inspect(value1.getValueRepr(), content = "20")
/// inspect(block1.getValueRepr(), content = "%block")
///
/// inspect(phi.getIncoming(2), content = "None")
/// ```
pub fn PHINode::getIncoming(self : PHINode, idx : Int) -> (&Value, BasicBlock)? {
  self.incomings.get(idx)
}

///|
/// Get all incoming value-block pairs as an array.
///
/// **Note**:
///
/// Returns a copy of the internal array containing all value-block pairs in the order they were added.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_incomings_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block1_bb = fval.addBasicBlock(name="block1")
/// let block2_bb = fval.addBasicBlock(name="block2")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
/// let val3 = ctx.getConstInt32(30)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
/// phi.addIncoming(val1, entry_bb)
/// phi.addIncoming(val2, block1_bb)
/// phi.addIncoming(val3, block2_bb)
///
/// let incomings = phi.getIncomings()
/// inspect(incomings.length(), content = "3")
/// inspect(incomings[0].0.getValueRepr(), content = "10")
/// inspect(incomings[0].1.getValueRepr(), content = "%entry")
/// inspect(incomings[1].0.getValueRepr(), content = "20")
/// inspect(incomings[2].0.getValueRepr(), content = "30")
/// ```
pub fn PHINode::getIncomings(self : PHINode) -> Array[(&Value, BasicBlock)] {
  self.incomings
}

///|
/// Get all incoming values as an array.
///
/// **Note**:
///
/// Returns an array containing only the values from all incoming value-block pairs, in the order they were added.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_values_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block1_bb = fval.addBasicBlock(name="block1")
/// let block2_bb = fval.addBasicBlock(name="block2")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
/// let val3 = ctx.getConstInt32(30)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
/// phi.addIncoming(val1, entry_bb)
/// phi.addIncoming(val2, block1_bb)
/// phi.addIncoming(val3, block2_bb)
///
/// let values = phi.getIncomingValues()
/// inspect(values.length(), content = "3")
/// inspect(values[0].getValueRepr(), content = "10")
/// inspect(values[1].getValueRepr(), content = "20")
/// inspect(values[2].getValueRepr(), content = "30")
/// ```
pub fn PHINode::getIncomingValues(self : PHINode) -> Array[&Value] {
  self.incomings.map(incoming => incoming.0)
}

///|
/// Get all incoming basic blocks as an array.
///
/// **Note**:
///
/// Returns an array containing only the basic blocks from all incoming value-block pairs, in the order they were added.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_blocks_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block1_bb = fval.addBasicBlock(name="block1")
/// let block2_bb = fval.addBasicBlock(name="block2")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
/// let val3 = ctx.getConstInt32(30)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
/// phi.addIncoming(val1, entry_bb)
/// phi.addIncoming(val2, block1_bb)
/// phi.addIncoming(val3, block2_bb)
///
/// let blocks = phi.getIncomingBlocks()
/// inspect(blocks.length(), content = "3")
/// inspect(blocks[0].getValueRepr(), content = "%entry")
/// inspect(blocks[1].getValueRepr(), content = "%block1")
/// inspect(blocks[2].getValueRepr(), content = "%block2")
/// ```
pub fn PHINode::getIncomingBlocks(self : PHINode) -> Array[BasicBlock] {
  self.incomings.map(incoming => incoming.1)
}

///|
/// Add an incoming value-block pair to the PHI node.
///
/// **Note**:
///
/// The value's type must match the PHI node's type. Will raise `LLVMValueError` if there is a type mismatch.
/// The basic block represents the predecessor block from which this value flows into the PHI node.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_add_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let block1_bb = fval.addBasicBlock(name="block1")
/// let block2_bb = fval.addBasicBlock(name="block2")
/// let merge_bb = fval.addBasicBlock(name="merge")
/// let val1 = ctx.getConstInt32(10)
/// let val2 = ctx.getConstInt32(20)
/// let val3 = ctx.getConstInt32(30)
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty, name="result")
///
/// inspect(phi.getNumIncomingValues(), content = "0")
///
/// phi.addIncoming(val1, entry_bb)
/// inspect(phi.getNumIncomingValues(), content = "1")
/// inspect(phi.getIncomingValue(0).unwrap().getValueRepr(), content = "10")
/// inspect(phi.getIncomingBlock(0).unwrap().getValueRepr(), content = "%entry")
///
/// phi.addIncoming(val2, block1_bb)
/// phi.addIncoming(val3, block2_bb)
/// inspect(phi.getNumIncomingValues(), content = "3")
///
/// let expected = "  %result = phi i32 [ 10, %entry ], [ 20, %block1 ], [ 30, %block2 ]"
/// inspect(phi, content = expected)
/// ```
pub fn PHINode::addIncoming(
  self : PHINode,
  value : &Value,
  block : BasicBlock,
) -> Unit raise LLVMValueError {
  guard value.getType() == self.getType() else {
    let msg = "PHINode incoming value type mismatch: " +
      "expected \{self.getType()}, got \{value.getType()}"
    raise LLVMValueError(msg)
  }
  self.incomings.push((value, block))
  value.addUser(self)
  block.addUser(self)
}

///|
pub impl Value for PHINode with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(entry_bb)
/// let phi = builder.createPHI(i32_ty)
///
/// inspect(phi.getValueRepr(), content = "%0")
///
/// phi.setName("result")
/// inspect(phi.getValueRepr(), content = "%result")
/// ```
pub impl Value for PHINode with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(entry_bb)
/// let phi = builder.createPHI(i32_ty)
///
/// inspect(phi.getName(), content = "None")
///
/// phi.setName("result")
/// inspect(phi.getName(), content = "Some(\"result\")")
/// ```
pub impl Value for PHINode with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [])
///
/// let fval = mod.addFunction(fty, "phi_demo")
/// let merge_bb = fval.addBasicBlock(name="merge")
///
/// builder.setInsertPoint(merge_bb)
/// let phi = builder.createPHI(i32_ty)
///
/// inspect(phi.getName(), content = "None")
///
/// phi.setName("result")
/// inspect(phi.getName(), content = "Some(\"result\")")
/// ```
pub impl Value for PHINode with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `PHINode::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `PHINode::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `PHINode::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for PHINode with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for PHINode with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl Value for PHINode with asValueEnum(self) {
  PHINode(self)
}

///|
pub impl User for PHINode with asUserEnum(self) {
  PHINode(self)
}

///|
pub impl User for PHINode with getUserBase(self) {
  let operands : Array[&Value] = []
  self.incomings.each(incoming => {
    operands.push(incoming.0)
    operands.push(incoming.1)
  })
  UserBase::{ operands, }
}

///|
pub impl Instruction for PHINode with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for PHINode with asInstEnum(self) {
  InstEnum::PHINode(self)
}

///|
pub impl Instruction for PHINode with getParent(self) {
  self.parent
}

///|
pub impl Show for PHINode with output(self, logger) {
  let repr = self.getValueRepr()
  let ty = self.getType()
  let str = "  \{repr} = phi \{ty}"
  let num_incoming = self.getNumIncomingValues()
  let incoming_strs = Array::new()
  for i = 0; i < num_incoming; i = i + 1 {
    if self.getIncoming(i) is Some((value, block)) {
      let value_repr = value.getValueRepr()
      let block_repr = block.getValueRepr()
      incoming_strs.push("[ \{value_repr}, \{block_repr} ]")
    }
  }
  let str = str +
    (if num_incoming > 0 { " " + incoming_strs.join(", ") } else { "" })
  logger.write_string(str)
}

// =======================================================
// CallInst
// =======================================================

///|
pub(all) enum TailCallKind {
  NoTail
  Tail
  MustTail
}

///|
pub impl Show for TailCallKind with output(self, logger) {
  let str = match self {
    NoTail => ""
    Tail => "tail"
    MustTail => "musttail"
  }
  logger.write_string(str)
}

///|
/// CallInst represents a function call instruction that invokes a function with the specified arguments.
///
/// **Note**:
///
/// Use `IRBuilder::createCall` to create a `CallInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let add_fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
/// let main_fty = ctx.getFunctionType(i32_ty, [])
///
/// let add_func = mod.addFunction(add_fty, "add")
/// let main_func = mod.addFunction(main_fty, "main")
/// let bb = main_func.addBasicBlock(name="entry")
/// let arg1 = ctx.getConstInt32(10)
/// let arg2 = ctx.getConstInt32(20)
///
/// builder.setInsertPoint(bb)
/// let call = builder.createCall(add_func, [arg1, arg2], name="sum")
///
/// inspect(call, content = "  %sum = call i32 @add(i32 10, i32 20)")
/// assert_true(call.asValueEnum() is CallInst(_))
///
/// let void_fty = ctx.getFunctionType(ctx.getVoidTy(), [])
/// let void_func = mod.addFunction(void_fty, "void_func")
/// let void_call = builder.createCall(void_func, [])
///
/// inspect(void_call, content = "  call void @void_func()")
/// ```
pub struct CallInst {
  uid : UInt64
  vty : &Type
  users : Array[&User]
  mut name : String?
  callee : Function
  args : Array[&Value]
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  mut tailCallKind : TailCallKind
}

///|
fn CallInst::new(
  callee : Function,
  args : Array[&Value],
  parent : Function,
  name~ : String?,
) -> CallInst {
  let fty = callee.getFunctionType()
  let name = match fty.getReturnType().asTypeEnum() {
    VoidType(_) => None
    _ => name
  }
  let uid = valueUIDAssigner.assign()
  let vty = fty.getReturnType()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CallInst::{
    uid,
    vty,
    users: [],
    name,
    callee,
    args,
    parent,
    bb,
    prev,
    next,
    tailCallKind: NoTail,
  }
  callee.addUser(inst)
  args.each(arg => arg.addUser(inst))
  inst
}

///|
pub fn CallInst::isTailCall(self : CallInst) -> Bool {
  not(self.tailCallKind is NoTail)
}

///|
pub fn CallInst::getTailCallKind(self : CallInst) -> TailCallKind {
  self.tailCallKind
}

///|
pub fn CallInst::setTailCallKind(
  self : CallInst,
  tailCallKind : TailCallKind,
) -> Unit {
  self.tailCallKind = tailCallKind
}

///|
pub fn CallInst::getFunctionType(self : CallInst) -> FunctionType {
  guard self.getOperand(0).unwrap().getType().asTypeEnum() is FunctionType(ft)
  ft
}

///|
pub fn CallInst::getCallee(self : CallInst) -> Function {
  guard self.getOperand(0) is Some(callee_val)
  guard callee_val.asValueEnum() is Function(callee)
  callee
}

///|
pub fn CallInst::getArgOperand(self : Self, idx : Int) -> &Value? {
  self.args.get(idx)
}

///|
pub fn CallInst::getNumArgs(self : Self) -> Int {
  self.callee.getFunctionType().getNumParams()
}

///|
pub impl Value for CallInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for CallInst with asValueEnum(self) {
  CallInst(self)
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let add_fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
/// let main_fty = ctx.getFunctionType(i32_ty, [])
///
/// let add_func = mod.addFunction(add_fty, "add")
/// let main_func = mod.addFunction(main_fty, "main")
/// let bb = main_func.addBasicBlock(name="entry")
/// let arg1 = ctx.getConstInt32(10)
/// let arg2 = ctx.getConstInt32(20)
///
/// builder.setInsertPoint(bb)
/// let call = builder.createCall(add_func, [arg1, arg2])
///
/// inspect(call.getValueRepr(), content = "%0")
///
/// call.setName("sum")
/// inspect(call.getValueRepr(), content = "%sum")
/// ```
pub impl Value for CallInst with getValueRepr(self) {
  if self.vty.asTypeEnum() is VoidType(_) {
    return ""
  }
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let add_fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
/// let main_fty = ctx.getFunctionType(i32_ty, [])
///
/// let add_func = mod.addFunction(add_fty, "add")
/// let main_func = mod.addFunction(main_fty, "main")
/// let bb = main_func.addBasicBlock(name="entry")
/// let arg1 = ctx.getConstInt32(10)
/// let arg2 = ctx.getConstInt32(20)
///
/// builder.setInsertPoint(bb)
/// let call = builder.createCall(add_func, [arg1, arg2])
///
/// inspect(call.getName(), content = "None")
///
/// call.setName("sum")
/// inspect(call.getName(), content = "Some(\"sum\")")
/// ```
pub impl Value for CallInst with getName(self) {
  self.name
}

///|
pub impl Value for CallInst with getNameOrSlot(self) {
  if self.vty.asTypeEnum() is VoidType(_) {
    return None
  }
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error. Cannot set name for CallInst with void return type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let add_fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
/// let main_fty = ctx.getFunctionType(i32_ty, [])
///
/// let add_func = mod.addFunction(add_fty, "add")
/// let main_func = mod.addFunction(main_fty, "main")
/// let bb = main_func.addBasicBlock(name="entry")
/// let arg1 = ctx.getConstInt32(10)
/// let arg2 = ctx.getConstInt32(20)
///
/// builder.setInsertPoint(bb)
/// let call = builder.createCall(add_func, [arg1, arg2])
///
/// inspect(call.getName(), content = "None")
///
/// call.setName("sum")
/// inspect(call.getName(), content = "Some(\"sum\")")
/// ```
pub impl Value for CallInst with setName(self, name) {
  if self.vty.asTypeEnum() is VoidType(_) {
    let msg = "Misuse `CallInst::setName`: " +
      "cannot set name for CallInst with void return type."
    raise LLVMValueError(msg)
  }
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `CallInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `CallInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `CallInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for CallInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl User for CallInst with asUserEnum(self) {
  CallInst(self)
}

///|
pub impl User for CallInst with getUserBase(self) {
  UserBase::{ operands: [self.callee] + self.args }
}

///|
pub impl Instruction for CallInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for CallInst with asInstEnum(self) {
  InstEnum::CallInst(self)
}

///|
pub impl Instruction for CallInst with getParent(self) {
  self.parent
}

///|
pub impl Show for CallInst with output(self, logger) {
  let callee = self.callee
  let fty = callee.getFunctionType()
  let ret_ty = fty.getReturnType()
  let is_var_arg = fty.isVarArg
  let is_void_ret = ret_ty.asTypeEnum() is VoidType(_)
  let prefix = if is_void_ret { "" } else { self.getValueRepr() }
  let tail_str = self.tailCallKind.to_string()
  let ret_attrs = callee.getReturnAttrs()
  let ret_attrs_str = if ret_attrs.is_empty() {
    ""
  } else {
    " " + ret_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
  }
  let arg_strs = Array::new()
  for idx, arg in self.args {
    let arg_ty = arg.getType()
    let arg_repr = arg.getValueRepr()
    let arg_attrs = callee.getParamAttrs(idx.reinterpret_as_uint())
    let arg_attrs_str = if not(arg_attrs.is_empty()) {
      " " + arg_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
    } else {
      ""
    }
    arg_strs.push("\{arg_ty}\{arg_attrs_str} \{arg_repr}")
  }
  let args_str = arg_strs.join(", ")
  let call_prefix = if tail_str.is_empty() {
    "call"
  } else {
    "\{tail_str} call"
  }
  let var_arg_func_mark = if is_var_arg {
    let param_ty_strs = fty.getParamTypes().map(t => t.to_string())
    param_ty_strs.push("...")
    let param_ty_str = param_ty_strs.join(", ")
    " (\{param_ty_str})"
  } else {
    ""
  }
  if is_void_ret {
    logger.write_string(
      "  \{call_prefix}\{ret_attrs_str} \{ret_ty}\{var_arg_func_mark} @\{callee.name}(\{args_str})",
    )
  } else {
    logger.write_string(
      "  \{prefix} = \{call_prefix}\{ret_attrs_str} \{ret_ty}\{var_arg_func_mark} @\{callee.name}(\{args_str})",
    )
  }
}

// =======================================================
// ExtractValueInst
// =======================================================

///|
/// ExtractValueInst represents an extractvalue instruction that extracts a value from an aggregate (struct or array) at the specified index.
///
/// **Note**:
///
/// Use `IRBuilder::createExtractValue` to create an `ExtractValueInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let struct_ty = ctx.getStructType([i32_ty, i32_ty])
/// let fty = ctx.getFunctionType(i32_ty, [struct_ty])
///
/// let fval = mod.addFunction(fty, "extractvalue_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let aggregate = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let extract = builder.createExtractValue(aggregate, [0], name="field")
///
/// inspect(extract, content = "  %field = extractvalue { i32, i32 } %0, 0")
/// assert_true(extract.asValueEnum() is ExtractValueInst(_))
/// ```
pub struct ExtractValueInst {
  uid : UInt64
  vty : &Type
  users : Array[&User]
  mut name : String?
  aggregate : &Value
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  indices : Array[Int]
}

///|
fn ExtractValueInst::new(
  aggregate : &Value,
  indices : Array[Int],
  parent : Function,
  name~ : String?,
) -> ExtractValueInst {
  let agg_ty = aggregate.getType()
  guard agg_ty.tryAsAggregateTypeEnum() is Some(agg_ty)
  guard agg_ty.getIndexedType(indices) is Some(result_ty)
  let uid = valueUIDAssigner.assign()
  let vty = result_ty
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = ExtractValueInst::{
    uid,
    vty,
    users: [],
    name,
    aggregate,
    parent,
    bb,
    prev,
    next,
    indices,
  }
  aggregate.addUser(inst)
  inst
}

///|
pub fn ExtractValueInst::getAggregateOperand(self : ExtractValueInst) -> &Value {
  self.aggregate
}

///|
pub fn ExtractValueInst::getIndices(self : ExtractValueInst) -> Array[Int] {
  self.indices
}

///|
pub impl Value for ExtractValueInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let struct_ty = ctx.getStructType([i32_ty, i32_ty])
/// let fty = ctx.getFunctionType(i32_ty, [struct_ty])
///
/// let fval = mod.addFunction(fty, "extractvalue_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let aggregate = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let extract = builder.createExtractValue(aggregate, [0])
///
/// inspect(extract.getValueRepr(), content = "%1")
///
/// extract.setName("field")
/// inspect(extract.getValueRepr(), content = "%field")
/// ```
pub impl Value for ExtractValueInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for ExtractValueInst with asValueEnum(self) {
  ExtractValueInst(self)
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let struct_ty = ctx.getStructType([i32_ty, i32_ty])
/// let fty = ctx.getFunctionType(i32_ty, [struct_ty])
///
/// let fval = mod.addFunction(fty, "extractvalue_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let aggregate = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let extract = builder.createExtractValue(aggregate, [0])
///
/// inspect(extract.getName(), content = "None")
///
/// extract.setName("field")
/// inspect(extract.getName(), content = "Some(\"field\")")
/// ```
pub impl Value for ExtractValueInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let struct_ty = ctx.getStructType([i32_ty, i32_ty])
/// let fty = ctx.getFunctionType(i32_ty, [struct_ty])
///
/// let fval = mod.addFunction(fty, "extractvalue_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let aggregate = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let extract = builder.createExtractValue(aggregate, [0])
///
/// inspect(extract.getName(), content = "None")
///
/// extract.setName("field")
/// inspect(extract.getName(), content = "Some(\"field\")")
/// ```
pub impl Value for ExtractValueInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `ExtractValueInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `ExtractValueInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `ExtractValueInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for ExtractValueInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for ExtractValueInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for ExtractValueInst with asUserEnum(self) {
  ExtractValueInst(self)
}

///|
pub impl User for ExtractValueInst with getUserBase(self) {
  UserBase::{ operands: [self.aggregate] }
}

///|
pub impl Instruction for ExtractValueInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for ExtractValueInst with asInstEnum(self) {
  InstEnum::ExtractValueInst(self)
}

///|
pub impl Instruction for ExtractValueInst with getParent(self) {
  self.parent
}

///|
pub impl UnaryInst for ExtractValueInst with asUnaryInstEnum(self) {
  UnaryInstEnum::ExtractValueInst(self)
}

///|
pub impl Show for ExtractValueInst with output(self, logger) {
  let repr = self.getValueRepr()
  let agg = self.getAggregateOperand()
  let agg_ty = agg.getType()
  let agg_repr = agg.getValueRepr()
  let indices_str = self.indices.iter().map(i => "\{i}").join(", ")
  logger.write_string(
    "  \{repr} = extractvalue \{agg_ty} \{agg_repr}, \{indices_str}",
  )
}

// =======================================================
// InsertValueInst
// =======================================================

///|
/// InsertValueInst represents an insertvalue instruction that inserts a value into an aggregate (struct or array) at the specified index.
///
/// **Note**:
///
/// Use `IRBuilder::createInsertValue` to create an `InsertValueInst`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let struct_ty = ctx.getStructType([i32_ty, i32_ty])
/// let fty = ctx.getFunctionType(struct_ty, [struct_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "insertvalue_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let aggregate = fval.getArg(0).unwrap()
/// let new_value = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let insert = builder.createInsertValue(aggregate, new_value, [1], name="updated")
///
/// inspect(insert, content = "  %updated = insertvalue { i32, i32 } %0, i32 %1, 1")
/// assert_true(insert.asValueEnum() is InsertValueInst(_))
/// ```
pub struct InsertValueInst {
  uid : UInt64
  vty : &Type
  users : Array[&User]
  aggregate : &Value
  insert_val : &Value
  mut name : String?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  indices : Array[Int]
}

///|
fn InsertValueInst::new(
  aggregate : &Value,
  insert_val : &Value,
  indices : Array[Int],
  parent : Function,
  name~ : String?,
) -> InsertValueInst {
  let agg_ty = aggregate.getType()
  guard agg_ty.tryAsAggregateTypeEnum() is Some(agg_ty)
  guard agg_ty.getIndexedType(indices) is Some(_)
  let uid = valueUIDAssigner.assign()
  let vty = agg_ty.asTypeClass()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = InsertValueInst::{
    uid,
    vty,
    users: [],
    aggregate,
    insert_val,
    name,
    parent,
    bb,
    prev,
    next,
    indices,
  }
  aggregate.addUser(inst)
  insert_val.addUser(inst)
  inst
}

///|
pub fn InsertValueInst::getAggregateOperand(self : InsertValueInst) -> &Value {
  self.aggregate
}

///|
pub fn InsertValueInst::getInsertedValueOperand(
  self : InsertValueInst,
) -> &Value {
  self.insert_val
}

///|
pub fn InsertValueInst::getIndices(self : InsertValueInst) -> Array[Int] {
  self.indices
}

///|
pub impl Value for InsertValueInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for InsertValueInst with asValueEnum(self) {
  InsertValueInst(self)
}

///|
/// Get simple representation of the value.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let struct_ty = ctx.getStructType([i32_ty, i32_ty])
/// let fty = ctx.getFunctionType(struct_ty, [struct_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "insertvalue_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let aggregate = fval.getArg(0).unwrap()
/// let new_value = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let insert = builder.createInsertValue(aggregate, new_value, [1])
///
/// inspect(insert.getValueRepr(), content = "%2")
///
/// insert.setName("updated")
/// inspect(insert.getValueRepr(), content = "%updated")
/// ```
pub impl Value for InsertValueInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let struct_ty = ctx.getStructType([i32_ty, i32_ty])
/// let fty = ctx.getFunctionType(struct_ty, [struct_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "insertvalue_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let aggregate = fval.getArg(0).unwrap()
/// let new_value = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let insert = builder.createInsertValue(aggregate, new_value, [1])
///
/// inspect(insert.getName(), content = "None")
///
/// insert.setName("updated")
/// inspect(insert.getName(), content = "Some(\"updated\")")
/// ```
pub impl Value for InsertValueInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let struct_ty = ctx.getStructType([i32_ty, i32_ty])
/// let fty = ctx.getFunctionType(struct_ty, [struct_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "insertvalue_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let aggregate = fval.getArg(0).unwrap()
/// let new_value = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let insert = builder.createInsertValue(aggregate, new_value, [1])
///
/// inspect(insert.getName(), content = "None")
///
/// insert.setName("updated")
/// inspect(insert.getName(), content = "Some(\"updated\")")
/// ```
pub impl Value for InsertValueInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `InsertValueInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `InsertValueInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `InsertValueInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for InsertValueInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for InsertValueInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for InsertValueInst with asUserEnum(self) {
  InsertValueInst(self)
}

///|
pub impl User for InsertValueInst with getUserBase(self) {
  UserBase::{ operands: [self.aggregate, self.getInsertedValueOperand()] }
}

///|
pub impl Instruction for InsertValueInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for InsertValueInst with asInstEnum(self) {
  InstEnum::InsertValueInst(self)
}

///|
pub impl Instruction for InsertValueInst with getParent(self) {
  self.parent
}

///|
pub impl Show for InsertValueInst with output(self, logger) {
  let repr = self.getValueRepr()
  let agg = self.getAggregateOperand()
  let val = self.getInsertedValueOperand()
  let agg_ty = agg.getType()
  let val_ty = val.getType()
  let agg_repr = agg.getValueRepr()
  let val_repr = val.getValueRepr()
  let indices_str = self.indices.iter().map(i => "\{i}").join(", ")
  logger.write_string(
    "  \{repr} = insertvalue \{agg_ty} \{agg_repr}, \{val_ty} \{val_repr}, \{indices_str}",
  )
}
