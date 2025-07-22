///|
pub enum BinaryOps {
  // Standard binary operators.
  Add
  FAdd
  Sub
  FSub
  Mul
  FMul
  SDiv
  UDiv
  FDiv
  URem
  SRem
  FRem

  // Logical operators
  Shl
  LShr
  AShr
  And
  Or
  Xor
} derive(Hash, Eq)

///|
pub impl Show for BinaryOps with output(self, logger) {
  let str = match self {
    Add => "add"
    FAdd => "fadd"
    Sub => "sub"
    FSub => "fsub"
    Mul => "mul"
    FMul => "fmul"
    SDiv => "sdiv"
    UDiv => "udiv"
    FDiv => "fdiv"
    URem => "urem"
    SRem => "srem"
    FRem => "frem"
    Shl => "shl"
    LShr => "lshr"
    AShr => "ashr"
    And => "and"
    Or => "or"
    Xor => "xor"
  }
  logger.write_string(str)
}

///|
pub enum BinaryOpFlags {

  // Only add, sub, mul, and shl
  // could have NoUnsignedWrap and NoSignedWrap flags.
  NoUnsignedWrap
  NoSignedWrap

  // only sdiv, udiv, ashr, lshr
  // could have Exact flag.
  Exact

  // Only Or could have Disjoint flag.
  //Disjoint
} derive(Hash, Eq)

///|
pub impl Show for BinaryOpFlags with output(self, logger) {
  let str = match self {
    NoUnsignedWrap => "nuw"
    NoSignedWrap => "nsw"
    Exact => "exact"
    //Disjoint => "disjoint"
  }
  logger.write_string(str)
}

///|
pub(all) enum FastMathFlag {
  AllowReassoc
  NoNaNs
  NoInfs
  NoSignedZeros
  AllowReciprocal
  AllowContract
  ApproxFunc
} derive(Hash, Eq)

///|
pub impl Show for FastMathFlag with output(self, logger) {
  let str = match self {
    AllowReassoc => "reassoc"
    NoNaNs => "nnan"
    NoInfs => "ninf"
    NoSignedZeros => "nsz"
    AllowReciprocal => "arcp"
    AllowContract => "contract"
    ApproxFunc => "afn"
  }
  logger.write_string(str)
}

// =======================================================
// AllocaInst
// =======================================================

///|
pub struct AllocaInst {
  uid: UInt64
  vty: &Type
  users: Array[&User]

  mut name: String?

  inst_base : InstBase
  data_ty : &Type
  align : Align
}

///|
fn AllocaInst::new(
  data_ty : &Type,
  parent : Function,
  addressSpace~ : AddressSpace,
  name~ : String? = None
) -> AllocaInst {
  let uid = valueUIDAssigner.assign()
  let vty = data_ty.getContext().getPtrTy(addressSpace~)
  let inst_base = InstBase::new(parent)
  let align = parent.getDataLayout().getAlignment(data_ty)
  AllocaInst::{ uid, vty, users:[], name, inst_base, data_ty, align }
}

///|
pub impl Value for AllocaInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

pub impl Value for AllocaInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for AllocaInst with asValueEnum(self) {
  AllocaInst(self)
}

pub impl NamedValue for AllocaInst with getName(self) {
  self.name
}

pub impl NamedValue for AllocaInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for AllocaInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
      Some(slot) => Some(Right(slot))
      None => None
    }
  }
}

///|
pub impl Instruction for AllocaInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for AllocaInst with asInstEnum(self) {
  AllocaInst(self)
}

///|
pub impl UnaryInst for AllocaInst with asUnaryInstEnum(self) {
  AllocaInst(self)
}

///|
pub impl Show for AllocaInst with output(self, logger) {
  let repr = self.getValueRepr()
  logger.write_string("  \{repr} = alloca \{self.data_ty}, \{self.align}")
}

// =======================================================
// LoadInst
// =======================================================

///|
pub(all) enum AtomicOrdering {
  NotAtomic
  Unordered
  Monotonic
  Acquire
  Release
  AcquireRelease
  SequentiallyConsistent
} derive(Hash, Eq)

///|
pub impl Show for AtomicOrdering with output(self, logger) {
  let str = match self {
    NotAtomic => ""
    Unordered => "unordered"
    Monotonic => "monotonic"
    Acquire => "acquire"
    Release => "release"
    AcquireRelease => "acquire_release"
    SequentiallyConsistent => "sequentially_consistent"
  }
  logger.write_string(str)
}

///| TODO: Not full implemented, remember erase `all`.
pub(all) struct LoadInst {
  // --- ValueBase ---

  // Unique identifier
  uid: UInt64

  // Type of the value
  vty: &Type

  // Users of this value
  users: Array[&User]

  // Name of the value
  mut name: String?

  // --- UserBase ---

  // Pointer which this instruction loads from.
  ptr: &Value

  inst_base : InstBase

  // --- LoadInst ---
  isVolatile : Bool
  atomicOrdering : AtomicOrdering
  align : Align
}

///|
fn LoadInst::new(
  load_ty : &Type,
  ptr : &Value,
  isVolatile : Bool,
  atomicOrdering : AtomicOrdering,
  parent : Function,
  name~ : String? = None
) -> LoadInst raise LLVMValueError {
  guard ptr.getType().asTypeEnum() is PointerType(_) else {
    raise LoadInstShouldLoadFromAPointer(ptr.getType())
  }
  guard load_ty.tryAsAbstractTypeEnum() is None else {
    raise LoadInstCannotLoadToAnAbstractType(load_ty)
  }
  guard not(isVolatile && not(atomicOrdering is NotAtomic)) else {
    raise LoadInstCannotBeVolatileAndAtomic
  }
  let vty = load_ty
  let inst_base = InstBase::new(parent)
  let align = parent.getDataLayout().getAlignment(load_ty)
  let uid = valueUIDAssigner.assign()
  let inst = LoadInst::{
    uid,
    vty,
    name,
    users: [],
    ptr,
    inst_base,
    isVolatile,
    atomicOrdering,
    align,
  }
  ptr.addUser(inst)
  inst
}

///|
pub impl Value for LoadInst with asValueEnum(self) {
  LoadInst(self)
}

///|
pub impl Value for LoadInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty,
    users: self.users,
  }
}

pub impl Value for LoadInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

pub impl NamedValue for LoadInst with getName(self) {
  self.name
}

pub impl NamedValue for LoadInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for LoadInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
      Some(slot) => Some(Right(slot))
      None => None
    }
  }
}

