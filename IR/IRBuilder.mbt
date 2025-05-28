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
///   let nsw_add = builder.createAdd!(arg0, arg1, has_nsw=true)
///   let nuw_add = builder.createAdd!(arg0, arg1, has_nuw=true)
///   let nsw_nuw_add = builder.createAdd!(
///     nsw_add, nuw_add, has_nsw=true, has_nuw=true
///   )
///   let _ = builder.createRet!(nsw_nuw_add)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = add nsw i32 %0, %1
///     #|  %3 = add nuw i32 %0, %1
///     #|  %4 = add nuw nsw i32 %2, %3
///     #|  ret i32 %4
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createAdd with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "add")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let forty_two = ctx.getConstInt32(42)
///   let thirty_three = ctx.getConstInt32(33)
///
///   let sum = builder.createAdd!(forty_two, thirty_three)
///   let _ = builder.createRet!(sum)
///
///   inspect(sum, content = "i32 75")
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add() {
///     #|entry:
///     #|  ret i32 75
///     #|}
///     ,
///   )
/// }
///
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
///   let sum = builder.createNSWAdd!(arg0, arg1)
///   let _ = builder.createRet!(sum)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = add nsw i32 %0, %1
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
/// test "IRBuilder::createNSWAdd with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "add")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let forty_two = ctx.getConstInt32(42)
///   let thirty_three = ctx.getConstInt32(33)
///
///   let sum = builder.createNSWAdd!(forty_two, thirty_three)
///   let _ = builder.createRet!(sum)
///
///   inspect(sum, content = "i32 75")
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add() {
///     #|entry:
///     #|  ret i32 75
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
///   let sum = builder.createNUWAdd!(arg0, arg1)
///   let _ = builder.createRet!(sum)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = add nuw i32 %0, %1
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
/// test "IRBuilder::createNUWAdd with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "add")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let forty_two = ctx.getConstInt32(42)
///   let thirty_three = ctx.getConstInt32(33)
///
///   let sum = builder.createNUWAdd!(forty_two, thirty_three)
///   let _ = builder.createRet!(sum)
///
///   inspect(sum, content = "i32 75")
///   inspect(
///     fval,
///     content = 
///     #|define i32 @add() {
///     #|entry:
///     #|  ret i32 75
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
///   let nsw_sub = builder.createSub!(arg0, arg1, has_nsw=true)
///   let nuw_sub = builder.createSub!(arg0, arg1, has_nuw=true)
///   let nsw_nuw_sub = builder.createSub!(
///     nsw_sub, nuw_sub, has_nsw=true, has_nuw=true
///   )
///   let _ = builder.createRet!(nsw_nuw_sub)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @sub(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = sub nsw i32 %0, %1
///     #|  %3 = sub nuw i32 %0, %1
///     #|  %4 = sub nuw nsw i32 %2, %3
///     #|  ret i32 %4
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createSub with constant folding" {
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
///   let diff = builder.createSub!(forty_two, thirty_three)
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
///   let diff = builder.createNSWSub!(arg0, arg1)
///   let _ = builder.createRet!(diff)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @sub(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = sub nsw i32 %0, %1
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
///   let nsw_mul = builder.createMul!(arg0, arg1, has_nsw=true)
///   let nuw_mul = builder.createMul!(arg0, arg1, has_nuw=true)
///   let nsw_nuw_mul = builder.createMul!(
///     nsw_mul, nuw_mul, has_nsw=true, has_nuw=true
///   )
///   let _ = builder.createRet!(nsw_nuw_mul)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = mul nsw i32 %0, %1
///     #|  %3 = mul nuw i32 %0, %1
///     #|  %4 = mul nuw nsw i32 %2, %3
///     #|  ret i32 %4
///     #|}
///     ,
///   )
/// }
/// ```
///
/// ## Constant Folding
///
/// ```moonbit
/// test "IRBuilder::createMul with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "mul")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let forty_two = ctx.getConstInt32(42)
///   let thirty_three = ctx.getConstInt32(33)
///
///   let prod = builder.createMul!(forty_two, thirty_three)
///   let _ = builder.createRet!(prod)
///
///   inspect(prod, content = "i32 1386")
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul() {
///     #|entry:
///     #|  ret i32 1386
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
///   let prod = builder.createNSWMul!(arg0, arg1)
///   let _ = builder.createRet!(prod)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = mul nsw i32 %0, %1
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
/// test "IRBuilder::createNSWMul with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "mul")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let forty_two = ctx.getConstInt32(42)
///   let thirty_three = ctx.getConstInt32(33)
///
///   let prod = builder.createNSWMul!(forty_two, thirty_three)
///   let _ = builder.createRet!(prod)
///
///   inspect(prod, content = "i32 1386")
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul() {
///     #|entry:
///     #|  ret i32 1386
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
///   let prod = builder.createNUWMul!(arg0, arg1)
///   let _ = builder.createRet!(prod)
///
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = mul nuw i32 %0, %1
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
/// test "IRBuilder::createNUWMul with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "mul")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let forty_two = ctx.getConstInt32(42)
///   let thirty_three = ctx.getConstInt32(33)
///
///   let prod = builder.createNUWMul!(forty_two, thirty_three)
///   let _ = builder.createRet!(prod)
///
///   inspect(prod, content = "i32 1386")
///   inspect(
///     fval,
///     content = 
///     #|define i32 @mul() {
///     #|entry:
///     #|  ret i32 1386
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
  fast_math_flags~: Set[FastMathFlag] = Set::new(),
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FAdd,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags
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
  fast_math_flags~: Set[FastMathFlag] = Set::new(),
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FSub,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags
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
  fast_math_flags~: Set[FastMathFlag] = Set::new(),
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FMul,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags
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
  fast_math_flags~: Set[FastMathFlag] = Set::new(),
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FDiv,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags
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
  fast_math_flags~: Set[FastMathFlag] = Set::new(),
) -> &Value!Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newFPMathOp!(
    BinaryOps::FRem,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags
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
///   let and_val = builder.createAnd!(arg0, arg1)
///   let _ = builder.createRet!(and_val)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @and_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = and i32 %0, %1
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
/// test "IRBuilder::createAnd with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "and_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const6 = ctx.getConstInt32(6) // 0b0110
///   let const3 = ctx.getConstInt32(3) // 0b0011
///
///   let and_result = builder.createAnd!(const6, const3) // Expected: 2 (0b0010)
///   let _ = builder.createRet!(and_result)
///
///   inspect(and_result, content = "i32 2")
///   inspect(
///     fval,
///     content =
///     #|define i32 @and_const_func() {
///     #|entry:
///     #|  ret i32 2
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
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) => return lhs_ci.and!(rhs_ci)
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
///   let or_val = builder.createOr!(arg0, arg1)
///   let _ = builder.createRet!(or_val)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @or_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = or i32 %0, %1
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
/// test "IRBuilder::createOr with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "or_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const6 = ctx.getConstInt32(6) // 0b0110
///   let const3 = ctx.getConstInt32(3) // 0b0011
///
///   let or_result = builder.createOr!(const6, const3) // Expected: 7 (0b0111)
///   let _ = builder.createRet!(or_result)
///
///   inspect(or_result, content = "i32 7")
///   inspect(
///     fval,
///     content =
///     #|define i32 @or_const_func() {
///     #|entry:
///     #|  ret i32 7
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
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) => return lhs_ci.or!(rhs_ci)
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
///   let xor_val = builder.createXor!(arg0, arg1)
///   let _ = builder.createRet!(xor_val)
///
///   inspect(
///     fval,
///     content =
///     #|define i32 @xor_func(i32 %0, i32 %1) {
///     #|entry:
///     #|  %2 = xor i32 %0, %1
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
/// test "IRBuilder::createXor with constant folding" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.addProgram("demo")
///   let builder = IRBuilder::new()
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [])
///   let fval = prog.addFunction!(fty, "xor_const_func")
///   let entryBB = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entryBB)
///
///   let const6 = ctx.getConstInt32(6) // 0b0110
///   let const3 = ctx.getConstInt32(3) // 0b0011
///
///   let xor_result = builder.createXor!(const6, const3) // Expected: 5 (0b0101)
///   let _ = builder.createRet!(xor_result)
///
///   inspect(xor_result, content = "i32 5")
///   inspect(
///     fval,
///     content =
///     #|define i32 @xor_const_func() {
///     #|entry:
///     #|  ret i32 5
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
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) => return lhs_ci.xor!(rhs_ci)
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
