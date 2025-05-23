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
pub fn IRBuilder::setInsertPoint[T : InsertPoint](
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
    Some(insertPt) => inst.insertAfter!(insertPt)
    None => self.bb.unwrap().head = Some(inst)
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

pub fn IRBuilder::createAdd(
  self: IRBuilder, 
  lhs: &Value, rhs:&Value,
  name~:String = "",
  has_nsw~: Bool = false,
  has_nuw~: Bool = false
) -> &Value!Error {
  match (lhs.tryAsConstantEnum(), rhs.tryAsConstantEnum()) {
    (Some(ConstantInt(lhs)), Some(ConstantInt(rhs))) => return lhs.add!(rhs)
    (Some(ConstantUInt(lhs)), Some(ConstantUInt(rhs))) => return lhs.add!(rhs)
    _ => ()
  }
  let parent = self.getInsertFunction()
  let inst = BinaryInstruction::newStandardOp!(
    BinaryOps::Add, lhs, rhs, parent, name, has_nsw, has_nuw
  )
  self.insert!(inst)
  inst
}

pub fn IRBuilder::createNSWAdd(
  self: IRBuilder, 
  lhs: &Value, rhs:&Value,
  name~:String = ""
) -> &Value!Error {
  self.createAdd(
    lhs, rhs, name~, has_nsw=true, has_nuw=false
  )
}

pub fn IRBuilder::createNUWAdd(
  self: IRBuilder, 
  lhs: &Value, rhs:&Value,
  name~:String = ""
) -> &Value!Error {
  self.createAdd(
    lhs, rhs, name~, has_nsw=false, has_nuw=true
  )
}
