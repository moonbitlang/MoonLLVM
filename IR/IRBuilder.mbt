///|
trait InsertPoint {
  asInsertPtEnum(Self) -> InsertPointEnum
}

///|
priv enum InsertPointEnum {
  BasicBlock(BasicBlock)
  Instruction(&Instruction)
}

///|
pub impl InsertPoint for BasicBlock with asInsertPtEnum(self) {
  InsertPointEnum::BasicBlock(self)
}

///|
pub impl InsertPoint for &Instruction with asInsertPtEnum(self) {
  InsertPointEnum::Instruction(self)
}

///|
pub struct IRBuilder {
  mut bb : BasicBlock?
  mut insertPt : &Instruction?
}

///|
pub fn IRBuilder::new() -> IRBuilder {
  IRBuilder::{ bb: None, insertPt: None }
}

///|
pub fn[T : InsertPoint] IRBuilder::setInsertPoint(
  self : IRBuilder,
  insertPt : T
) -> Unit {
  match insertPt.asInsertPtEnum() {
    BasicBlock(bb) => {
      self.bb = Some(bb)
      self.insertPt = bb.lastInst()
    }
    Instruction(inst) => {
      self.bb = inst.getBasicBlock()
      self.insertPt = Some(inst)
    }
  }
}

///|
fn IRBuilder::insert(self : IRBuilder, inst : &Instruction) -> Unit!Error {
  guard self.bb is Some(_) else { raise UnsetInsertPoint }
  match self.insertPt {
    Some(insertPt) => {
      inst.insertAfter!(insertPt)
      self.insertPt = Some(inst)
    }
    None => {
      self.bb.unwrap().head = Some(inst)
      self.insertPt = Some(inst)
    }
  }
}

///|
fn IRBuilder::getInsertFunction(self : IRBuilder) -> Function {
  self.bb.unwrap().parent
}

///|
pub fn IRBuilder::createRet(
  self : IRBuilder,
  retVal : &Value
) -> &Instruction!Error {
  let parent = self.getInsertFunction()
  let retInst = ReturnInst::new(Some(retVal), parent)
  self.insert!(retInst)
  retInst
}

///|
pub fn IRBuilder::createRetVoid(self : IRBuilder) -> &Instruction!Error {
  let parent = self.getInsertFunction()
  let retInst = ReturnInst::new(None, parent)
  self.insert!(retInst)
  retInst
}

///|
pub fn IRBuilder::createAlloca(
  self : IRBuilder,
  data_ty : &Type,
  addressSpace~ : AddressSpace = AddressSpace::default(),
  name~ : String = ""
) -> &Value!Error {
  let allocaInst = AllocaInst::new(
    data_ty,
    self.getInsertFunction(),
    addressSpace~,
    name,
  )
  self.insert!(allocaInst)
  allocaInst
}

///| Create Add Instruction.
///
/// **Note:** 
///
/// - (Constant folding) If both operands are constant integers, the addition is
/// evaluated at compile time and the result is returned as a constant value.
///
/// - `nsw` stands for "no signed wrap", which means that the addition
/// operation is guaranteed not to overflow for signed integers.
/// If an overflow occurs, the behavior is undefined.
///
/// - `nuw` stands for "no unsigned wrap", which means that the addition
/// operation is guaranteed not to overflow for unsigned integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createAdd" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "add")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular addition with nsw and nuw flags
///   let nsw_add = builder.createAdd!(arg0, arg1, has_nsw=true)
///   let nuw_add = builder.createAdd!(arg0, arg1, has_nuw=true)
///   
///   // Test constant folding
///   let const_42 = ctx.getConstInt32(42)
///   let const_33 = ctx.getConstInt32(33)
///   let const_sum = builder.createAdd!(const_42, const_33) // Should fold to 75
///   
///   // Combine results with both nsw and nuw flags
///   let final_add = builder.createAdd!(
///     nsw_add, nuw_add, has_nsw=true, has_nuw=true
///   )
///   let result = builder.createAdd!(final_add, const_sum)
///   let _ = builder.createRet!(result)
///
///   // Verify constant folding worked
///   inspect(const_sum, content = "i32 75")
///   
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = add nsw i32 %0, %1
///     #|  %3 = add nuw i32 %0, %1
///     #|  %4 = add nuw nsw i32 %2, %3
///     #|  %5 = add i32 %4, 75
///     #|  ret i32 %5
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createAdd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  has_nsw~ : Bool = false,
  has_nuw~ : Bool = false
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) => return lhs.add!(rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if has_nuw {
    flags.add(BinaryOpFlags::NoUnsignedWrap)
  }
  if has_nsw {
    flags.add(BinaryOpFlags::NoSignedWrap)
  }
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Add,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create Add Instruction with no signed wrap (NSW) flag.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the addition is
/// evaluated at compile time and the result is returned as a constant value.
///
/// - `nsw` stands for "no signed wrap", which means that the addition
/// operation is guaranteed not to overflow for signed integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createNSWAdd" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "add")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular addition with nsw flag
///   let sum = builder.createNSWAdd!(arg0, arg1)
///   
///   // Test constant folding
///   let const_42 = ctx.getConstInt32(42)
///   let const_33 = ctx.getConstInt32(33)
///   let const_sum = builder.createNSWAdd!(const_42, const_33) // Should fold to 75
///   
///   let result = builder.createAdd!(sum, const_sum)
///   let _ = builder.createRet!(result)
///
///   // Verify constant folding worked
///   inspect(const_sum, content = "i32 75")
///   
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = add nsw i32 %0, %1
///     #|  %3 = add i32 %2, 75
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createNSWAdd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createAdd(lhs, rhs, name~, has_nsw=true, has_nuw=false)
}

///| Create Add Instruction with no unsigned wrap (NUW) flag.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the addition is
/// evaluated at compile time and the result is returned as a constant value.
///
/// - `nuw` stands for "no unsigned wrap", which means that the addition
/// operation is guaranteed not to overflow for unsigned integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createNUWAdd" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "add")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular addition with nuw flag
///   let sum = builder.createNUWAdd!(arg0, arg1)
///   
///   // Test constant folding
///   let const_42 = ctx.getConstInt32(42)
///   let const_33 = ctx.getConstInt32(33)
///   let const_sum = builder.createNUWAdd!(const_42, const_33) // Should fold to 75
///   
///   let result = builder.createAdd!(sum, const_sum)
///   let _ = builder.createRet!(result)
///
///   // Verify constant folding worked
///   inspect(const_sum, content = "i32 75")
///   
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = add nuw i32 %0, %1
///     #|  %3 = add i32 %2, 75
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createNUWAdd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createAdd(lhs, rhs, name~, has_nsw=false, has_nuw=true)
}