///|
pub impl User for LoadInst with asUserEnum(self) {
  LoadInst(self)
}

///|
pub impl User for LoadInst with getUserBase(self) {
  UserBase::{ operands: [self.ptr] }
}

///|
pub impl Instruction for LoadInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for LoadInst with asInstEnum(self) {
  LoadInst(self)
}

///|
pub impl UnaryInst for LoadInst with asUnaryInstEnum(self) {
  LoadInst(self)
}

///|
pub impl Show for LoadInst with output(self, logger) {
  let align = self.align
  let repr = self.getValueRepr()
  let ptr_repr = self.ptr.getValueRepr()
  let load_ty = self.getType()

  let str = match (self.isVolatile, self.atomicOrdering) {
    (true, _) =>
      "  \{repr} = load volatile \{load_ty}, ptr \{ptr_repr}, \{align}"
    (false, NotAtomic) =>
      "  \{repr} = load \{load_ty}, ptr \{ptr_repr}, \{align}"
    (false, _) =>
      "  \{repr} = load atomic \{load_ty}, ptr \{ptr_repr} \{self.atomicOrdering}, \{align}"
  }
  logger.write_string(str)
}

// =======================================================
// StoreInst
// =======================================================

///|
pub struct StoreInst {
  // --- ValueBase ---

  // Unique identifier
  uid: UInt64

  // Type of the value
  vty: &Type

  // --- UserBase ---
  value: &Value
  ptr: &Value

  inst_base : InstBase

  // --- StoreInst ---
  isVolatile : Bool
  atomicOrdering : AtomicOrdering
  align : Align
}

///|
fn StoreInst::new(
  value : &Value,
  ptr : &Value,
  isVolatile : Bool,
  atomicOrdering : AtomicOrdering,
  parent : Function
) -> StoreInst raise LLVMValueError {
  guard ptr.getType().asTypeEnum() is PointerType(_) else {
    raise StoreInstShouldStoreToAPointer(ptr.getType())
  }
  guard value.getType().tryAsAbstractTypeEnum() is None else {
    raise StoreInstCannotStoreAnAbstractType(value.getType())
  }
  guard not(isVolatile && not(atomicOrdering is NotAtomic)) else {
    raise StoreInstCannotBeVolatileAndAtomic
  }
  let ctx = value.getContext()
  let uid = valueUIDAssigner.assign()
  let value_ty = value.getType()
  let inst_base = InstBase::new(parent)
  let align = parent.getDataLayout().getAlignment(value_ty)
  let inst = StoreInst::{
    uid,
    vty: ctx.getVoidTy(),
    value,
    ptr,
    inst_base,
    isVolatile,
    atomicOrdering,
    align,
  }
  value.addUser(inst)
  ptr.addUser(inst)
  inst
}

///|
pub fn StoreInst::getValueOperand(self : StoreInst) -> &Value {
  self.value
}

///|
pub fn StoreInst::getPointerOperand(self : StoreInst) -> &Value {
  self.ptr
}

///|
pub impl Value for StoreInst with asValueEnum(self) {
  StoreInst(self)
}

pub impl Value for StoreInst with getValueRepr(self) {
  ignore(self)
  ""
}

///|
pub impl Value for StoreInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty,
    users: [],
  }
}

///|
pub impl User for StoreInst with asUserEnum(self) {
  StoreInst(self)
}

///|
pub impl User for StoreInst with getUserBase(self) {
  UserBase::{
    operands: [self.value, self.ptr],
  }
}

///|
pub impl Instruction for StoreInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for StoreInst with asInstEnum(self) {
  StoreInst(self)
}

///|
pub impl Show for StoreInst with output(self, logger) {
  let align = self.align
  let value = self.getValueOperand()
  let ptr = self.getPointerOperand()
  let value_ty = value.getType()
  let value_repr =value.getValueRepr()
  let ptr_repr = ptr.getValueRepr()
  let str = match (self.isVolatile, self.atomicOrdering) {
    (true, _) =>
      "  store volatile \{value_ty} \{value_repr}, ptr \{ptr_repr}, \{align}"
    (false, NotAtomic) =>
      "  store \{value_ty} \{value_repr}, ptr \{ptr_repr}, \{align}"
    (false, _) =>
      "  store atomic \{value_ty} \{value_repr}, ptr \{ptr_repr} \{self.atomicOrdering}, \{align}"
  }
  logger.write_string(str)
}

// =======================================================
// BinaryInstructions
// =======================================================

///|
pub struct BinaryInst {
  // --- ValueBase ---

  // Unique identifier
  uid: UInt64

  // Type of the value
  vty: &Type

  // Users of this value
  users: Array[&User]

  // Name of the value
  mut name: String?


  // --- UserBase ---
  lhs: &Value
  rhs: &Value

  inst_base : InstBase

  // --- BinaryInst ---
  opcode : BinaryOps
  flags : Set[BinaryOpFlags]
  fast_math_flags : Set[FastMathFlag]
}

///|
fn BinaryInst::newStandardOp(
  opcode : BinaryOps,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name~ : String? = None,
  flags : Set[BinaryOpFlags]
) -> BinaryInst raise LLVMValueError {
  guard opcode
    is (Add
    | Sub
    | Mul
    | SDiv
    | UDiv
    | SRem
    | URem
    | And
    | Or
    | Xor
    | Shl
    | LShr
    | AShr) else {
    llvm_unreachable(
      "Should not call BinaryInst::newStandardOp with opcode \{opcode}",
    )
  }
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy else { raise TypeMismatchForBinaryOp(lhsTy, rhsTy) }
  guard lhsTy.tryAsIntTypeEnum() is Some(_) else {
    raise TypeNotSupportForBinaryOp(lhsTy, opcode)
  }
  let vty = lhsTy
  let uid = valueUIDAssigner.assign()

  let inst_base = InstBase::new(parent)
  let inst = BinaryInst::{
    uid,
    vty,
    lhs,
    rhs,
    name,
    users: [],
    inst_base,
    opcode,
    flags,
    fast_math_flags: Set::new(),
  }
  lhs.addUser(inst)
  rhs.addUser(inst)
  inst
}

