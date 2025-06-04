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
) -> LoadInst!LLVMValueError {
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
  user_base.operands.push(ptr)
  let align = parent.getDataLayout().getAlignment(load_ty)
  LoadInst::{ base, inst_base, user_base, isVolatile, atomicOrdering, align }
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
) -> StoreInst!LLVMValueError {
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
  user_base.operands.push(value)
  user_base.operands.push(ptr)
  let align = parent.getDataLayout().getAlignment(vty)
  StoreInst::{ base, inst_base, user_base, isVolatile, atomicOrdering, align }
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
pub struct BinaryInstruction {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  opcode : BinaryOps
  flags : Set[BinaryOpFlags]
  fast_math_flags : Set[FastMathFlag]
}

///|
fn BinaryInstruction::newStandardOp(
  opcode : BinaryOps,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name : String,
  flags : Set[BinaryOpFlags]
) -> BinaryInstruction!LLVMValueError {
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
    unreachable(
      "Should not call BinaryInstruction::newStandardOp with opcode \{opcode}",
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
  user_base.operands.push(lhs)
  user_base.operands.push(rhs)
  BinaryInstruction::{
    base,
    user_base,
    inst_base,
    opcode,
    flags,
    fast_math_flags: Set::new(),
  }
}

///|
fn BinaryInstruction::newFPMathOp(
  opcode : BinaryOps,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name : String,
  fast_math_flags : Set[FastMathFlag]
) -> BinaryInstruction!LLVMValueError {
  guard opcode is (FAdd | FSub | FMul | FDiv | FRem) else {
    unreachable(
      "Should not call BinaryInstruction::newFPMathOp with opcode \{opcode}",
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
  user_base.operands.push(lhs)
  user_base.operands.push(rhs)
  BinaryInstruction::{
    base,
    user_base,
    inst_base,
    opcode,
    flags: Set::new(),
    fast_math_flags,
  }
}

///|
pub impl Value for BinaryInstruction with getValueBase(self) {
  self.base
}

///|
pub impl Value for BinaryInstruction with asValueEnum(self) {
  BinaryInstruction(self)
}

///|
pub impl User for BinaryInstruction with asUserEnum(self) {
  BinaryInstruction(self)
}

///|
pub impl User for BinaryInstruction with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for BinaryInstruction with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for BinaryInstruction with asInstEnum(self) {
  InstEnum::BinaryInstruction(self)
}

///|
pub impl Show for BinaryInstruction with output(self, logger) {
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
  let flags_str = self.flags.iter().map(fn { f => "\{f}" }).join(" ")
  let flags_str = if flags_str.is_empty() { "" } else { " " + flags_str }
  let fast_math_flags_str = self.fast_math_flags
    .iter()
    .map(fn { f => "\{f}" })
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
) -> CmpInst!LLVMValueError {
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy else { raise TypeMismatchForCmpInst(lhsTy, rhsTy) }
  let vty = parent.getContext().getInt1Ty()
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  user_base.operands.push(lhs)
  user_base.operands.push(rhs)
  CmpInst::{ base, user_base, inst_base, predicate }
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
) -> CastInst!LLVMValueError {
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
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: Trunc }
}

///|
fn CastInst::newZExt(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
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
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: ZExt }
}

///|
fn CastInst::newSExt(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
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
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: SExt }
}

///|
fn CastInst::newFPTrunc(
  src_val : &Value,
  dst_ty : &FPType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
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
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: FPTrunc }
}

///|
fn CastInst::newFPExt(
  src_val : &Value,
  dst_ty : &FPType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
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
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: FPExt }
}

///|
fn CastInst::newUIToFP(
  src_val : &Value,
  dst_ty : &FPType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise UIToFPInstTypeMismatch(src_val.getType(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: UIToFP }
}

///|
fn CastInst::newFPToUI(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
  guard src_val.getType().tryAsFPTypeEnum() is Some(_) else {
    raise FPToUIInstTypeMismatch(src_val.getType(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: FPToUI }
}

///|
fn CastInst::newSIToFP(
  src_val : &Value,
  dst_ty : &FPType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise SIToFPInstTypeMismatch(src_val.getType(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: SIToFP }
}

///|
fn CastInst::newFPToSI(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
  guard src_val.getType().tryAsFPTypeEnum() is Some(_) else {
    raise FPToSIInstTypeMismatch(src_val.getType(), dst_ty)
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: FPToSI }
}

///|
fn CastInst::newPtrToInt(
  src_val : &Value,
  dst_ty : &IntegerType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
  guard src_val.getType().asTypeEnum() is PointerType(_) else {
    raise PtrToIntCastInstTypeMismatch(src_val.getType())
  }
  let vty = dst_ty
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: PtrToInt }
}

///|
fn CastInst::newIntToPtr(
  src_val : &Value,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
  guard src_val.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise IntToPtrCastInstTypeMismatch(src_val.getType())
  }
  let vty = src_val.getContext().getPtrTy()
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: IntToPtr }
}

///|
/// REVIEW: Currently bitcast is only allowed between primitive types.
/// while in real cpp llvm, bitcast can be used to cast between aggregate types.
fn CastInst::newBitCast(
  src_val : &Value,
  dst_ty : &PrimitiveType,
  parent : Function,
  name : String
) -> CastInst!LLVMValueError {
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
  user_base.operands.push(src_val)
  CastInst::{ base, user_base, inst_base, opcode: BitCast }
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
) -> GetElementPtrInst!LLVMValueError {
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
  user_base.operands.push(ptr)
  for idx in indices {
    user_base.operands.push(idx)
  }
  GetElementPtrInst::{ base, user_base, inst_base, isInbounds, pointeeType }
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
) -> SelectInst!LLVMValueError {
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
  user_base.operands.push(condition)
  user_base.operands.push(trueValue)
  user_base.operands.push(falseValue)
  SelectInst::{ base, user_base, inst_base }
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
) -> ReturnInst!LLVMValueError {
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
  if retVal is Some(val) {
    user_base.operands.push(val)
  }
  ReturnInst::{ base, user_base, inst_base }
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
) -> BranchInst!LLVMValueError {
  guard condition.getType().tryAsIntegerTypeEnum() is Some(intTy) else {
    raise BranchInstConditionNotBoolean(condition.getType())
  }
  guard intTy.getBitWidth() == 1 else {
    raise BranchInstConditionNotBoolean(condition.getType())
  }
  let base = ValueBase::new(parent.getContext().getVoidTy())
  let user_base = UserBase::new("")
  let inst_base = InstBase::new(parent)
  user_base.operands.push(condition)
  user_base.operands.push(trueBlock)
  user_base.operands.push(falseBlock)
  BranchInst::{ base, user_base, inst_base }
}

///|
fn BranchInst::newUnconditional(
  targetBlock : BasicBlock,
  parent : Function
) -> BranchInst {
  let base = ValueBase::new(parent.getContext().getVoidTy())
  let user_base = UserBase::new("")
  let inst_base = InstBase::new(parent)
  user_base.operands.push(targetBlock)
  BranchInst::{ base, user_base, inst_base }
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