///| Create Sub Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the subtraction is
/// evaluated at compile time and the result is returned as a constant value.
///
/// - `nsw` stands for "no signed wrap", which means that the subtraction
/// operation is guaranteed not to overflow for signed integers.
/// If an overflow occurs, the behavior is undefined.
///
/// - `nuw` stands for "no unsigned wrap", which means that the subtraction
/// operation is guaranteed not to overflow for unsigned integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createSub" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "sub")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular subtraction with nsw and nuw flags
///   let nsw_sub = builder.createSub!(arg0, arg1, has_nsw=true)
///   let nuw_sub = builder.createSub!(arg0, arg1, has_nuw=true)
///   
///   // Test constant folding
///   let const_42 = ctx.getConstInt32(42)
///   let const_33 = ctx.getConstInt32(33)
///   let const_diff = builder.createSub!(const_42, const_33) // Should fold to 9
///   
///   // Combine results with both nsw and nuw flags
///   let final_sub = builder.createSub!(
///     nsw_sub, nuw_sub, has_nsw=true, has_nuw=true
///   )
///   let result = builder.createAdd!(final_sub, const_diff)
///   let _ = builder.createRet!(result)
///
///   // Verify constant folding worked
///   inspect(const_diff, content = "i32 9")
///   
///   inspect(
///     fval,
///     content = 
///     #|define i32 @sub(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = sub nsw i32 %0, %1
///     #|  %3 = sub nuw i32 %0, %1
///     #|  %4 = sub nuw nsw i32 %2, %3
///     #|  %5 = add i32 %4, 9
///     #|  ret i32 %5
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createSub(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  has_nsw~ : Bool = false,
  has_nuw~ : Bool = false
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) => return lhs.sub!(rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if has_nuw {
    flags.add(BinaryOpFlags::NoUnsignedWrap)
  }
  if has_nsw {
    flags.add(BinaryOpFlags::NoSignedWrap)
  }
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Sub,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create Sub Instruction with no signed wrap (NSW) flag.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the subtraction is
/// evaluated at compile time and the result is returned as a constant value.
///
/// - `nsw` stands for "no signed wrap", which means that the subtraction
/// operation is guaranteed not to overflow for signed integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createNSWSub" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "sub")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular subtraction with nsw flag
///   let diff = builder.createNSWSub!(arg0, arg1)
///   
///   // Test constant folding
///   let const_42 = ctx.getConstInt32(42)
///   let const_33 = ctx.getConstInt32(33)
///   let const_diff = builder.createNSWSub!(const_42, const_33) // Should fold to 9
///   
///   let result = builder.createAdd!(diff, const_diff)
///   let _ = builder.createRet!(result)
///
///   // Verify constant folding worked
///   inspect(const_diff, content = "i32 9")
///   
///   inspect(
///     fval,
///     content = 
///     #|define i32 @sub(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = sub nsw i32 %0, %1
///     #|  %3 = add i32 %2, 9
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createNSWSub(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createSub(lhs, rhs, name~, has_nsw=true, has_nuw=false)
}

///| Create Sub Instruction with no unsigned wrap (NUW) flag.
///
/// **Note:** `nuw` stands for "no unsigned wrap", which means that the subtraction
/// operation is guaranteed not to overflow for unsigned integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createNUWSub" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "sub")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let diff = builder.createNUWSub!(arg0, arg1)
///   let _ = builder.createRet!(diff)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @sub(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = sub nuw i32 %0, %1
///     #|  ret i32 %2
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createNSWSub with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "sub")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let forty_two = ctx.getConstInt32(42)
///   let thirty_three = ctx.getConstInt32(33)
///
///   let diff = builder.createNSWSub!(forty_two, thirty_three)
///   let _ = builder.createRet!(diff)
///
///   inspect(diff, content = "i32 9")
///   inspect(
///     fval,
///     content = 
///     #|define i32 @sub() {
///     #|entry:
///     #|  ret i32 9
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createNUWSub(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createSub(lhs, rhs, name~, has_nsw=false, has_nuw=true)
}

///| Create Mul Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the multiplication is
/// evaluated at compile time and the result is returned as a constant value.
///
/// - `nsw` stands for "no signed wrap", which means that the multiplication
/// operation is guaranteed not to overflow for signed integers.
/// If an overflow occurs, the behavior is undefined.
///
/// - `nuw` stands for "no unsigned wrap", which means that the multiplication
/// operation is guaranteed not to overflow for unsigned integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createMul" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "mul")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular multiplication with nsw and nuw flags
///   let nsw_mul = builder.createMul!(arg0, arg1, has_nsw=true)
///   let nuw_mul = builder.createMul!(arg0, arg1, has_nuw=true)
///   
///   // Test constant folding
///   let const_42 = ctx.getConstInt32(42)
///   let const_33 = ctx.getConstInt32(33)
///   let const_prod = builder.createMul!(const_42, const_33) // Should fold to 1386
///   
///   // Combine results with both nsw and nuw flags
///   let final_mul = builder.createMul!(
///     nsw_mul, nuw_mul, has_nsw=true, has_nuw=true
///   )
///   let result = builder.createAdd!(final_mul, const_prod)
///   let _ = builder.createRet!(result)
///
///   // Verify constant folding worked
///   inspect(const_prod, content = "i32 1386")
///   
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = mul nsw i32 %0, %1
///     #|  %3 = mul nuw i32 %0, %1
///     #|  %4 = mul nuw nsw i32 %2, %3
///     #|  %5 = add i32 %4, 1386
///     #|  ret i32 %5
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createMul(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  has_nsw~ : Bool = false,
  has_nuw~ : Bool = false
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) => return lhs.mul!(rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if has_nuw {
    flags.add(BinaryOpFlags::NoUnsignedWrap)
  }
  if has_nsw {
    flags.add(BinaryOpFlags::NoSignedWrap)
  }
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Mul,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create Mul Instruction with no signed wrap (NSW) flag.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the multiplication is
/// evaluated at compile time and the result is returned as a constant value.
///
/// - `nsw` stands for "no signed wrap", which means that the multiplication
/// operation is guaranteed not to overflow for signed integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createNSWMul" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "mul")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular multiplication with nsw flag
///   let prod = builder.createNSWMul!(arg0, arg1)
///   
///   // Test constant folding
///   let const_42 = ctx.getConstInt32(42)
///   let const_33 = ctx.getConstInt32(33)
///   let const_prod = builder.createNSWMul!(const_42, const_33) // Should fold to 1386
///   
///   let result = builder.createAdd!(prod, const_prod)
///   let _ = builder.createRet!(result)
///
///   // Verify constant folding worked
///   inspect(const_prod, content = "i32 1386")
///   
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = mul nsw i32 %0, %1
///     #|  %3 = add i32 %2, 1386
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createNSWMul(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createMul(lhs, rhs, name~, has_nsw=true, has_nuw=false)
}

///| Create Mul Instruction with no unsigned wrap (NUW) flag.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the multiplication is
/// evaluated at compile time and the result is returned as a constant value.
///
/// - `nuw` stands for "no unsigned wrap", which means that the multiplication
/// operation is guaranteed not to overflow for unsigned integers.
/// If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createNUWMul" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "mul")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular multiplication with nuw flag
///   let prod = builder.createNUWMul!(arg0, arg1)
///   
///   // Test constant folding
///   let const_42 = ctx.getConstInt32(42)
///   let const_33 = ctx.getConstInt32(33)
///   let const_prod = builder.createNUWMul!(const_42, const_33) // Should fold to 1386
///   
///   let result = builder.createAdd!(prod, const_prod)
///   let _ = builder.createRet!(result)
///
///   // Verify constant folding worked
///   inspect(const_prod, content = "i32 1386")
///   
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = mul nuw i32 %0, %1
///     #|  %3 = add i32 %2, 1386
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createNUWMul(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createMul(lhs, rhs, name~, has_nsw=false, has_nuw=true)
}

///| Create SDiv (signed division) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the signed division is
/// evaluated at compile time and the result is returned as a constant value. (Currently disabled due to missing `ConstantInt::sdiv!`)
///
/// - If the divisor is zero, or if the division overflows (e.g., `INT_MIN / -1`), the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createSDiv" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "sdiv_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let quot = builder.createSDiv!(arg0, arg1)
///   let _ = builder.createRet!(quot)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @sdiv_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = sdiv i32 %0, %1
///     #|  ret i32 %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createSDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  is_exact~ : Bool = false
) -> &Value!Error {
  // match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
  //   (Some(ConstantInt(c_lhs)), Some(ConstantInt(c_rhs))) => return c_lhs.sdiv!(c_rhs) // Assuming ConstantInt has sdiv!
  //   _ => ()
  // }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if is_exact {
    flags.add(BinaryOpFlags::Exact)
  }
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::SDiv,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create SDiv (signed division) Instruction with `exact` flag.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the signed division is
/// evaluated at compile time and the result is returned as a constant value. (Currently disabled due to missing `ConstantInt::sdiv!`)
///
/// - The `exact` keyword means that the operation is known to have no remainder.
///
/// - If the divisor is zero, or if the division overflows (e.g., `INT_MIN / -1`), the behavior is undefined.
///
/// - **Limitation**: The underlying `BinaryInstruction::newStandardOp` does not currently support setting the `exact` flag.
/// Therefore, this function will generate a standard `sdiv` instruction without the `exact` property being enforced at the IR level by this constructor.
///
/// ```moonbit
/// test "IRBuilder::createExactSDiv" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "exact_sdiv_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let quot = builder.createExactSDiv!(arg0, arg1)
///   let _ = builder.createRet!(quot)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @exact_sdiv_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = sdiv exact i32 %0, %1
///     #|  ret i32 %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createExactSDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createSDiv(lhs, rhs, name~, is_exact=true)
}

