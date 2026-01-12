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

///|
/// BinaryInst represents a binary operation instruction that performs arithmetic or logical operations on two operands.
///
/// **Note**:
///
/// Use `IRBuilder::createAdd`, `IRBuilder::createSub`, `IRBuilder::createMul`, etc. to create binary instructions.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "binary_ops_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let add = builder.createAdd(arg1, arg2, name="sum")
///   inspect(add, content="  %sum = add i32 %0, %1")
///   assert_true(add.asValueEnum() is BinaryInst(_))
///   let sub = builder.createSub(arg1, arg2, name="diff")
///   inspect(sub, content="  %diff = sub i32 %0, %1")
///   let mul = builder.createMul(arg1, arg2, name="product")
///   inspect(mul, content="  %product = mul i32 %0, %1")
///   let and_result = builder.createAnd(arg1, arg2, name="and_result")
///   inspect(and_result, content="  %and_result = and i32 %0, %1")
///   let or_result = builder.createOr(arg1, arg2, name="or_result")
///   inspect(or_result, content="  %or_result = or i32 %0, %1")
///   let xor_result = builder.createXor(arg1, arg2, name="xor_result")
///   inspect(xor_result, content="  %xor_result = xor i32 %0, %1")
/// }
/// ```
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "binary_ops_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let add = builder.createAdd(arg1, arg2)
///   inspect(add.getValueRepr(), content="%2")
///   add.setName("sum")
///   inspect(add.getValueRepr(), content="%sum")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "binary_ops_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let add = builder.createAdd(arg1, arg2)
///   inspect(add.getName(), content="None")
///   add.setName("sum")
///   inspect(add.getName(), content="Some(\"sum\")")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "binary_ops_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let add = builder.createAdd(arg1, arg2)
///   inspect(add.getName(), content="None")
///   add.setName("sum")
///   inspect(add.getName(), content="Some(\"sum\")")
/// }
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
