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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let i64_ty = ctx.getInt64Ty()
///   let f32_ty = ctx.getFloatTy()
///   let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///   let fval = mod.addFunction(fty, "cast_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let trunc = builder.createTrunc(arg, i32_ty, name="truncated")
///   inspect(trunc, content="  %truncated = trunc i64 %0 to i32")
///   assert_true(trunc.asValueEnum() is CastInst(_))
///   let zext = builder.createZExt(trunc, i64_ty, name="extended")
///   inspect(zext, content="  %extended = zext i32 %truncated to i64")
///   let bitcast = builder.createBitCast(trunc, f32_ty, name="bits")
///   inspect(bitcast, content="  %bits = bitcast i32 %truncated to float")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let i64_ty = ctx.getInt64Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///   let fval = mod.addFunction(fty, "cast_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let trunc = builder.createTrunc(arg, i32_ty)
///   inspect(trunc.getValueRepr(), content="%1")
///   trunc.setName("truncated")
///   inspect(trunc.getValueRepr(), content="%truncated")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let i64_ty = ctx.getInt64Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///   let fval = mod.addFunction(fty, "cast_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let trunc = builder.createTrunc(arg, i32_ty)
///   inspect(trunc.getName(), content="None")
///   trunc.setName("truncated")
///   inspect(trunc.getName(), content="Some(\"truncated\")")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let i64_ty = ctx.getInt64Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i64_ty])
///   let fval = mod.addFunction(fty, "cast_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let trunc = builder.createTrunc(arg, i32_ty)
///   inspect(trunc.getName(), content="None")
///   trunc.setName("truncated")
///   inspect(trunc.getName(), content="Some(\"truncated\")")
/// }
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