///| Create UDiv (unsigned division) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant unsigned integers, the unsigned division is
/// evaluated at compile time and the result is returned as a constant value. (Currently disabled due to assumed missing `ConstantUInt::udiv!`)
///
/// - If the divisor is zero, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createUDiv" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty() // Using i32 for unsigned operations as well, common in LLVM
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "udiv_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let quot = builder.createUDiv!(arg0, arg1)
///   let _ = builder.createRet!(quot)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @udiv_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = udiv i32 %0, %1
///     #|  ret i32 %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createUDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  is_exact~ : Bool = false
) -> &Value!Error {
  // match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
  //   (Some(ConstantUInt(c_lhs)), Some(ConstantUInt(c_rhs))) => return c_lhs.udiv!(c_rhs) // Assumed missing
  //   _ => ()
  // }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if is_exact {
    flags.add(BinaryOpFlags::Exact)
  }
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::UDiv,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create UDiv (unsigned division) Instruction with `exact` flag.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant unsigned integers, the unsigned division is
/// evaluated at compile time and the result is returned as a constant value. (Currently disabled due to assumed missing `ConstantUInt::udiv!`)
///
/// - The `exact` keyword means that the operation is known to have no remainder.
/// If the division has a remainder, the behavior is undefined.
///
/// - If the divisor is zero, the behavior is undefined.
///
/// - **Limitation**: The underlying `BinaryInstruction::newStandardOp` does not currently support setting the `exact` flag.
/// Therefore, this function will generate a standard `udiv` instruction without the `exact` property being enforced at the IR level by this constructor.
///
/// ```moonbit
/// test "IRBuilder::createExactUDiv" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "exact_udiv_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let quot = builder.createExactUDiv!(arg0, arg1)
///   let _ = builder.createRet!(quot)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @exact_udiv_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = udiv exact i32 %0, %1
///     #|  ret i32 %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createExactUDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createUDiv(lhs, rhs, name~, is_exact=true)
}

///| Create SRem (signed remainder) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the signed remainder is
/// evaluated at compile time and the result is returned as a constant value. (Currently disabled due to assumed missing `ConstantInt::srem!`)
///
/// - If the divisor is zero, the behavior is undefined.
///
/// - **Limitation**: The underlying `BinaryInstruction::newStandardOp` explicitly prevents the use of `BinaryOps::SRem`.
/// Attempting to create this instruction using it will result in an `unreachable` error.
///
/// ```moonbit
/// test "IRBuilder::createSRem" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "srem_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let rem = builder.createSRem!(arg0, arg1)
///   let _ = builder.createRet!(rem)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @srem_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = srem i32 %0, %1
///     #|  ret i32 %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createSRem(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  // Constant folding for SRem is currently disabled due to assumed missing `ConstantInt::srem!`
  // match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
  //   (Some(ConstantInt(c_lhs)), Some(ConstantInt(c_rhs))) => return c_lhs.srem!(c_rhs)
  //   _ => ()
  // }

  let parent = self.getInsertFunction()
  let flags = Set::new() // nsw, nuw, exact are not applicable to SRem
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::SRem,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create URem (unsigned remainder) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant unsigned integers, the unsigned remainder is
/// evaluated at compile time and the result is returned as a constant value. (Currently disabled due to assumed missing `ConstantUInt::urem!`)
///
/// - If the divisor is zero, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createURem" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty() // Using i32 for unsigned operations as well
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "urem_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let rem = builder.createURem!(arg0, arg1)
///   let _ = builder.createRet!(rem)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @urem_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = urem i32 %0, %1
///     #|  ret i32 %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createURem(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  // Constant folding for URem is currently disabled due to assumed missing `ConstantUInt::urem!`
  // match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
  //   (Some(ConstantUInt(c_lhs)), Some(ConstantUInt(c_rhs))) => return c_lhs.urem!(c_rhs)
  //   _ => ()
  // }

  let parent = self.getInsertFunction()
  let flags = Set::new() // nsw, nuw, exact are not applicable to URem
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::URem,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create FAdd (floating-point addition) Instruction.
///
/// ```moonbit
/// test "IRBuilder::createFAdd" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "fadd_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let sum = builder.createFAdd!(arg0, arg1)
///   let _ = builder.createRet!(sum)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fadd_func(float %0, float %1) {
///     #|entry:
///     #|  %2 = fadd float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Fast Math Flags
///
/// This function supports fast math flags, which can be used to
/// optimize floating-point operations.
///
/// ```moonbit
/// test "IRBuilder::createFAdd" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "fadd_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let fast_math_flags = Set::of([FastMathFlag::NoNaNs])
///   let sum = builder.createFAdd!(arg0, arg1, fast_math_flags~)
///   let _ = builder.createRet!(sum)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fadd_func(float %0, float %1) {
///     #|entry:
///     #|  %2 = fadd nnan float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createFAdd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FAdd,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert!(inst)
  inst
}

///| Create FSub (floating-point subtraction) Instruction.
///
/// ```moonbit
/// test "IRBuilder::createFSub" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "fsub_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let diff = builder.createFSub!(arg0, arg1)
///   let _ = builder.createRet!(diff)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fsub_func(float %0, float %1) {
///     #|entry:
///     #|  %2 = fsub float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Fast Math Flags
///
/// This function supports fast math flags, which can be used to
/// optimize floating-point operations.
///
/// ```moonbit
/// test "IRBuilder::createFSub with fast math flags" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "fsub_func_fast")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let fast_math_flags = Set::of([FastMathFlag::NoInfs])
///   let diff = builder.createFSub!(arg0, arg1, fast_math_flags~)
///   let _ = builder.createRet!(diff)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fsub_func_fast(float %0, float %1) {
///     #|entry:
///     #|  %2 = fsub ninf float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createFSub(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FSub,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert!(inst)
  inst
}

///| Create FMul (floating-point multiplication) Instruction.
///
/// ```moonbit
/// test "IRBuilder::createFMul" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "fmul_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let prod = builder.createFMul!(arg0, arg1)
///   let _ = builder.createRet!(prod)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fmul_func(float %0, float %1) {
///     #|entry:
///     #|  %2 = fmul float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Fast Math Flags
///
/// This function supports fast math flags, which can be used to
/// optimize floating-point operations.
///
/// ```moonbit
/// test "IRBuilder::createFMul with fast math flags" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "fmul_func_fast")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let fast_math_flags = Set::of([FastMathFlag::NoSignedZeros])
///   let prod = builder.createFMul!(arg0, arg1, fast_math_flags~)
///   let _ = builder.createRet!(prod)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fmul_func_fast(float %0, float %1) {
///     #|entry:
///     #|  %2 = fmul nsz float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createFMul(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FMul,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert!(inst)
  inst
}

///| Create FDiv (floating-point division) Instruction.
///
/// ```moonbit
/// test "IRBuilder::createFDiv" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "fdiv_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let quot = builder.createFDiv!(arg0, arg1)
///   let _ = builder.createRet!(quot)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fdiv_func(float %0, float %1) {
///     #|entry:
///     #|  %2 = fdiv float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Fast Math Flags
///
/// This function supports fast math flags, which can be used to
/// optimize floating-point operations.
///
/// ```moonbit
/// test "IRBuilder::createFDiv with fast math flags" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "fdiv_func_fast")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let fast_math_flags = Set::of([FastMathFlag::AllowReciprocal])
///   let quot = builder.createFDiv!(arg0, arg1, fast_math_flags~)
///   let _ = builder.createRet!(quot)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fdiv_func_fast(float %0, float %1) {
///     #|entry:
///     #|  %2 = fdiv arcp float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createFDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FDiv,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert!(inst)
  inst
}

///| Create FRem (floating-point remainder) Instruction.
///
/// ```moonbit
/// test "IRBuilder::createFRem" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "frem_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let rem = builder.createFRem!(arg0, arg1)
///   let _ = builder.createRet!(rem)
///
///   inspect(
///     fval,
///     content =
///     #|define float @frem_func(float %0, float %1) {
///     #|entry:
///     #|  %2 = frem float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Fast Math Flags
///
/// This function supports fast math flags, which can be used to
/// optimize floating-point operations.
///
/// ```moonbit
/// test "IRBuilder::createFRem with fast math flags" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
///   let fval = prog.addFunction!(fty, "frem_func_fast")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   let fast_math_flags = Set::of([FastMathFlag::AllowContract])
///   let rem = builder.createFRem!(arg0, arg1, fast_math_flags~)
///   let _ = builder.createRet!(rem)
///
///   inspect(
///     fval,
///     content =
///     #|define float @frem_func_fast(float %0, float %1) {
///     #|entry:
///     #|  %2 = frem contract float %0, %1
///     #|  ret float %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createFRem(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FRem,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert!(inst)
  inst
}

