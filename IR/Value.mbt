// =======================================================
// Value
// =======================================================

///|
pub enum ValueEnum {

  // ======= Constant Values =======
  /// The following two is global values.
  Function(Function)
  GlobalVariable(GlobalVariable)
  //GlobalIFunc(GlobalIFunc)

  /// Base class for constants with no operands.
  ///
  /// These constants have no operands; they represent their data directly.
  /// Since they can be in use by unrelated modules (and are never based on
  /// GlobalValues), it never makes sense to RAUW them.
  ///
  /// These do not have use lists. It is illegal to inspect the uses. These behave
  /// as if they have no uses (i.e. use_empty() is always true).
  ConstantInt(ConstantInt)
  ConstantFP(ConstantFP)
  ConstantPointerNull(ConstantPointerNull)
  //ConstantAggregateZero(ConstantAggregateZero)
  //ConstantAggregate(ConstantAggregate)
  ConstantArray(ConstantArray)
  ConstantVector(ConstantVector)
  ConstantStruct(ConstantStruct)
  //ConstantTokenNone(ConstantTokenNone)
  //UndefValue(UndefValue)
  //PoisonValue(PoisonValue)
  //
  //BlockAddress(BlockAddress)

  // =========
  Argument(Argument)
  BasicBlock(BasicBlock)
  // MetadataAsValue(MetadataAsValue)

  // ======= Instruction Values =======
  // ------- Unary Instruction
  AllocaInst(AllocaInst)
  LoadInst(LoadInst)
  ExtractValueInst(ExtractValueInst)
  // FreezeInst(FreezeInst)
  CastInst(CastInst)
  BinaryInst(BinaryInst)
  ICmpInst(ICmpInst)
  FCmpInst(FCmpInst)
  StoreInst(StoreInst)
  GetElementPtrInst(GetElementPtrInst)
  SelectInst(SelectInst)
  //ExtractElementInst(ExtractElementInst)
  InsertValueInst(InsertValueInst)
  //InsertElementInst(InsertElementInst)
  //ShuffleVectorInst(ShuffleVectorInst)
  PHINode(PHINode)
  ReturnInst(ReturnInst)
  BranchInst(BranchInst)
  SwitchInst(SwitchInst)
  CallInst(CallInst)
  //FenceInst(FenceInst)
  //AtomicCmpXchgInst(AtomicCmpXchgInst)
  //AtomicRMWInst(AtomicRMWInst)

  // ======= Not Plan To Support =======
  //VAArgInst(VAArgInst)
  //InvokeInst(InvokeInst)
  //CallBrInst(CallBrInst)
  //IndirectBrInst(IndirectBrInst)
  //ResumeInst(ResumeInst)
  //CatchSwitchInst(CatchSwitchInst)
  //CatchReturnInst(CatchReturnInst)
  //CleanupReturnInst(CleanupReturnInst)
  //UnreachableInst(UnreachableInst)
  //LandingPadInst(LandingPadInst)
  //InlineAsm(InlineAsm)
}

///|
pub fn ValueEnum::tryAsConstantEnum(self : ValueEnum) -> ConstantEnum? {
  match self {
    ConstantInt(c) => ConstantInt(c) |> Some
    ConstantFP(c) => ConstantFP(c) |> Some
    ConstantPointerNull(c) => ConstantPointerNull(c) |> Some
    ConstantArray(c) => ConstantArray(c) |> Some
    ConstantVector(c) => ConstantVector(c) |> Some
    ConstantStruct(c) => ConstantStruct(c) |> Some
    _ => None
  }
}

///|
pub fn ValueEnum::tryAsUserEnum(self : ValueEnum) -> UserEnum? {
  match self {
    LoadInst(c) => LoadInst(c) |> Some
    //VAArgInst(c) => VAArgInst(c) |> Some
    ExtractValueInst(c) => ExtractValueInst(c) |> Some
    //FreezeInst(c) => FreezeInst(c) |> Some
    CastInst(c) => CastInst(c) |> Some
    BinaryInst(b) => BinaryInst(b) |> Some
    ICmpInst(c) => ICmpInst(c) |> Some
    FCmpInst(c) => FCmpInst(c) |> Some
    StoreInst(s) => StoreInst(s) |> Some
    GetElementPtrInst(g) => GetElementPtrInst(g) |> Some
    SelectInst(s) => SelectInst(s) |> Some
    InsertValueInst(i) => InsertValueInst(i) |> Some
    PHINode(p) => PHINode(p) |> Some
    ReturnInst(r) => ReturnInst(r) |> Some
    BranchInst(b) => BranchInst(b) |> Some
    SwitchInst(s) => SwitchInst(s) |> Some
    CallInst(c) => CallInst(c) |> Some
    _ => None
  }
}