///|
fn BinaryInst::newFPMathOp(
  opcode : BinaryOps,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name~ : String? = None,
  fast_math_flags : Set[FastMathFlag]
) -> BinaryInst raise LLVMValueError {
  guard opcode is (FAdd | FSub | FMul | FDiv | FRem) else {
    llvm_unreachable(
      "Should not call BinaryInst::newFPMathOp with opcode \{opcode}",
    )
  }
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy else { raise TypeMismatchForBinaryOp(lhsTy, rhsTy) }
  guard lhsTy.tryAsFPTypeEnum() is Some(_) else {
    raise TypeNotSupportForBinaryOp(lhsTy, opcode)
  }
  let uid = valueUIDAssigner.assign()
  let vty = lhsTy
  let inst_base = InstBase::new(parent)
  let inst = BinaryInst::{
    uid,
    vty,
    lhs,
    rhs,
    name,
    users: [],
    inst_base,
    opcode,
    flags: Set::new(),
    fast_math_flags,
  }
  lhs.addUser(inst)
  rhs.addUser(inst)
  inst
}

///|
pub impl Value for BinaryInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty,
    users: self.users,
  }
}

///|
pub impl Value for BinaryInst with asValueEnum(self) {
  BinaryInst(self)
}

pub impl Value for BinaryInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

pub impl NamedValue for BinaryInst with getName(self) {
  self.name
}

pub impl NamedValue for BinaryInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for BinaryInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
      Some(slot) => Some(Right(slot))
      None => None
    }
  }
}

///|
pub impl User for BinaryInst with asUserEnum(self) {
  BinaryInst(self)
}

///|
pub impl User for BinaryInst with getUserBase(self) {
  UserBase::{
    operands: [self.lhs, self.rhs],
  }
}

///|
pub impl Instruction for BinaryInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for BinaryInst with asInstEnum(self) {
  BinaryInst(self)
}

///|
pub impl Show for BinaryInst with output(self, logger) {
  let ty = self.getType()
  let repr = self.getValueRepr()
  let lhs_repr = self.lhs.getValueRepr()
  let rhs_repr = self.rhs.getValueRepr()
  let flags_str = self.flags.iter().map(f => "\{f}").join(" ")
  let flags_str = if flags_str.is_empty() { "" } else { " " + flags_str }
  let fast_math_flags_str = self.fast_math_flags
    .iter()
    .map(f => "\{f}")
    .join(" ")
  let fast_math_flags_str = if fast_math_flags_str.is_empty() {
    ""
  } else {
    " " + fast_math_flags_str
  }
  let flags_str = flags_str + fast_math_flags_str
  logger.write_string(
    "  \{repr} = \{self.opcode}\{flags_str} \{ty} \{lhs_repr}, \{rhs_repr}",
  )
}

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
pub struct ICmpInst {
  //base : ValueBase
  //user_base : UserBase
  uid: UInt64
  lhs: &Value
  rhs: &Value
  mut name: String?
  users: Array[&User]
  inst_base : InstBase
  predicate : IntPredicate
}

///|
fn ICmpInst::new(
  predicate : IntPredicate,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name~ : String? = None
) -> ICmpInst raise LLVMValueError {
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy else { raise TypeMismatchForCmpInst(lhsTy, rhsTy) }
  guard lhsTy.tryAsIntTypeEnum() is Some(_) else {
    raise TypeMismatchForICmpInst(lhsTy)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = ICmpInst::{ uid, lhs, rhs, name, users: [], inst_base, predicate }
  lhs.addUser(inst)
  rhs.addUser(inst)
  inst
}

///|
impl Value for ICmpInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getType(),
    users: self.users,
  }
}

///|
impl Value for ICmpInst with asValueEnum(self) {
  ICmpInst(self)
}

impl Value for ICmpInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

impl NamedValue for ICmpInst with getName(self) {
  self.name
}

impl NamedValue for ICmpInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

impl NamedValue for ICmpInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
      Some(slot) => Some(Right(slot))
      None => None
    }
  }
}


///|
impl User for ICmpInst with asUserEnum(self) {
  ICmpInst(self)
}

///|
impl User for ICmpInst with getUserBase(self) {
  UserBase::{
    operands: [self.lhs, self.rhs],
  }
}

///|
impl Instruction for ICmpInst with getInstBase(self) {
  self.inst_base
}

///|
impl Instruction for ICmpInst with asInstEnum(self) {
  InstEnum::ICmpInst(self)
}

///|
impl Show for ICmpInst with output(self, logger) {
  let lhs_ty = self.lhs.getType()
  let repr = self.getValueRepr()
  let lhs_repr = self.lhs.getValueRepr()
  let rhs_repr = self.rhs.getValueRepr()
  logger.write_string(
    "  \{repr} = \{self.predicate} \{lhs_ty} \{lhs_repr}, \{rhs_repr}",
  )
}

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
pub struct FCmpInst {
  uid: UInt64
  lhs: &Value
  rhs: &Value
  mut name: String?
  users: Array[&User]
  inst_base : InstBase
  predicate : FloatPredicate
}

///|
fn FCmpInst::new(
  predicate : FloatPredicate,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name~ : String? = None
) -> FCmpInst raise LLVMValueError {
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy else { raise TypeMismatchForCmpInst(lhsTy, rhsTy) }
  guard lhsTy.tryAsFPTypeEnum() is Some(_) else {
    raise TypeMismatchForFCmpInst(lhsTy)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = FCmpInst::{ uid, lhs, rhs, name, users:[], inst_base, predicate }
  lhs.addUser(inst)
  rhs.addUser(inst)
  inst
}

///|
impl Value for FCmpInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getType(),
    users: self.users,
  }
}

impl Value for FCmpInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
impl Value for FCmpInst with asValueEnum(self) {
  FCmpInst(self)
}

impl NamedValue for FCmpInst with getName(self) {
  self.name
}

impl NamedValue for FCmpInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

impl NamedValue for FCmpInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
      Some(slot) => Some(Right(slot))
      None => None
    }
  }
}

///|
impl User for FCmpInst with asUserEnum(self) {
  FCmpInst(self)
}

///|
impl User for FCmpInst with getUserBase(self) {
  UserBase::{
    operands: [self.lhs, self.rhs],
  }
}

///|
impl Instruction for FCmpInst with getInstBase(self) {
  self.inst_base
}

///|
impl Instruction for FCmpInst with asInstEnum(self) {
  FCmpInst(self)
}

///|
impl Show for FCmpInst with output(self, logger) {
  let lhs_ty = self.lhs.getType()
  let repr = self.getValueRepr()
  let lhs_repr = self.lhs.getValueRepr()
  let rhs_repr = self.rhs.getValueRepr()
  logger.write_string(
    "  %\{repr} = \{self.predicate} \{lhs_ty} \{lhs_repr}, \{rhs_repr}",
  )
}

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
pub struct CastInst {
  uid: UInt64
  to_ty: &Type
  from_val: &Value
  mut name: String?
  users: Array[&User]
  inst_base : InstBase
  opcode : CastOps
}