///| Create And Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the bitwise AND is
/// evaluated at compile time and the result is returned as a constant value.
///
/// ```moonbit
/// test "IRBuilder::createAnd" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "and_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular and with variables
///   let and_vars = builder.createAnd!(arg0, arg1)
///   
///   // Test constant folding with two constants
///   let const6 = ctx.getConstInt32(6) // 0b0110
///   let const3 = ctx.getConstInt32(3) // 0b0011
///   let and_consts = builder.createAnd!(const6, const3) // Should fold to 2 (0b0010)
///   
///   // Test mixed: one constant, one variable
///   let and_mixed = builder.createAnd!(and_vars , and_consts)
///   
///   let _ = builder.createRet!(and_mixed )
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @and_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = and i32 %0, %1
///     #|  %3 = and i32 %2, 2
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createAnd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.and!(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::And,
    lhs,
    rhs,
    parent,
    name,
    Set::new(),
  )
  self.insert!(inst)
  inst
}

///| Create Or Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the bitwise OR is
/// evaluated at compile time and the result is returned as a constant value.
///
/// ```moonbit
/// test "IRBuilder::createOr" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "or_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular or with variables
///   let or_vars = builder.createOr!(arg0, arg1)
///   
///   // Test constant folding with two constants
///   let const6 = ctx.getConstInt32(6) // 0b0110
///   let const3 = ctx.getConstInt32(3) // 0b0011
///   let or_consts = builder.createOr!(const6, const3) // Should fold to 7 (0b0111)
///   
///   // Test mixed: one constant, one variable
///   let or_mixed = builder.createOr!(or_vars, or_consts)
///   
///   let _ = builder.createRet!(or_mixed)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @or_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = or i32 %0, %1
///     #|  %3 = or i32 %2, 7
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createOr(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.or!(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Or,
    lhs,
    rhs,
    parent,
    name,
    Set::new(),
  )
  self.insert!(inst)
  inst
}

///| Create Xor Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the bitwise XOR is
/// evaluated at compile time and the result is returned as a constant value.
///
/// ```moonbit
/// test "IRBuilder::createXor" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "xor_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test regular xor with variables
///   let xor_vars = builder.createXor!(arg0, arg1)
///   
///   // Test constant folding with two constants
///   let const6 = ctx.getConstInt32(6) // 0b0110
///   let const3 = ctx.getConstInt32(3) // 0b0011
///   let xor_consts = builder.createXor!(const6, const3) // Should fold to 5 (0b0101)
///   
///   // Test mixed: one constant, one variable
///   let xor_mixed = builder.createXor!(xor_vars, xor_consts)
///   
///   let _ = builder.createRet!(xor_mixed)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @xor_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = xor i32 %0, %1
///     #|  %3 = xor i32 %2, 5
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createXor(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.xor!(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Xor,
    lhs,
    rhs,
    parent,
    name,
    Set::new(),
  )
  self.insert!(inst)
  inst
}

///| Create Shl (Shift Left) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the bitwise SHL is
/// evaluated at compile time and the result is returned as a constant value.
/// - `nsw` stands for "no signed wrap". If an overflow occurs, the behavior is undefined.
/// - `nuw` stands for "no unsigned wrap". If an overflow occurs, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createShl" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "shl_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap() // Shift amount
///
///   // Test regular shl with variables
///   let shl_vars = builder.createShl!(arg0, arg1)
///   
///   // Test constant folding
///   let const_val = ctx.getConstInt32(1) // 0b0001
///   let const_shift = ctx.getConstInt32(1) // shift by 1
///   let shl_consts = builder.createShl!(const_val, const_shift) // Should fold to 2 (0b0010)
///   
///   // Test with flags
///   let shl_nsw = builder.createShl!(shl_vars, shl_consts , has_nsw=true)
///   let shl_nuw = builder.createShl!(shl_nsw , shl_consts , has_nuw=true)
///   
///   let _ = builder.createRet!(shl_nuw)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @shl_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = shl i32 %0, %1
///     #|  %3 = shl nsw i32 %2, 2
///     #|  %4 = shl nuw i32 %3, 2
///     #|  ret i32 %4
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createShl(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  has_nsw~ : Bool = false,
  has_nuw~ : Bool = false
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.shl!(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if has_nuw {
    flags.add(BinaryOpFlags::NoUnsignedWrap)
  }
  if has_nsw {
    flags.add(BinaryOpFlags::NoSignedWrap)
  }
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Shl,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create LShr (Logical Shift Right) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the logical shift right is
/// evaluated at compile time and the result is returned as a constant value.
/// - The `exact` keyword means that the operation is known to have no ones shifted out.
/// If any ones are shifted out, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createLShr" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "lshr_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap() // Shift amount
///
///   // Test regular lshr with variables
///   let lshr_vars = builder.createLShr!(arg0, arg1)
///   
///   // Test constant folding
///   let const_val = ctx.getConstInt32(20) // 0b10100
///   let const_shift = ctx.getConstInt32(2) // shift by 2
///   let lshr_consts = builder.createLShr!(const_val, const_shift) // Should fold to 5 (0b00101)
///   
///   // Test with exact flag
///   let lshr_exact = builder.createLShr!(lshr_vars, lshr_consts, is_exact=true)
///   
///   let _ = builder.createRet!(lshr_exact)
///
///   // Verify constant folding worked
///   inspect(lshr_consts, content = "i32 5")
///   
///   inspect(
///     fval,
///     content =
///     #|define i32 @lshr_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = lshr i32 %0, %1
///     #|  %3 = lshr exact i32 %2, 5
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createLShr(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  is_exact~ : Bool = false
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.lshr!(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if is_exact {
    flags.add(BinaryOpFlags::Exact)
  }
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::LShr,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create AShr (Arithmetic Shift Right) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers, the arithmetic shift right is
/// evaluated at compile time and the result is returned as a constant value.
/// - The `exact` keyword means that the operation is known to have no ones shifted out from a different sign bit.
/// If any ones are shifted out that differ from the original sign bit, the behavior is undefined.
///
/// ```moonbit
/// test "IRBuilder::createAShr" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "ashr_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap() // Shift amount
///
///   // Test regular ashr with variables
///   let ashr_vars = builder.createAShr!(arg0, arg1)
///   
///   // Test constant folding with negative number
///   let const_val_neg = ctx.getConstInt32(-20) // 0xFFFFFFEC (i32)
///   let const_shift = ctx.getConstInt32(2) // shift by 2
///   let ashr_consts = builder.createAShr!(const_val_neg, const_shift) // Should fold to -5
///   
///   // Test with exact flag
///   let ashr_exact = builder.createAShr!(ashr_vars, ashr_consts, is_exact=true)
///   
///   let _ = builder.createRet!(ashr_exact)
///
///   // Verify constant folding worked
///   inspect(ashr_consts, content = "i32 -5")
///   
///   inspect(
///     fval,
///     content =
///     #|define i32 @ashr_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = ashr i32 %0, %1
///     #|  %3 = ashr exact i32 %2, -5
///     #|  ret i32 %3
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createAShr(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  is_exact~ : Bool = false
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.ashr!(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if is_exact {
    flags.add(BinaryOpFlags::Exact)
  }
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::AShr,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert!(inst)
  inst
}

///| Create Comparison Instruction (ICmp or FCmp).
///
/// **Note:**
///
/// - (Constant folding) If both operands are constant integers or floating-point values, 
/// the comparison is evaluated at compile time and the result is returned as a constant i1 value.
///
/// - For integer comparisons, use ICMP_xxx predicates
///   (EQ, NE, SGT, SGE, SLT, SLE, UGT, UGE, ULT, ULE).
///
/// - For floating-point comparisons, use FCMP_xxx predicates
///   (OEQ, OGT, OGE, OLT, OLE, ONE, ORD, UNO, UEQ, UGT, UGE, ULT, ULE, UNE, TRUE, FALSE).
///
/// ```moonbit
/// test "IRBuilder::createCmp with integers" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let i1ty = ctx.getInt1Ty()
///   let fty = ctx.getFunctionType!(i1ty, [i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "cmp_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test signed greater than
///   let cmp_sgt = builder.createCmp!(ICMP_SGT, arg0, arg1)
///   let _ = builder.createRet!(cmp_sgt)
///
///   inspect(
///     fval,
///     content =
///     #|define i1 @cmp_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = icmp sgt i32 %0, %1
///     #|  ret i1 %2
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ```moonbit
/// test "IRBuilder::createCmp with floating-point" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let floatty = ctx.getFloatTy()
///   let i1ty = ctx.getInt1Ty()
///   let fty = ctx.getFunctionType!(i1ty, [floatty, floatty])
///   let fval = prog.addFunction!(fty, "fcmp_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let arg1 = fval.getArg(1).unwrap()
///
///   // Test ordered equal
///   let fcmp_oeq = builder.createCmp!(FCMP_OEQ, arg0, arg1)
///   let _ = builder.createRet!(fcmp_oeq)
///
///   inspect(
///     fval,
///     content =
///     #|define i1 @fcmp_func(float %0, float %1) {
///     #|entry:
///     #|  %2 = fcmp oeq float %0, %1
///     #|  ret i1 %2
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createCmp with constant folding - integers" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i1ty = ctx.getInt1Ty()
///   let fty = ctx.getFunctionType!(i1ty, [])
///
///   // Test integer constant comparison
///   let fval_int = prog.addFunction!(fty, "icmp_const_func")
///   let entryBB_int = fval_int.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB_int)
///   
///   let const_5 = ctx.getConstInt32(5)
///   let const_10 = ctx.getConstInt32(10)
///   
///   // 5 < 10 should be true
///   let cmp_result = builder.createCmp!(ICMP_SLT, const_5, const_10)
///   let _ = builder.createRet!(cmp_result)
///   
///   inspect(cmp_result, content="i1 true")
///   inspect(
///     fval_int,
///     content =
///     #|define i1 @icmp_const_func() {
///     #|entry:
///     #|  ret i1 true
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ```moonbit
/// test "IRBuilder::createCmp with constant folding - floating-point" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i1ty = ctx.getInt1Ty()
///   let fty = ctx.getFunctionType!(i1ty, [])
///
///   // Test floating-point constant comparison
///   let fval_fp = prog.addFunction!(fty, "fcmp_const_func")
///   let entryBB_fp = fval_fp.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB_fp)
///   
///   let const_1_5 = ctx.getConstFloat(1.5)
///   let const_2_5 = ctx.getConstFloat(2.5)
///   
///   // 1.5 < 2.5 should be true (ordered less than)
///   let fcmp_result = builder.createCmp!(FCMP_OLT, const_1_5, const_2_5)
///   let _ = builder.createRet!(fcmp_result)
///   
///   inspect(fcmp_result, content="i1 true")
///   inspect(
///     fval_fp,
///     content =
///     #|define i1 @fcmp_const_func() {
///     #|entry:
///     #|  ret i1 true
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createCmp(
  self : IRBuilder,
  pred : Predicate,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) =>
      return lhs.compare!(pred, rhs)
    (Some(ConstantFP(lhs)), Some(ConstantFP(rhs))) =>
      return lhs.compare!(pred, rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CmpInst::new!(pred, lhs, rhs, parent, name)
  self.insert!(inst)
  inst
}

///| Create Eq (Equality) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_EQ, ...)`.
pub fn IRBuilder::createICmpEQ(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_EQ, lhs, rhs, name~)
}

///| Create Ne (Not Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_NE, ...)`.
pub fn IRBuilder::createICmpNE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_NE, lhs, rhs, name~)
}

///| Create UGT (Unsigned Greater Than) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_UGT, ...)`.
pub fn IRBuilder::createICmpUGT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_UGT, lhs, rhs, name~)
}