///|
pub fn ValueEnum::tryAsInstEnum(self : ValueEnum) -> InstEnum? {
  match self {
    AllocaInst(c) => AllocaInst(c) |> Some
    LoadInst(c) => LoadInst(c) |> Some
    //VAArgInst(c) => VAArgInst(c) |> Some
    ExtractValueInst(c) => ExtractValueInst(c) |> Some
    //FreezeInst(c) => FreezeInst(c) |> Some
    CastInst(c) => CastInst(c) |> Some
    BinaryInst(b) => BinaryInst(b) |> Some
    ICmpInst(c) => ICmpInst(c) |> Some
    FCmpInst(c) => FCmpInst(c) |> Some
    StoreInst(s) => StoreInst(s) |> Some
    GetElementPtrInst(g) => GetElementPtrInst(g) |> Some
    SelectInst(s) => SelectInst(s) |> Some
    InsertValueInst(i) => InsertValueInst(i) |> Some
    PHINode(p) => PHINode(p) |> Some
    ReturnInst(r) => ReturnInst(r) |> Some
    BranchInst(b) => BranchInst(b) |> Some
    SwitchInst(s) => SwitchInst(s) |> Some
    CallInst(c) => CallInst(c) |> Some
    _ => None
  }
}

///|
pub trait Value: Show {
  getValueBase(Self) -> ValueBase
  asValueEnum(Self) -> ValueEnum

  // All values are typed, get the type of this value.
  getType(Self) -> &Type = _

  // All values hold a context through their type.
  getContext(Self) -> Context = _
  //getValueName(Self) -> String? = _

  addUser(Self, user : &User) -> Unit = _

  // Get the string representation of the value.
  // If the value is named value, use name or its slot as the representation.
  // If the value is constant, use its value as the representation.
  getValueRepr(Self) -> String

  /// Change the name of the value.
  ///
  /// Choose a new unique name if the provided name is taken.
  ///
  /// ** Parameters **
  ///
  /// - `name`: The new name; if name is "", the value's name will be removed.
  //setName(Self, name: String) -> Unit raise LLVMValueError = _
  getName(Self) -> String?
  setName(Self, name : String) -> Unit raise LLVMValueError
  removeName(Self) -> Unit raise LLVMValueError
  getNameOrSlot(Self) -> Either[String, UInt64]?
  getNameOrSlotStr(Self) -> String = _

  /// Change all uses of this to point to a new Value.
  ///
  /// Go through the uses list for this definition and make each use point to
  /// "V" instead of "this".  After this completes, 'this's use list is
  /// guaranteed to be empty.
  ///
  /// It's equivalent to: LLVM: replaceAllUsesWith(this, V)
  /// Please note that in LLVM, this API is `replaceAllUsesWith`, while here
  /// is `replaceAllUsersWith`.
  replaceAllUsersWith(Self, other : &Value) -> Unit = _
  getUsers(Self) -> Array[&User]? = _

  // It's equivalent to: LLVM: use_empty
  // Please note that in LLVM, this API is `use_empty`, while here
  // is `user_empty`.
  user_empty(Self) -> Bool = _
  tryAsConstant(Self) -> &Constant? = _
  tryAsConstantEnum(Self) -> ConstantEnum? = _
  tryAsUser(Self) -> &User? = _
  tryAsUserEnum(Self) -> UserEnum? = _
  tryAsInst(Self) -> &Instruction? = _
  tryAsInstEnum(Self) -> InstEnum? = _
}

///|
impl Eq for &Value with op_equal(self, other) {
  self.getValueBase() == other.getValueBase()
}

///|
impl Value with getType(self) {
  self.getValueBase().vty
}

///|
impl Value with getContext(self) {
  self.getValueBase().vty.getContext()
}

///|
impl Value with addUser(self, user) {
  self.getValueBase().users.push(user)
}

///|
impl Value with getNameOrSlotStr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => name
    Some(Right(slot)) => slot.to_string()
    None => "<badref>"
  }
}

///|
impl Value with replaceAllUsersWith(self, other : &Value) {
  let users = match self.getUsers() {
    None => return
    Some(users) => users
  }
  for user in users {
    let operands = user.getOperands()
    for i in 0..<operands.length() {
      if operands[i] == self {
        user.getUserBase().operands[i] = other
      }
    }
  }
}

///|
impl Value with getUsers(self) {
  if self.tryAsConstant() is Some(_) {
    None
  } else {
    Some(self.getValueBase().users)
  }
}

///|
impl Value with user_empty(self) {
  match self.getUsers() {
    Some(users) => users.is_empty()
    None => false // if self is constant, it `users` is None
    // but we don't think constant's users is empty.
  }
}

