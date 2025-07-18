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
fn IRBuilder::new() -> IRBuilder {
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
fn IRBuilder::insert(self : IRBuilder, inst : &Instruction) -> Unit raise Error {
  guard self.bb is Some(_) else { raise UnsetInsertPoint }
  match self.insertPt {
    Some(insertPt) => {
      inst.insertAfter(insertPt)
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

///| Create a Return Instruction
///
/// **Note:**
/// 
/// `IRBuilder::createRet` could not return void. use `IRBuilder::createRetVoid` for that purpose.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "direct_ret")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let ret = builder.createRet(arg)
///
/// inspect(ret, content = "  ret i32 %0")
/// ```
pub fn IRBuilder::createRet(
  self : IRBuilder,
  retVal : &Value
) -> &Instruction raise Error {
  let parent = self.getInsertFunction()
  let retInst = ReturnInst::new(Some(retVal), parent)
  self.insert(retInst)
  retInst
}

///| Create a Return Instruction with no return value (void)
///
/// **Note:**
///
/// If you want to return a value, use `IRBuilder::createRet` instead.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let void_ty = ctx.getVoidTy()
/// let fty = ctx.getFunctionType(void_ty, [])
///
/// let fval = mod.addFunction(fty, "direct_ret")
/// let bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(bb)
/// let ret = builder.createRetVoid()
///
/// inspect(ret, content = "  ret void")
/// ```
pub fn IRBuilder::createRetVoid(self : IRBuilder) -> &Instruction raise Error {
  let parent = self.getInsertFunction()
  let retInst = ReturnInst::new(None, parent)
  self.insert(retInst)
  retInst
}

///|
pub fn IRBuilder::createAlloca(
  self : IRBuilder,
  data_ty : &Type,
  addressSpace~ : AddressSpace = AddressSpace::default(),
  name~ : String = ""
) -> &Value raise Error {
  let allocaInst = AllocaInst::new(
    data_ty,
    self.getInsertFunction(),
    addressSpace~,
    name,
  )
  self.insert(allocaInst)
  allocaInst
}

///| Create an Add Instruction
///
/// **Note:**
/// 
/// This creates an integer addition instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "add_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let add = builder.createAdd(arg1, arg2, name="sum")
/// inspect(add, content = "  %sum = add i32 %0, %1")
/// assert_true(add.asValueEnum() is BinaryInst(_))
///
/// let one = ctx.getConstInt32(1)
/// let two = ctx.getConstInt32(2)
/// let three = builder.createAdd(one, two)
/// inspect(three, content = "i32 3")
/// assert_true(three.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createAdd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  has_nsw~ : Bool = false,
  has_nuw~ : Bool = false
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) => return lhs.add(rhs)
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
  let inst = BinaryInst::newStandardOp(
    BinaryOps::Add,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an NSW Add Instruction
///
/// **Note:**
/// 
/// This creates an integer addition instruction with No Signed Wrap (NSW) flag. If signed overflow occurs, the result is undefined.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "nsw_add_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let add = builder.createNSWAdd(arg1, arg2, name="sum")
/// inspect(add, content = "  %sum = add nsw i32 %0, %1")
/// assert_true(add.asValueEnum() is BinaryInst(_))
///
/// let one = ctx.getConstInt32(1)
/// let two = ctx.getConstInt32(2)
/// let three = builder.createNSWAdd(one, two)
/// inspect(three, content = "i32 3")
/// assert_true(three.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createNSWAdd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createAdd(lhs, rhs, name~, has_nsw=true, has_nuw=false)
}

///| Create an NUW Add Instruction
///
/// **Note:**
/// 
/// This creates an integer addition instruction with No Unsigned Wrap (NUW) flag. If unsigned overflow occurs, the result is undefined.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "nuw_add_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let add = builder.createNUWAdd(arg1, arg2, name="sum")
/// inspect(add, content = "  %sum = add nuw i32 %0, %1")
/// assert_true(add.asValueEnum() is BinaryInst(_))
///
/// let one = ctx.getConstInt32(1)
/// let two = ctx.getConstInt32(2)
/// let three = builder.createNUWAdd(one, two)
/// inspect(three, content = "i32 3")
/// assert_true(three.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createNUWAdd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createAdd(lhs, rhs, name~, has_nsw=false, has_nuw=true)
}

///| Create a Sub Instruction
///
/// **Note:**
/// 
/// This creates an integer subtraction instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "sub_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let sub = builder.createSub(arg1, arg2, name="diff")
/// inspect(sub, content = "  %diff = sub i32 %0, %1")
/// assert_true(sub.asValueEnum() is BinaryInst(_))
///
/// let five = ctx.getConstInt32(5)
/// let two = ctx.getConstInt32(2)
/// let three = builder.createSub(five, two)
/// inspect(three, content = "i32 3")
/// assert_true(three.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createSub(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  has_nsw~ : Bool = false,
  has_nuw~ : Bool = false
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) => return lhs.sub(rhs)
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
  let inst = BinaryInst::newStandardOp(
    BinaryOps::Sub,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an NSW Sub Instruction
///
/// **Note:**
/// 
/// This creates an integer subtraction instruction with No Signed Wrap (NSW) flag. If signed overflow occurs, the result is undefined.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "nsw_sub_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let sub = builder.createNSWSub(arg1, arg2, name="diff")
/// inspect(sub, content = "  %diff = sub nsw i32 %0, %1")
/// assert_true(sub.asValueEnum() is BinaryInst(_))
///
/// let five = ctx.getConstInt32(5)
/// let two = ctx.getConstInt32(2)
/// let three = builder.createNSWSub(five, two)
/// inspect(three, content = "i32 3")
/// assert_true(three.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createNSWSub(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createSub(lhs, rhs, name~, has_nsw=true, has_nuw=false)
}

///| Create an NUW Sub Instruction
///
/// **Note:**
/// 
/// This creates an integer subtraction instruction with No Unsigned Wrap (NUW) flag. If unsigned overflow occurs, the result is undefined.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "nuw_sub_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let sub = builder.createNUWSub(arg1, arg2, name="diff")
/// inspect(sub, content = "  %diff = sub nuw i32 %0, %1")
/// assert_true(sub.asValueEnum() is BinaryInst(_))
///
/// let five = ctx.getConstInt32(5)
/// let two = ctx.getConstInt32(2)
/// let three = builder.createNUWSub(five, two)
/// inspect(three, content = "i32 3")
/// assert_true(three.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createNUWSub(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createSub(lhs, rhs, name~, has_nsw=false, has_nuw=true)
}