///| Create UGE (Unsigned Greater Than or Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_UGE, ...)`.
pub fn IRBuilder::createICmpUGE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_UGE, lhs, rhs, name~)
}

///| Create ULT (Unsigned Less Than) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_ULT, ...)`.
pub fn IRBuilder::createICmpULT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_ULT, lhs, rhs, name~)
}

///| Create ULE (Unsigned Less Than or Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_ULE, ...)`.
pub fn IRBuilder::createICmpULE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_ULE, lhs, rhs, name~)
}

///| Create SGT (Signed Greater Than) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_SGT, ...)`.
pub fn IRBuilder::createICmpSGT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_SGT, lhs, rhs, name~)
}

///| Create SGE (Signed Greater Than or Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_SGE, ...)`.
pub fn IRBuilder::createICmpSGE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_SGE, lhs, rhs, name~)
}

///| Create SLT (Signed Less Than) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_SLT, ...)`.
pub fn IRBuilder::createICmpSLT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_SLT, lhs, rhs, name~)
}

///| Create SLE (Signed Less Than or Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createCmp(ICMP_SLE, ...)`.
pub fn IRBuilder::createICmpSLE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(ICMP_SLE, lhs, rhs, name~)
}

///| Create OEQ (Ordered Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_OEQ, ...)`.
pub fn IRBuilder::createFCmpOEQ(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_OEQ, lhs, rhs, name~)
}

///| Create OGT (Ordered Greater Than) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_OGT, ...)`.
pub fn IRBuilder::createFCmpOGT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_OGT, lhs, rhs, name~)
}

///| Create OGE (Ordered Greater Than or Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_OGE, ...)`.
pub fn IRBuilder::createFCmpOGE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_OGE, lhs, rhs, name~)
}

///| Create OLT (Ordered Less Than) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_OLT, ...)`.
pub fn IRBuilder::createFCmpOLT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_OLT, lhs, rhs, name~)
}

///| Create OLE (Ordered Less Than or Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_OLE, ...)`.
pub fn IRBuilder::createFCmpOLE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_OLE, lhs, rhs, name~)
}

///| Create ONE (Ordered Not Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_ONE, ...)`.
pub fn IRBuilder::createFCmpONE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_ONE, lhs, rhs, name~)
}

///| Create ORD (Ordered) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_ORD, ...)`.
pub fn IRBuilder::createFCmpORD(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_ORD, lhs, rhs, name~)
}

///| Create UNO (Unordered) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_UNO, ...)`.
pub fn IRBuilder::createFCmpUNO(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_UNO, lhs, rhs, name~)
}

///| Create UEQ (Unordered Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_UEQ, ...)`.
pub fn IRBuilder::createFCmpUEQ(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_UEQ, lhs, rhs, name~)
}

///| Create UGT (Unordered Greater Than) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_UGT, ...)`.
pub fn IRBuilder::createFCmpUGT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_UGT, lhs, rhs, name~)
}

///| Create UGE (Unordered Greater Than or Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_UGE, ...)`.
pub fn IRBuilder::createFCmpUGE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_UGE, lhs, rhs, name~)
}

///| Create ULT (Unordered Less Than) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_ULT, ...)`.
pub fn IRBuilder::createFCmpULT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_ULT, lhs, rhs, name~)
}

///| Create ULE (Unordered Less Than or Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_ULE, ...)`.
pub fn IRBuilder::createFCmpULE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_ULE, lhs, rhs, name~)
}

///| Create UNE (Unordered Not Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_UNE, ...)`.
pub fn IRBuilder::createFCmpUNE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value!Error {
  self.createCmp!(FCMP_UNE, lhs, rhs, name~)
}