///|
impl Value with tryAsConstant(self) {
  match self.asValueEnum() {
    ConstantInt(c) => Some((c : &Constant))
    ConstantFP(c) => Some(c)
    ConstantPointerNull(c) => Some(c)
    ConstantArray(c) => Some(c)
    ConstantVector(c) => Some(c)
    ConstantStruct(c) => Some(c)
    _ => None
  }
}

///|
impl Value with tryAsConstantEnum(self) {
  match self.asValueEnum() {
    ConstantInt(c) => Some(ConstantInt(c))
    ConstantFP(c) => Some(ConstantFP(c))
    ConstantPointerNull(c) => Some(ConstantPointerNull(c))
    ConstantArray(c) => Some(ConstantArray(c))
    ConstantVector(c) => Some(ConstantVector(c))
    ConstantStruct(c) => Some(ConstantStruct(c))
    _ => None
  }
}

///|
impl Value with tryAsUser(self) {
  match self.asValueEnum() {
    LoadInst(c) => Some((c : &User))
    //VAArgInst(c) => Some(VAArgInst(c))
    ExtractValueInst(c) => Some(c)
    //FreezeInst(c) => Some(FreezeInst(c))
    CastInst(c) => Some(c)
    BinaryInst(b) => Some(b)
    ICmpInst(c) => Some(c)
    FCmpInst(c) => Some(c)
    StoreInst(s) => Some(s)
    GetElementPtrInst(g) => Some(g)
    SelectInst(s) => Some(s)
    InsertValueInst(i) => Some(i)
    PHINode(p) => Some(p)
    ReturnInst(r) => Some(r)
    BranchInst(b) => Some(b)
    SwitchInst(s) => Some(s)
    CallInst(c) => Some(c)
    _ => None
  }
}

///|
impl Value with tryAsUserEnum(self) {
  match self.asValueEnum() {
    LoadInst(c) => Some(LoadInst(c))
    //VAArgInst(c) => Some(VAArgInst(c))
    ExtractValueInst(c) => Some(ExtractValueInst(c))
    //FreezeInst(c) => Some(FreezeInst(c))
    CastInst(c) => Some(CastInst(c))
    BinaryInst(b) => Some(BinaryInst(b))
    ICmpInst(c) => Some(ICmpInst(c))
    FCmpInst(c) => Some(FCmpInst(c))
    StoreInst(s) => Some(StoreInst(s))
    GetElementPtrInst(g) => Some(GetElementPtrInst(g))
    SelectInst(s) => Some(SelectInst(s))
    InsertValueInst(i) => Some(InsertValueInst(i))
    PHINode(p) => Some(PHINode(p))
    ReturnInst(r) => Some(ReturnInst(r))
    BranchInst(b) => Some(BranchInst(b))
    SwitchInst(s) => Some(SwitchInst(s))
    CallInst(c) => Some(CallInst(c))
    _ => None
  }
}

///|
impl Value with tryAsInst(self) {
  match self.asValueEnum() {
    AllocaInst(c) => Some((c : &Instruction))
    LoadInst(c) => Some(c)
    //VAArgInst(c) => Some(VAArgInst(c))
    ExtractValueInst(c) => Some(c)
    //FreezeInst(c) => Some(FreezeInst(c))
    CastInst(c) => Some(c)
    BinaryInst(b) => Some(b)
    ICmpInst(c) => Some(c)
    FCmpInst(c) => Some(c)
    StoreInst(s) => Some(s)
    GetElementPtrInst(g) => Some(g)
    SelectInst(s) => Some(s)
    InsertValueInst(i) => Some(i)
    PHINode(p) => Some(p)
    ReturnInst(r) => Some(r)
    BranchInst(b) => Some(b)
    SwitchInst(s) => Some(s)
    CallInst(c) => Some(c)
    _ => None
  }
}

///|
impl Value with tryAsInstEnum(self) {
  match self.asValueEnum() {
    AllocaInst(c) => Some(AllocaInst(c))
    LoadInst(c) => Some(LoadInst(c))
    //VAArgInst(c) => Some(VAArgInst(c))
    ExtractValueInst(c) => Some(ExtractValueInst(c))
    //FreezeInst(c) => Some(FreezeInst(c))
    CastInst(c) => Some(CastInst(c))
    BinaryInst(b) => Some(BinaryInst(b))
    ICmpInst(c) => Some(ICmpInst(c))
    FCmpInst(c) => Some(FCmpInst(c))
    StoreInst(s) => Some(StoreInst(s))
    GetElementPtrInst(g) => Some(GetElementPtrInst(g))
    SelectInst(s) => Some(SelectInst(s))
    InsertValueInst(i) => Some(InsertValueInst(i))
    PHINode(p) => Some(PHINode(p))
    ReturnInst(r) => Some(ReturnInst(r))
    BranchInst(b) => Some(BranchInst(b))
    SwitchInst(s) => Some(SwitchInst(s))
    CallInst(c) => Some(CallInst(c))
    _ => None
  }
}

