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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let struct_ty = ctx.getStructType([i32_ty, i32_ty])
///   let fty = ctx.getFunctionType(struct_ty, [struct_ty, i32_ty])
///   let fval = mod.addFunction(fty, "insertvalue_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let aggregate = fval.getArg(0).unwrap()
///   let new_value = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let insert = builder.createInsertValue(
///     aggregate,
///     new_value,
///     [1],
///     name="updated",
///   )
///   inspect(insert, content="  %updated = insertvalue { i32, i32 } %0, i32 %1, 1")
///   assert_true(insert.asValueEnum() is InsertValueInst(_))
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let struct_ty = ctx.getStructType([i32_ty, i32_ty])
///   let fty = ctx.getFunctionType(struct_ty, [struct_ty, i32_ty])
///   let fval = mod.addFunction(fty, "insertvalue_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let aggregate = fval.getArg(0).unwrap()
///   let new_value = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let insert = builder.createInsertValue(aggregate, new_value, [1])
///   inspect(insert.getValueRepr(), content="%2")
///   insert.setName("updated")
///   inspect(insert.getValueRepr(), content="%updated")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let struct_ty = ctx.getStructType([i32_ty, i32_ty])
///   let fty = ctx.getFunctionType(struct_ty, [struct_ty, i32_ty])
///   let fval = mod.addFunction(fty, "insertvalue_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let aggregate = fval.getArg(0).unwrap()
///   let new_value = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let insert = builder.createInsertValue(aggregate, new_value, [1])
///   inspect(insert.getName(), content="None")
///   insert.setName("updated")
///   inspect(insert.getName(), content="Some(\"updated\")")
/// }
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
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let struct_ty = ctx.getStructType([i32_ty, i32_ty])
///   let fty = ctx.getFunctionType(struct_ty, [struct_ty, i32_ty])
///   let fval = mod.addFunction(fty, "insertvalue_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let aggregate = fval.getArg(0).unwrap()
///   let new_value = fval.getArg(1).unwrap()
///   builder.setInsertPoint(bb)
///   let insert = builder.createInsertValue(aggregate, new_value, [1])
///   inspect(insert.getName(), content="None")
///   insert.setName("updated")
///   inspect(insert.getName(), content="Some(\"updated\")")
/// }
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
