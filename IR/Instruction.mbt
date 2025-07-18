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
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  data_ty : &Type
  align : Align
}

///|
fn AllocaInst::new(
  data_ty : &Type,
  parent : Function,
  addressSpace~ : AddressSpace,
  name : String
) -> AllocaInst {
  let vty = data_ty.getContext().getPtrTy(addressSpace~)
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let align = parent.getDataLayout().getAlignment(data_ty)
  AllocaInst::{ base, user_base, inst_base, data_ty, align }
}

///|
pub impl Value for AllocaInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for AllocaInst with asValueEnum(self) {
  ValueEnum::AllocaInst(self)
}

///|
pub impl User for AllocaInst with asUserEnum(self) {
  UserEnum::AllocaInst(self)
}

///|
pub impl User for AllocaInst with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for AllocaInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for AllocaInst with asInstEnum(self) {
  InstEnum::AllocaInst(self)
}

///|
pub impl UnaryInst for AllocaInst with asUnaryInstEnum(self) {
  UnaryInstEnum::AllocaInst(self)
}

///|
pub impl Show for AllocaInst with output(self, logger) {
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if self.getParent().getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }
  logger.write_string("  %\{prefix} = alloca \{self.data_ty}, \{self.align}")
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
  base : ValueBase
  inst_base : InstBase
  user_base : UserBase
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
  name : String
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
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let align = parent.getDataLayout().getAlignment(load_ty)
  let inst = LoadInst::{
    base,
    inst_base,
    user_base,
    isVolatile,
    atomicOrdering,
    align,
  }
  inst.addOperand(ptr)
  inst
}

///|
pub impl Value for LoadInst with asValueEnum(self) {
  LoadInst(self)
}

///|
pub impl Value for LoadInst with getValueBase(self) {
  self.base
}

///|
pub impl User for LoadInst with asUserEnum(self) {
  UserEnum::LoadInst(self)
}

///|
pub impl User for LoadInst with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for LoadInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for LoadInst with asInstEnum(self) {
  InstEnum::LoadInst(self)
}

///|
pub impl UnaryInst for LoadInst with asUnaryInstEnum(self) {
  UnaryInstEnum::LoadInst(self)
}

///|
pub impl Show for LoadInst with output(self, logger) {
  let parent = self.getParent()
  let align = self.align
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }

  // 获取指针操作数
  let ptr = self.getOperand(0).unwrap()
  let ptr_str = match ptr.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(ptr) is Some(slot) => "%\{slot}"
    None if ptr.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let load_ty = self.getType()
  let str = match (self.isVolatile, self.atomicOrdering) {
    (true, _) =>
      "  %\{prefix} = load volatile \{load_ty}, ptr \{ptr_str}, \{align}"
    (false, NotAtomic) =>
      "  %\{prefix} = load \{load_ty}, ptr \{ptr_str}, \{align}"
    (false, _) =>
      "  %\{prefix} = load atomic \{load_ty}, ptr \{ptr_str} \{self.atomicOrdering}, \{align}"
  }
  logger.write_string(str)
}

// =======================================================
// StoreInst
// =======================================================

///|
pub struct StoreInst {
  base : ValueBase
  inst_base : InstBase
  user_base : UserBase
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
  let vty = value.getType()
  let base = ValueBase::new(vty.getContext().getVoidTy())
  let user_base = UserBase::new("")
  let inst_base = InstBase::new(parent)
  let align = parent.getDataLayout().getAlignment(vty)
  let inst = StoreInst::{
    base,
    inst_base,
    user_base,
    isVolatile,
    atomicOrdering,
    align,
  }
  inst..addOperand(value)..addOperand(ptr)
  inst
}

///|
pub fn StoreInst::getValueOperand(self : StoreInst) -> &Value {
  self.getOperand(0).unwrap()
}

///|
pub fn StoreInst::getPointerOperand(self : StoreInst) -> &Value {
  self.getOperand(1).unwrap()
}

///|
pub impl Value for StoreInst with asValueEnum(self) {
  StoreInst(self)
}

///|
pub impl Value for StoreInst with getValueBase(self) {
  self.base
}

///|
pub impl User for StoreInst with asUserEnum(self) {
  StoreInst(self)
}

///|
pub impl User for StoreInst with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for StoreInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for StoreInst with asInstEnum(self) {
  InstEnum::StoreInst(self)
}

///|
pub impl Show for StoreInst with output(self, logger) {
  let parent = self.getParent()
  let align = self.align
  let value = self.getValueOperand()
  let ptr = self.getPointerOperand()
  let value_ty = value.getType()
  let value_str = match value.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(value) is Some(slot) => "%\{slot}"
    None if value.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let ptr_str = match ptr.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(ptr) is Some(slot) => "%\{slot}"
    None if ptr.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let str = match (self.isVolatile, self.atomicOrdering) {
    (true, _) =>
      "  store volatile \{value_ty} \{value_str}, ptr \{ptr_str}, \{align}"
    (false, NotAtomic) =>
      "  store \{value_ty} \{value_str}, ptr \{ptr_str}, \{align}"
    (false, _) =>
      "  store atomic \{value_ty} \{value_str}, ptr \{ptr_str} \{self.atomicOrdering}, \{align}"
  }
  logger.write_string(str)
}

