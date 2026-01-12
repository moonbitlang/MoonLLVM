// =======================================================
// SelectInst
// =======================================================

///|
/// SelectInst represents a select instruction that chooses between two values based on a boolean condition.
///
/// **Note**:
///
/// Use `IRBuilder::createSelect` to create a `SelectInst`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i1_ty = ctx.getInt1Ty()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "select_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let cond = fval.getArg(0).unwrap()
///   let true_val = fval.getArg(1).unwrap()
///   let false_val = fval.getArg(2).unwrap()
///   builder.setInsertPoint(bb)
///   let select = builder.createSelect(cond, true_val, false_val, name="result")
///   inspect(select, content="  %result = select i1 %0, i32 %1, i32 %2")
///   assert_true(select.asValueEnum() is SelectInst(_))
/// }
/// ```
pub struct SelectInst {
  uid : UInt64
  users : Array[&User]
  vty : &Type
  condition : &Value
  trueValue : &Value
  falseValue : &Value
  mut name : String?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn SelectInst::new(
  condition : &Value,
  trueValue : &Value,
  falseValue : &Value,
  parent : Function,
  name~ : String?,
) -> SelectInst {
  let vty = trueValue.getType()
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = SelectInst::{
    uid,
    vty,
    condition,
    trueValue,
    falseValue,
    name,
    parent,
    users: [],
    bb,
    prev,
    next,
  }
  condition.addUser(inst)
  trueValue.addUser(inst)
  falseValue.addUser(inst)
  inst
}

///|
pub fn SelectInst::getCondition(self : SelectInst) -> &Value {
  self.condition
}

///|
pub fn SelectInst::getTrueValue(self : SelectInst) -> &Value {
  self.trueValue
}

///|
pub fn SelectInst::getFalseValue(self : SelectInst) -> &Value {
  self.falseValue
}

///|
pub impl Value for SelectInst with getValueBase(self) {
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
///   let i1_ty = ctx.getInt1Ty()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "select_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let cond = fval.getArg(0).unwrap()
///   let true_val = fval.getArg(1).unwrap()
///   let false_val = fval.getArg(2).unwrap()
///   builder.setInsertPoint(bb)
///   let select = builder.createSelect(cond, true_val, false_val)
///   inspect(select.getValueRepr(), content="%3")
///   select.setName("result")
///   inspect(select.getValueRepr(), content="%result")
/// }
/// ```
pub impl Value for SelectInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for SelectInst with asValueEnum(self) {
  SelectInst(self)
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
///   let i1_ty = ctx.getInt1Ty()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "select_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let cond = fval.getArg(0).unwrap()
///   let true_val = fval.getArg(1).unwrap()
///   let false_val = fval.getArg(2).unwrap()
///   builder.setInsertPoint(bb)
///   let select = builder.createSelect(cond, true_val, false_val)
///   inspect(select.getName(), content="None")
///   select.setName("result")
///   inspect(select.getName(), content="Some(\"result\")")
/// }
/// ```
pub impl Value for SelectInst with getName(self) {
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
///   let i1_ty = ctx.getInt1Ty()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
///   let fval = mod.addFunction(fty, "select_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let cond = fval.getArg(0).unwrap()
///   let true_val = fval.getArg(1).unwrap()
///   let false_val = fval.getArg(2).unwrap()
///   builder.setInsertPoint(bb)
///   let select = builder.createSelect(cond, true_val, false_val)
///   inspect(select.getName(), content="None")
///   select.setName("result")
///   inspect(select.getName(), content="Some(\"result\")")
/// }
/// ```
pub impl Value for SelectInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `SelectInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `SelectInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `SelectInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for SelectInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for SelectInst with getNameOrSlot(self) {
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
pub impl User for SelectInst with asUserEnum(self) {
  SelectInst(self)
}

///|
pub impl User for SelectInst with getUserBase(self) {
  UserBase::{ operands: [self.condition, self.trueValue, self.falseValue] }
}

///|
pub impl Instruction for SelectInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for SelectInst with asInstEnum(self) {
  InstEnum::SelectInst(self)
}

///|
pub impl Instruction for SelectInst with getParent(self) {
  self.parent
}

///|
pub impl Show for SelectInst with output(self, logger) {
  let repr = self.getValueRepr()
  let condition = self.getCondition()
  let trueValue = self.getTrueValue()
  let falseValue = self.getFalseValue()
  let condition_repr = condition.getValueRepr()
  let trueValue_repr = trueValue.getValueRepr()
  let falseValue_repr = falseValue.getValueRepr()
  let condition_ty = condition.getType()
  let value_ty = trueValue.getType()
  logger.write_string(
    "  \{repr} = select \{condition_ty} \{condition_repr}, \{value_ty} \{trueValue_repr}, \{value_ty} \{falseValue_repr}",
  )
}
