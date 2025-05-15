///|
pub enum ValueEnum {

  // ======= Constant Values =======
  /// The following two is global values.
  //Function(Function)
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
  //ConstantFP(ConstantFP)
  //ConstantAggregateZero(ConstantAggregateZero)
  //ConstantAggregate(ConstantAggregate)
  //ConstantArray(ConstantArray)
  //ConstantStruct(ConstantStruct)
  //ConstantVector(ConstantVector)
  //ConstantPointerNull(ConstantPointerNull)
  //ConstantDataArray(ConstantDataArray)
  //ConstantDataVector(ConstantDataVector)
  //ConstantTokenNone(ConstantTokenNone)
  //UndefValue(UndefValue)
  //PoisonValue(PoisonValue)
  //
  //BlockAddress(BlockAddress)
  //ConstantExpr(ConstantExpr)

  // ======= Instruction Values =======
  // ------- Unary Instruction
  // AllocaInst(AllocaInst)
  // LoadInst(LoadInst)
  // VAArgInst(VAArgInst)
  // ExtractValueInst(ExtractValueInst)
  // FreezeInst(FreezeInst)
  // CastInst(CastInst)
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
  // Argument(Argument)
  // BasicBlock(BasicBlock)
  // InlineAsm(InlineAsm)
  // MetadataAsValue(MetadataAsValue)
}

///|
pub trait Value: Show + Hash {
  base(Self) -> ValueBase

  // All values are typed, get the type of this value.
  getType(Self) -> &Type = _

  // All values hold a context through their type.
  getContext(Self) -> LLVMContext = _

  /// All values can potentially be named.
  /// use `getName() is None` to check if a value has no name.
  getName(Self) -> String? = _

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

///|
impl Value with getName(self) {
  self.base().name
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
  name : String?
  users : Array[&Value]
  // uses: Array[&Value]
} derive(Eq, Hash)

//trait User: Value {
//  getOperands(Self) -> Array[&Value]
//}

// ====================================================================
// ConstantInt
// ====================================================================

///|
pub struct ConstantInt {
  base : ValueBase
  value : MbtSignedEnum
} derive(Eq, Hash)

// TODO: eliminate guard in the future.
///|
fn ConstantInt::new(
  vty : &Type,
  value : &MbtSigned
) -> ConstantInt!LLVMValueError {
  guard vty.asTypeEnum() is IntegerType(ity) else {
    unreachable("ConstantInt::new: vty is not IntegerType")
  }
  let value = match (ity.getBitWidth(), value.asEnum()) {
    (8, Int8(b)) => Int8(b)
    (16, Int16(b)) => Int16(b)
    (32, Int32(b)) => Int32(b)
    (64, Int64(b)) => Int64(b)
    (1, _) => raise ConstantIntTypeShouldNotBe1
    _ => raise ConstantIntTypeMismatch(vty, value.asEnum())
  }
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantInt::{ base, value }
}

///|
pub fn ConstantInt::getValueWithInt64(self : ConstantInt) -> Int64 {
  match self.value {
    Int8(b) => b.to_int64()
    Int16(b) => b.to_int64()
    Int32(b) => b.to_int64()
    Int64(b) => b
  }
}

///|
pub fn ConstantInt::getIntegerType(self : ConstantInt) -> IntegerType {
  guard self.getType().asTypeEnum() is IntegerType(ity)
  ity
}

///|
pub fn ConstantInt::equalsInt(self : ConstantInt, value : &MbtSigned) -> Bool {
  match (self.value, value.asEnum()) {
    (Int8(b1), Int8(b2)) => b1 == b2
    (Int16(b1), Int16(b2)) => b1 == b2
    (Int32(b1), Int32(b2)) => b1 == b2
    (Int64(b1), Int64(b2)) => b1 == b2
    _ => false
  }
}

///|
pub fn ConstantInt::isNegative(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b > 127
    Int16(b) => b < 0
    Int32(b) => b < 0
    Int64(b) => b < 0
  }
}

///|
pub fn ConstantInt::isZero(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == 0
    Int16(b) => b == 0
    Int32(b) => b == 0
    Int64(b) => b == 0
  }
}

///|
pub fn ConstantInt::isOne(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == 1
    Int16(b) => b == 1
    Int32(b) => b == 1
    Int64(b) => b == 1
  }
}

///|
pub fn ConstantInt::isMinusOne(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == 255
    Int16(b) => b == -1
    Int32(b) => b == -1
    Int64(b) => b == -1
  }
}

///|
pub fn ConstantInt::isMaxValue(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == 127
    Int16(b) => b == @int16.max_value
    Int32(b) => b == @int.max_value
    Int64(b) => b == @int64.max_value
  }
}