///|
impl Hash for &Value with hash_combine(self, hasher) {
  hasher.combine_uint64(self.getValueBase().uid)
}

///|
/// 
/// - `users`: means the values which use this value, all values can get users list
/// from `getUsers()`
/// - `uses`: means the values used by this value, not all values have `uses` list.
/// for example, constant values, function arguments, have no `uses` list.
///
/// For example: %2 = add i32 %0, %1
///
/// users of %2 : []
/// uses of %2 : [%0, %1]
///
/// users of %0 : [%2]
/// uses of %0 : []
///
/// users of %1 : [%2]
/// uses of %1 : []
struct ValueBase {
  uid : UInt64
  vty : &Type
  users : Array[&User]
} derive(Eq, Show)

///|
//fn ValueBase::new(vty : &Type, users~ : Array[&Value] = []) -> ValueBase {
//  let uid = valueUIDAssigner.assign()
//  ValueBase::{ vty, users, uid }
//}

// =======================================================
// NamedValue
// =======================================================

pub trait NamedValue: Value {}

// =======================================================
// User
// =======================================================

///|
struct UserBase {
  operands : Array[&Value]
} derive(Eq)

///|
//pub fn UserBase::new(operands~ : Array[&Value] = []) -> UserBase {
//  let name = match name {
//    "" => None
//    name => Some(name)
//  }
//  UserBase::{ name, operands }
//}

///|
pub trait User: Value {
  asUserEnum(Self) -> UserEnum
  getUserBase(Self) -> UserBase
  getOperands(Self) -> Array[&Value] = _
  getOperand(Self, index : Int) -> &Value? = _
  getNumOperands(Self) -> Int = _
}

///|
pub impl Eq for &User with op_equal(self, other) {
  self.getValueBase().uid == other.getValueBase().uid
}

///|
impl User with getOperands(self) {
  self.getUserBase().operands
}

///|
impl User with getOperand(self, index : Int) {
  let operands = self.getOperands()
  guard index >= 0 && index < operands.length() else { return None }
  Some(operands[index])
}

///|
impl User with getNumOperands(self) {
  self.getOperands().length()
}

///|
pub enum UserEnum {
  //Instruction(Instruction)
  LoadInst(LoadInst)
  //VAArgInst(VAArgInst)
  ExtractValueInst(ExtractValueInst)
  //FreezeInst(FreezeInst)
  CastInst(CastInst)
  BinaryInst(BinaryInst)
  ICmpInst(ICmpInst)
  FCmpInst(FCmpInst)
  StoreInst(StoreInst)
  GetElementPtrInst(GetElementPtrInst)
  SelectInst(SelectInst)
  InsertValueInst(InsertValueInst)
  PHINode(PHINode)
  ReturnInst(ReturnInst)
  BranchInst(BranchInst)
  SwitchInst(SwitchInst)
  CallInst(CallInst)
}

///|
pub fn UserEnum::asUserClass(self : Self) -> &User {
  match self {
    LoadInst(l) => l as &User
    ExtractValueInst(e) => e
    BinaryInst(b) => b
    ICmpInst(c) => c
    FCmpInst(c) => c
    StoreInst(s) => s
    CastInst(c) => c
    GetElementPtrInst(g) => g
    SelectInst(s) => s
    InsertValueInst(i) => i
    PHINode(p) => p
    ReturnInst(r) => r
    BranchInst(b) => b
    SwitchInst(s) => s
    CallInst(c) => c
  }
}

// =======================================================
// Instruction
// =======================================================

///|
pub struct InstBase {
  priv bb : Ref[BasicBlock?]
  priv next : Ref[&Instruction?]
  priv prev : Ref[&Instruction?]
}

///|
//pub fn InstBase::new(
//  bb~ : BasicBlock? = None,
//  next~ : &Instruction? = None,
//  prev~ : &Instruction? = None,
//) -> InstBase {
//  InstBase::{ bb, next, prev }
//}

///|
pub trait Instruction: Value {
  getInstBase(Self) -> InstBase
  asInstEnum(Self) -> InstEnum
  getParent(Self) -> Function
  getBasicBlock(Self) -> BasicBlock? = _
  getInstName(Self) -> String? = _
  isIndependent(Self) -> Bool = _
  next(Self) -> &Instruction? = _
  prev(Self) -> &Instruction? = _
  insertAfter(Self, &Instruction) -> Unit raise LLVMValueError = _
  insertBefore(Self, &Instruction) -> Unit raise LLVMValueError = _
  moveBefore(Self, &Instruction) -> Unit = _
  moveAfter(Self, &Instruction) -> Unit = _
  removeFromParent(Self) -> Unit = _
  eraseFromParent(Self) -> Unit = _
}

