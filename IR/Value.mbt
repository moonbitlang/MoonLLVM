// =======================================================
// Value
// =======================================================

///|
pub enum ValueEnum {

  // ======= Constant Values =======
  /// The following two is global values.
  Function(Function)
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
  //ConstantStruct(ConstantStruct)
  //ConstantTokenNone(ConstantTokenNone)
  //UndefValue(UndefValue)
  //PoisonValue(PoisonValue)
  //
  //BlockAddress(BlockAddress)

  // ======= Instruction Values =======
  // ------- Unary Instruction
  AllocaInst(AllocaInst)
  LoadInst(LoadInst)
  // VAArgInst(VAArgInst)
  // ExtractValueInst(ExtractValueInst)
  // FreezeInst(FreezeInst)
  CastInst(CastInst)
  BinaryInstruction(BinaryInstruction)
  CmpInst(CmpInst)
  //StoreInst(StoreInst)
  GetElementPtrInst(GetElementPtrInst)
  //SelectInst(SelectInst)
  //ExtractElementInst(ExtractElementInst)
  //InsertElementInst(InsertElementInst)
  //ShuffleVectorInst(ShuffleVectorInst)
  //PHINode(PHINodeInst)
  ReturnInst(ReturnInst)
  //BranchInst(BranchInst)
  //SwitchInst(SwitchInst)
  //IndirectBrInst(IndirectBrInst)
  //ResumeInst(ResumeInst)
  //CatchSwitchInst(CatchSwitchInst)
  //CatchReturnInst(CatchReturnInst)
  //CleanupReturnInst(CleanupReturnInst)
  //UnreachableInst(UnreachableInst)
  //LandingPadInst(LandingPadInst)
  //FenceInst(FenceInst)
  //AtomicCmpXchgInst(AtomicCmpXchgInst)
  //AtomicRMWInst(AtomicRMWInst)
  //
  // =========
  Argument(Argument)
  BasicBlock(BasicBlock)
  // InlineAsm(InlineAsm)
  // MetadataAsValue(MetadataAsValue)
}

///|
pub fn ValueEnum::tryAsConstantEnum(self : ValueEnum) -> ConstantEnum? {
  match self {
    ConstantInt(c) => ConstantInt(c) |> Some
    ConstantFP(c) => ConstantFP(c) |> Some
    ConstantPointerNull(c) => ConstantPointerNull(c) |> Some
    ConstantArray(c) => ConstantArray(c) |> Some
    ConstantVector(c) => ConstantVector(c) |> Some
    _ => None
  }
}

///|
pub fn ValueEnum::tryAsUserEnum(self : ValueEnum) -> UserEnum? {
  match self {
    AllocaInst(c) => AllocaInst(c) |> Some
    LoadInst(c) => LoadInst(c) |> Some
    //VAArgInst(c) => VAArgInst(c) |> Some
    //ExtractValueInst(c) => ExtractValueInst(c) |> Some
    //FreezeInst(c) => FreezeInst(c) |> Some
    CastInst(c) => CastInst(c) |> Some
    BinaryInstruction(b) => BinaryInstruction(b) |> Some
    CmpInst(c) => CmpInst(c) |> Some
    GetElementPtrInst(g) => GetElementPtrInst(g) |> Some
    ReturnInst(r) => ReturnInst(r) |> Some
    _ => None
  }
}

