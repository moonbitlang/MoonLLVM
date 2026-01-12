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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let f32_ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///   let fval = mod.addFunction(fty, "fcmp_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let oeq_cmp = builder.createFCmp(OEQ, arg1, arg2, name="oeq_cmp")
///   inspect(oeq_cmp, content="  %oeq_cmp = fcmp oeq float %0, %1")
///   assert_true(oeq_cmp.asValueEnum() is FCmpInst(_))
///   let ogt_cmp = builder.createFCmp(OGT, arg1, arg2, name="ogt_cmp")
///   inspect(ogt_cmp, content="  %ogt_cmp = fcmp ogt float %0, %1")
///   let olt_cmp = builder.createFCmp(OLT, arg1, arg2, name="olt_cmp")
///   inspect(olt_cmp, content="  %olt_cmp = fcmp olt float %0, %1")
///   let uno_cmp = builder.createFCmp(UNO, arg1, arg2, name="uno_cmp")
///   inspect(uno_cmp, content="  %uno_cmp = fcmp uno float %0, %1")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let f32_ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///   let fval = mod.addFunction(fty, "fcmp_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let oeq_cmp = builder.createFCmp(OEQ, arg1, arg2)
///   inspect(oeq_cmp.getValueRepr(), content="%2")
///   oeq_cmp.setName("oeq_cmp")
///   inspect(oeq_cmp.getValueRepr(), content="%oeq_cmp")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let f32_ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///   let fval = mod.addFunction(fty, "fcmp_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let oeq_cmp = builder.createFCmp(OEQ, arg1, arg2)
///   inspect(oeq_cmp.getName(), content="None")
///   oeq_cmp.setName("oeq_cmp")
///   inspect(oeq_cmp.getName(), content="Some(\"oeq_cmp\")")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let f32_ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType(f32_ty, [f32_ty, f32_ty])
///   let fval = mod.addFunction(fty, "fcmp_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg1 = fval.getArg(0).unwrap()
///   let arg2 = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let oeq_cmp = builder.createFCmp(OEQ, arg1, arg2)
///   inspect(oeq_cmp.getName(), content="None")
///   oeq_cmp.setName("oeq_cmp")
///   inspect(oeq_cmp.getName(), content="Some(\"oeq_cmp\")")
/// }
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