///| Create a Mul Instruction
///
/// **Note:**
/// 
/// This creates an integer multiplication instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "mul_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let mul = builder.createMul(arg1, arg2, name="product")
/// inspect(mul, content = "  %product = mul i32 %0, %1")
/// assert_true(mul.asValueEnum() is BinaryInst(_))
///
/// let three = ctx.getConstInt32(3)
/// let four = ctx.getConstInt32(4)
/// let twelve = builder.createMul(three, four)
/// inspect(twelve, content = "i32 12")
/// assert_true(twelve.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createMul(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  has_nsw~ : Bool = false,
  has_nuw~ : Bool = false
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) => return lhs.mul(rhs)
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
  let inst = BinaryInst::newStandardOp(
    BinaryOps::Mul,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an NSW Mul Instruction
///
/// **Note:**
/// 
/// This creates an integer multiplication instruction with No Signed Wrap (NSW) flag. If signed overflow occurs, the result is undefined.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "nsw_mul_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let mul = builder.createNSWMul(arg1, arg2, name="product")
/// inspect(mul, content = "  %product = mul nsw i32 %0, %1")
/// assert_true(mul.asValueEnum() is BinaryInst(_))
///
/// let three = ctx.getConstInt32(3)
/// let four = ctx.getConstInt32(4)
/// let twelve = builder.createNSWMul(three, four)
/// inspect(twelve, content = "i32 12")
/// assert_true(twelve.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createNSWMul(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createMul(lhs, rhs, name~, has_nsw=true, has_nuw=false)
}

///| Create an NUW Mul Instruction
///
/// **Note:**
/// 
/// This creates an integer multiplication instruction with No Unsigned Wrap (NUW) flag. If unsigned overflow occurs, the result is undefined.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "nuw_mul_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let mul = builder.createNUWMul(arg1, arg2, name="product")
/// inspect(mul, content = "  %product = mul nuw i32 %0, %1")
/// assert_true(mul.asValueEnum() is BinaryInst(_))
///
/// let three = ctx.getConstInt32(3)
/// let four = ctx.getConstInt32(4)
/// let twelve = builder.createNUWMul(three, four)
/// inspect(twelve, content = "i32 12")
/// assert_true(twelve.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createNUWMul(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createMul(lhs, rhs, name~, has_nsw=false, has_nuw=true)
}

///| Create an SDiv Instruction
///
/// **Note:**
/// 
/// This creates a signed integer division instruction.
/// Both operands must be integer types with the same bitwidth.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "sdiv_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let div = builder.createSDiv(arg1, arg2, name="quotient")
/// inspect(div, content = "  %quotient = sdiv i32 %0, %1")
/// assert_true(div.asValueEnum() is BinaryInst(_))
///
/// let twelve = ctx.getConstInt32(12)
/// let three = ctx.getConstInt32(3)
/// let four = builder.createSDiv(twelve, three)
/// inspect(four, content = "i32 4")
/// assert_true(four.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createSDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  is_exact~ : Bool = false
) -> &Value raise Error {
  // match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
  //   (Some(ConstantInt(c_lhs)), Some(ConstantInt(c_rhs))) => return c_lhs.sdiv(c_rhs) // Assuming ConstantInt has sdiv!
  //   _ => ()
  // }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if is_exact {
    flags.add(BinaryOpFlags::Exact)
  }
  let inst = BinaryInst::newStandardOp(
    BinaryOps::SDiv,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an Exact SDiv Instruction
///
/// **Note:**
/// 
/// This creates an exact signed integer division instruction. Both operands must be integer types with the same bitwidth.
/// The exact flag indicates that the division is expected to be exact (no remainder).
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "exact_sdiv_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let div = builder.createExactSDiv(arg1, arg2, name="quotient")
/// inspect(div, content = "  %quotient = sdiv exact i32 %0, %1")
/// assert_true(div.asValueEnum() is BinaryInst(_))
///
/// let twelve = ctx.getConstInt32(12)
/// let three = ctx.getConstInt32(3)
/// let four = builder.createExactSDiv(twelve, three)
/// inspect(four, content = "i32 4")
/// assert_true(four.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createExactSDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createSDiv(lhs, rhs, name~, is_exact=true)
}

///| Create a UDiv Instruction
///
/// **Note:**
/// 
/// This creates an unsigned integer division instruction. 
/// Both operands must be integer types with the same bitwidth.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "udiv_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let div = builder.createUDiv(arg1, arg2, name="quotient")
/// inspect(div, content = "  %quotient = udiv i32 %0, %1")
/// assert_true(div.asValueEnum() is BinaryInst(_))
///
/// let twelve = ctx.getConstInt32(12)
/// let three = ctx.getConstInt32(3)
/// let four = builder.createUDiv(twelve, three)
/// inspect(four, content = "i32 4")
/// assert_true(four.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createUDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  is_exact~ : Bool = false
) -> &Value raise Error {
  // match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
  //   (Some(ConstantUInt(c_lhs)), Some(ConstantUInt(c_rhs))) => return c_lhs.udiv(c_rhs) // Assumed missing
  //   _ => ()
  // }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if is_exact {
    flags.add(BinaryOpFlags::Exact)
  }
  let inst = BinaryInst::newStandardOp(
    BinaryOps::UDiv,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an Exact UDiv Instruction
///
/// **Note:**
/// 
/// This creates an exact unsigned integer division instruction.
/// Both operands must be integer types with the same bitwidth.
/// The exact flag indicates that the division is expected to be exact (no remainder).
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "exact_udiv_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let div = builder.createExactUDiv(arg1, arg2, name="quotient")
/// inspect(div, content = "  %quotient = udiv exact i32 %0, %1")
/// assert_true(div.asValueEnum() is BinaryInst(_))
///
/// let twelve = ctx.getConstInt32(12)
/// let three = ctx.getConstInt32(3)
/// let four = builder.createExactUDiv(twelve, three)
/// inspect(four, content = "i32 4")
/// assert_true(four.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createExactUDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createUDiv(lhs, rhs, name~, is_exact=true)
}