///|
fn CastInst::newTrunc(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsIntTypeEnum() is Some(from_ty) else {
    raise TruncCastInstTypeMismatch(from_val.getType(), to_ty)
  }
  guard from_ty.getBitWidth() > to_ty.getBitWidth() else {
    raise TruncCastInstTypeMismatch(from_ty.asTypeClass(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: Trunc }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newZExt(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsIntTypeEnum() is Some(from_ty) else {
    raise ZExtCastInstTypeMismatch(from_val.getType(), to_ty)
  }
  guard from_ty.getBitWidth() < to_ty.getBitWidth() else {
    raise ZExtCastInstTypeMismatch(from_ty.asTypeClass(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: ZExt }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newSExt(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsIntTypeEnum() is Some(from_ty) else {
    raise SExtCastInstTypeMismatch(from_val.getType(), to_ty)
  }
  guard from_ty.getBitWidth() < to_ty.getBitWidth() else {
    raise SExtCastInstTypeMismatch(from_ty.asTypeClass(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: SExt }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newFPTrunc(
  from_val : &Value,
  to_ty : &FPType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsIntTypeEnum() is Some(from_ty) else {
    raise FPTruncCastInstTypeMismatch(from_val.getType(), to_ty)
  }
  guard from_ty.getBitWidth() < to_ty.getBitWidth() else {
    raise FPTruncCastInstTypeMismatch(from_ty.asTypeClass(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: FPTrunc }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newFPExt(
  from_val : &Value,
  to_ty : &FPType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsIntTypeEnum() is Some(from_ty) else {
    raise FPExtCastInstTypeMismatch(from_val.getType(), to_ty)
  }
  guard from_ty.getBitWidth() < to_ty.getBitWidth() else {
    raise FPExtCastInstTypeMismatch(from_ty.asTypeClass(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: FPExt }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newUIToFP(
  from_val : &Value,
  to_ty : &FPType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsIntTypeEnum() is Some(_) else {
    raise UIToFPInstTypeMismatch(from_val.getType(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: UIToFP }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newFPToUI(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsFPTypeEnum() is Some(_) else {
    raise FPToUIInstTypeMismatch(from_val.getType(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: UIToFP }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newSIToFP(
  from_val : &Value,
  to_ty : &FPType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsIntTypeEnum() is Some(_) else {
    raise SIToFPInstTypeMismatch(from_val.getType(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: SIToFP }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newFPToSI(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsFPTypeEnum() is Some(_) else {
    raise FPToSIInstTypeMismatch(from_val.getType(), to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: FPToSI }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newPtrToInt(
  from_val : &Value,
  to_ty : &IntegerType,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().asTypeEnum() is PointerType(_) else {
    raise PtrToIntCastInstTypeMismatch(from_val.getType())
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: PtrToInt }
  from_val.addUser(inst)
  inst
}

///|
fn CastInst::newIntToPtr(
  from_val : &Value,
  parent : Function,
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  guard from_val.getType().tryAsIntTypeEnum() is Some(_) else {
    raise IntToPtrCastInstTypeMismatch(from_val.getType())
  }
  let to_ty = from_val.getContext().getPtrTy()
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: IntToPtr }
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
  name~ : String? = None
) -> CastInst raise LLVMValueError {
  let src_ty = from_val.getType()
  guard src_ty != to_ty else { raise BitCastInstTypeMismatch(src_ty, to_ty) }
  guard src_ty.tryAsPrimitiveTypeEnum() is Some(src_ty_prim) else {
    raise BitCastOnlyAcceptPrimitiveTypes(src_ty)
  }
  guard src_ty_prim.getBitWidth() == to_ty.getBitWidth() else {
    raise BitCastInstTypeMismatch(src_ty, to_ty)
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ uid, to_ty, from_val, name, users: [], inst_base, opcode: BitCast }
  from_val.addUser(inst)
  inst
}

///|
pub impl Value for CastInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.to_ty,
    users: self.users,
  }
}

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

pub impl NamedValue for CastInst with getName(self) {
  self.name
}

pub impl NamedValue for CastInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for CastInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
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
  UserBase::{
    operands: [self.from_val],
  }
}

///|
pub impl UnaryInst for CastInst with asUnaryInstEnum(self) {
  CastInst(self)
}

///|
pub impl Instruction for CastInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for CastInst with asInstEnum(self) {
  CastInst(self)
}

///|
pub impl Show for CastInst with output(self, logger) {
  let repr = self.getValueRepr()
  let to_ty = self.to_ty
  let from_ty = self.from_val.getType()
  let from_val_repr = self.from_val.getValueRepr()

  logger.write_string(
    "  %\{repr} = \{self.opcode} \{from_ty} \{from_val_repr} to \{to_ty}",
  )
}

// =======================================================
// GetElementPtrInst
// =======================================================

///|
pub struct GetElementPtrInst {
  uid: UInt64
  users: Array[&User]
  ptr: &Value
  indices: Array[&Value]
  mut name: String?
  inst_base : InstBase
  isInbounds : Bool
  pointeeType : &Type
}

///|
fn GetElementPtrInst::new(
  ptr : &Value,
  pointeeType : &Type,
  indices : Array[&Value],
  isInbounds : Bool,
  parent : Function,
  name~ : String? = None
) -> GetElementPtrInst raise LLVMValueError {
  guard ptr.getType().asTypeEnum() is PointerType(_) else {
    raise GetElementPtrInstValueTypeNotPtr(ptr.getType())
  }
  guard pointeeType.isValidGEPType() else {
    raise GetElementPtrInstNotValidPointeeType(pointeeType)
  }
  for idx in indices {
    guard idx.getType().tryAsIntTypeEnum() is Some(_) else {
      raise GetElementPtrInstIndexNotInteger(idx.getType())
    }
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = GetElementPtrInst::{
    uid,
    users: [],
    ptr,
    indices,
    name,
    inst_base,
    isInbounds,
    pointeeType,
  }
  ptr.addUser(inst)
  indices.each(idx => idx.addUser(inst))
  inst
}

///|
impl Value for GetElementPtrInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getContext().getPtrTy(),
    users: self.users,
  }
}

impl Value for GetElementPtrInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
impl Value for GetElementPtrInst with asValueEnum(self) {
  GetElementPtrInst(self)
}

impl NamedValue for GetElementPtrInst with getName(self) {
  self.name
}

impl NamedValue for GetElementPtrInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

impl NamedValue for GetElementPtrInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
      Some(slot) => Some(Right(slot))
      None => None
    }
  }
}

///|
impl User for GetElementPtrInst with asUserEnum(self) {
  GetElementPtrInst(self)
}

///|
impl User for GetElementPtrInst with getUserBase(self) {
  UserBase::{
    operands: [self.ptr] + self.indices,
  }
}

///|
impl Instruction for GetElementPtrInst with getInstBase(self) {
  self.inst_base
}

///|
impl Instruction for GetElementPtrInst with asInstEnum(self) {
  InstEnum::GetElementPtrInst(self)
}

///|
impl Show for GetElementPtrInst with output(self, logger) {
  let repr = self.getValueRepr()
  let ptr_repr = self.ptr.getValueRepr()
  let indices_reprs = Array::new()
  self.indices.each(index =>
    indices_reprs.push("\{index.getType()} \{index.getValueRepr()}")
  )
  let indices_repr = if indices_reprs.length() > 0 {
    ", " + indices_reprs.join(", ")
  } else {
    ""
  }
  let inbounds_str = if self.isInbounds { " inbounds" } else { "" }
  logger.write_string(
    "  \{repr} = getelementptr\{inbounds_str} \{self.pointeeType}, ptr \{ptr_repr}\{indices_repr}",
  )
}

// =======================================================
// SelectInst
// =======================================================

///|
pub struct SelectInst {
  uid: UInt64
  users: Array[&User]
  vty: &Type
  condition: &Value
  trueValue: &Value
  falseValue: &Value
  mut name: String?
  inst_base : InstBase
}

///|
fn SelectInst::new(
  condition : &Value,
  trueValue : &Value,
  falseValue : &Value,
  parent : Function,
  name~ : String? = None
) -> SelectInst raise LLVMValueError {
  guard condition.getType().tryAsIntTypeEnum() is Some(Int1Type(_)) else {
    raise SelectInstConditionNotBoolean(condition.getType())
  }
  let vty = trueValue.getType()
  guard vty == falseValue.getType() else {
    raise SelectInstTypeMismatch(vty, falseValue.getType())
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = SelectInst::{ uid, vty, condition, trueValue, falseValue, name, users:[], inst_base }
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
  ValueBase::{
    uid: self.uid,
    vty: self.vty,
    users: self.users,
  }
}

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

pub impl NamedValue for SelectInst with getName(self) {
  self.name
}

pub impl NamedValue for SelectInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for SelectInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
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
  UserBase::{
    operands: [self.condition, self.trueValue, self.falseValue],
  }
}

///|
pub impl Instruction for SelectInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for SelectInst with asInstEnum(self) {
  InstEnum::SelectInst(self)
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

// =======================================================
// ReturnInst
// =======================================================

///|
pub struct ReturnInst {
  uid: UInt64
  retVal: &Value?
  inst_base : InstBase
}

///|
fn ReturnInst::new(
  retVal : &Value?,
  parent : Function
) -> ReturnInst raise LLVMValueError {
  let vty = match retVal {
    Some(val) => val.getType()
    None => parent.getContext().getVoidTy()
  }
  guard vty == parent.getReturnType() else {
    raise TypeMismatchForReturnInst(vty, parent.getReturnType())
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = ReturnInst::{ uid, retVal, inst_base }
  if retVal is Some(val) {
    val.addUser(inst)
  }
  inst
}

///|
pub impl Value for ReturnInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getType(),
    users: [],
  }
}

///|
pub impl Value for ReturnInst with asValueEnum(self) {
  ReturnInst(self)
}

pub impl Value for ReturnInst with getValueRepr(self) {
  ignore(self)
  ""
}

///|
pub impl User for ReturnInst with asUserEnum(self) {
  ReturnInst(self)
}

///|
pub impl User for ReturnInst with getUserBase(self) {
  let operands : Array[&Value] = match self.retVal {
    Some(val) => [val]
    None => []
  }
  UserBase::{
    operands,
  }
}

///|
pub impl Instruction for ReturnInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for ReturnInst with asInstEnum(self) {
  ReturnInst(self)
}

///|
pub impl Show for ReturnInst with output(self, logger) {
  let retStr = match self.retVal {
    Some(val) => "\{val.getType()} \{val.getValueRepr()}" 
    None => "void"
  }
  logger.write_string("  ret \{retStr}")
}

// =======================================================
// BranchInst
// =======================================================

///|
pub struct BranchInst {
  // --- ValueBase ---

  // Unique identifier
  uid: UInt64

  condition: &Value?
  trueBlock: BasicBlock?
  falseBlock: BasicBlock?

  inst_base : InstBase
}

///|
fn BranchInst::newConditional(
  condition : &Value,
  trueBlock : BasicBlock,
  falseBlock : BasicBlock,
  parent : Function
) -> BranchInst raise LLVMValueError {
  guard condition.getType().tryAsIntTypeEnum() is Some(intTy) else {
    raise BranchInstConditionNotBoolean(condition.getType())
  }
  guard intTy.getBitWidth() == 1 else {
    raise BranchInstConditionNotBoolean(condition.getType())
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = BranchInst::{
    uid,
    condition: Some(condition),
    trueBlock: Some(trueBlock),
    falseBlock: Some(falseBlock),
    inst_base
  }
  condition.addUser(inst)
  trueBlock.addUser(inst)
  falseBlock.addUser(inst)
  inst
}

///|
fn BranchInst::newUnconditional(
  targetBlock : BasicBlock,
  parent : Function
) -> BranchInst {
  let inst_base = InstBase::new(parent)
  let uid = valueUIDAssigner.assign()
  let inst = BranchInst::{
    uid,
    condition: None,
    trueBlock: Some(targetBlock),
    falseBlock: None,
    inst_base
  }
  targetBlock.addUser(inst)
  inst
}

///|
pub fn BranchInst::getCondition(self : Self) -> &Value? {
  self.condition
}

///|
pub fn BranchInst::getNumSuccessors(self : Self) -> Int {
  match self.condition {
    Some(_) => 2 // conditional branch
    None => 1 // unconditional branch
  }
}

///|
pub fn BranchInst::getSuccessor(self : BranchInst, idx : Int) -> BasicBlock? {
  match idx {
    0 => self.trueBlock
    1 => self.falseBlock
    _ => None
  }
}

///|
pub fn BranchInst::isConditional(self : BranchInst) -> Bool {
  match self.condition {
    Some(_) => true
    None => false
  }
}

///|
pub fn BranchInst::isUnconditional(self : BranchInst) -> Bool {
  match self.condition {
    Some(_) => false
    None => true
  }
}

///|
pub impl Value for BranchInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getContext().getVoidTy(), // BranchInst does not have a value type
    users: [],
  }
}

///|
pub impl Value for BranchInst with asValueEnum(self) {
  BranchInst(self)
}

pub impl Value for BranchInst with getValueRepr(self) {
  ignore(self)
  ""
}

///|
pub impl User for BranchInst with asUserEnum(self) {
  BranchInst(self)
}

///|
pub impl User for BranchInst with getUserBase(self) {
  let operands: Array[&Value] = []
  match self.condition {
    Some(cond) => operands.push(cond)
    None => ()
  }
  match self.trueBlock {
    Some(block) => operands.push(block)
    None => ()
  }
  match self.falseBlock {
    Some(block) => operands.push(block)
    None => ()
  }
  UserBase::{
    operands,
  }
}

///|
pub impl Instruction for BranchInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for BranchInst with asInstEnum(self) {
  InstEnum::BranchInst(self)
}

///|
pub impl Show for BranchInst with output(self, logger) {
  if self.isConditional() {
    let condition_repr = self.condition.unwrap().getValueRepr()
    let true_block_repr = self.trueBlock.unwrap().getValueRepr()
    let false_block_repr = self.falseBlock.unwrap().getValueRepr()
    logger.write_string(
      "  br \{self.condition.unwrap().getType()} \{condition_repr}, label \{true_block_repr}, label \{false_block_repr}",
    )
  } else {
    let target_block_repr = self.trueBlock.unwrap().getValueRepr()
    logger.write_string("  br label \{target_block_repr}")
  }
}

// =======================================================
// Switch Inst
// =======================================================

///|
pub struct SwitchInst {
  uid: UInt64
  condition: &Value
  defaultDest: BasicBlock
  cases: Array[(ConstantInt, BasicBlock)]
  inst_base : InstBase
}

///|
fn SwitchInst::new(
  cond : &Value,
  defaultDest : BasicBlock,
  parent : Function
) -> SwitchInst raise LLVMValueError {
  guard cond.getType().tryAsIntTypeEnum() is Some(_) else {
    raise SwitchInstConditionNotInteger(cond.getType())
  }
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  let inst = SwitchInst::{ uid, condition:cond, defaultDest, cases: [], inst_base }
  cond.addUser(inst)
  defaultDest.addUser(inst)
  inst
}

///|
pub fn SwitchInst::getCondition(self : Self) -> &Value {
  self.condition
}

///|
pub fn SwitchInst::getDefaultDest(self : Self) -> BasicBlock {
  self.defaultDest
}

///|
pub fn SwitchInst::getNumCases(self : Self) -> Int {
  self.cases.length()
}

///|
pub fn SwitchInst::getCase(
  self : Self,
  idx : Int
) -> (ConstantInt, BasicBlock)? {
  self.cases.get(idx)
}

///|
pub fn SwitchInst::addCase(
  self : Self,
  cond : ConstantInt,
  dest : BasicBlock
) -> Unit raise LLVMValueError {
  guard self.getCondition().getType().tryAsIntTypeEnum() is Some(intTy)
  guard cond.getType().tryAsIntTypeEnum() is Some(case_cond_ty)
  guard intTy == case_cond_ty else {
    let intTy = intTy.asTypeClass()
    let case_cond_ty = case_cond_ty.asTypeClass()
    raise SwitchInstCaseConditionTypeMismatch(intTy, case_cond_ty)
  }
  cond.addUser(self)
  dest.addUser(self)
  match self.getBasicBlock() {
    Some(bb) => dest.preds.push(bb)
    None => ()
  }
}

///|
pub impl Value for SwitchInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getContext().getVoidTy(), // SwitchInst does not have a value type
    users: [],
  }
}

///|
pub impl Value for SwitchInst with asValueEnum(self) {
  SwitchInst(self)
}

pub impl Value for SwitchInst with getValueRepr(self) {
  ignore(self)
  ""
}

///|
pub impl User for SwitchInst with asUserEnum(self) {
  SwitchInst(self)
}

///|
pub impl User for SwitchInst with getUserBase(self) {
  let operands: Array[&Value] = [self.condition, self.defaultDest]
  self.cases.each(case => {
    operands.push(case.0) // case condition
    operands.push(case.1) // case destination
  })
  UserBase::{
    operands: [self.condition, self.defaultDest] + self.cases.map(case => case.1),
  }
}

///|
pub impl Instruction for SwitchInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for SwitchInst with asInstEnum(self) {
  InstEnum::SwitchInst(self)
}

///|
pub impl Show for SwitchInst with output(self, logger) {
  let condition = self.getCondition()
  let condition_ty = condition.getType()

  // Format condition value
  let condition_repr = condition.getValueRepr()

  // Format default destination
  let default_dest = self.getDefaultDest()
  let default_dest_repr = default_dest.getValueRepr()

  // Start with the switch statement
  logger.write_string(
    "  switch \{condition_ty} \{condition_repr}, label \{default_dest_repr} [",
  )

  // Add each case
  let num_cases = self.getNumCases()
  for i = 0; i < num_cases; i = i + 1 {
    if self.getCase(i) is Some((case_value, case_dest)) {
      let case_dest_repr = case_dest.getValueRepr()
      logger.write_string(
        "\n    \{condition_ty} \{case_value.valstr()}, label \{case_dest_repr}",
      )
    }
  }

  // Close the switch statement
  logger.write_string("\n  ]")
}

// =======================================================
// PHINode
// =======================================================

///|
pub struct PHINode {
  uid: UInt64
  vty: &Type
  users: Array[&User]

  mut name: String?

  incomings: Array[(&Value, BasicBlock)]
  inst_base : InstBase
}

///|
fn PHINode::new(vty : &Type, parent : Function, name~ : String? = None) -> PHINode {
  let uid = valueUIDAssigner.assign()
  let inst_base = InstBase::new(parent)
  PHINode::{ uid, vty, users: [], name, incomings: [], inst_base }
}

///|
pub fn PHINode::getNumIncomingValues(self : PHINode) -> Int {
  self.incomings.length()
}

///|
pub fn PHINode::getIncomingValue(self : PHINode, idx : Int) -> &Value? {
  match self.incomings.get(idx){
    Some((value, _)) => Some(value)
    None => None
  }
}

///|
pub fn PHINode::getIncomingBlock(self : PHINode, idx : Int) -> BasicBlock? {
  match self.incomings.get(idx) {
    Some((_, block)) => Some(block)
    None => None
  }
}

///|
pub fn PHINode::getIncoming(self : PHINode, idx : Int) -> (&Value, BasicBlock)? {
  self.incomings.get(idx)
}

///|
pub fn PHINode::getIncomings(self : PHINode) -> Array[(&Value, BasicBlock)] {
  self.incomings
}

///|
pub fn PHINode::getIncomingValues(self : PHINode) -> Array[&Value] {
  self.incomings.map(incoming => incoming.0)
}

///|
pub fn PHINode::getIncomingBlocks(self : PHINode) -> Array[BasicBlock] {
  self.incomings.map(incoming => incoming.1)
}

///|
pub fn PHINode::addIncoming(
  self : PHINode,
  value : &Value,
  block : BasicBlock
) -> Unit raise LLVMValueError {
  guard value.getType() == self.getType() else {
    raise PHINodeIncomingValueTypeMismatch(value.getType(), self.getType())
  }
  self.incomings.push((value, block))
  value.addUser(self)
  block.addUser(self)
}

///|
pub impl Value for PHINode with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty,
    users: self.users,
  }
}

pub impl Value for PHINode with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

pub impl NamedValue for PHINode with getName(self) {
  self.name
}

pub impl NamedValue for PHINode with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for PHINode with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
      Some(slot) => Some(Right(slot))
      None => None
    }
  }
}

///|
pub impl Value for PHINode with asValueEnum(self) {
  PHINode(self)
}

///|
pub impl User for PHINode with asUserEnum(self) {
  PHINode(self)
}

///|
pub impl User for PHINode with getUserBase(self) {
  let operands: Array[&Value] = []
  self.incomings.each(
    incoming => {
      operands.push(incoming.0)
      operands.push(incoming.1)
    }
  )
  UserBase::{
    operands,
  }
}

///|
pub impl Instruction for PHINode with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for PHINode with asInstEnum(self) {
  InstEnum::PHINode(self)
}

///|
pub impl Show for PHINode with output(self, logger) {
  let repr = self.getValueRepr()
  let ty = self.getType()
  let str = "  \{repr} = phi \{ty}"
  let num_incoming = self.getNumIncomingValues()
  let incoming_strs = Array::new()
  for i = 0; i < num_incoming; i = i + 1 {
    if self.getIncoming(i) is Some((value, block)) {
      let value_repr = value.getValueRepr()
      let block_repr = block.getValueRepr()
      incoming_strs.push("[ \{value_repr}, \{block_repr} ]")
    }
  }
  let str = str +
    (if num_incoming > 0 { " " + incoming_strs.join(", ") } else { "" })
  logger.write_string(str)
}

// =======================================================
// CallInst
// =======================================================

///|
pub(all) enum TailCallKind {
  NoTail
  Tail
  MustTail
}

///|
pub impl Show for TailCallKind with output(self, logger) {
  let str = match self {
    NoTail => ""
    Tail => "tail"
    MustTail => "musttail"
  }
  logger.write_string(str)
}

///|
pub struct CallInst {
  uid: UInt64
  vty: &Type
  users: Array[&User]
  mut name: String?

  callee : Function
  args: Array[&Value]
  inst_base : InstBase
  mut tailCallKind : TailCallKind
}

///|
fn CallInst::new(
  callee : Function,
  args : Array[&Value],
  parent : Function,
  name~ : String? = None
) -> CallInst raise LLVMValueError {
  let fty = callee.getFunctionType()
  let expected_params = fty.getNumParams().reinterpret_as_int()
  guard args.length() == expected_params else {
    raise CallInstArgCountMismatch(expected_params, args.length())
  }
  let argTys = args.map(arg => arg.getType())
  let paramTys = callee.getParamTypes()
  let arg_param_type_match = argTys
    .zip(paramTys)
    .iter()
    .all(arg_param => {
      let (arg_ty, param_ty) = arg_param
      arg_ty == param_ty
    })
  guard arg_param_type_match else {
    raise CallInstArgTypeMismatchParamType(argTys, paramTys)
  }
  let name = if fty.getReturnType().asTypeEnum() is VoidType(_) {
    // 如果返回类型是void，name可以是空字符串
    None
  } else {
    name
  }
  let uid = valueUIDAssigner.assign()
  let vty = fty.getReturnType()
  let inst_base = InstBase::new(parent)
  let inst = CallInst::{
    uid,
    vty,
    users: [],
    name,
    callee,
    args,
    inst_base,
    tailCallKind: NoTail,
  }
  callee.addUser(inst)
  args.each(arg => arg.addUser(inst))
  inst
}

///|
pub fn CallInst::isTailCall(self : CallInst) -> Bool {
  not(self.tailCallKind is NoTail)
}

///|
pub fn CallInst::getTailCallKind(self : CallInst) -> TailCallKind {
  self.tailCallKind
}

///|
pub fn CallInst::setTailCallKind(
  self : CallInst,
  tailCallKind : TailCallKind
) -> Unit {
  self.tailCallKind = tailCallKind
}

///|
pub fn CallInst::getFunctionType(self : CallInst) -> FunctionType {
  guard self.getOperand(0).unwrap().getType().asTypeEnum() is FunctionType(ft)
  ft
}

///|
pub fn CallInst::getCallee(self : CallInst) -> Function {
  guard self.getOperand(0) is Some(callee_val)
  guard callee_val.asValueEnum() is Function(callee)
  callee
}

///|
pub fn CallInst::getArgOperand(self : Self, idx : Int) -> &Value? {
  guard idx >= 0 && idx < self.getNumArgs() - 1 else { return None }
  self.getOperand(idx + 1) // +1 because the first operand is the callee
}

///|
pub fn CallInst::getNumArgs(self : Self) -> Int {
  self.callee.getFunctionType().getNumParams().reinterpret_as_int()
}

///|
pub impl Value for CallInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty,
    users: self.users,
  }
}

///|
pub impl Value for CallInst with asValueEnum(self) {
  CallInst(self)
}

pub impl Value for CallInst with getValueRepr(self) {
  if self.vty.asTypeEnum() is VoidType(_) {
    return ""
  }
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

pub impl NamedValue for CallInst with getName(self) {
  self.name
}

pub impl NamedValue for CallInst with getNameOrSlot(self) {
  if self.vty.asTypeEnum() is VoidType(_) {
    return None
  }
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
      Some(slot) => Some(Right(slot))
      None => None
    }
  }
}

pub impl NamedValue for CallInst with setName(self, name) {
  if self.vty.asTypeEnum() is VoidType(_) {
    raise SetNameForVoidTypeValue
  }
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

///|
pub impl User for CallInst with asUserEnum(self) {
  CallInst(self)
}

///|
pub impl User for CallInst with getUserBase(self) {
  UserBase::{
    operands: [self.callee] + self.args,
  }
}

///|
pub impl Instruction for CallInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for CallInst with asInstEnum(self) {
  InstEnum::CallInst(self)
}

///|
pub impl Show for CallInst with output(self, logger) {
  // 获取被调用函数的信息
  let callee = self.callee
  let fty = callee.getFunctionType()
  let ret_ty = fty.getReturnType()
  let is_void_ret = ret_ty.asTypeEnum() is VoidType(_)

  // 格式化返回值名称或slot
  let prefix = if is_void_ret {
    "" // 如果返回类型是void，不需要前缀
  } else {
    self.getValueRepr()
  }

  // 格式化tail call类型let tail_str = match self.tck {
  let tail_str = self.tailCallKind.to_string()

  // 格式化返回值属性
  let ret_attrs = callee.getReturnAttrs()
  let ret_attrs_str = if ret_attrs.is_empty() {
    ""
  } else {
    " " + ret_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
  }

  // 格式化参数
  let arg_strs = Array::new()
  for idx, arg in self.args {
    let arg_ty = arg.getType()
    let arg_repr = arg.getValueRepr()

    // 获取参数属性
    //let arg_idx = self.callee.getParamIndex(arg)
    let arg_attrs = callee.getArgAttrs(idx.reinterpret_as_uint())
    let arg_attrs_str = if not(arg_attrs.is_empty()) {
      " " + arg_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
    } else {
      ""
    }

    arg_strs.push("\{arg_ty}\{arg_attrs_str} \{arg_repr}")
  }
  let args_str = arg_strs.join(", ")
  let call_prefix = if tail_str.is_empty() {
    "call"
  } else {
    "\{tail_str} call"
  }
  if is_void_ret {
    logger.write_string(
      "  \{call_prefix}\{ret_attrs_str} \{ret_ty} @\{callee.name}(\{args_str})",
    )
  } else {
    logger.write_string(
      "  %\{prefix} = \{call_prefix}\{ret_attrs_str} \{ret_ty} @\{callee.name}(\{args_str})",
    )
  }
}

// =======================================================
// ExtractValueInst
// =======================================================

///|
pub struct ExtractValueInst {
  uid: UInt64
  vty: &Type
  users: Array[&User]
  mut name: String?
  aggregate : &Value
  inst_base : InstBase
  indices : Array[Int]
}

///|
fn ExtractValueInst::new(
  aggregate : &Value,
  indices : Array[Int],
  parent : Function,
  name~ : String? = None
) -> ExtractValueInst raise LLVMValueError {
  guard not(indices.is_empty()) else {
    raise ExtractValueInstRequiresNonEmptyIndices
  }

  // 验证聚合类型
  let agg_ty = aggregate.getType()
  guard agg_ty.tryAsAggregateTypeEnum() is Some(agg_ty) else {
    raise ExtractValueInstInvalidAggregateType(agg_ty)
  }
  guard agg_ty.getIndexedType(indices) is Some(result_ty) else {
    raise ExtractValueInstInvalidIndex(agg_ty.asTypeClass(), indices)
  }
  //let base = ValueBase::new(result_ty)
  let uid = valueUIDAssigner.assign()
  let vty = result_ty
  let inst_base = InstBase::new(parent)
  let inst = ExtractValueInst::{ uid, vty, users:[], name, aggregate, inst_base, indices }
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
  ValueBase::{
    uid: self.uid,
    vty: self.vty,
    users: self.users,
  }
}

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

pub impl NamedValue for ExtractValueInst with getName(self) {
  self.name
}

pub impl NamedValue for ExtractValueInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for ExtractValueInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
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
  UserBase::{
    operands: [self.aggregate],
  }
}

///|
pub impl Instruction for ExtractValueInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for ExtractValueInst with asInstEnum(self) {
  InstEnum::ExtractValueInst(self)
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

// =======================================================
// InsertValueInst
// =======================================================

///|
pub struct InsertValueInst {
  uid: UInt64
  vty: &Type
  users: Array[&User]
  aggregate : &Value
  insert_val : &Value
  mut name: String?
  inst_base : InstBase
  indices : Array[Int]
}

///|
fn InsertValueInst::new(
  aggregate : &Value,
  insert_val : &Value,
  indices : Array[Int],
  parent : Function,
  name~ : String? = None
) -> InsertValueInst raise LLVMValueError {
  guard not(indices.is_empty()) else {
    raise InsertValueInstRequiresNonEmptyIndices
  }

  let agg_ty = aggregate.getType()
  guard agg_ty.tryAsAggregateTypeEnum() is Some(agg_ty) else {
    raise InsertValueInstInvalidAggregateType(agg_ty)
  }
  guard agg_ty.getIndexedType(indices) is Some(_) else {
    raise InsertValueInstInvalidIndex(agg_ty.asTypeClass(), indices)
  }
  let uid = valueUIDAssigner.assign()
  let vty = agg_ty.asTypeClass()
  let inst_base = InstBase::new(parent)
  let inst = InsertValueInst::{ uid, vty, users:[], aggregate, insert_val, name, inst_base, indices }
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
  self : InsertValueInst
) -> &Value {
  self.insert_val
}

///|
pub fn InsertValueInst::getIndices(self : InsertValueInst) -> Array[Int] {
  self.indices
}

///|
pub impl Value for InsertValueInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty,
    users: self.users,
  }
}

///|
pub impl Value for InsertValueInst with asValueEnum(self) {
  InsertValueInst(self)
}

pub impl Value for InsertValueInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

pub impl NamedValue for InsertValueInst with getName(self) {
  self.name
}

pub impl NamedValue for InsertValueInst with setName(self, name) {
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for InsertValueInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
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
  UserBase::{
    operands: [self.aggregate, self.getInsertedValueOperand()],
  }
}

///|
pub impl Instruction for InsertValueInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for InsertValueInst with asInstEnum(self) {
  InstEnum::InsertValueInst(self)
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