///|
pub fn ConstantInt::isMinValue(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == 128
    Int16(b) => b == @int16.min_value
    Int32(b) => b == @int.min_value
    Int64(b) => b == @int64.min_value
  }
}

///|
impl Value for ConstantInt with base(self) {
  self.base
}

///|
pub impl Show for ConstantInt with output(self, logger) {
  let val_str = match self.value {
    Int8(b) => b.to_int().to_string()
    _ => self.value.asClass().to_string()
  }
  logger.write_string("\{self.getIntegerType()} \{val_str}")
}

// ====================================================================
// ConstantUInt
// ====================================================================

///|
pub struct ConstantUInt {
  base : ValueBase
  value : MbtUnsignedEnum
} derive(Eq, Hash)

///|
fn ConstantUInt::new(
  vty : &Type,
  value : &MbtUnsigned
) -> ConstantUInt!LLVMValueError {
  guard vty.asTypeEnum() is IntegerType(ity) else {
    unreachable("ConstantUInt::new: vty is not IntegerType")
  }
  let value = match (ity.getBitWidth(), value.asEnum()) {
    (8, UInt8(b)) => UInt8(b)
    (16, UInt16(b)) => UInt16(b)
    (32, UInt32(b)) => UInt32(b)
    (64, UInt64(b)) => UInt64(b)
    (1, _) => raise ConstantUIntTypeShouldNotBe1
    _ => raise ConstantUIntTypeMismatch(vty, value.asEnum())
  }
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantUInt::{ base, value }
}

///|
pub fn ConstantUInt::getValueWithUInt64(self : ConstantUInt) -> UInt64 {
  match self.value {
    UInt8(b) => b.to_uint64()
    UInt16(b) => b.to_int().to_uint64()
    UInt32(b) => b.to_uint64()
    UInt64(b) => b
  }
}

///|
pub fn ConstantUInt::getIntegerType(self : ConstantUInt) -> IntegerType {
  guard self.getType().asTypeEnum() is IntegerType(ity)
  ity
}

///|
pub fn ConstantUInt::equalsInt(
  self : ConstantUInt,
  value : &MbtUnsigned
) -> Bool {
  match (self.value, value.asEnum()) {
    (UInt8(b1), UInt8(b2)) => b1 == b2
    (UInt16(b1), UInt16(b2)) => b1 == b2
    (UInt32(b1), UInt32(b2)) => b1 == b2
    (UInt64(b1), UInt64(b2)) => b1 == b2
    _ => false
  }
}

///|
pub fn ConstantUInt::isZero(self : ConstantUInt) -> Bool {
  match self.value {
    UInt8(b) => b == 0
    UInt16(b) => b == 0
    UInt32(b) => b == 0
    UInt64(b) => b == 0
  }
}

///|
pub fn ConstantUInt::isOne(self : ConstantUInt) -> Bool {
  match self.value {
    UInt8(b) => b == 1
    UInt16(b) => b == 1
    UInt32(b) => b == 1
    UInt64(b) => b == 1
  }
}

///|
pub fn ConstantUInt::isMaxValue(self : ConstantUInt) -> Bool {
  match self.value {
    UInt8(b) => b == 255
    UInt16(b) => b == @uint16.max_value
    UInt32(b) => b == @uint.max_value
    UInt64(b) => b == @uint64.max_value
  }
}

///|
pub fn ConstantUInt::isMinValue(self : ConstantUInt) -> Bool {
  match self.value {
    UInt8(b) => b == 0
    UInt16(b) => b == 0
    UInt32(b) => b == 0
    UInt64(b) => b == 0
  }
}

///|
impl Value for ConstantUInt with base(self) {
  self.base
}

///|
pub impl Show for ConstantUInt with output(self, logger) {
  let val_str = match self.value {
    UInt8(b) => b.to_int().to_string()
    _ => self.value.asClass().to_string()
  }
  logger.write_string("\{self.getIntegerType()} \{val_str}")
}

// ====================================================================
// ConstantBool
// ====================================================================

///|
pub struct ConstantBool {
  base : ValueBase
  value : Bool
} derive(Eq, Hash)

///|
fn ConstantBool::new(ctx : LLVMContext, value : Bool) -> ConstantBool {
  let vty = ctx.getInt1Ty()
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantBool::{ base, value }
}

///|
pub fn ConstantBool::getValue(self : ConstantBool) -> Bool {
  self.value
}

///|
pub fn ConstantBool::isTrue(self : ConstantBool) -> Bool {
  self.value
}

///|
pub fn ConstantBool::isFalse(self : ConstantBool) -> Bool {
  self.value |> not
}

///|
impl Value for ConstantBool with base(self) {
  self.base
}

///|
pub impl Show for ConstantBool with output(self, logger) {
  let val_str = match self.value {
    true => 1
    false => 0
  }
  logger.write_string("\{self.getType()} \{val_str}")
}