///| Create an SRem Instruction
///
/// **Note:**
/// 
/// This creates a signed integer remainder instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "srem_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let rem = builder.createSRem(arg1, arg2, name="remainder")
/// inspect(rem, content = "  %remainder = srem i32 %0, %1")
/// assert_true(rem.asValueEnum() is BinaryInst(_))
///
/// let thirteen = ctx.getConstInt32(13)
/// let five = ctx.getConstInt32(5)
/// let three = builder.createSRem(thirteen, five)
/// inspect(three, content = "i32 3")
/// assert_true(three.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createSRem(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  // Constant folding for SRem is currently disabled due to assumed missing `ConstantInt::srem!`
  // match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
  //   (Some(ConstantInt(c_lhs)), Some(ConstantInt(c_rhs))) => return c_lhs.srem(c_rhs)
  //   _ => ()
  // }

  let parent = self.getInsertFunction()
  let flags = Set::new() // nsw, nuw, exact are not applicable to SRem
  let inst = BinaryInst::newStandardOp(
    BinaryOps::SRem,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create a URem Instruction
///
/// **Note:**
/// 
/// This creates an unsigned integer remainder instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "urem_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let rem = builder.createURem(arg1, arg2, name="remainder")
/// inspect(rem, content = "  %remainder = urem i32 %0, %1")
/// assert_true(rem.asValueEnum() is BinaryInst(_))
///
/// let thirteen = ctx.getConstInt32(13)
/// let five = ctx.getConstInt32(5)
/// let three = builder.createURem(thirteen, five)
/// inspect(three, content = "i32 3")
/// assert_true(three.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createURem(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  // Constant folding for URem is currently disabled due to assumed missing `ConstantUInt::urem!`
  // match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
  //   (Some(ConstantUInt(c_lhs)), Some(ConstantUInt(c_rhs))) => return c_lhs.urem(c_rhs)
  //   _ => ()
  // }

  let parent = self.getInsertFunction()
  let flags = Set::new() // nsw, nuw, exact are not applicable to URem
  let inst = BinaryInst::newStandardOp(
    BinaryOps::URem,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an FAdd Instruction
///
/// **Note:**
/// 
/// This creates a floating-point addition instruction.
/// Both operands must be floating-point types with the same bitwidth.
///
/// **Fast Math Flags:**
///
/// Allowed Fast Math Flags:
/// 1. `AllowReassoc`
/// 2. `AllowContract`
/// 3. `NoNaNs`
/// 4. `NoInfs`
/// 5. `NoSignedZeros`
/// 6. `AllowReciprocal`
/// 7. `ApproxFunc`
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "fadd_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let fadd = builder.createFAdd(arg1, arg2, name="sum")
/// inspect(fadd, content = "  %sum = fadd float %0, %1")
/// assert_true(fadd.asValueEnum() is BinaryInst(_))
///
/// let one = ctx.getConstFloat(1.0)
/// let two = ctx.getConstFloat(2.0)
/// let three = builder.createFAdd(one, two)
/// inspect(three, content = "float 3.000000e+00")
/// assert_true(three.asValueEnum() is ConstantFP(_))
///
/// let nnan_fadd = builder.createFAdd(arg1, arg2, name="sum_nnan", fast_math=[NoNaNs])
/// inspect(nnan_fadd, content = "  %sum_nnan = fadd nnan float %0, %1")
///
/// let ninf_fadd = builder.createFAdd(arg1, arg2, name="sum_ninf", fast_math=[NoInfs])
/// inspect(ninf_fadd, content = "  %sum_ninf = fadd ninf float %0, %1")
///
/// let nnan_ninf_fadd = builder.createFAdd(
///   arg1, arg2, name="sum_nnan_ninf", fast_math=[NoNaNs, NoInfs]
/// )
/// inspect(nnan_ninf_fadd, content = "  %sum_nnan_ninf = fadd nnan ninf float %0, %1")
/// ```
pub fn IRBuilder::createFAdd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math~ : Array[FastMathFlag] = []
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let fast_math_flags = Set::from_array(fast_math)
  let inst = BinaryInst::newFPMathOp(
    BinaryOps::FAdd,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert(inst)
  inst
}

///| Create an FSub Instruction
///
/// **Note:**
/// 
/// This creates a floating-point subtraction instruction. Both operands must be floating-point types with the same bitwidth.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "fsub_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let fsub = builder.createFSub(arg1, arg2, name="diff")
/// inspect(fsub, content = "  %diff = fsub float %0, %1")
/// assert_true(fsub.asValueEnum() is BinaryInst(_))
///
/// let five = ctx.getConstFloat(5.0)
/// let two = ctx.getConstFloat(2.0)
/// let three = builder.createFSub(five, two)
/// inspect(three, content = "float 3.000000e+00")
/// assert_true(three.asValueEnum() is ConstantFP(_))
/// ```
pub fn IRBuilder::createFSub(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInst::newFPMathOp(
    BinaryOps::FSub,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert(inst)
  inst
}

///| Create an FMul Instruction
///
/// **Note:**
/// 
/// This creates a floating-point multiplication instruction. Both operands must be floating-point types with the same bitwidth.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "fmul_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let fmul = builder.createFMul(arg1, arg2, name="product")
/// inspect(fmul, content = "  %product = fmul float %0, %1")
/// assert_true(fmul.asValueEnum() is BinaryInst(_))
///
/// let three = ctx.getConstFloat(3.0)
/// let four = ctx.getConstFloat(4.0)
/// let twelve = builder.createFMul(three, four)
/// inspect(twelve, content = "float 1.200000e+01")
/// assert_true(twelve.asValueEnum() is ConstantFP(_))
/// ```
pub fn IRBuilder::createFMul(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInst::newFPMathOp(
    BinaryOps::FMul,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert(inst)
  inst
}

///| Create an FDiv Instruction
///
/// **Note:**
/// 
/// This creates a floating-point division instruction. Both operands must be floating-point types with the same bitwidth.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "fdiv_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let fdiv = builder.createFDiv(arg1, arg2, name="quotient")
/// inspect(fdiv, content = "  %quotient = fdiv float %0, %1")
/// assert_true(fdiv.asValueEnum() is BinaryInst(_))
///
/// let eight = ctx.getConstFloat(8.0)
/// let two = ctx.getConstFloat(2.0)
/// let four = builder.createFDiv(eight, two)
/// inspect(four, content = "float 4.000000e+00")
/// assert_true(four.asValueEnum() is ConstantFP(_))
/// ```
pub fn IRBuilder::createFDiv(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInst::newFPMathOp(
    BinaryOps::FDiv,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert(inst)
  inst
}

///| Create an FRem Instruction
///
/// **Note:**
/// 
/// This creates a floating-point remainder instruction. Both operands must be floating-point types with the same bitwidth.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///
/// let fval = mod.addFunction(fty, "frem_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let frem = builder.createFRem(arg1, arg2, name="remainder")
/// inspect(frem, content = "  %remainder = frem float %0, %1")
/// assert_true(frem.asValueEnum() is BinaryInst(_))
///
/// let five_and_half = ctx.getConstFloat(5.5)
/// let two = ctx.getConstFloat(2.0)
/// let one_and_half = builder.createFRem(five_and_half, two)
/// inspect(one_and_half, content = "float 1.500000e+00")
/// assert_true(one_and_half.asValueEnum() is ConstantFP(_))
/// ```
pub fn IRBuilder::createFRem(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  fast_math_flags~ : Set[FastMathFlag] = Set::new()
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let inst = BinaryInst::newFPMathOp(
    BinaryOps::FRem,
    lhs,
    rhs,
    parent,
    name,
    fast_math_flags,
  )
  self.insert(inst)
  inst
}

///| Create an And Instruction
///
/// **Note:**
/// 
/// This creates a bitwise AND instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "and_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let and_result = builder.createAnd(arg1, arg2, name="result")
/// inspect(and_result, content = "  %result = and i32 %0, %1")
/// assert_true(and_result.asValueEnum() is BinaryInst(_))
///
/// let val1 = ctx.getConstInt32(12)  // 1100 in binary
/// let val2 = ctx.getConstInt32(10)  // 1010 in binary
/// let result = builder.createAnd(val1, val2)  // 1000 in binary = 8
/// inspect(result, content = "i32 8")
/// assert_true(result.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createAnd(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.compute_and(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInst::newStandardOp(
    BinaryOps::And,
    lhs,
    rhs,
    parent,
    name,
    Set::new(),
  )
  self.insert(inst)
  inst
}

///| Create an Or Instruction
///
/// **Note:**
/// 
/// This creates a bitwise OR instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "or_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let or_result = builder.createOr(arg1, arg2, name="result")
/// inspect(or_result, content = "  %result = or i32 %0, %1")
/// assert_true(or_result.asValueEnum() is BinaryInst(_))
///
/// let val1 = ctx.getConstInt32(12)  // 1100 in binary
/// let val2 = ctx.getConstInt32(10)  // 1010 in binary
/// let result = builder.createOr(val1, val2)  // 1110 in binary = 14
/// inspect(result, content = "i32 14")
/// assert_true(result.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createOr(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.or(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInst::newStandardOp(
    BinaryOps::Or,
    lhs,
    rhs,
    parent,
    name,
    Set::new(),
  )
  self.insert(inst)
  inst
}

///| Create an Xor Instruction
///
/// **Note:**
/// 
/// This creates a bitwise XOR instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "xor_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let xor_result = builder.createXor(arg1, arg2, name="result")
/// inspect(xor_result, content = "  %result = xor i32 %0, %1")
/// assert_true(xor_result.asValueEnum() is BinaryInst(_))
///
/// let val1 = ctx.getConstInt32(12)  // 1100 in binary
/// let val2 = ctx.getConstInt32(10)  // 1010 in binary
/// let result = builder.createXor(val1, val2)  // 0110 in binary = 6
/// inspect(result, content = "i32 6")
/// assert_true(result.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createXor(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.xor(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInst::newStandardOp(
    BinaryOps::Xor,
    lhs,
    rhs,
    parent,
    name,
    Set::new(),
  )
  self.insert(inst)
  inst
}