///|
impl Instruction with getBasicBlock(self) {
  self.getInstBase().bb.val
}

///|
impl Instruction with getInstName(self) {
  match self.asInstEnum() {
    AllocaInst(i) => i.getName()
    LoadInst(i) => i.getName()
    ExtractValueInst(i) => i.getName()
    CastInst(i) => i.getName()
    BinaryInst(i) => i.getName()
    ICmpInst(i) => i.getName()
    FCmpInst(i) => i.getName()
    StoreInst(_) => None
    GetElementPtrInst(i) => i.getName()
    SelectInst(i) => i.getName()
    InsertValueInst(i) => i.getName()
    PHINode(i) => i.getName()
    ReturnInst(_) => None
    BranchInst(_) => None
    SwitchInst(_) => None
    CallInst(i) => i.getName()
  }
}

///|
impl Instruction with isIndependent(self) {
  let bb = self.getBasicBlock()
  let prev = self.prev()
  let next = self.next()
  bb is None && prev is None && next is None
}

///|
impl Instruction with next(self) {
  self.getInstBase().next.val
}

///|
impl Instruction with prev(self) {
  self.getInstBase().prev.val
}

///|
impl Instruction with insertAfter(self, insertPt : &Instruction) {
  guard self.isIndependent() else {
    raise LLVMValueError(
      "Misuse `Instruction::insertAfter`, Only independent instruction can be inserted",
    )
  }
  match insertPt.next() {
    None => {
      insertPt.getInstBase().next.val = Some(self)
      self.getInstBase().prev.val = Some(insertPt)
      self.getInstBase().bb.val = insertPt.getBasicBlock()
    }
    Some(ori_next) => {
      insertPt.getInstBase().next.val = Some(self)
      self.getInstBase().prev.val = Some(insertPt)
      self.getInstBase().next.val = Some(ori_next)
      ori_next.getInstBase().prev.val = Some(self)
      self.getInstBase().bb.val = insertPt.getBasicBlock()
    }
  }
}

///|
impl Instruction with insertBefore(self, insertPt : &Instruction) {
  guard self.isIndependent() else {
    raise LLVMValueError(
      "Misuse `Instruction::insertAfter`, Only independent instruction can be inserted",
    )
  }
  match insertPt.prev() {
    None => {
      insertPt.getInstBase().prev.val = Some(self)
      self.getInstBase().next.val = Some(insertPt)
      self.getInstBase().bb.val = insertPt.getBasicBlock()
    }
    Some(ori_prev) => {
      insertPt.getInstBase().prev.val = Some(self)
      self.getInstBase().next.val = Some(insertPt)
      self.getInstBase().prev.val = Some(ori_prev)
      ori_prev.getInstBase().next.val = Some(self)
      self.getInstBase().bb.val = insertPt.getBasicBlock()
    }
  }
}

///|
impl Instruction with moveBefore(self, insertPt : &Instruction) {
  self.removeFromParent()
  (try? self.insertBefore(insertPt)).unwrap()
}

///|
impl Instruction with moveAfter(self, insertPt : &Instruction) {
  self.removeFromParent()
  (try? self.insertAfter(insertPt)).unwrap()
}

///|
impl Instruction with removeFromParent(self) {
  let bb = match self.getBasicBlock() {
    Some(bb) => bb
    None => return
  }
  match (self.prev(), self.next()) {
    // independent instruction, do nothing.
    (None, None) => ()
    (Some(prev), None) => prev.getInstBase().next.val = None
    // It must be the head of the basic block.
    (None, Some(next)) => bb.head = Some(next)
    (Some(prev), Some(next)) => {
      prev.getInstBase().next.val = Some(next)
      next.getInstBase().prev.val = Some(prev)
    }
  }
  self.getInstBase().bb.val = None
  self.getInstBase().prev.val = None
  self.getInstBase().next.val = None
}

///|
impl Instruction with eraseFromParent(self) {
  self.removeFromParent()
  if self.getInstName() is Some(name) {
    self.getParent().symbols.remove(name)
  }
}

///|
pub enum InstEnum {
  AllocaInst(AllocaInst)
  LoadInst(LoadInst)
  //VAArgInst(VAArgInst)
  ExtractValueInst(ExtractValueInst)
  //FreezeInst(FreezeInst)
  CastInst(CastInst)
  BinaryInst(BinaryInst)
  ICmpInst(ICmpInst)
  FCmpInst(FCmpInst)
  StoreInst(StoreInst)
  GetElementPtrInst(GetElementPtrInst)
  SelectInst(SelectInst)
  InsertValueInst(InsertValueInst)
  PHINode(PHINode)
  ReturnInst(ReturnInst)
  BranchInst(BranchInst)
  SwitchInst(SwitchInst)
  CallInst(CallInst)
}