// =======================================================
// BinaryInstructions
// =======================================================

///|
pub struct BinaryInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
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
  name : String,
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
  guard lhsTy.tryAsIntegerTypeEnum() is Some(_) else {
    raise TypeNotSupportForBinaryOp(lhsTy, opcode)
  }
  let vty = lhsTy
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = BinaryInst::{
    base,
    user_base,
    inst_base,
    opcode,
    flags,
    fast_math_flags: Set::new(),
  }
  inst..addOperand(lhs)..addOperand(rhs)
  inst
}

///|
fn BinaryInst::newFPMathOp(
  opcode : BinaryOps,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name : String,
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
  let vty = lhsTy
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = BinaryInst::{
    base,
    user_base,
    inst_base,
    opcode,
    flags: Set::new(),
    fast_math_flags,
  }
  inst..addOperand(lhs)..addOperand(rhs)
  inst
}

///|
pub impl Value for BinaryInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for BinaryInst with asValueEnum(self) {
  BinaryInst(self)
}

///|
pub impl User for BinaryInst with asUserEnum(self) {
  BinaryInst(self)
}

///|
pub impl User for BinaryInst with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for BinaryInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for BinaryInst with asInstEnum(self) {
  InstEnum::BinaryInst(self)
}

///|
pub impl Show for BinaryInst with output(self, logger) {
  let parent = self.getParent()
  let ty = self.getType()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }
  let lhs = self.getOperand(0).unwrap()
  let rhs = self.getOperand(1).unwrap()
  let lhs_str = match lhs.getValueName() {
    Some(lhs) => "%\{lhs}"
    None if parent.getSlot(lhs) is Some(lhs_slot) => "%\{lhs_slot}"
    None if lhs.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let rhs_str = match rhs.getValueName() {
    Some(rhs) => "%\{rhs}"
    None if parent.getSlot(rhs) is Some(rhs_slot) => "%\{rhs_slot}"
    None if rhs.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
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
    "  %\{prefix} = \{self.opcode}\{flags_str} \{ty} \{lhs_str}, \{rhs_str}",
  )
}

// =======================================================
// CmpInst
// =======================================================

///|
pub(all) enum Predicate {
  /// Always false (always folded)
  FCMP_FALSE
  /// True if ordered and equal
  FCMP_OEQ
  /// True if ordered and greater than
  FCMP_OGT
  /// True if ordered and greater than or equal
  FCMP_OGE
  /// True if ordered and less than
  FCMP_OLT
  /// True if ordered and less than or equal
  FCMP_OLE
  /// True if ordered and operands are unequal
  FCMP_ONE
  /// True if ordered (no nans)
  FCMP_ORD
  /// True if unordered: isnan(X) | isnan(Y)
  FCMP_UNO
  /// True if unordered or equal
  FCMP_UEQ
  /// True if unordered or greater than
  FCMP_UGT
  /// True if unordered, greater than, or equal
  FCMP_UGE
  /// True if unordered or less than
  FCMP_ULT
  /// True if unordered, less than, or equal
  FCMP_ULE
  /// True if unordered or not equal
  FCMP_UNE
  /// Always true (always folded)
  FCMP_TRUE
  /// equal
  ICMP_EQ
  /// not equal
  ICMP_NE
  /// unsigned greater than
  ICMP_UGT
  /// unsigned greater or equal
  ICMP_UGE
  /// unsigned less than
  ICMP_ULT
  /// unsigned less or equal
  ICMP_ULE
  /// signed greater than
  ICMP_SGT
  /// signed greater or equal
  ICMP_SGE
  /// signed less than
  ICMP_SLT
  /// signed less or equal
  ICMP_SLE
}

///|
pub impl Show for Predicate with output(self, logger) {
  let str = match self {
    FCMP_FALSE => "fcmp false"
    FCMP_OEQ => "fcmp oeq"
    FCMP_OGT => "fcmp ogt"
    FCMP_OGE => "fcmp oge"
    FCMP_OLT => "fcmp olt"
    FCMP_OLE => "fcmp ole"
    FCMP_ONE => "fcmp one"
    FCMP_ORD => "fcmp ord"
    FCMP_UNO => "fcmp uno"
    FCMP_UEQ => "fcmp ueq"
    FCMP_UGT => "fcmp ugt"
    FCMP_UGE => "fcmp uge"
    FCMP_ULT => "fcmp ult"
    FCMP_ULE => "fcmp ule"
    FCMP_UNE => "fcmp une"
    FCMP_TRUE => "fcmp true"
    ICMP_EQ => "icmp eq"
    ICMP_NE => "icmp ne"
    ICMP_UGT => "icmp ugt"
    ICMP_UGE => "icmp uge"
    ICMP_ULT => "icmp ult"
    ICMP_ULE => "icmp ule"
    ICMP_SGT => "icmp sgt"
    ICMP_SGE => "icmp sge"
    ICMP_SLT => "icmp slt"
    ICMP_SLE => "icmp sle"
  }
  logger.write_string(str)
}