///| Create a Shl Instruction
///
/// **Note:**
/// 
/// This creates a left shift instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "shl_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let shl_result = builder.createShl(arg1, arg2, name="result")
/// inspect(shl_result, content = "  %result = shl i32 %0, %1")
/// assert_true(shl_result.asValueEnum() is BinaryInst(_))
///
/// let val = ctx.getConstInt32(5)   // 101 in binary
/// let shift = ctx.getConstInt32(2) // shift left by 2
/// let result = builder.createShl(val, shift)  // 10100 in binary = 20
/// inspect(result, content = "i32 20")
/// assert_true(result.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createShl(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  has_nsw~ : Bool = false,
  has_nuw~ : Bool = false
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.compute_shl(rhs_ci)
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
  let inst = BinaryInst::newStandardOp(
    BinaryOps::Shl,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an LShr Instruction
///
/// **Note:**
/// 
/// This creates a logical right shift instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "lshr_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let lshr_result = builder.createLShr(arg1, arg2, name="result")
/// inspect(lshr_result, content = "  %result = lshr i32 %0, %1")
/// assert_true(lshr_result.asValueEnum() is BinaryInst(_))
///
/// let twenty = ctx.getConstInt32(20)   // 10100 in binary
/// let two = ctx.getConstInt32(2)       // shift right by 2
/// let five = builder.createLShr(twenty, two)  // 101 in binary = 5
/// inspect(five, content = "i32 5")
/// assert_true(five.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createLShr(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  is_exact~ : Bool = false
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.lshr(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if is_exact {
    flags.add(BinaryOpFlags::Exact)
  }
  let inst = BinaryInst::newStandardOp(
    BinaryOps::LShr,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an AShr Instruction
///
/// **Note:**
/// 
/// This creates an arithmetic right shift instruction. Both operands must be integer types with the same bitwidth.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///
/// let fval = mod.addFunction(fty, "ashr_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg1 = fval.getArg(0).unwrap()
/// let arg2 = fval.getArg(1).unwrap()
///
/// builder.setInsertPoint(bb)
/// let ashr_result = builder.createAShr(arg1, arg2, name="result")
/// inspect(ashr_result, content = "  %result = ashr i32 %0, %1")
/// assert_true(ashr_result.asValueEnum() is BinaryInst(_))
///
/// let twenty = ctx.getConstInt32(20)   // 10100 in binary
/// let two = ctx.getConstInt32(2)       // shift right by 2
/// let five = builder.createAShr(twenty, two)  // 101 in binary = 5
/// inspect(five, content = "i32 5")
/// assert_true(five.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createAShr(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = "",
  is_exact~ : Bool = false
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs_ci)), Some(ConstantInt(rhs_ci))) =>
      return lhs_ci.ashr(rhs_ci)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let flags = Set::new()
  if is_exact {
    flags.add(BinaryOpFlags::Exact)
  }
  let inst = BinaryInst::newStandardOp(
    BinaryOps::AShr,
    lhs,
    rhs,
    parent,
    name,
    flags,
  )
  self.insert(inst)
  inst
}

///| Create an Integer Compare Instruction.
///
/// **Note:**
///
/// 1. `lhs` and `rhs` must be integer types with the same bitwidth.
/// 2. Allowed predicates: EQ, NE, SGT, SGE, SLT, SLE, UGT, UGE, ULT, ULE.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
/// let fval = mod.addFunction(fty, "icmp_demo")
///
/// let bb = fval.addBasicBlock(name="entry")
/// let arg0 = fval.getArg(0).unwrap()
/// let arg1 = fval.getArg(1).unwrap()
/// builder.setInsertPoint(bb)
///
/// let eq_cmp = builder.createICmp(IntPredicate::EQ, arg0, arg1, name="eq_cmp")
/// inspect(eq_cmp, content = "  %eq_cmp = icmp eq i32 %0, %1")
/// assert_true(eq_cmp.asValueEnum() is ICmpInst(_))
///
/// let val1 = ctx.getConstInt32(5)
/// let val2 = ctx.getConstInt32(5)
/// let result = builder.createICmpEQ(val1, val2)
/// inspect(result, content = "i1 true")
/// assert_true(result.asValueEnum() is ConstantInt(_))
///
/// let ne_cmp = builder.createICmpNE(arg0, arg1, name="ne_cmp")
/// inspect(ne_cmp, content = "  %ne_cmp = icmp ne i32 %0, %1")
///
/// let sgt_cmp = builder.createICmpSGT(arg0, arg1, name="sgt_cmp")
/// inspect(sgt_cmp, content = "  %sgt_cmp = icmp sgt i32 %0, %1")
///
/// let sge_cmp = builder.createICmpSGE(arg0, arg1, name="sge_cmp")
/// inspect(sge_cmp, content = "  %sge_cmp = icmp sge i32 %0, %1")
///
/// let slt_cmp = builder.createICmpSLT(arg0, arg1, name="slt_cmp")
/// inspect(slt_cmp, content = "  %slt_cmp = icmp slt i32 %0, %1")
///
/// let sle_cmp = builder.createICmpSLE(arg0, arg1, name="sle_cmp")
/// inspect(sle_cmp, content = "  %sle_cmp = icmp sle i32 %0, %1")
///
/// let ugt_cmp = builder.createICmpUGT(arg0, arg1, name="ugt_cmp")
/// inspect(ugt_cmp, content = "  %ugt_cmp = icmp ugt i32 %0, %1")
///
/// let uge_cmp = builder.createICmpUGE(arg0, arg1, name="uge_cmp")
/// inspect(uge_cmp, content = "  %uge_cmp = icmp uge i32 %0, %1")
///
/// let ult_cmp = builder.createICmpULT(arg0, arg1, name="ult_cmp")
/// inspect(ult_cmp, content = "  %ult_cmp = icmp ult i32 %0, %1")
///
/// let ule_cmp = builder.createICmpULE(arg0, arg1, name="ule_cmp")
/// inspect(ule_cmp, content = "  %ule_cmp = icmp ule i32 %0, %1")
/// ```
pub fn IRBuilder::createICmp(
  self : IRBuilder,
  pred : IntPredicate,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) =>
      return lhs.compare(pred, rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = ICmpInst::new(pred, lhs, rhs, parent, name)
  self.insert(inst)
  inst
}