// =======================================================
// UnaryInst
// =======================================================

///|
pub trait UnaryInst: Instruction {
  asUnaryInstEnum(Self) -> UnaryInstEnum
}

///|
pub enum UnaryInstEnum {
  AllocaInst(AllocaInst)
  LoadInst(LoadInst)
  //VAArgInst(VAArgInst)
  ExtractValueInst(ExtractValueInst)
  //FreezeInst(FreezeInst)
  CastInst(CastInst)
}

// =======================================================
// Constant
// =======================================================

///|
pub enum ConstantEnum {
  ConstantInt(ConstantInt)
  ConstantFP(ConstantFP)
  ConstantPointerNull(ConstantPointerNull)
  ConstantArray(ConstantArray)
  ConstantVector(ConstantVector)
  ConstantStruct(ConstantStruct)
} derive(Eq)

///|
pub trait Constant: Value {
  asConstantEnum(Self) -> ConstantEnum
}

///|
impl Eq for &Constant with op_equal(self, other) {
  self.asConstantEnum() == other.asConstantEnum()
}

// =======================================================
// GlobalValue
// =======================================================

///|
pub trait GlobalValue: Value {
  getGlobalValueBase(Self) -> GlobalValueBase
  asGlobalValueEnum(Self) -> GlobalValueEnum
  getLinkage(Self) -> LinkageTypes = _
  setLinkage(Self, linkage : LinkageTypes) -> Unit = _
}

///|
impl GlobalValue with getLinkage(self) {
  self.getGlobalValueBase().linkage
}

///|
impl GlobalValue with setLinkage(self, linkage : LinkageTypes) {
  self.getGlobalValueBase().linkage = linkage
}

///|
struct GlobalValueBase {
  mut linkage : LinkageTypes
  //visibility: VisibilityTypes
  //unnamed_addr: UnnamedAddr
  //dllStorageClass: DLLStorageClassTypes
  //threadLocal: ThreadLocalTypes
}

///|
pub enum GlobalValueEnum {
  Function(Function)
  GlobalVariable(GlobalVariable)
  //GlobalIFunc(GlobalIFunc)
}

///|
pub(all) enum LinkageTypes {
  /// Externally visible function
  ExternalLinkage
  /// Available for inspection, not emission.
  AvailableExternallyLinkage
  /// Keep one copy of function when linking (inline)
  LinkOnceAnyLinkage
  /// Keep one copy of function when linking,\
  /// but only replaced by something equivalent.
  LinkOnceODRLinkage
  /// Keep one copy of named function when linking (weak)
  WeakAnyLinkage
  /// Keep one copy of named function when linkin,
  /// but only replaced by something equivalent.
  WeakODRLinkage
  /// Special purpose, only applies to global arrays
  AppendingLinkage
  /// Rename collisions when linking (static functions).
  InternalLinkage
  /// Like Internal, but omit from symbol table.
  PrivateLinkage
  /// ExternalWeak linkage description.
  ExternalWeakLinkage
  /// Tentative definitions.
  CommonLinkage
} derive(Eq)

///|
pub impl Show for LinkageTypes with output(self, logger) {
  let s = match self {
    ExternalLinkage => ""
    AvailableExternallyLinkage => "available_externally"
    LinkOnceODRLinkage => "linkonce_odr"
    LinkOnceAnyLinkage => "linkonce"
    WeakAnyLinkage => "weak"
    WeakODRLinkage => "weak_odr"
    AppendingLinkage => "appending"
    InternalLinkage => "internal"
    PrivateLinkage => "private"
    ExternalWeakLinkage => "external_weak"
    CommonLinkage => "common"
  }
  logger.write_string(s)
}

///|
pub(all) enum VisibilityTypes {
  DefaultVisibility
  HiddenVisibility
  ProtectedVisibility
}

///|
pub(all) enum DLLStorageClassTypes {
  DefaultDLLStorageClass
  /// Function to be imported from DLL.
  DLLImportStorageClass
  /// Function to be accessoble from DLL.
  DLLExportStorageClass
}

// =======================================================
// GlobalVariable
// =======================================================