///| Create Trunc (truncate) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant integer, the truncation is
/// evaluated at compile time and the result is returned as a constant value.
/// - Truncates an integer value to a smaller integer type.
/// - The source type bit width must be greater than the destination type bit width.
///
/// ```moonbit
/// test "IRBuilder::createTrunc" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let i16ty = ctx.getInt16Ty()
///   let fty = ctx.getFunctionType!(i16ty, [i32ty])
///   let fval = prog.addFunction!(fty, "trunc_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   
///   // Test regular trunc with variable
///   let trunc_var = builder.createTrunc!(arg0, i16ty)
///   
///   // Test constant folding
///   let const_val = ctx.getConstInt32(0x12345) // 74565
///   let trunc_const = builder.createTrunc!(const_val, i16ty) // Should fold to 0x2345 = 9029
///   
///   let _ = builder.createRet!(trunc_var)
///
///   // Verify constant folding worked
///   inspect(trunc_const, content="i16 9029")
///   
///   inspect(
///     fval,
///     content =
///     #|define i16 @trunc_func(i32 %0) {
///     #|entry:
///     #|  %1 = trunc i32 %0
///     #|  ret i16 %1
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createTrunc(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.trunc!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newTrunc!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create ZExt (zero extend) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant integer, the zero extension is
/// evaluated at compile time and the result is returned as a constant value.
/// - Zero extends an integer value to a larger integer type by filling with zeros.
/// - The source type bit width must be less than the destination type bit width.
///
/// ```moonbit
/// test "IRBuilder::createZExt" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i16ty = ctx.getInt16Ty()
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i16ty])
///   let fval = prog.addFunction!(fty, "zext_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   
///   // Test regular zext with variable
///   let zext_var = builder.createZExt!(arg0, i32ty)
///   
///   // Test constant folding
///   let const_val = ctx.getConstInt16(-1) // 0xFFFF as i16
///   let zext_const = builder.createZExt!(const_val, i32ty) // Should fold to 0x0000FFFF = 65535
///   
///   let _ = builder.createRet!(zext_var)
///
///   // Verify constant folding worked
///   inspect(zext_const, content="i32 65535")
///   
///   inspect(
///     fval,
///     content =
///     #|define i32 @zext_func(i16 %0) {
///     #|entry:
///     #|  %1 = zext i16 %0
///     #|  ret i32 %1
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createZExt(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.zext!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newZExt!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create SExt (sign extend) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant integer, the sign extension is
/// evaluated at compile time and the result is returned as a constant value.
/// - Sign extends an integer value to a larger integer type by filling with the sign bit.
/// - The source type bit width must be less than the destination type bit width.
///
/// ```moonbit
/// test "IRBuilder::createSExt" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i16ty = ctx.getInt16Ty()
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i16ty])
///   let fval = prog.addFunction!(fty, "sext_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   
///   // Test regular sext with variable
///   let sext_var = builder.createSExt!(arg0, i32ty)
///   
///   // Test constant folding
///   let const_val = ctx.getConstInt16(-1) // 0xFFFF as i16
///   let sext_const = builder.createSExt!(const_val, i32ty) // Should fold to 0xFFFFFFFF = -1
///   
///   let _ = builder.createRet!(sext_var)
///
///   // Verify constant folding worked
///   inspect(sext_const, content="i32 -1")
///   
///   inspect(
///     fval,
///     content =
///     #|define i32 @sext_func(i16 %0) {
///     #|entry:
///     #|  %1 = sext i16 %0
///     #|  ret i32 %1
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createSExt(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.sext!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newSExt!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create FPTrunc (floating-point truncate) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant floating-point value, the truncation is
/// evaluated at compile time and the result is returned as a constant value.
/// - Truncates a floating-point value to a smaller floating-point type.
/// - The source type bit width must be greater than the destination type bit width.
///
/// ```moonbit
/// test "IRBuilder::createFPTrunc" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f64ty = ctx.getDoubleTy()
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [f64ty])
///   let fval = prog.addFunction!(fty, "fptrunc_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let fptrunc_val = builder.createFPTrunc!(arg0, f32ty)
///   let _ = builder.createRet!(fptrunc_val)
///
///   inspect(
///     fval,
///     content =
///     #|define float @fptrunc_func(double %0) {
///     #|entry:
///     #|  %1 = fptrunc double %0
///     #|  ret float %1
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createFPTrunc with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [])
///   let fval = prog.addFunction!(fty, "fptrunc_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstDouble(3.14159)
///   let fptrunc_result = builder.createFPTrunc!(const_val, f32ty)
///   let _ = builder.createRet!(fptrunc_result)
///
///   // Test that constant folding worked - result should be a constant
///   assert_true!(fptrunc_result.tryAsConstant() is Some(_))
/// }
/// ```
pub fn IRBuilder::createFPTrunc(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &FPType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantFP(cf)) => return cf.fptrunc!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newFPTrunc!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create FPExt (floating-point extend) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant floating-point value, the extension is
/// evaluated at compile time and the result is returned as a constant value.
/// - Extends a floating-point value to a larger floating-point type.
/// - The source type bit width must be less than the destination type bit width.
///
/// ```moonbit
/// test "IRBuilder::createFPExt" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let f64ty = ctx.getDoubleTy()
///   let fty = ctx.getFunctionType!(f64ty, [f32ty])
///   let fval = prog.addFunction!(fty, "fpext_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let fpext_val = builder.createFPExt!(arg0, f64ty)
///   let _ = builder.createRet!(fpext_val)
///
///   inspect(
///     fval,
///     content =
///     #|define double @fpext_func(float %0) {
///     #|entry:
///     #|  %1 = fpext float %0
///     #|  ret double %1
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createFPExt with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f64ty = ctx.getDoubleTy()
///   let fty = ctx.getFunctionType!(f64ty, [])
///   let fval = prog.addFunction!(fty, "fpext_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstFloat(3.14159)
///   let fpext_result = builder.createFPExt!(const_val, f64ty)
///   let _ = builder.createRet!(fpext_result)
///
///   // Test that constant folding worked - result should be a constant
///   assert_true!(fpext_result.tryAsConstant() is Some(_))
/// }
/// ```
pub fn IRBuilder::createFPExt(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &FPType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantFP(cf)) => return cf.fpext!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newFPExt!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create UIToFP (unsigned integer to floating-point) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant integer, the conversion is
/// evaluated at compile time and the result is returned as a constant value.
/// - Converts an unsigned integer value to a floating-point type.
/// - The integer value is interpreted as unsigned regardless of its sign bit.
///
/// ```moonbit
/// test "IRBuilder::createUIToFP" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [i32ty])
///   let fval = prog.addFunction!(fty, "uitofp_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let uitofp_val = builder.createUIToFP!(arg0, f32ty)
///   let _ = builder.createRet!(uitofp_val)
///
///   inspect(
///     fval,
///     content =
///     #|define float @uitofp_func(i32 %0) {
///     #|entry:
///     #|  %1 = uitofp i32 %0
///     #|  ret float %1
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createUIToFP with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [])
///   let fval = prog.addFunction!(fty, "uitofp_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstInt32(42)
///   let uitofp_result = builder.createUIToFP!(const_val, f32ty)
///   let _ = builder.createRet!(uitofp_result)
///
///   // Test that constant folding worked - result should be a constant
///   assert_true!(uitofp_result.tryAsConstant() is Some(_))
/// }
/// ```
pub fn IRBuilder::createUIToFP(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &FPType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.uitofp!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newUIToFP!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create FPToUI (floating-point to unsigned integer) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant floating-point value, the conversion is
/// evaluated at compile time and the result is returned as a constant value.
/// - Converts a floating-point value to an unsigned integer type.
/// - The floating-point value is truncated towards zero and interpreted as unsigned.
///
/// ```moonbit
/// test "IRBuilder::createFPToUI" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [f32ty])
///   let fval = prog.addFunction!(fty, "fptoui_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let fptoui_val = builder.createFPToUI!(arg0, i32ty)
///   let _ = builder.createRet!(fptoui_val)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @fptoui_func(float %0) {
///     #|entry:
///     #|  %1 = fptoui float %0
///     #|  ret i32 %1
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createFPToUI with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "fptoui_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstFloat(42.7)
///   let fptoui_result = builder.createFPToUI!(const_val, i32ty)
///   let _ = builder.createRet!(fptoui_result)
///
///   inspect(fptoui_result, content="i32 42")
///   inspect(
///     fval,
///     content =
///     #|define i32 @fptoui_const_func() {
///     #|entry:
///     #|  ret i32 42
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createFPToUI(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantFP(cf)) => return cf.fptoui!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newFPToUI!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create SIToFP (signed integer to floating-point) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant integer, the conversion is
/// evaluated at compile time and the result is returned as a constant value.
/// - Converts a signed integer value to a floating-point type.
/// - The integer value is interpreted as signed.
///
/// ```moonbit
/// test "IRBuilder::createSIToFP" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [i32ty])
///   let fval = prog.addFunction!(fty, "sitofp_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let sitofp_val = builder.createSIToFP!(arg0, f32ty)
///   let _ = builder.createRet!(sitofp_val)
///
///   inspect(
///     fval,
///     content =
///     #|define float @sitofp_func(i32 %0) {
///     #|entry:
///     #|  %1 = sitofp i32 %0
///     #|  ret float %1
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createSIToFP with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [])
///   let fval = prog.addFunction!(fty, "sitofp_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstInt32(-42)
///   let sitofp_result = builder.createSIToFP!(const_val, f32ty)
///   let _ = builder.createRet!(sitofp_result)
///
///   // Test that constant folding worked - result should be a constant
///   assert_true!(sitofp_result.tryAsConstant() is Some(_))
/// }
/// ```
pub fn IRBuilder::createSIToFP(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &FPType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.sitofp!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newSIToFP!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create FPToSI (floating-point to signed integer) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant floating-point value, the conversion is
/// evaluated at compile time and the result is returned as a constant value.
/// - Converts a floating-point value to a signed integer type.
/// - The floating-point value is truncated towards zero and interpreted as signed.
///
/// ```moonbit
/// test "IRBuilder::createFPToSI" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [f32ty])
///   let fval = prog.addFunction!(fty, "fptosi_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let fptosi_val = builder.createFPToSI!(arg0, i32ty)
///   let _ = builder.createRet!(fptosi_val)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @fptosi_func(float %0) {
///     #|entry:
///     #|  %1 = fptosi float %0
///     #|  ret i32 %1
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createFPToSI with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "fptosi_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstFloat(-42.7)
///   let fptosi_result = builder.createFPToSI!(const_val, i32ty)
///   let _ = builder.createRet!(fptosi_result)
///
///   inspect(fptosi_result, content="i32 -42")
///   inspect(
///     fval,
///     content =
///     #|define i32 @fptosi_const_func() {
///     #|entry:
///     #|  ret i32 -42
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createFPToSI(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantFP(cf)) => return cf.fptosi!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newFPToSI!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create IntToPtr (integer to pointer) Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant integer, the conversion is
/// evaluated at compile time and the result is returned as a constant null pointer.
/// - Converts an integer value to a pointer type.
/// - For constant folding, this always returns a null pointer since we cannot create
///   meaningful pointer constants from integer values at compile time.
///
/// ```moonbit
/// test "IRBuilder::createIntToPtr" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i64ty = ctx.getInt64Ty()
///   let ptrty = ctx.getPtrTy()
///   let fty = ctx.getFunctionType!(ptrty, [i64ty])
///   let fval = prog.addFunction!(fty, "inttoptr_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let inttoptr_val = builder.createIntToPtr!(arg0)
///   let _ = builder.createRet!(inttoptr_val)
///
///   inspect(
///     fval,
///     content =
///     #|define ptr @inttoptr_func(i64 %0) {
///     #|entry:
///     #|  %1 = inttoptr i64 %0
///     #|  ret ptr %1
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createIntToPtr with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let ptrty = ctx.getPtrTy()
///   let fty = ctx.getFunctionType!(ptrty, [])
///   let fval = prog.addFunction!(fty, "inttoptr_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstInt64(0x12345678)
///   let inttoptr_result = builder.createIntToPtr!(const_val)
///   let _ = builder.createRet!(inttoptr_result)
///
///   inspect(inttoptr_result, content="ptr null")
///   inspect(
///     fval,
///     content =
///     #|define ptr @inttoptr_const_func() {
///     #|entry:
///     #|  ret ptr null
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createIntToPtr(
  self : IRBuilder,
  src_val : &Value,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.inttoptr!()
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newIntToPtr!(src_val, parent, name)
  self.insert!(inst)
  inst
}

///| Create PtrToInt (pointer to integer) Instruction.
///
/// **Note:**
///
/// - Converts a pointer value to an integer type.
/// - The source must be a pointer type.
/// - No constant folding is performed for this instruction.
///
/// ```moonbit
/// test "IRBuilder::createPtrToInt" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let ptrty = ctx.getPtrTy()
///   let i64ty = ctx.getInt64Ty()
///   let fty = ctx.getFunctionType!(i64ty, [ptrty])
///   let fval = prog.addFunction!(fty, "ptrtoint_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let ptrtoint_val = builder.createPtrToInt!(arg0, i64ty)
///   let _ = builder.createRet!(ptrtoint_val)
///
///   inspect(
///     fval,
///     content =
///     #|define i64 @ptrtoint_func(ptr %0) {
///     #|entry:
///     #|  %1 = ptrtoint ptr %0
///     #|  ret i64 %1
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createPtrToInt(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value!Error {
  // No constant folding for PtrToInt as pointer constants are complex
  let parent = self.getInsertFunction()
  let inst = CastInst::newPtrToInt!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create BitCast Instruction.
///
/// **Note:**
///
/// - (Constant folding) If the operand is a constant value, the bitcast is
/// evaluated at compile time and the result is returned as a constant value.
/// - Reinterprets the bit pattern of a value as a different type.
/// - The source and destination types must have the same bit width.
/// - Currently only supports primitive types.
///
/// ```moonbit
/// test "IRBuilder::createBitCast" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [i32ty])
///   let fval = prog.addFunction!(fty, "bitcast_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap()
///   let bitcast_val = builder.createBitCast!(arg0, f32ty)
///   let _ = builder.createRet!(bitcast_val)
///
///   inspect(
///     fval,
///     content =
///     #|define float @bitcast_func(i32 %0) {
///     #|entry:
///     #|  %1 = bitcast i32 %0
///     #|  ret float %1
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createBitCast with constant folding - int to float" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let f32ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType!(f32ty, [])
///   let fval = prog.addFunction!(fty, "bitcast_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstInt32(0x40000000) // 2.0f bit pattern
///   let bitcast_result = builder.createBitCast!(const_val, f32ty)
///   let _ = builder.createRet!(bitcast_result)
///
///   // Test that constant folding worked - result should be a constant
///   assert_true!(bitcast_result.tryAsConstant() is Some(_))
/// }
/// ```
///
/// ```moonbit
/// test "IRBuilder::createBitCast with constant folding - float to int" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "bitcast_fp_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const_val = ctx.getConstFloat(2.0)
///   let bitcast_result = builder.createBitCast!(const_val, i32ty)
///   let _ = builder.createRet!(bitcast_result)
///
///   // Test that constant folding worked - result should be a constant
///   assert_true!(bitcast_result.tryAsConstant() is Some(_))
/// }
/// ```
pub fn IRBuilder::createBitCast(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &PrimitiveType,
  name~ : String = ""
) -> &Value!Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.bitcast!(dst_ty)
    Some(ConstantFP(cf)) => return cf.bitcast!(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newBitCast!(src_val, dst_ty, parent, name)
  self.insert!(inst)
  inst
}

///| Create GetElementPtr Instruction.
///
/// **Note:**
///
/// - Creates a getelementptr instruction for pointer arithmetic
/// - The `ptr` operand must be a pointer type
/// - The `pointeeType` specifies the type being pointed to
/// - `indices` is an array of integer values for indexing
/// - `inbounds` flag indicates that all computed addresses are within bounds
/// - No constant folding is performed for this instruction
///
/// ```moonbit
/// test "IRBuilder::createGEP" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let ptrty = ctx.getPtrTy()
///   let fty = ctx.getFunctionType!(ptrty, [ptrty, i32ty, i32ty])
///   let fval = prog.addFunction!(fty, "gep_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let arg0 = fval.getArg(0).unwrap() // ptr
///   let arg1 = fval.getArg(1).unwrap() // index1
///   let arg2 = fval.getArg(2).unwrap() // index2
///   let const0 = ctx.getConstInt32(0)
///   let const5 = ctx.getConstInt32(5)
///
///   // Basic GEP with single index
///   let gep1 = builder.createGEP!(arg0, i32ty, [arg1])
///   // GEP with inbounds flag and multiple indices
///   let gep2 = builder.createGEP!(gep1, i32ty, [arg1, arg2], inbounds=true)
///   // GEP with constant indices
///   let gep3 = builder.createGEP!(gep2, i32ty, [const0, const5])
///   let _ = builder.createRet!(gep3)
///
///   inspect(
///     fval,
///     content =
///     #|define ptr @gep_func(ptr %0, i32 %1, i32 %2) {
///     #|entry:
///     #|  %3 = getelementptr i32, ptr %0, i32 %1
///     #|  %4 = getelementptr inbounds i32, ptr %3, i32 %1, i32 %2
///     #|  %5 = getelementptr i32, ptr %4, i32 0, i32 5
///     #|  ret ptr %5
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createGEP(
  self : IRBuilder,
  ptr : &Value,
  pointeeType : &Type,
  indices : Array[&Value],
  name~ : String = "",
  inbounds~ : Bool = false
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = GetElementPtrInst::new!(
    ptr, pointeeType, indices, inbounds, parent, name,
  )
  self.insert!(inst)
  inst
}

///| Create Load Instruction.
///
/// Loads a value from memory at the specified pointer address.
///
/// **Note:**
///
/// - `isVolatile` indicates that the load may have side effects and should
///   not be optimized away.
///
/// - `atomicOrdering` specifies the memory ordering constraints for atomic
///   loads (None for non-atomic).
///
/// - `isVolatile` and `atomicOrdering` are mutually exclusive; you cannot
///   have both volatile and atomic on the same load.
///
/// ```moonbit
/// test "IRBuilder::createLoad" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let ptrty = ctx.getPtrTy()
///   let fty = ctx.getFunctionType!(i32ty, [ptrty])
///   let fval = prog.addFunction!(fty, "load_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let ptr_arg = fval.getArg(0).unwrap()
///   
///   // Test regular load
///   let loaded_val = builder.createLoad!(i32ty, ptr_arg)
///   
///   // Test volatile load  
///   let volatile_load = builder.createLoad!(i32ty, ptr_arg, isVolatile=true)
///   
///   // Test atomic load with name
///   let atomic_load = builder.createLoad!(i32ty, ptr_arg, atomicOrdering=Acquire)
///   
///   let add1 = builder.createAdd!(loaded_val, volatile_load)
///   let add2 = builder.createAdd!(add1, atomic_load)
///   let _ = builder.createRet!(add2)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @load_func(ptr %0) {
///     #|entry:
///     #|  %1 = load i32, ptr %0, align 4
///     #|  %2 = load volatile i32, ptr %0, align 4
///     #|  %3 = load atomic i32, ptr %0 acquire, align 4
///     #|  %4 = add i32 %1, %2
///     #|  %5 = add i32 %4, %3
///     #|  ret i32 %5
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createLoad(
  self : IRBuilder,
  load_ty : &Type,
  ptr : &Value,
  isVolatile~ : Bool = false,
  atomicOrdering~ : AtomicOrdering = NotAtomic,
  name~ : String = ""
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = LoadInst::new!(
    load_ty, ptr, isVolatile, atomicOrdering, parent, name,
  )
  self.insert!(inst)
  inst
}

///| Create Store Instruction.
///
/// Stores a value to memory at the specified pointer address.
///
/// **Note:**
///
/// - `isVolatile` indicates that the store may have side effects and should
///   not be optimized away.
///
/// - `atomicOrdering` specifies the memory ordering constraints for atomic
///   stores (NotAtomic for non-atomic).
///
/// - `isVolatile` and `atomicOrdering` are mutually exclusive; you cannot
///   have both volatile and atomic on the same store.
///
/// ```moonbit
/// test "IRBuilder::createStore" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let voidty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType!(voidty, [i32ty])
///   let fval = prog.addFunction!(fty, "store_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let val_arg = fval.getArg(0).unwrap()
///   
///   // Create multiple allocations
///   let ptr1 = builder.createAlloca!(i32ty, name="ptr1")
///   let ptr2 = builder.createAlloca!(i32ty, name="ptr2") 
///   let ptr3 = builder.createAlloca!(i32ty, name="ptr3")
///   
///   // Test regular store
///   let _ = builder.createStore!(val_arg, ptr1)
///   
///   // Test volatile store
///   let _ = builder.createStore!(val_arg, ptr2, isVolatile=true)
///   
///   // Test atomic store
///   let _ = builder.createStore!(val_arg, ptr3, atomicOrdering=Release)
///   
///   let _ = builder.createRetVoid!()
///
///   inspect(
///     fval,
///     content = 
///     #|define void @store_func(i32 %0) {
///     #|entry:
///     #|  %ptr1 = alloca i32, align 4
///     #|  %ptr2 = alloca i32, align 4
///     #|  %ptr3 = alloca i32, align 4
///     #|  store i32 %0, ptr %ptr1, align 4
///     #|  store volatile i32 %0, ptr %ptr2, align 4
///     #|  store atomic i32 %0, ptr %ptr3 release, align 4
///     #|  ret void
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createStore(
  self : IRBuilder,
  value : &Value,
  ptr : &Value,
  isVolatile~ : Bool = false,
  atomicOrdering~ : AtomicOrdering = NotAtomic
) -> &Instruction!Error {
  let parent = self.getInsertFunction()
  let inst = StoreInst::new!(value, ptr, isVolatile, atomicOrdering, parent)
  self.insert!(inst)
  inst
}

///| Create unconditional branch Instruction.
///
/// Creates an unconditional branch that jumps to the specified destination basic block.
///
/// **Note:**
///
/// - The branch instruction does not return a value (void type)
/// - This terminates the current basic block
/// - Control flow will continue at the destination basic block
///
/// ```moonbit
/// test "IRBuilder::createBr" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "br_test")
///   
///   let entryBB = fval.addBasicBlock(name="entry")
///   let targetBB = fval.addBasicBlock(name="target")
///   
///   // Setup entry block
///   builder.setInsertPoint(entryBB)
///   let _ = builder.createBr!(targetBB)
///   
///   // Setup target block
///   builder.setInsertPoint(targetBB)
///   let const_val = ctx.getConstInt32(42)
///   let _ = builder.createRet!(const_val)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @br_test() {
///     #|entry:
///     #|  br label %target
///     #|
///     #|target:
///     #|  ret i32 42
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createBr(self : Self, dst : BasicBlock) -> &Instruction!Error {
  let parent = self.getInsertFunction()
  let inst = BranchInst::newUnconditional(dst, parent)
  self.insert(inst)
  inst
}

///| Create conditional branch Instruction.
///
/// Creates a conditional branch that jumps to one of two destination basic blocks
/// based on the condition value.
///
/// **Note:**
///
/// - The condition must be of i1 type (boolean)
///
/// ```moonbit
/// test "IRBuilder::createCondBr" {
///  let ctx = @IR.LLVMContext::new()
///  let prog = ctx.addProgram("demo")
///  let builder = @IR.IRBuilder::new()
///
///  let i32ty = ctx.getInt32Ty()
///  let forty_two = ctx.getConstInt32(42)
///  let thirty_three = ctx.getConstInt32(33)
///
///  let fty = ctx.getFunctionType!(i32ty, [i32ty])
///  let fval = prog.addFunction!(fty, "foo")
///
///  let entryBB = fval.addBasicBlock(name="entry")
///  builder.setInsertPoint(entryBB)
///  let alloc = builder.createAlloca!(i32ty)
///
///  let arg0 = fval.getArg(0).unwrap()
///  let cond = builder.createCmp!(ICMP_SGT, arg0, ctx.getConstInt32(0))
///  let thenBB = fval.addBasicBlock()
///  let elseBB = fval.addBasicBlock()
///  let mergeBB = fval.addBasicBlock()
///
///  let _ = builder.createCondBr!(cond, thenBB, elseBB)
///  builder.setInsertPoint(thenBB)
///  let _ = builder.createStore!(thirty_three, alloc)
///  let _ = builder.createBr!(mergeBB)
///
///  builder.setInsertPoint(elseBB)
///  let _ = builder.createStore!(forty_two, alloc)
///  let _ = builder.createBr!(mergeBB)
///
///  builder.setInsertPoint(mergeBB)
///  let loaded = builder.createLoad!(i32ty, alloc)
///  let _ = builder.createRet!(loaded)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @foo(i32 %0) {
///     #|entry:
///     #|  %1 = alloca i32, align 4
///     #|  %2 = icmp sgt i32 %0, 0
///     #|  br i1 %2, label %3, label %4
///     #|
///     #|3:
///     #|  store i32 33, ptr %1, align 4
///     #|  br label %5
///     #|
///     #|4:
///     #|  store i32 42, ptr %1, align 4
///     #|  br label %5
///     #|
///     #|5:
///     #|  %6 = load i32, ptr %1, align 4
///     #|  ret i32 %6
//      #|}
///|     ,
///   )
/// }
/// ```
pub fn IRBuilder::createCondBr(
  self : Self,
  cond : &Value,
  true_dst : BasicBlock,
  false_dst : BasicBlock
) -> &Instruction!Error {
  let parent = self.getInsertFunction()
  let inst = BranchInst::newConditional(cond, true_dst, false_dst, parent)
  self.insert(inst)
  inst
}

///| Create Select Instruction.
///
/// Creates a select instruction that chooses between two values based on a condition.
/// The select instruction is similar to the ternary operator in many programming languages.
///
/// **Note:**
///
/// - The condition must be of i1 type (boolean)
///
/// - The true and false values must have the same type
///
/// - The result type is the same as the operand types
///
/// - (Constant folding) If the condition is a constant, the appropriate operand is returned directly
///
/// ```moonbit
/// test "IRBuilder::createSelect" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i1ty = ctx.getInt1Ty()
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i1ty, i32ty])
///   let fval = prog.addFunction!(fty, "select_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let cond = fval.getArg(0).unwrap()
///   let true_val = fval.getArg(1).unwrap()
///   
///   let forty_two = ctx.getConstInt32(42)
///   let thirty_three = ctx.getConstInt32(33)
///   let always_true = ctx.getConstTrue()
///   let false_val = builder.createSelect!(always_true, forty_two, thirty_three)
///
///   let select_result = builder.createSelect!(cond, true_val, false_val)
///   let _ = builder.createRet!(select_result)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @select_func(i1 %0, i32 %1) {
///     #|entry:
///     #|  %2 = select i1 %0, i32 %1, i32 42
///     #|  ret i32 %2
///     #|}
///     ,
///   )
/// }
/// ```
pub fn IRBuilder::createSelect(
  self : IRBuilder,
  condition : &Value,
  trueValue : &Value,
  falseValue : &Value,
  name~ : String = ""
) -> &Value!Error {
  match condition.tryAsConstantEnum() {
    Some(ConstantInt(ci)) =>
      if ci.getValue() != 0L {
        return trueValue
      } else {
        return falseValue
      }
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = SelectInst::new!(condition, trueValue, falseValue, parent, name)
  self.insert!(inst)
  inst
}