///| Create Eq (Equality) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(ICMP_EQ, ...)`.
pub fn IRBuilder::createICmpEQ(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(EQ, lhs, rhs, name~)
}

///| Create Ne (Not Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(ICMP_NE, ...)`.
pub fn IRBuilder::createICmpNE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(NE, lhs, rhs, name~)
}

///| Create UGT (Unsigned Greater Than) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(UGT, ...)`.
pub fn IRBuilder::createICmpUGT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(UGT, lhs, rhs, name~)
}

///| Create UGE (Unsigned Greater Than or Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(UGE, ...)`.
pub fn IRBuilder::createICmpUGE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(UGE, lhs, rhs, name~)
}

///| Create ULT (Unsigned Less Than) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(ULT, ...)`.
pub fn IRBuilder::createICmpULT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(ULT, lhs, rhs, name~)
}

///| Create ULE (Unsigned Less Than or Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(ULE, ...)`.
pub fn IRBuilder::createICmpULE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(ULE, lhs, rhs, name~)
}

///| Create SGT (Signed Greater Than) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(SGT, ...)`.
pub fn IRBuilder::createICmpSGT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(SGT, lhs, rhs, name~)
}

///| Create SGE (Signed Greater Than or Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(SGE, ...)`.
pub fn IRBuilder::createICmpSGE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(SGE, lhs, rhs, name~)
}

///| Create SLT (Signed Less Than) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(SLT, ...)`.
pub fn IRBuilder::createICmpSLT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(SLT, lhs, rhs, name~)
}

///| Create SLE (Signed Less Than or Equal) Comparison Instruction.
///
/// It's equivalent to `IRBuilder::createICmp(SLE, ...)`.
pub fn IRBuilder::createICmpSLE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createICmp(SLE, lhs, rhs, name~)
}

///| Create a Float Compare Instruction.
///
/// **Note:**
///
/// 1. `lhs` and `rhs` must be floating-point types with the same bitwidth.
/// 2. Allowed predicates: OEQ, OGT, OGE, OLT, OLE, ONE, ORD, UEQ, UGT, UGE, ULT, ULE, UNE.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
/// let fval = mod.addFunction(fty, "fcmp_demo")
///
/// let bb = fval.addBasicBlock(name="entry")
/// let arg0 = fval.getArg(0).unwrap()
/// let arg1 = fval.getArg(1).unwrap()
/// builder.setInsertPoint(bb)
///
/// let oeq_cmp = builder.createFCmp(FloatPredicate::OEQ, arg0, arg1, name="oeq_cmp")
/// inspect(oeq_cmp, content = "  %oeq_cmp = fcmp oeq float %0, %1")
/// assert_true(oeq_cmp.asValueEnum() is FCmpInst(_))
///
/// let val1 = ctx.getConstFloat(3.14)
/// let val2 = ctx.getConstFloat(3.14)
/// let result = builder.createFCmpOEQ(val1, val2)
/// inspect(result, content = "i1 true")
/// assert_true(result.asValueEnum() is ConstantInt(_))
///
/// let ogt_cmp = builder.createFCmpOGT(arg0, arg1, name="ogt_cmp")
/// inspect(ogt_cmp, content = "  %ogt_cmp = fcmp ogt float %0, %1")
///
/// let oge_cmp = builder.createFCmpOGE(arg0, arg1, name="oge_cmp")
/// inspect(oge_cmp, content = "  %oge_cmp = fcmp oge float %0, %1")
///
/// let olt_cmp = builder.createFCmpOLT(arg0, arg1, name="olt_cmp")
/// inspect(olt_cmp, content = "  %olt_cmp = fcmp olt float %0, %1")
///
/// let ole_cmp = builder.createFCmpOLE(arg0, arg1, name="ole_cmp")
/// inspect(ole_cmp, content = "  %ole_cmp = fcmp ole float %0, %1")
///
/// let one_cmp = builder.createFCmpONE(arg0, arg1, name="one_cmp")
/// inspect(one_cmp, content = "  %one_cmp = fcmp one float %0, %1")
///
/// let ord_cmp = builder.createFCmpORD(arg0, arg1, name="ord_cmp")
/// inspect(ord_cmp, content = "  %ord_cmp = fcmp ord float %0, %1")
///
/// let ueq_cmp = builder.createFCmpUEQ(arg0, arg1, name="ueq_cmp")
/// inspect(ueq_cmp, content = "  %ueq_cmp = fcmp ueq float %0, %1")
///
/// let ugt_cmp = builder.createFCmpUGT(arg0, arg1, name="ugt_cmp")
/// inspect(ugt_cmp, content = "  %ugt_cmp = fcmp ugt float %0, %1")
///
/// let uge_cmp = builder.createFCmpUGE(arg0, arg1, name="uge_cmp")
/// inspect(uge_cmp, content = "  %uge_cmp = fcmp uge float %0, %1")
///
/// let ult_cmp = builder.createFCmpULT(arg0, arg1, name="ult_cmp")
/// inspect(ult_cmp, content = "  %ult_cmp = fcmp ult float %0, %1")
///
/// let ule_cmp = builder.createFCmpULE(arg0, arg1, name="ule_cmp")
/// inspect(ule_cmp, content = "  %ule_cmp = fcmp ule float %0, %1")
///
/// let une_cmp = builder.createFCmpUNE(arg0, arg1, name="une_cmp")
/// inspect(une_cmp, content = "  %une_cmp = fcmp une float %0, %1")
/// ```
pub fn IRBuilder::createFCmp(
  self : IRBuilder,
  pred : FloatPredicate,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantFP(lhs)), Some(ConstantFP(rhs))) =>
      return lhs.compare(pred, rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = FCmpInst::new(pred, lhs, rhs, parent, name)
  self.insert(inst)
  inst
}

///| Create OEQ (Ordered Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_OEQ, ...)`.
pub fn IRBuilder::createFCmpOEQ(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(OEQ, lhs, rhs, name~)
}

///| Create OGT (Ordered Greater Than) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(FCMP_OGT, ...)`.
pub fn IRBuilder::createFCmpOGT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(OGT, lhs, rhs, name~)
}

///| Create OGE (Ordered Greater Than or Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(OGE, ...)`.
pub fn IRBuilder::createFCmpOGE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(OGE, lhs, rhs, name~)
}

///| Create OLT (Ordered Less Than) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(OLT, ...)`.
pub fn IRBuilder::createFCmpOLT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(OLT, lhs, rhs, name~)
}

///| Create OLE (Ordered Less Than or Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(OLE, ...)`.
pub fn IRBuilder::createFCmpOLE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(OLE, lhs, rhs, name~)
}

///| Create ONE (Ordered Not Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(ONE, ...)`.
pub fn IRBuilder::createFCmpONE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(ONE, lhs, rhs, name~)
}

///| Create ORD (Ordered) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(ORD, ...)`.
pub fn IRBuilder::createFCmpORD(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(ORD, lhs, rhs, name~)
}