///|
/// GlobalVariable represents a global variable in LLVM IR.
///
/// Global variables are values that are stored in the global address space
/// and can be accessed by any function in the module. They have a type, 
/// an optional initializer, and various attributes like mutability and linkage.
///
/// Example:
/// ```moonbit
/// let ctx = Context::new()
/// let module = ctx.addModule("test")
/// let i32ty = ctx.getInt32Ty()
/// 
/// // Create a mutable global variable with initial value 42
/// let init_val = ctx.getConstInt32(42)
/// let gv = module.addGlobalVariable(i32ty, "my_global", Some(init_val), isConstant=false)
/// inspect(gv, content="@my_global = global i32 42")
/// 
/// // Create an immutable global variable without initializer (will be zero-initialized)
/// let gv2 = module.addGlobalVariable(i32ty, "my_const", None, isConstant=true)
/// inspect(gv2, content="@my_const = constant i32 zeroinitializer")
/// ```
pub struct GlobalVariable {
  // Unique identifier for the global variable
  uid : UInt64

  // Type of the global variable (pointer type)
  vty : PointerType

  // Users of the global variable
  users : Array[&User]

  // Global value base for linkage and other global attributes
  gv_base : GlobalValueBase

  // Module that this global variable belongs to
  parent_module : Module

  // Index of the global variable in the module
  index : UInt

  // Name of the global variable
  priv mut name : String

  // Address space information
  addressSpace : AddressSpace

  // The type of value that this global variable holds
  valueType : &Type

  // Optional initializer value
  mut initializer : &Constant?

  // Whether this global variable is mutable
  mut isConstant : Bool

  // Thread-local storage model (if any)
  mut threadLocalMode : ThreadLocalMode

  // Whether this global variable is externally initialized
  mut isExternallyInitialized : Bool
}

///|
/// Thread-local storage modes for global variables
pub enum ThreadLocalMode {
  NotThreadLocal
  GeneralDynamicTLSModel
  LocalDynamicTLSModel  
  InitialExecTLSModel
  LocalExecTLSModel
} derive(Eq)

///|
impl Show for ThreadLocalMode with output(self, logger) {
  let s = match self {
    NotThreadLocal => ""
    GeneralDynamicTLSModel => "thread_local"
    LocalDynamicTLSModel => "thread_local(localdynamic)"
    InitialExecTLSModel => "thread_local(initialexec)"
    LocalExecTLSModel => "thread_local(localexec)"
  }
  logger.write_string(s)
}

///|
fn GlobalVariable::new(
  valueType : &Type,
  name : String,
  initializer : &Constant?,
  linkage~ : LinkageTypes = ExternalLinkage,
  addressSpace~ : AddressSpace = AddressSpace(0),
  isConstant~ : Bool = false,
  threadLocalMode~ : ThreadLocalMode = NotThreadLocal,
  isExternallyInitialized~ : Bool = false,
  index : UInt,
  parent_module : Module,
) -> GlobalVariable {
  let uid = valueUIDAssigner.assign()
  let ctx = valueType.getContext()
  let vty = ctx.getPtrTy(addressSpace~)
  let users = []
  let gv_base = GlobalValueBase::{ linkage, }
  
  GlobalVariable::{
    uid,
    vty,
    users,
    gv_base,
    parent_module,
    index,
    name,
    addressSpace,
    valueType,
    initializer,
    isConstant,
    threadLocalMode,
    isExternallyInitialized,
  }
}

///|
/// Get the type of value that this global variable holds (not the pointer type).
pub fn GlobalVariable::getValueType(self : GlobalVariable) -> &Type {
  self.valueType
}

///|
/// Get the initializer of this global variable, if any.
pub fn GlobalVariable::getInitializer(self : GlobalVariable) -> &Constant? {
  self.initializer
}

///|
/// Set the initializer of this global variable.
pub fn GlobalVariable::setInitializer(
  self : GlobalVariable, 
  init : &Constant?
) -> Unit {
  self.initializer = init
}

///|
/// Check if this global variable has an initializer.
pub fn GlobalVariable::hasInitializer(self : GlobalVariable) -> Bool {
  self.initializer is Some(_)
}

///|
/// Check if this global variable is constant (immutable).
pub fn GlobalVariable::isConstant(self : GlobalVariable) -> Bool {
  self.isConstant
}

///|
/// Set whether this global variable is constant.
pub fn GlobalVariable::setConstant(self : GlobalVariable, isConstant : Bool) -> Unit {
  self.isConstant = isConstant
}

///|
/// Check if this global variable is mutable.
pub fn GlobalVariable::isMutable(self : GlobalVariable) -> Bool {
  not(self.isConstant)
}

///|
/// Set whether this global variable is mutable.
pub fn GlobalVariable::setMutable(self : GlobalVariable, isMutable : Bool) -> Unit {
  self.isConstant = not(isMutable)
}

