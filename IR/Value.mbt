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
  ConstantBool(ConstantBool)
  ConstantUInt(ConstantUInt)
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
  //LoadInst(LoadInst)
  // VAArgInst(VAArgInst)
  // ExtractValueInst(ExtractValueInst)
  // FreezeInst(FreezeInst)
  //CastInst(CastInst)
  //BinaryInstruction(BinaryInstruction)
  //CmpInst(CompareInst)
  //StoreInst(StoreInst)
  //GetElementPtrInst(GetElementPtrInst)
  //SelectInst(SelectInst)
  //ExtractElementInst(ExtractElementInst)
  //InsertElementInst(InsertElementInst)
  //ShuffleVectorInst(ShuffleVectorInst)
  //PHINode(PHINodeInst)
  //ReturnInst(ReturnInst)
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
  // BasicBlock(BasicBlock)
  // InlineAsm(InlineAsm)
  // MetadataAsValue(MetadataAsValue)
}

///|
pub trait Value: Show {
  base(Self) -> ValueBase
  asValueEnum(Self) -> ValueEnum

  // All values are typed, get the type of this value.
  getType(Self) -> &Type = _

  // All values hold a context through their type.
  getContext(Self) -> LLVMContext = _

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
}

///|
impl Eq for &Value with op_equal(self, other) {
  self.base() == other.base()
}

///|
impl Value with getType(self) {
  self.base().vty
}

///|
impl Value with getContext(self) {
  self.base().vty.getContext()
}

//impl Value with setName(_, name: String) {
//  raise DuplicateValueName(name)
//}

///|
impl Value with getUsers(self) {
  self.base().users
}

///|
impl Value with user_empty(self) {
  self.getUsers().is_empty()
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
} derive(Eq)

// =======================================================
// User
// =======================================================

pub struct UserBase {
  name: String?
  operands: Array[&Value]
}

pub trait User: Value {
  asUserEnum(Self) -> UserEnum
  getUserBase(Self) -> UserBase
  getName(Self) -> String? = _
  getOperands(Self) -> Array[&Value] = _
}

impl User with getName(self) {
  self.getUserBase().name
}

impl User with getOperands(self) {
  self.getUserBase().operands
}

pub enum UserEnum {
  //Instruction(Instruction)
  AllocaInst(AllocaInst)
  //LoadInst(LoadInst)
  //VAArgInst(VAArgInst)
  //ExtractValueInst(ExtractValueInst)
  //FreezeInst(FreezeInst)
  //CastInst(CastInst)
}

// =======================================================
// Instruction
// =======================================================

pub struct InstBase {
  name: String?
  parent: Function
  //bb: BasicBlock
  next: &Instruction?
  prev: &Instruction?
}

pub trait Instruction: User {
  getInstBase(Self) -> InstBase
  asInstEnum(Self) -> InstEnum
  //next(Self) -> &Instruction? = _
  //prev(Self) -> &Instruction? = _
  // insertBefore(self, pos: &Instruction) -> Unit!LLVMValueError = _
  // insertAfter(self, pos: &Instruction) -> Unit!LLVMValueError = _
}

//impl Instruction with next(self) {
//  self.getInstBase().next
//}
//
//impl Instruction with prev(self) {
//  self.getInstBase().prev
//}

pub enum InstEnum {
  AllocaInst(AllocaInst)
}

// =======================================================
// UnaryInst
// =======================================================

pub trait UnaryInst: Instruction {
  asUnaryInstEnum(Self) -> UnaryInstEnum
}

pub enum UnaryInstEnum {
  AllocaInst(AllocaInst)
  //LoadInst(LoadInst)
  //VAArgInst(VAArgInst)
  //ExtractValueInst(ExtractValueInst)
  //FreezeInst(FreezeInst)
  //CastInst(CastInst)
}


// =======================================================
// Constant
// =======================================================

///|
pub enum ConstantEnum {
  ConstantInt(ConstantInt)
  ConstantBool(ConstantBool)
  ConstantUInt(ConstantUInt)
  ConstantFP(ConstantFP)
  ConstantPointerNull(ConstantPointerNull)
  ConstantArray(ConstantArray)
  ConstantVector(ConstantVector)
} derive(Eq)

///|
trait Constant: Value {
  asConstantEnum(Self) -> ConstantEnum
}

///|
impl Eq for &Constant with op_equal(self, other) {
  self.asConstantEnum() == other.asConstantEnum()
}

// =======================================================
// GlobalValue
// =======================================================

pub trait GlobalValue : Value {
  getGlobalValueBase(Self) -> GlobalValueBase
  asGlobalValueEnum(Self) -> GlobalValueEnum
  getLinkage(Self) -> LinkageTypes = _
  setLinkage(Self, linkage: LinkageTypes) -> Unit = _
}

impl GlobalValue with getLinkage(self) {
  self.getGlobalValueBase().linkage
}

impl GlobalValue with setLinkage(self, linkage: LinkageTypes) {
  self.getGlobalValueBase().linkage = linkage
}

struct GlobalValueBase {
  mut linkage: LinkageTypes
  //visibility: VisibilityTypes
  //unnamed_addr: UnnamedAddr
  //dllStorageClass: DLLStorageClassTypes
  //threadLoacal: ThreadLocalTypes
}

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