///| Create UNO (Unordered) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(UNO, ...)`.
pub fn IRBuilder::createFCmpUNO(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(UNO, lhs, rhs, name~)
}

///| Create UEQ (Unordered Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(UEQ, ...)`.
pub fn IRBuilder::createFCmpUEQ(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(UEQ, lhs, rhs, name~)
}

///| Create UGT (Unordered Greater Than) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(UGT, ...)`.
pub fn IRBuilder::createFCmpUGT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(UGT, lhs, rhs, name~)
}

///| Create UGE (Unordered Greater Than or Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(UGE, ...)`.
pub fn IRBuilder::createFCmpUGE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(UGE, lhs, rhs, name~)
}

///| Create ULT (Unordered Less Than) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(ULT, ...)`.
pub fn IRBuilder::createFCmpULT(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(ULT, lhs, rhs, name~)
}

///| Create ULE (Unordered Less Than or Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createCmp(ULE, ...)`.
pub fn IRBuilder::createFCmpULE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(ULE, lhs, rhs, name~)
}

///| Create UNE (Unordered Not Equal) Comparison Instruction for floating-point values.
///
/// It's equivalent to `IRBuilder::createFCmp(UNE, ...)`.
pub fn IRBuilder::createFCmpUNE(
  self : IRBuilder,
  lhs : &Value,
  rhs : &Value,
  name~ : String = ""
) -> &Value raise Error {
  self.createFCmp(UNE, lhs, rhs, name~)
}