///|
/// Get the thread-local storage mode of this global variable.
pub fn GlobalVariable::getThreadLocalMode(self : GlobalVariable) -> ThreadLocalMode {
  self.threadLocalMode
}

///|
/// Set the thread-local storage mode of this global variable.
pub fn GlobalVariable::setThreadLocalMode(
  self : GlobalVariable, 
  mode : ThreadLocalMode
) -> Unit {
  self.threadLocalMode = mode
}

///|
/// Check if this global variable is thread-local.
pub fn GlobalVariable::isThreadLocal(self : GlobalVariable) -> Bool {
  match self.threadLocalMode {
    NotThreadLocal => false
    _ => true
  }
}

///|
/// Check if this global variable is externally initialized.
pub fn GlobalVariable::isExternallyInitialized(self : GlobalVariable) -> Bool {
  self.isExternallyInitialized
}

///|
/// Set whether this global variable is externally initialized.
pub fn GlobalVariable::setExternallyInitialized(
  self : GlobalVariable, 
  isExternal : Bool
) -> Unit {
  self.isExternallyInitialized = isExternal
}

///|
/// Implement Eq for GlobalVariable based on the unique identifier
pub impl Eq for GlobalVariable with op_equal(self, other) {
  self.uid == other.uid
}

///|
/// Get the address space of this global variable.
pub fn GlobalVariable::getAddressSpace(self : GlobalVariable) -> AddressSpace {
  self.addressSpace
}

///|
/// Check if this global variable is defined in this module (has body/initializer).
pub fn GlobalVariable::hasDefinition(self : GlobalVariable) -> Bool {
  self.hasInitializer()
}

///|
/// Check if this global variable is a declaration (no initializer).
pub fn GlobalVariable::isDeclaration(self : GlobalVariable) -> Bool {
  not(self.hasDefinition())
}

// Implement Value trait for GlobalVariable

///|
pub impl Value for GlobalVariable with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for GlobalVariable with asValueEnum(self) {
  GlobalVariable(self)
}

///|
pub impl Value for GlobalVariable with getValueRepr(self) {
  "@\{self.name}"
}

///|
pub impl Value for GlobalVariable with getName(self : GlobalVariable) -> String? {
  Some(self.name)
}

///|
pub impl Value for GlobalVariable with getNameOrSlot(self) {
  Some(Left(self.name))
}

///|
pub impl Value for GlobalVariable with setName(
  self, 
  name
) -> Unit raise LLVMValueError {
  if name.is_empty() {
    raise LLVMValueError("Misuse `GlobalVariable::setName`: name cannot be empty")
  }
  if isInValidName(name) {
    let msg = "Misuse `GlobalVariable::setName`: " +
      "name '\{name}' contains illegal characters, " +
      "only alphanumeric characters and underscores are allowed."
    raise LLVMValueError(msg)
  }
  // Note: We should also check for name conflicts in the module, 
  // but that would require access to the module's symbol table
  self.name = name
}

///|
pub impl Value for GlobalVariable with removeName(_) {
  let msg = "Calling always failed function `GlobalVariable::removeName`. " +
    "remove global variable name is not allowed."
  raise LLVMValueError(msg)
}

// Implement GlobalValue trait for GlobalVariable

///|
pub impl GlobalValue for GlobalVariable with getGlobalValueBase(self) {
  self.gv_base
}

///|
pub impl GlobalValue for GlobalVariable with asGlobalValueEnum(self) {
  GlobalVariable(self)
}

// Implement Show trait for GlobalVariable

///|
pub impl Show for GlobalVariable with output(self, logger) {
  // Format: [@name =] [linkage] [thread_local] [constant|global] type [initializer]
  
  let name_str = "@\{self.name}"
  
  let linkage_str = self.getLinkage().to_string()
  let linkage_part = if linkage_str.is_empty() { "" } else { linkage_str + " " }
  
  let thread_local_str = self.threadLocalMode.to_string()
  let thread_local_part = if thread_local_str.is_empty() { "" } else { thread_local_str + " " }
  
  let constant_or_global = if self.isConstant { "constant" } else { "global" }
  
  let type_str = self.valueType.to_string()
  
  let init_str = match self.initializer {
    Some(init) => " " + init.getValueRepr()
    None => " zeroinitializer"
  }
  
  let externally_init_str = if self.isExternallyInitialized {
    ", externally_initialized"
  } else {
    ""
  }
  
  // Address space (only show if not default)
  let addr_space_str = match self.addressSpace {
    AddressSpace(0) => ""
    AddressSpace(n) => " addrspace(\{n})"
  }
  
  let result = "\{name_str} = \{linkage_part}\{thread_local_part}\{constant_or_global} \{type_str}\{addr_space_str}\{init_str}\{externally_init_str}"
  logger.write_string(result)
}