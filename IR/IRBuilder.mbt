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
    (Some(ConstantUInt(lhs)), Some(ConstantUInt(rhs))) => return lhs.add!(rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Add,
    lhs,
    rhs,
    parent,
    name,
    has_nsw,
    has_nuw,
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
    (Some(ConstantUInt(lhs)), Some(ConstantUInt(rhs))) => return lhs.sub!(rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Sub,
    lhs,
    rhs,
    parent,
    name,
    has_nsw,
    has_nuw,
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
    (Some(ConstantUInt(lhs)), Some(ConstantUInt(rhs))) => return lhs.mul!(rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Mul,
    lhs,
    rhs,
    parent,
    name,
    has_nsw,
    has_nuw,
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
