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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "icmp_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let eq_cmp = builder.createICmp(EQ, arg1, arg2, name="eq_cmp")
///   inspect(eq_cmp, content="  %eq_cmp = icmp eq i32 %0, %1")
///   assert_true(eq_cmp.asValueEnum() is ICmpInst(_))
///   let ne_cmp = builder.createICmp(NE, arg1, arg2, name="ne_cmp")
///   inspect(ne_cmp, content="  %ne_cmp = icmp ne i32 %0, %1")
///   let sgt_cmp = builder.createICmp(SGT, arg1, arg2, name="sgt_cmp")
///   inspect(sgt_cmp, content="  %sgt_cmp = icmp sgt i32 %0, %1")
///   let ugt_cmp = builder.createICmp(UGT, arg1, arg2, name="ugt_cmp")
///   inspect(ugt_cmp, content="  %ugt_cmp = icmp ugt i32 %0, %1")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "icmp_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let eq_cmp = builder.createICmp(EQ, arg1, arg2)
///   inspect(eq_cmp.getValueRepr(), content="%2")
///   eq_cmp.setName("eq_cmp")
///   inspect(eq_cmp.getValueRepr(), content="%eq_cmp")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "icmp_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let eq_cmp = builder.createICmp(EQ, arg1, arg2)
///   inspect(eq_cmp.getName(), content="None")
///   eq_cmp.setName("eq_cmp")
///   inspect(eq_cmp.getName(), content="Some(\"eq_cmp\")")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "icmp_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let eq_cmp = builder.createICmp(EQ, arg1, arg2)
///   inspect(eq_cmp.getName(), content="None")
///   eq_cmp.setName("eq_cmp")
///   inspect(eq_cmp.getName(), content="Some(\"eq_cmp\")")
/// }
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
pub impl Show for ICmpInst with output(self, logger) {
  let lhs_ty = self.lhs.getType()
  let repr = self.getValueRepr()
  let lhs_repr = self.lhs.getValueRepr()
  let rhs_repr = self.rhs.getValueRepr()
  logger.write_string(
    "  \{repr} = \{self.predicate} \{lhs_ty} \{lhs_repr}, \{rhs_repr}",
  )
}


