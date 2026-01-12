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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let struct_ty = ctx.getStructType([i32_ty, i32_ty])
///   let fty = ctx.getFunctionType(i32_ty, [struct_ty])
///   let fval = mod.addFunction(fty, "extractvalue_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let aggregate = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let extract = builder.createExtractValue(aggregate, [0], name="field")
///   inspect(extract, content="  %field = extractvalue { i32, i32 } %0, 0")
///   assert_true(extract.asValueEnum() is ExtractValueInst(_))
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let struct_ty = ctx.getStructType([i32_ty, i32_ty])
///   let fty = ctx.getFunctionType(i32_ty, [struct_ty])
///   let fval = mod.addFunction(fty, "extractvalue_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let aggregate = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let extract = builder.createExtractValue(aggregate, [0])
///   inspect(extract.getValueRepr(), content="%1")
///   extract.setName("field")
///   inspect(extract.getValueRepr(), content="%field")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let struct_ty = ctx.getStructType([i32_ty, i32_ty])
///   let fty = ctx.getFunctionType(i32_ty, [struct_ty])
///   let fval = mod.addFunction(fty, "extractvalue_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let aggregate = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let extract = builder.createExtractValue(aggregate, [0])
///   inspect(extract.getName(), content="None")
///   extract.setName("field")
///   inspect(extract.getName(), content="Some(\"field\")")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let struct_ty = ctx.getStructType([i32_ty, i32_ty])
///   let fty = ctx.getFunctionType(i32_ty, [struct_ty])
///   let fval = mod.addFunction(fty, "extractvalue_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let aggregate = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let extract = builder.createExtractValue(aggregate, [0])
///   inspect(extract.getName(), content="None")
///   extract.setName("field")
///   inspect(extract.getName(), content="Some(\"field\")")
/// }
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