///|
pub struct CmpInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  predicate : Predicate
}

///|
fn CmpInst::new(
  predicate : Predicate,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name : String
) -> CmpInst raise LLVMValueError {
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy else { raise TypeMismatchForCmpInst(lhsTy, rhsTy) }
  let vty = parent.getContext().getInt1Ty()
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CmpInst::{ base, user_base, inst_base, predicate }
  inst..addOperand(lhs)..addOperand(rhs)
  inst
}

///|
impl Value for CmpInst with getValueBase(self) {
  self.base
}

///|
impl Value for CmpInst with asValueEnum(self) {
  CmpInst(self)
}

///|
impl User for CmpInst with asUserEnum(self) {
  CmpInst(self)
}

///|
impl User for CmpInst with getUserBase(self) {
  self.user_base
}

///|
impl Instruction for CmpInst with getInstBase(self) {
  self.inst_base
}

///|
impl Instruction for CmpInst with asInstEnum(self) {
  InstEnum::CmpInst(self)
}

///|
impl Show for CmpInst with output(self, logger) {
  let parent = self.getParent()
  let lhs = self.getOperand(0).unwrap()
  let rhs = self.getOperand(1).unwrap()
  let lhs_ty = lhs.getType()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }
  let lhs_str = match lhs.getValueName() {
    Some(lhs) => "%\{lhs}"
    None if parent.getSlot(lhs) is Some(lhs_slot) => "%\{lhs_slot}"
    None if lhs.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let rhs_str = match rhs.getValueName() {
    Some(rhs) => "%\{rhs}"
    None if parent.getSlot(rhs) is Some(rhs_slot) => "%\{rhs_slot}"
    None if rhs.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  logger.write_string(
    "  %\{prefix} = \{self.predicate} \{lhs_ty} \{lhs_str}, \{rhs_str}",
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
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  opcode : CastOps
}

///|
fn CastInst::newTrunc(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(src_ty) else {
    raise TruncCastInstTypeMismatch(src_val.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() > dst_ty.getBitWidth() else {
    raise TruncCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: Trunc }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newZExt(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(src_ty) else {
    raise ZExtCastInstTypeMismatch(src_val.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() < dst_ty.getBitWidth() else {
    raise ZExtCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: ZExt }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newSExt(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(src_ty) else {
    raise SExtCastInstTypeMismatch(src_val.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() < dst_ty.getBitWidth() else {
    raise SExtCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: SExt }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newFPTrunc(
  src_val : &Value,
  dst_ty : &FPType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsFPTypeEnum() is Some(src_ty) else {
    raise FPTruncCastInstTypeMismatch(src_val.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() > dst_ty.getBitWidth() else {
    raise FPTruncCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: FPTrunc }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newFPExt(
  src_val : &Value,
  dst_ty : &FPType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsFPTypeEnum() is Some(src_ty) else {
    raise FPExtCastInstTypeMismatch(src_val.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() < dst_ty.getBitWidth() else {
    raise FPExtCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: FPExt }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newUIToFP(
  src_val : &Value,
  dst_ty : &FPType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise UIToFPInstTypeMismatch(src_val.getType(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: UIToFP }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newFPToUI(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsFPTypeEnum() is Some(_) else {
    raise FPToUIInstTypeMismatch(src_val.getType(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: FPToUI }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newSIToFP(
  src_val : &Value,
  dst_ty : &FPType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise SIToFPInstTypeMismatch(src_val.getType(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: SIToFP }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newFPToSI(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsFPTypeEnum() is Some(_) else {
    raise FPToSIInstTypeMismatch(src_val.getType(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: FPToSI }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newPtrToInt(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().asTypeEnum() is PointerType(_) else {
    raise PtrToIntCastInstTypeMismatch(src_val.getType())
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: PtrToInt }
  inst.addOperand(src_val)
  inst
}

///|
fn CastInst::newIntToPtr(
  src_val : &Value,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise IntToPtrCastInstTypeMismatch(src_val.getType())
  }
  let vty = src_val.getContext().getPtrTy()
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: IntToPtr }
  inst.addOperand(src_val)
  inst
}

///|
/// REVIEW: Currently bitcast is only allowed between primitive types.
/// while in real cpp llvm, bitcast can be used to cast between aggregate types.
fn CastInst::newBitCast(
  src_val : &Value,
  dst_ty : &PrimitiveType,
  parent : Function,
  name : String
) -> CastInst raise LLVMValueError {
  let src_ty = src_val.getType()
  guard src_ty != dst_ty else { raise BitCastInstTypeMismatch(src_ty, dst_ty) }
  guard src_ty.tryAsPrimitiveTypeEnum() is Some(src_ty_prim) else {
    raise BitCastOnlyAcceptPrimitiveTypes(src_ty)
  }
  guard src_ty_prim.getBitWidth() == dst_ty.getBitWidth() else {
    raise BitCastInstTypeMismatch(src_ty, dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CastInst::{ base, user_base, inst_base, opcode: BitCast }
  inst.addOperand(src_val)
  inst
}

///|
pub impl Value for CastInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for CastInst with asValueEnum(self) {
  CastInst(self)
}

///|
pub impl User for CastInst with asUserEnum(self) {
  CastInst(self)
}

///|
pub impl User for CastInst with getUserBase(self) {
  self.user_base
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
  let parent = self.getParent()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }
  let src = self.getOperand(0).unwrap()
  let src_str = match src.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(src) is Some(s) => "%\{s}"
    None if src.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  logger.write_string(
    "  %\{prefix} = \{self.opcode} \{src.getType()} \{src_str}",
  )
}

// =======================================================
// GetElementPtrInst
// =======================================================

///|
pub struct GetElementPtrInst {
  base : ValueBase
  user_base : UserBase
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
  name : String
) -> GetElementPtrInst raise LLVMValueError {
  guard ptr.getType().asTypeEnum() is PointerType(_) else {
    raise GetElementPtrInstValueTypeNotPtr(ptr.getType())
  }
  guard pointeeType.isValidGEPType() else {
    raise GetElementPtrInstNotValidPointeeType(pointeeType)
  }
  for idx in indices {
    guard idx.getType().tryAsIntegerTypeEnum() is Some(_) else {
      raise GetElementPtrInstIndexNotInteger(idx.getType())
    }
  }
  let vty = pointeeType.getContext().getPtrTy()
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = GetElementPtrInst::{
    base,
    user_base,
    inst_base,
    isInbounds,
    pointeeType,
  }
  inst.addOperand(ptr)
  for idx in indices {
    inst.addOperand(idx)
  }
  inst
}

///|
impl Value for GetElementPtrInst with getValueBase(self) {
  self.base
}

///|
impl Value for GetElementPtrInst with asValueEnum(self) {
  GetElementPtrInst(self)
}

///|
impl User for GetElementPtrInst with asUserEnum(self) {
  GetElementPtrInst(self)
}

///|
impl User for GetElementPtrInst with getUserBase(self) {
  self.user_base
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
  let parent = self.getParent()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }

  // Format the pointer operand
  let ptr = self.getOperand(0).unwrap()
  let ptr_str = match ptr.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(ptr) is Some(slot) => "%\{slot}"
    None if ptr.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }

  // Format the indices
  let indices_strs = Array::new()
  let operand_count = self.getOperands().length()
  for i = 1; i < operand_count; i = i + 1 {
    let idx = self.getOperand(i).unwrap()
    let idx_str = match idx.getValueName() {
      Some(name) => "%\{name}"
      None if parent.getSlot(idx) is Some(slot) => "%\{slot}"
      None if idx.tryAsConstant() is Some(c) => c.valstr()
      _ => "<badref>"
    }
    indices_strs.push("\{idx.getType()} \{idx_str}")
  }
  let indices_str = if indices_strs.length() > 0 {
    ", " + indices_strs.join(", ")
  } else {
    ""
  }
  let inbounds_str = if self.isInbounds { " inbounds" } else { "" }
  logger.write_string(
    "  %\{prefix} = getelementptr\{inbounds_str} \{self.pointeeType}, ptr \{ptr_str}\{indices_str}",
  )
}

// =======================================================
// SelectInst
// =======================================================

///|
pub struct SelectInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
}

///|
fn SelectInst::new(
  condition : &Value,
  trueValue : &Value,
  falseValue : &Value,
  parent : Function,
  name : String
) -> SelectInst raise LLVMValueError {
  guard condition.getType().tryAsIntegerTypeEnum() is Some(intTy) &&
    intTy.getBitWidth() == 1 else {
    raise SelectInstConditionNotBoolean(condition.getType())
  }
  let vty = trueValue.getType()
  guard vty == falseValue.getType() else {
    raise SelectInstTypeMismatch(vty, falseValue.getType())
  }
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = SelectInst::{ base, user_base, inst_base }
  inst.addOperand(condition)
  inst.addOperand(trueValue)
  inst.addOperand(falseValue)
  inst
}

///|
pub fn SelectInst::getCondition(self : SelectInst) -> &Value {
  self.getOperand(0).unwrap()
}

///|
pub fn SelectInst::getTrueValue(self : SelectInst) -> &Value {
  self.getOperand(1).unwrap()
}

///|
pub fn SelectInst::getFalseValue(self : SelectInst) -> &Value {
  self.getOperand(2).unwrap()
}

///|
pub impl Value for SelectInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for SelectInst with asValueEnum(self) {
  SelectInst(self)
}

///|
pub impl User for SelectInst with asUserEnum(self) {
  SelectInst(self)
}

///|
pub impl User for SelectInst with getUserBase(self) {
  self.user_base
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
  let parent = self.getParent()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }
  let condition = self.getCondition()
  let trueValue = self.getTrueValue()
  let falseValue = self.getFalseValue()
  let condition_str = match condition.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(condition) is Some(slot) => "%\{slot}"
    None if condition.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let trueValue_str = match trueValue.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(trueValue) is Some(slot) => "%\{slot}"
    None if trueValue.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let falseValue_str = match falseValue.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(falseValue) is Some(slot) => "%\{slot}"
    None if falseValue.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let condition_ty = condition.getType()
  let value_ty = trueValue.getType()
  logger.write_string(
    "  %\{prefix} = select \{condition_ty} \{condition_str}, \{value_ty} \{trueValue_str}, \{value_ty} \{falseValue_str}",
  )
}

// =======================================================
// ReturnInst
// =======================================================

///|
pub struct ReturnInst {
  base : ValueBase
  user_base : UserBase
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
  let base = ValueBase::new(vty)
  let user_base = UserBase::new("")
  let inst_base = InstBase::new(parent)
  let inst = ReturnInst::{ base, user_base, inst_base }
  if retVal is Some(val) {
    inst.addOperand(val)
  }
  inst
}

///|
pub impl Value for ReturnInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for ReturnInst with asValueEnum(self) {
  ReturnInst(self)
}

///|
pub impl User for ReturnInst with asUserEnum(self) {
  ReturnInst(self)
}

///|
pub impl User for ReturnInst with getUserBase(self) {
  self.user_base
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
  let retStr = match self.getOperand(0) {
    Some(val) =>
      "\{val.getType()} " +
      (match val.getValueName() {
        Some(name) => "%\{name}"
        None if val.tryAsConstant() is Some(c) => c.valstr()
        None if self.getParent().getSlot(val) is Some(s) => "%\{s}"
        None => "<badref>"
      })
    None => "void"
  }
  logger.write_string("  ret \{retStr}")
}

// =======================================================
// BranchInst
// =======================================================

///|
pub struct BranchInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
}

///|
fn BranchInst::newConditional(
  condition : &Value,
  trueBlock : BasicBlock,
  falseBlock : BasicBlock,
  parent : Function
) -> BranchInst raise LLVMValueError {
  guard condition.getType().tryAsIntegerTypeEnum() is Some(intTy) else {
    raise BranchInstConditionNotBoolean(condition.getType())
  }
  guard intTy.getBitWidth() == 1 else {
    raise BranchInstConditionNotBoolean(condition.getType())
  }
  let base = ValueBase::new(parent.getContext().getVoidTy())
  let user_base = UserBase::new("")
  let inst_base = InstBase::new(parent)
  let inst = BranchInst::{ base, user_base, inst_base }
  inst.addOperand(condition)
  inst.addOperand(trueBlock)
  inst.addOperand(falseBlock)
  inst
}

///|
fn BranchInst::newUnconditional(
  targetBlock : BasicBlock,
  parent : Function
) -> BranchInst {
  let base = ValueBase::new(parent.getContext().getVoidTy())
  let user_base = UserBase::new("")
  let inst_base = InstBase::new(parent)
  let inst = BranchInst::{ base, user_base, inst_base }
  inst.addOperand(targetBlock)
  inst
}

///|
pub fn BranchInst::getCondition(self : Self) -> &Value? {
  if self.isConditional() {
    self.getOperand(0)
  } else {
    None
  }
}

///|
pub fn BranchInst::getNumSuccessors(self : Self) -> Int {
  1 + self.isConditional().to_int()
}

///|
pub fn BranchInst::getSuccessor(self : BranchInst, idx : Int) -> BasicBlock? {
  guard idx >= 0 && idx < self.getNumSuccessors() else { return None }
  let val = match self.isConditional() {
    true => self.getOperand(idx + 1).unwrap()
    false => self.getOperand(idx).unwrap()
  }
  guard val.asValueEnum() is BasicBlock(bb)
  Some(bb)
}

///|
pub fn BranchInst::isConditional(self : BranchInst) -> Bool {
  self.getNumOperands() == 3
}

///|
pub fn BranchInst::isUnconditional(self : BranchInst) -> Bool {
  self.getNumOperands() == 1
}

///|
pub impl Value for BranchInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for BranchInst with asValueEnum(self) {
  BranchInst(self)
}

///|
pub impl User for BranchInst with asUserEnum(self) {
  BranchInst(self)
}

///|
pub impl User for BranchInst with getUserBase(self) {
  self.user_base
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
  if self.getCondition() is Some(condition) {
    let parent = self.getParent()
    let condition_str = match condition.getValueName() {
      Some(name) => "%\{name}"
      None if parent.getSlot(condition) is Some(slot) => "%\{slot}"
      None if condition.tryAsConstant() is Some(c) => c.valstr()
      _ => "<badref>"
    }
    let true_block = self.getSuccessor(0).unwrap()
    let false_block = self.getSuccessor(1).unwrap()
    let true_block_str = match true_block.getValueName() {
      Some(name) => "%\{name}"
      None if parent.getSlot(true_block) is Some(slot) => "%\{slot}"
      _ => "<badref>"
    }
    let false_block_str = match false_block.getValueName() {
      Some(name) => "%\{name}"
      None if parent.getSlot(false_block) is Some(slot) => "%\{slot}"
      _ => "<badref>"
    }
    logger.write_string(
      "  br \{condition.getType()} \{condition_str}, label \{true_block_str}, label \{false_block_str}",
    )
  } else {
    let target_block = self.getSuccessor(0).unwrap()
    let parent = self.getParent()
    let target_block_str = match target_block.getValueName() {
      Some(name) => "%\{name}"
      None if parent.getSlot(target_block) is Some(slot) => "%\{slot}"
      _ => "<badref>"
    }
    logger.write_string("  br label \{target_block_str}")
  }
}

// =======================================================
// Switch Inst
// =======================================================

///|
pub struct SwitchInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
}

///|
fn SwitchInst::new(
  cond : &Value,
  defaultDest : BasicBlock,
  parent : Function
) -> SwitchInst raise LLVMValueError {
  guard cond.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise SwitchInstConditionNotInteger(cond.getType())
  }
  let vty = parent.getContext().getVoidTy()
  let base = ValueBase::new(vty)
  let user_base = UserBase::new("")
  let inst_base = InstBase::new(parent)
  let inst = SwitchInst::{ base, user_base, inst_base }
  inst.addOperand(cond)
  inst.addOperand(defaultDest)
  inst
}

///|
pub fn SwitchInst::getCondition(self : Self) -> &Value {
  self.getOperand(0).unwrap()
}

///|
pub fn SwitchInst::getDefaultDest(self : Self) -> BasicBlock {
  guard self.getOperand(1).unwrap().asValueEnum() is BasicBlock(bb)
  bb
}

///|
pub fn SwitchInst::getNumCases(self : Self) -> Int {
  self.getNumOperands() / 2 - 1
}

///|
pub fn SwitchInst::getCase(
  self : Self,
  idx : Int
) -> (ConstantInt, BasicBlock)? {
  guard idx >= 0 && idx < self.getNumCases() else { return None }
  let idx = idx + 1 // +1 for the default case
  let condidx = 2 * idx
  let destidx = condidx + 1
  let cond = self.getOperand(condidx).unwrap()
  let dest = self.getOperand(destidx).unwrap()
  guard cond.asValueEnum() is ConstantInt(c)
  guard dest.asValueEnum() is BasicBlock(bb)
  Some((c, bb))
}

///|
pub fn SwitchInst::addCase(
  self : Self,
  cond : ConstantInt,
  dest : BasicBlock
) -> Unit raise LLVMValueError {
  guard self.getCondition().getType().tryAsIntegerTypeEnum() is Some(intTy)
  guard cond.getType().tryAsIntegerTypeEnum() is Some(case_cond_ty)
  guard intTy == case_cond_ty else {
    let intTy = intTy.asTypeClass()
    let case_cond_ty = case_cond_ty.asTypeClass()
    raise SwitchInstCaseConditionTypeMismatch(intTy, case_cond_ty)
  }
  self.addOperand(cond)
  self.addOperand(dest)
}

///|
pub impl Value for SwitchInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for SwitchInst with asValueEnum(self) {
  SwitchInst(self)
}

///|
pub impl User for SwitchInst with asUserEnum(self) {
  SwitchInst(self)
}

///|
pub impl User for SwitchInst with getUserBase(self) {
  self.user_base
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
  let parent = self.getParent()
  let condition = self.getCondition()
  let condition_ty = condition.getType()

  // Format condition value
  let condition_str = match condition.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(condition) is Some(slot) => "%\{slot}"
    None if condition.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }

  // Format default destination
  let default_dest = self.getDefaultDest()
  let default_dest_str = match default_dest.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(default_dest) is Some(slot) => "%\{slot}"
    _ => "<badref>"
  }

  // Start with the switch statement
  logger.write_string(
    "  switch \{condition_ty} \{condition_str}, label \{default_dest_str} [",
  )

  // Add each case
  let num_cases = self.getNumCases()
  for i = 0; i < num_cases; i = i + 1 {
    if self.getCase(i) is Some((case_value, case_dest)) {
      let case_dest_str = match case_dest.getValueName() {
        Some(name) => "%\{name}"
        None if parent.getSlot(case_dest) is Some(slot) => "%\{slot}"
        _ => "<badref>"
      }
      logger.write_string(
        "\n    \{condition_ty} \{case_value.valstr()}, label \{case_dest_str}",
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
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
}

///|
fn PHINode::new(vty : &Type, parent : Function, name : String) -> PHINode {
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  PHINode::{ base, user_base, inst_base }
}

///|
pub fn PHINode::getNumIncomingValues(self : PHINode) -> Int {
  self.getNumOperands() / 2
}

///|
pub fn PHINode::getIncomingValue(self : PHINode, idx : Int) -> &Value? {
  guard idx >= 0 && idx < self.getNumIncomingValues() else { return None }
  self.getOperand(idx * 2)
}

///|
pub fn PHINode::getIncomingBlock(self : PHINode, idx : Int) -> BasicBlock? {
  guard idx >= 0 && idx < self.getNumIncomingValues() else { return None }
  guard self.getOperand(idx * 2 + 1) is Some(block_val) else { return None }
  guard block_val.asValueEnum() is BasicBlock(block) else { return None }
  Some(block)
}

///|
pub fn PHINode::getIncoming(self : PHINode, idx : Int) -> (&Value, BasicBlock)? {
  guard self.getOperand(idx * 2) is Some(value) else { return None }
  guard self.getOperand(idx * 2 + 1) is Some(block_val) else { return None }
  guard block_val.asValueEnum() is BasicBlock(block) else { return None }
  Some((value, block))
}

///|
pub fn PHINode::getIncomings(self : PHINode) -> Array[(&Value, BasicBlock)] {
  let num_incoming = self.getNumIncomingValues()
  let incomings = Array::new()
  for i in 0..<num_incoming {
    guard self.getOperand(i * 2) is Some(value)
    guard self.getOperand(i * 2 + 1) is Some(block_val)
    guard block_val.asValueEnum() is BasicBlock(block)
    incomings.push((value, block))
  }
  incomings
}

///|
pub fn PHINode::getIncomingValues(self : PHINode) -> Array[&Value] {
  let num_incoming = self.getNumIncomingValues()
  let values = Array::new()
  for i in 0..<num_incoming {
    guard self.getOperand(i * 2) is Some(value)
    values.push(value)
  }
  values
}

///|
pub fn PHINode::getIncomingBlocks(self : PHINode) -> Array[BasicBlock] {
  let num_incoming = self.getNumIncomingValues()
  let blocks = Array::new()
  for i in 0..<num_incoming {
    guard self.getOperand(i * 2 + 1) is Some(block_val)
    guard block_val.asValueEnum() is BasicBlock(block)
    blocks.push(block)
  }
  blocks
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
  self.addOperand(value)
  self.addOperand(block)
}

///|
pub impl Value for PHINode with getValueBase(self) {
  self.base
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
  self.user_base
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
  let parent = self.getParent()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }
  let ty = self.getType()
  let str = "  %\{prefix} = phi \{ty}"
  let num_incoming = self.getNumIncomingValues()
  let incoming_strs = Array::new()
  for i = 0; i < num_incoming; i = i + 1 {
    if self.getIncoming(i) is Some((value, block)) {
      let value_str = match value.getValueName() {
        Some(name) => "%\{name}"
        None if parent.getSlot(value) is Some(slot) => "%\{slot}"
        None if value.tryAsConstant() is Some(c) => c.valstr()
        _ => "<badref>"
      }
      let block_str = match block.getValueName() {
        Some(name) => "%\{name}"
        None if parent.getSlot(block) is Some(slot) => "%\{slot}"
        _ => "<badref>"
      }
      incoming_strs.push("[ \{value_str}, \{block_str} ]")
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
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  callee : Function
  mut tailCallKind : TailCallKind
}

///|
fn CallInst::new(
  callee : Function,
  args : Array[&Value],
  parent : Function,
  name : String
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
    ""
  } else {
    name
  }
  let ret_ty = fty.getReturnType()
  let base = ValueBase::new(ret_ty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = CallInst::{
    base,
    user_base,
    inst_base,
    callee,
    tailCallKind: NoTail,
  }
  inst.addOperand(callee)
  args.each(arg => inst.addOperand(arg))
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
  self.base
}

///|
pub impl Value for CallInst with asValueEnum(self) {
  CallInst(self)
}

///|
pub impl User for CallInst with asUserEnum(self) {
  CallInst(self)
}

///|
pub impl User for CallInst with getUserBase(self) {
  self.user_base
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
  let parent = self.getParent()

  // 获取被调用函数的信息
  let callee = self.callee
  let fty = callee.getFunctionType()
  let ret_ty = fty.getReturnType()
  let is_void_ret = ret_ty.asTypeEnum() is VoidType(_)

  // 格式化返回值名称或slot
  let prefix = if is_void_ret {
    "" // 如果返回类型是void，不需要前缀
  } else {
    match self.getName() {
      Some(name) => "\{name}"
      None if parent.getSlot(self) is Some(s) => "%\{s}"
      None => "<badref>"
    }
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
  let num_operands = self.getNumOperands()
  for i in 1..<num_operands { // 跳过第0个操作数（函数本身）
    let arg = self.getOperand(i).unwrap()
    let arg_ty = arg.getType()

    // 获取参数属性
    let arg_idx = (i - 1).reinterpret_as_uint()
    let arg_attrs = callee.getArgAttrs(arg_idx)
    let arg_attrs_str = match arg_attrs {
      Some(attrs) if not(attrs.is_empty()) =>
        " " + attrs.iter().map(fn(a) { "\{a}" }).join(" ")
      _ => ""
    }

    // 格式化参数值
    let arg_str = match arg.getValueName() {
      Some(name) => "%\{name}"
      None if parent.getSlot(arg) is Some(slot) => "%\{slot}"
      None if arg.tryAsConstant() is Some(c) => c.valstr()
      _ => "<badref>"
    }
    arg_strs.push("\{arg_ty}\{arg_attrs_str} \{arg_str}")
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
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  indices : Array[Int]
}

///|
fn ExtractValueInst::new(
  agg : &Value,
  indices : Array[Int],
  parent : Function,
  name : String
) -> ExtractValueInst raise LLVMValueError {
  guard not(indices.is_empty()) else {
    raise ExtractValueInstRequiresNonEmptyIndices
  }

  // 验证聚合类型
  let agg_ty = agg.getType()
  guard agg_ty.tryAsAggregateTypeEnum() is Some(agg_ty) else {
    raise ExtractValueInstInvalidAggregateType(agg_ty)
  }
  guard agg_ty.getIndexedType(indices) is Some(result_ty) else {
    raise ExtractValueInstInvalidIndex(agg_ty.asTypeClass(), indices)
  }
  let base = ValueBase::new(result_ty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = ExtractValueInst::{ base, user_base, inst_base, indices }
  inst.addOperand(agg)
  inst
}

///|
pub fn ExtractValueInst::getAggregateOperand(self : ExtractValueInst) -> &Value {
  self.getOperand(0).unwrap()
}

///|
pub fn ExtractValueInst::getIndices(self : ExtractValueInst) -> Array[Int] {
  self.indices
}

///|
pub impl Value for ExtractValueInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for ExtractValueInst with asValueEnum(self) {
  ExtractValueInst(self)
}

///|
pub impl User for ExtractValueInst with asUserEnum(self) {
  ExtractValueInst(self)
}

///|
pub impl User for ExtractValueInst with getUserBase(self) {
  self.user_base
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
  let parent = self.getParent()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }
  let agg = self.getAggregateOperand()
  let agg_ty = agg.getType()
  let agg_str = match agg.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(agg) is Some(slot) => "%\{slot}"
    None if agg.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let indices_str = self.indices.iter().map(i => "\{i}").join(", ")
  logger.write_string(
    "  %\{prefix} = extractvalue \{agg_ty} \{agg_str}, \{indices_str}",
  )
}

// =======================================================
// InsertValueInst
// =======================================================

///|
pub struct InsertValueInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  indices : Array[Int]
}

///|
fn InsertValueInst::new(
  agg : &Value,
  val : &Value,
  indices : Array[Int],
  parent : Function,
  name : String
) -> InsertValueInst raise LLVMValueError {
  guard not(indices.is_empty()) else {
    raise InsertValueInstRequiresNonEmptyIndices
  }

  // 验证聚合类型
  let agg_ty = agg.getType()
  guard agg_ty.tryAsAggregateTypeEnum() is Some(agg_ty) else {
    raise InsertValueInstInvalidAggregateType(agg_ty)
  }
  guard agg_ty.getIndexedType(indices) is Some(_) else {
    raise InsertValueInstInvalidIndex(agg_ty.asTypeClass(), indices)
  }
  let base = ValueBase::new(agg_ty.asTypeClass())
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let inst = InsertValueInst::{ base, user_base, inst_base, indices }
  inst.addOperand(agg)
  inst.addOperand(val)
  inst
}

///|
pub fn InsertValueInst::getAggregateOperand(self : InsertValueInst) -> &Value {
  self.getOperand(0).unwrap()
}

///|
pub fn InsertValueInst::getInsertedValueOperand(
  self : InsertValueInst
) -> &Value {
  self.getOperand(1).unwrap()
}

///|
pub fn InsertValueInst::getIndices(self : InsertValueInst) -> Array[Int] {
  self.indices
}

///|
pub impl Value for InsertValueInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for InsertValueInst with asValueEnum(self) {
  InsertValueInst(self)
}

///|
pub impl User for InsertValueInst with asUserEnum(self) {
  InsertValueInst(self)
}

///|
pub impl User for InsertValueInst with getUserBase(self) {
  self.user_base
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
  let parent = self.getParent()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badref>"
  }
  let agg = self.getAggregateOperand()
  let val = self.getInsertedValueOperand()
  let agg_ty = agg.getType()
  let val_ty = val.getType()
  let agg_str = match agg.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(agg) is Some(slot) => "%\{slot}"
    None if agg.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let val_str = match val.getValueName() {
    Some(name) => "%\{name}"
    None if parent.getSlot(val) is Some(slot) => "%\{slot}"
    None if val.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let indices_str = self.indices.iter().map(i => "\{i}").join(", ")
  logger.write_string(
    "  %\{prefix} = insertvalue \{agg_ty} \{agg_str}, \{val_ty} \{val_str}, \{indices_str}",
  )
}