///| Create a Trunc Instruction
///
/// **Note:**
/// 
/// This creates a truncation instruction that truncates an integer value to a smaller integer type.
/// The input value must be an integer type, and the target type must be a smaller integer type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i64_ty = ctx.getInt64Ty()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///
/// let fval = mod.addFunction(fty, "trunc_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let trunc = builder.createTrunc(arg, i32_ty, name="truncated")
/// inspect(trunc, content = "  %truncated = trunc i64 %0 to i32")
/// assert_true(trunc.asValueEnum() is CastInst(_))
///
/// let big_val = ctx.getConstInt64(0x123456789L)
/// let small_val = builder.createTrunc(big_val, i32_ty)
/// inspect(small_val, content = "i32 591751049")
/// assert_true(small_val.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createTrunc(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.trunc(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newTrunc(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a ZExt Instruction
///
/// **Note:**
/// 
/// This creates a zero extension instruction that extends an integer value to a larger integer type by padding with zeros.
/// The input value must be an integer type, and the target type must be a larger integer type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let i64_ty = ctx.getInt64Ty()
/// let fty = ctx.getFunctionType(i64_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "zext_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let zext = builder.createZExt(arg, i64_ty, name="extended")
/// inspect(zext, content = "  %extended = zext i32 %0 to i64")
/// assert_true(zext.asValueEnum() is CastInst(_))
///
/// let small_val = ctx.getConstInt32(42)
/// let big_val = builder.createZExt(small_val, i64_ty)
/// inspect(big_val, content = "i64 42")
/// assert_true(big_val.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createZExt(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.zext(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newZExt(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a SExt Instruction
///
/// **Note:**
/// 
/// This creates a sign extension instruction that extends an integer value to a larger integer type by replicating the sign bit.
/// The input value must be an integer type, and the target type must be a larger integer type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let i64_ty = ctx.getInt64Ty()
/// let fty = ctx.getFunctionType(i64_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "sext_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let sext = builder.createSExt(arg, i64_ty, name="extended")
/// inspect(sext, content = "  %extended = sext i32 %0 to i64")
/// assert_true(sext.asValueEnum() is CastInst(_))
///
/// let small_val = ctx.getConstInt32(-42)
/// let big_val = builder.createSExt(small_val, i64_ty)
/// inspect(big_val, content = "i64 -42")
/// assert_true(big_val.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createSExt(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.sext(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newSExt(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a FPTrunc Instruction
///
/// **Note:**
/// 
/// This creates a floating-point truncation instruction that truncates a floating-point value to a smaller floating-point type.
/// The input value must be a floating-point type, and the target type must be a smaller floating-point type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f64_ty = ctx.getDoubleTy()
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [f64_ty])
///
/// let fval = mod.addFunction(fty, "fptrunc_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let fptrunc = builder.createFPTrunc(arg, f32_ty, name="truncated")
/// inspect(fptrunc, content = "  %truncated = fptrunc double %0 to float")
/// assert_true(fptrunc.asValueEnum() is CastInst(_))
///
/// let big_val = ctx.getConstDouble(3.14159)
/// let small_val = builder.createFPTrunc(big_val, f32_ty)
/// assert_true(small_val.asValueEnum() is ConstantFP(_))
/// ```
pub fn IRBuilder::createFPTrunc(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &FPType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantFP(cf)) => return cf.fptrunc(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newFPTrunc(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a FPExt Instruction
///
/// **Note:**
/// 
/// This creates a floating-point extension instruction that extends a floating-point value to a larger floating-point type.
/// The input value must be a floating-point type, and the target type must be a larger floating-point type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let f64_ty = ctx.getDoubleTy()
/// let fty = ctx.getFunctionType(f64_ty, [f32_ty])
///
/// let fval = mod.addFunction(fty, "fpext_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let fpext = builder.createFPExt(arg, f64_ty, name="extended")
///
/// inspect(fpext, content = "  %extended = fpext float %0 to double")
/// ```
pub fn IRBuilder::createFPExt(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &FPType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantFP(cf)) => return cf.fpext(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newFPExt(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a UIToFP Instruction
///
/// **Note:**
/// 
/// This creates an unsigned integer to floating-point conversion instruction that converts an unsigned integer value to a floating-point value.
/// The input value must be an integer type, and the target type must be a floating-point type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "uitofp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let uitofp = builder.createUIToFP(arg, f32_ty, name="converted")
/// inspect(uitofp, content = "  %converted = uitofp i32 %0 to float")
/// assert_true(uitofp.asValueEnum() is CastInst(_))
///
/// let int_val = ctx.getConstInt32(42)
/// let float_val = builder.createUIToFP(int_val, f32_ty)
/// assert_true(float_val.asValueEnum() is ConstantFP(_))
/// ```
pub fn IRBuilder::createUIToFP(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &FPType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.uitofp(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newUIToFP(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a FPToUI Instruction
///
/// **Note:**
/// 
/// This creates a floating-point to unsigned integer conversion instruction that converts a floating-point value to an unsigned integer.
/// The input value must be a floating-point type, and the target type must be an integer type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [f32_ty])
///
/// let fval = mod.addFunction(fty, "fptoui_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let fptoui = builder.createFPToUI(arg, i32_ty, name="converted")
/// inspect(fptoui, content = "  %converted = fptoui float %0 to i32")
/// assert_true(fptoui.asValueEnum() is CastInst(_))
///
/// let float_val = ctx.getConstFloat(3.14)
/// let int_val = builder.createFPToUI(float_val, i32_ty)
/// inspect(int_val, content = "i32 3")
/// assert_true(int_val.asValueEnum() is ConstantInt(_))
/// ```
pub fn IRBuilder::createFPToUI(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantFP(cf)) => return cf.fptoui(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newFPToUI(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a SIToFP Instruction
///
/// **Note:**
/// 
/// This creates a signed integer to floating-point conversion instruction that converts a signed integer value to a floating-point value.
/// The input value must be an integer type, and the target type must be a floating-point type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "sitofp_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let sitofp = builder.createSIToFP(arg, f32_ty, name="converted")
///
/// inspect(sitofp, content = "  %converted = sitofp i32 %0 to float")
/// ```
pub fn IRBuilder::createSIToFP(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &FPType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.sitofp(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newSIToFP(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a FPToSI Instruction
///
/// **Note:**
/// 
/// This creates a floating-point to signed integer conversion instruction that converts a floating-point value to a signed integer.
/// The input value must be a floating-point type, and the target type must be an integer type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let f32_ty = ctx.getFloatTy()
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32_ty, [f32_ty])
///
/// let fval = mod.addFunction(fty, "fptosi_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let fptosi = builder.createFPToSI(arg, i32_ty, name="converted")
///
/// inspect(fptosi, content = "  %converted = fptosi float %0 to i32")
/// ```
pub fn IRBuilder::createFPToSI(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantFP(cf)) => return cf.fptosi(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newFPToSI(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create an IntToPtr Instruction
///
/// **Note:**
/// 
/// This creates an integer to pointer conversion instruction that converts an integer value to a pointer.
/// The input value must be an integer type, and the target type must be a pointer type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i64_ty = ctx.getInt64Ty()
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(ptr_ty, [i64_ty])
///
/// let fval = mod.addFunction(fty, "inttoptr_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let inttoptr = builder.createIntToPtr(arg, name="ptr")
///
/// inspect(inttoptr, content = "  %ptr = inttoptr i64 %0 to ptr")
/// ```
pub fn IRBuilder::createIntToPtr(
  self : IRBuilder,
  src_val : &Value,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.inttoptr()
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newIntToPtr(src_val, parent, name)
  self.insert(inst)
  inst
}

///| Create a PtrToInt Instruction
///
/// **Note:**
/// 
/// This creates a pointer to integer conversion instruction that converts a pointer value to an integer.
/// The input value must be a pointer type, and the target type must be an integer type.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i64_ty = ctx.getInt64Ty()
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(i64_ty, [ptr_ty])
///
/// let fval = mod.addFunction(fty, "ptrtoint_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let ptrtoint = builder.createPtrToInt(arg, i64_ty, name="int_val")
///
/// inspect(ptrtoint, content = "  %int_val = ptrtoint ptr %0 to i64")
/// ```
pub fn IRBuilder::createPtrToInt(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &IntegerType,
  name~ : String = ""
) -> &Value raise Error {
  // No constant folding for PtrToInt as pointer constants are complex
  let parent = self.getInsertFunction()
  let inst = CastInst::newPtrToInt(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a BitCast Instruction
///
/// **Note:**
/// 
/// This creates a bitcast instruction that converts a value from one type to another without changing the bit representation.
/// The source and destination types must have the same bit width.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let f32_ty = ctx.getFloatTy()
/// let fty = ctx.getFunctionType(f32_ty, [i32_ty])
///
/// let fval = mod.addFunction(fty, "bitcast_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let bitcast = builder.createBitCast(arg, f32_ty, name="bits")
///
/// inspect(bitcast, content = "  %bits = bitcast i32 %0 to float")
/// ```
pub fn IRBuilder::createBitCast(
  self : IRBuilder,
  src_val : &Value,
  dst_ty : &PrimitiveType,
  name~ : String = ""
) -> &Value raise Error {
  match src_val.tryAsConstantEnum() {
    Some(ConstantInt(ci)) => return ci.bitcast(dst_ty)
    Some(ConstantFP(cf)) => return cf.bitcast(dst_ty)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = CastInst::newBitCast(src_val, dst_ty, parent, name)
  self.insert(inst)
  inst
}

///| Create a GetElementPtr Instruction
///
/// **Note:**
/// 
/// This creates a getelementptr instruction that calculates the address of a sub-element of an aggregate object.
/// The pointer must be a pointer type, and all indices must be integer values.
/// When inbounds is true, the result is undefined if the computed address is outside the bounds of the allocated object.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let array_ty = ctx.getArrayType(i32_ty, 10)
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(ctx.getPtrTy(), [ptr_ty])
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
/// ```
pub fn IRBuilder::createGEP(
  self : IRBuilder,
  ptr : &Value,
  pointeeType : &Type,
  indices : Array[&Value],
  name~ : String = "",
  inbounds~ : Bool = false
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let inst = GetElementPtrInst::new(
    ptr, pointeeType, indices, inbounds, parent, name,
  )
  self.insert(inst)
  inst
}

///| Create a Load Instruction
///
/// **Note:**
/// 
/// This loads a value from memory at the specified pointer.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(ctx.getVoidTy(), [])
///
/// let fval = mod.addFunction(fty, "load_demo")
/// let bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(bb)
/// let alloca = builder.createAlloca(i32_ty, name="temp")
/// let load = builder.createLoad(i32_ty, alloca, name="val")
///
/// inspect(load, content = "  %val = load i32, ptr %temp, align 4")
/// ```
pub fn IRBuilder::createLoad(
  self : IRBuilder,
  load_ty : &Type,
  ptr : &Value,
  isVolatile~ : Bool = false,
  atomicOrdering~ : AtomicOrdering = NotAtomic,
  name~ : String = ""
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let inst = LoadInst::new(
    load_ty, ptr, isVolatile, atomicOrdering, parent, name,
  )
  self.insert(inst)
  inst
}

///| Create a Store Instruction
///
/// **Note:**
/// 
/// This stores a value into memory at the specified pointer.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(ctx.getVoidTy(), [])
///
/// let fval = mod.addFunction(fty, "store_demo")
/// let bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(bb)
/// let alloca = builder.createAlloca(i32_ty, name="temp")
/// let const_val = ctx.getConstInt32(42)
/// let store = builder.createStore(const_val, alloca)
///
/// inspect(store, content = "  store i32 42, ptr %temp, align 4")
/// ```
pub fn IRBuilder::createStore(
  self : IRBuilder,
  value : &Value,
  ptr : &Value,
  isVolatile~ : Bool = false,
  atomicOrdering~ : AtomicOrdering = NotAtomic
) -> &Instruction raise Error {
  let parent = self.getInsertFunction()
  let inst = StoreInst::new(value, ptr, isVolatile, atomicOrdering, parent)
  self.insert(inst)
  inst
}

///| Create an Unconditional Branch Instruction
///
/// **Note:**
/// 
/// This creates an unconditional branch instruction that transfers control to the specified basic block.
/// The destination must be a valid basic block.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let void_ty = ctx.getVoidTy()
/// let fty = ctx.getFunctionType(void_ty, [])
///
/// let fval = mod.addFunction(fty, "br_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let target_bb = fval.addBasicBlock(name="target")
///
/// builder.setInsertPoint(entry_bb)
/// let br = builder.createBr(target_bb)
///
/// inspect(br, content = "  br label %target")
/// ```
pub fn IRBuilder::createBr(
  self : Self,
  dst : BasicBlock
) -> &Instruction raise Error {
  let parent = self.getInsertFunction()
  let inst = BranchInst::newUnconditional(dst, parent)
  self.insert(inst)
  inst
}

///| Create a Conditional Branch Instruction
///
/// **Note:**
/// 
/// This creates a conditional branch instruction that transfers control to one of two basic blocks based on a boolean condition.
/// The condition must be an i1 (boolean) type, and both destinations must be valid basic blocks.
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
/// let fval = mod.addFunction(fty, "cond_br_demo")
/// let entry_bb = fval.addBasicBlock(name="entry")
/// let true_bb = fval.addBasicBlock(name="true_branch")
/// let false_bb = fval.addBasicBlock(name="false_branch")
/// let cond = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(entry_bb)
/// let cond_br = builder.createCondBr(cond, true_bb, false_bb)
///
/// inspect(cond_br, content = "  br i1 %0, label %true_branch, label %false_branch")
/// ```
pub fn IRBuilder::createCondBr(
  self : Self,
  cond : &Value,
  true_dst : BasicBlock,
  false_dst : BasicBlock
) -> &Instruction raise Error {
  let parent = self.getInsertFunction()
  let inst = BranchInst::newConditional(cond, true_dst, false_dst, parent)
  self.insert(inst)
  inst
}

///| Create a Select Instruction
///
/// **Note:**
/// 
/// This creates a select instruction that chooses between two values based on a boolean condition.
/// The condition must be an i1 (boolean) type, and both values must have the same type.
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
/// ```
pub fn IRBuilder::createSelect(
  self : IRBuilder,
  condition : &Value,
  trueValue : &Value,
  falseValue : &Value,
  name~ : String = ""
) -> &Value raise Error {
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
  let inst = SelectInst::new(condition, trueValue, falseValue, parent, name)
  self.insert(inst)
  inst
}

///| Create a Switch Instruction
///
/// **Note:**
/// 
/// This creates a switch instruction that transfers control to one of many basic blocks based on an integer value.
/// The value must be an integer type, and numCases specifies the expected number of cases.
/// Use `SwitchInst::addCase` to add individual cases after creation.
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
/// let default_bb = fval.addBasicBlock(name="default")
/// let value = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(entry_bb)
/// let switch = builder.createSwitch(value, default_bb)
/// let case_val = ctx.getConstInt32(42)
/// switch.addCase(case_val, case1_bb)
///
/// let expect = 
///   #|  switch i32 %0, label %default [
///   #|    i32 42, label %case1
///   #|  ]
///
/// inspect(switch, content = expect)
/// ```
pub fn IRBuilder::createSwitch(
  self : IRBuilder,
  cond : &Value,
  defaultDest : BasicBlock
) -> SwitchInst raise Error {
  let parent = self.getInsertFunction()
  let inst = SwitchInst::new(cond, defaultDest, parent)
  self.insert(inst)
  inst
}

///| Create a PHI Instruction
///
/// **Note:**
/// 
/// This creates a PHI node instruction that selects a value based on the predecessor basic block.
/// The type specifies the type of the PHI node's result value.
/// Use `PHINode::addIncoming` to add incoming values and their corresponding basic blocks.
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
/// ```
pub fn IRBuilder::createPHI(
  self : IRBuilder,
  ty : &Type,
  name~ : String = ""
) -> PHINode raise Error {
  let parent = self.getInsertFunction()
  let phi = PHINode::new(ty, parent, name)
  self.insert(phi)
  phi
}

///| Create a Call Instruction
///
/// **Note:**
/// 
/// This creates a call instruction that invokes a function with the specified arguments.
/// The function must be a valid Function object, and the arguments must match the function's parameter types.
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
/// ```
pub fn IRBuilder::createCall(
  self : IRBuilder,
  callee : Function,
  args : Array[&Value],
  name~ : String = ""
) -> CallInst raise Error {
  let parent = self.getInsertFunction()
  let inst = CallInst::new(callee, args, parent, name)
  self.insert(inst)
  inst
}

///| Create an ExtractValue Instruction
///
/// **Note:**
/// 
/// This creates an extractvalue instruction that extracts a value from an aggregate (struct or array) at the specified index.
/// The aggregate must be an aggregate type, and the index must be valid for the aggregate type.
///
/// ```moonbit skip
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
/// let extract = builder.createExtractValue(aggregate, 0, name="field")
///
/// inspect(extract, content = "  %field = extractvalue { i32, i32 } %0, 0")
/// ```
pub fn IRBuilder::createExtractValue(
  self : IRBuilder,
  aggregate : &Value,
  indices : Array[Int],
  name~ : String = ""
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let inst = ExtractValueInst::new(aggregate, indices, parent, name)
  self.insert(inst)
  inst
}

///| Create an InsertValue Instruction
///
/// **Note:**
/// 
/// This creates an insertvalue instruction that inserts a value into an aggregate (struct or array) at the specified index.
/// The aggregate must be an aggregate type, and the value type must match the element type at the given index.
///
/// ```moonbit skip
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
/// let insert = builder.createInsertValue(aggregate, new_value, 1, name="updated")
///
/// inspect(insert, content = "  %updated = insertvalue { i32, i32 } %0, i32 %1, 1")
/// ```
pub fn IRBuilder::createInsertValue(
  self : IRBuilder,
  aggregate : &Value,
  value : &Value,
  indices : Array[Int],
  name~ : String = ""
) -> &Value raise Error {
  let parent = self.getInsertFunction()
  let inst = InsertValueInst::new(aggregate, value, indices, parent, name)
  self.insert(inst)
  inst
}

///| Create a Malloc Instruction
///
/// **Note:**
/// 
/// This creates a malloc instruction that allocates memory for a single instance of the specified type.
/// The type must not be an abstract type. The result is a pointer to the allocated memory.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(ptr_ty, [])
///
/// let fval = mod.addFunction(fty, "malloc_demo")
/// let bb = fval.addBasicBlock(name="entry")
///
/// builder.setInsertPoint(bb)
/// let malloc = builder.createMalloc(i32_ty, name="ptr")
///
/// inspect(malloc, content = "  %ptr = tail call ptr @malloc(i32 ptrtoint (ptr getelementptr (i32, ptr null, i32 1) to i32))")
/// ```
//pub fn IRBuilder::createMalloc(
//  self : Self,
//  ty : &Type,
//  name~ : String = "",
//  loc~ : SourceLoc = _
//) -> CallInst raise {

///| Create a Free Instruction
///
/// **Note:**
/// 
/// This creates a free instruction that deallocates memory previously allocated by malloc.
/// The pointer must be a pointer type and should point to memory allocated by malloc.
///
/// ```moonbit skip
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let void_ty = ctx.getVoidTy()
/// let ptr_ty = ctx.getPtrTy()
/// let fty = ctx.getFunctionType(void_ty, [ptr_ty])
///
/// let fval = mod.addFunction(fty, "free_demo")
/// let bb = fval.addBasicBlock(name="entry")
/// let ptr_arg = fval.getArg(0).unwrap()
///
/// builder.setInsertPoint(bb)
/// let free = builder.createFree(ptr_arg)
///
/// inspect(free, content = "  tail call void @free(ptr %0)")
/// ```
//pub fn IRBuilder::createFree(
//  self : Self,
//  ptr : &Value,
//  loc~ : SourceLoc = _
//) -> CallInst raise {