///|
pub fn ValueEnum::tryAsInstEnum(self : ValueEnum) -> InstEnum? {
  match self {
    AllocaInst(c) => AllocaInst(c) |> Some
    LoadInst(c) => LoadInst(c) |> Some
    //VAArgInst(c) => VAArgInst(c) |> Some
    //ExtractValueInst(c) => ExtractValueInst(c) |> Some
    //FreezeInst(c) => FreezeInst(c) |> Some
    CastInst(c) => CastInst(c) |> Some
    BinaryInstruction(b) => BinaryInstruction(b) |> Some
    CmpInst(c) => CmpInst(c) |> Some
    GetElementPtrInst(g) => GetElementPtrInst(g) |> Some
    ReturnInst(r) => ReturnInst(r) |> Some
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
  getContext(Self) -> LLVMContext = _
  getValueName(Self) -> String? = _

  /// Change the name of the value.
  ///
  /// Choose a new unique name if the provided name is taken.
  ///
  /// ** Parameters **
  ///
  /// - `name`: The new name; if name is "", the value's name will be removed.
  //setName(Self, name: String) -> Unit!LLVMValueError = _

  /// Change all uses of this to point to a new Value.
  ///
  /// Go through the uses list for this definition and make each use point to
  /// "V" instead of "this".  After this completes, 'this's use list is
  /// guaranteed to be empty.
  ///
  /// It's equivalent to: LLVM: replaceAllUsesWith(this, V)
  /// Please note that in LLVM, this API is `replaceAllUsesWith`, while here
  /// is `replaceAllUsersWith`.
  //replaceAllUsersWith(Self, other: &Value) -> Unit = _

  getUsers(Self) -> Array[&Value] = _

  // It's equivalent to: LLVM: use_empty
  // Please note that in LLVM, this API is `use_empty`, while here
  // is `user_empty`.
  user_empty(Self) -> Bool = _
  tryAsConstant(Self) -> &Constant? = _
  tryAsConstantEnum(Self) -> ConstantEnum? = _
  tryAsUserEnum(Self) -> UserEnum? = _
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
impl Value with getValueName(self) {
  match self.asValueEnum() {
    Function(f) => Some(f.name)
    Argument(a) => a.getName()
    BasicBlock(bb) => bb.getName()
    v if v.tryAsConstantEnum() is Some(_) => None
    u if u.tryAsUserEnum() is Some(u) =>
      match u.getUserName() {
        Some(name) => Some(name)
        None => None
      }
    _ => None
  }
}

///|
impl Value with getUsers(self) {
  self.getValueBase().users
}

///|
impl Value with user_empty(self) {
  self.getUsers().is_empty()
}

///|
impl Value with tryAsConstant(self) {
  match self.asValueEnum() {
    ConstantInt(c) => Some((c : &Constant))
    ConstantFP(c) => Some(c)
    ConstantPointerNull(c) => Some(c)
    ConstantArray(c) => Some(c)
    ConstantVector(c) => Some(c)
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
    _ => None
  }
}

impl Value with tryAsUserEnum(self) {
  match self.asValueEnum() {
    AllocaInst(c) => Some(AllocaInst(c))
    LoadInst(c) => Some(LoadInst(c))
    //VAArgInst(c) => Some(VAArgInst(c))
    //ExtractValueInst(c) => Some(ExtractValueInst(c))
    //FreezeInst(c) => Some(FreezeInst(c))
    CastInst(c) => Some(CastInst(c))
    BinaryInstruction(b) => Some(BinaryInstruction(b))
    CmpInst(c) => Some(CmpInst(c))
    GetElementPtrInst(g) => Some(GetElementPtrInst(g))
    ReturnInst(r) => Some(ReturnInst(r))
    _ => None
  }
}

///|
impl Hash for &Value with hash_combine(self, hasher) {
  hasher.combine_uint64(self.getValueBase().oid)
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
  vty : &Type
  users : Array[&Value]
  oid : UInt64
} derive(Eq)

///|
fn ValueBase::new(vty : &Type, users~ : Array[&Value] = []) -> ValueBase {
  let oid = valueOIDAssigner.val
  valueOIDAssigner.val += 1
  ValueBase::{ vty, users, oid }
}

// =======================================================
// User
// =======================================================

///|
pub struct UserBase {
  name : String?
  operands : Array[&Value]
}

///|
pub fn UserBase::new(name : String, operands~ : Array[&Value] = []) -> UserBase {
  let name = match name {
    "" => None
    name => Some(name)
  }
  UserBase::{ name, operands }
}

///|
pub trait User: Value {
  asUserEnum(Self) -> UserEnum
  getUserBase(Self) -> UserBase
  getUserName(Self) -> String? = _
  getOperands(Self) -> Array[&Value] = _
  getOperand(Self, index : Int) -> &Value? = _
}

///|
impl User with getUserName(self) {
  self.getUserBase().name
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
pub enum UserEnum {
  //Instruction(Instruction)
  AllocaInst(AllocaInst)
  LoadInst(LoadInst)
  //VAArgInst(VAArgInst)
  //ExtractValueInst(ExtractValueInst)
  //FreezeInst(FreezeInst)
  CastInst(CastInst)
  BinaryInstruction(BinaryInstruction)
  CmpInst(CmpInst)
  GetElementPtrInst(GetElementPtrInst)
  ReturnInst(ReturnInst)
}

///|
pub fn UserEnum::getUserName(self : UserEnum) -> String? {
  match self {
    AllocaInst(c) => c.getUserName()
    LoadInst(l) => l.getUserName()
    BinaryInstruction(b) => b.getUserName()
    CmpInst(c) => c.getUserName()
    CastInst(c) => c.getUserName()
    GetElementPtrInst(g) => g.getUserName()
    ReturnInst(_) => None
  }
}

// =======================================================
// Instruction
// =======================================================

///|
pub struct InstBase {
  parent : Function
  priv mut bb : BasicBlock?
  priv mut next : &Instruction?
  priv mut prev : &Instruction?
}

///|
pub fn InstBase::new(
  parent : Function,
  bb~ : BasicBlock? = None,
  next~ : &Instruction? = None,
  prev~ : &Instruction? = None
) -> InstBase {
  InstBase::{ parent, bb, next, prev }
}

///|
pub trait Instruction: User {
  getInstBase(Self) -> InstBase
  asInstEnum(Self) -> InstEnum
  getName(Self) -> String? = _
  getParent(Self) -> Function = _
  getBasicBlock(Self) -> BasicBlock? = _
  isIndependent(Self) -> Bool = _
  next(Self) -> &Instruction? = _
  prev(Self) -> &Instruction? = _
  insertAfter(Self, &Instruction) -> Unit!LLVMValueError = _
  insertBefore(Self, &Instruction) -> Unit!LLVMValueError = _
}

///|
impl Instruction with getName(self) {
  self.getUserName()
}

///|
impl Instruction with getParent(self) {
  self.getInstBase().parent
}

///|
impl Instruction with getBasicBlock(self) {
  self.getInstBase().bb
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
  self.getInstBase().next
}

///|
impl Instruction with prev(self) {
  self.getInstBase().prev
}

///|
impl Instruction with insertAfter(self, insertPt : &Instruction) {
  guard self.isIndependent() else { raise OnlyIndependInstructionCanBeInsert }
  match insertPt.next() {
    None => {
      insertPt.getInstBase().next = Some(self)
      self.getInstBase().prev = Some(insertPt)
      self.getInstBase().bb = insertPt.getBasicBlock()
    }
    Some(ori_next) => {
      insertPt.getInstBase().next = Some(self)
      self.getInstBase().prev = Some(insertPt)
      self.getInstBase().next = Some(ori_next)
      ori_next.getInstBase().prev = Some(self)
      self.getInstBase().bb = insertPt.getBasicBlock()
    }
  }
}

///|
impl Instruction with insertBefore(self, insertPt : &Instruction) {
  guard self.isIndependent() else { raise OnlyIndependInstructionCanBeInsert }
  match insertPt.prev() {
    None => {
      insertPt.getInstBase().prev = Some(self)
      self.getInstBase().next = Some(insertPt)
      self.getInstBase().bb = insertPt.getBasicBlock()
    }
    Some(ori_prev) => {
      insertPt.getInstBase().prev = Some(self)
      self.getInstBase().next = Some(insertPt)
      self.getInstBase().prev = Some(ori_prev)
      ori_prev.getInstBase().next = Some(self)
      self.getInstBase().bb = insertPt.getBasicBlock()
    }
  }
}

///|
pub enum InstEnum {
  AllocaInst(AllocaInst)
  LoadInst(LoadInst)
  //VAArgInst(VAArgInst)
  //ExtractValueInst(ExtractValueInst)
  //FreezeInst(FreezeInst)
  CastInst(CastInst)
  BinaryInstruction(BinaryInstruction)
  CmpInst(CmpInst)
  GetElementPtrInst(GetElementPtrInst)
  ReturnInst(ReturnInst)
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
  //ExtractValueInst(ExtractValueInst)
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
} derive(Eq)

///|
pub trait Constant: Value {
  asConstantEnum(Self) -> ConstantEnum
  valstr(Self) -> String
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
  //threadLoacal: ThreadLocalTypes
}

///|
pub enum GlobalValueEnum {
  Function(Function)
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
}

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
