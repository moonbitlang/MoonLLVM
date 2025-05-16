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
  asValueEnum(Self) -> ValueEnum

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

///| ConstantInt
///
/// Use `LLVMContext::getConstInt8, getConstInt16, getConstInt32, getConstInt64`
/// To create a new ConstantInt.
///
/// ```moonbit
/// test "Constant Signed Integer" {
///   let ctx = LLVMContext::new()
///   let i8 = ctx.getConstInt8(0)
///   let i16 = ctx.getConstInt16(1)
///   let i32 = ctx.getConstInt32(-2)
///   let i64 = ctx.getConstInt64(16)
///
///   inspect!(i8, content="i8 0")
///   inspect!(i16, content="i16 1")
///   inspect!(i32, content="i32 -2")
///   inspect!(i64, content="i64 16")
/// }
/// ```
pub struct ConstantInt {
  base : ValueBase
  value : MbtSignedEnum
} derive(Eq, Hash)

// TODO: eliminate guard in the future.
///|
fn ConstantInt::new[T : MbtSigned](vty : &Type, value : T) -> ConstantInt {
  guard vty.asTypeEnum() is IntegerType(ity) else {
    unreachable("ConstantInt::new: vty is not IntegerType")
  }
  let value = match (ity.getBitWidth(), value.asEnum()) {
    (8, Int8(b)) => Int8(b)
    (16, Int16(s)) => Int16(s)
    (32, Int32(i)) => Int32(i)
    (64, Int64(l)) => Int64(l)
    (1, _) =>
      unreachable("ConstantInt::new: i1 type could not create constant int")
    _ => unreachable("Type MisMatch")
  }
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantInt::{ base, value }
}

///|
fn ConstantInt::getValue(self : ConstantInt) -> MbtSignedEnum {
  self.value
}

///| Get the value of this constant as a signed 64-bits integer.
///
/// ```moonbit
/// test "ConstantInt getValueAsInt64" {
///   let ctx = LLVMContext::new()
///
///   let i8_zero = ctx.getConstInt8(0)
///   let i16_one = ctx.getConstInt16(1)
///   let i32_two = ctx.getConstInt32(2)
///   let i64_m1 = ctx.getConstInt64(-1)
///   let i8_m1 = ctx.getConstInt8(-1)
///
///   assert_eq!(i8_zero.getValueAsInt64(), 0)
///   assert_eq!(i16_one.getValueAsInt64(), 1)
///   assert_eq!(i32_two.getValueAsInt64(), 2)
///   assert_eq!(i64_m1.getValueAsInt64(), -1)
///   assert_eq!(i8_m1.getValueAsInt64(), -1)
/// }
/// ```
pub fn ConstantInt::getValueAsInt64(self : ConstantInt) -> Int64 {
  self.value.to_int64()
}

///| Get the type of constant int value.
///
/// ```moonbit
/// test "ConstantInt getIntegerType" {
///   let ctx = LLVMContext::new()
///
///   let i8_zero = ctx.getConstInt8(0)
///   let i16_one = ctx.getConstInt16(1)
///   let i32_m2 = ctx.getConstInt32(-2)
///   let i64_m16 = ctx.getConstInt64(-16)
///
///   inspect!(i8_zero.getIntegerType(), content="i8")
///   inspect!(i16_one.getIntegerType(), content="i16")
///   inspect!(i32_m2.getIntegerType(), content="i32")
///   inspect!(i64_m16.getIntegerType(), content="i64")
/// }
/// ```
pub fn ConstantInt::getIntegerType(self : ConstantInt) -> IntegerType {
  guard self.getType().asTypeEnum() is IntegerType(ity)
  ity
}

///| Compare the value of this constant int with a signed integer.
///
/// ```moonbit
/// test "ConstantInt equals" {
///   let ctx = LLVMContext::new()
///
///   assert_true!(ctx.getConstInt8(0).equals(0))
///   assert_true!(ctx.getConstInt8(-1).equals(-1))
///   assert_true!(ctx.getConstInt8(1).equals(1))
///   assert_true!(ctx.getConstInt16(16).equals(16))
///   assert_true!(ctx.getConstInt32(-128).equals(-128))
/// }
/// ```
pub fn ConstantInt::equals[T : MbtSigned](
  self : ConstantInt,
  value : T
) -> Bool {
  self.value.to_int64() == value.to_int64()
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
impl Value for ConstantInt with asValueEnum(self) {
  ConstantInt(self)
}

///|
pub impl Show for ConstantInt with output(self, logger) {
  let val_str = match self.value {
    Int8(b) =>
      match b.to_int() {
        0..=127 as v => v.to_string()
        v => (v - 256).to_string()
      }
    _ => self.value.asClass().to_string()
  }
  logger.write_string("\{self.getIntegerType()} \{val_str}")
}

// ====================================================================
// ConstantUInt
// ====================================================================

///| ConstantUInt.
///
/// Use `LLVMContext::getConstUInt8, getConstUInt16, getConstUInt32, getConstUInt64` 
/// to create a new ConstantUInt.
///
/// ```moonbit
/// test "Constant Unsigned Integer" {
///   let ctx = LLVMContext::new()
///
///   let i8 = ctx.getConstUInt8(0)
///   let i16 = ctx.getConstUInt16(1)
///   let i32 = ctx.getConstUInt32(2)
///   let i64 = ctx.getConstUInt64(16)
///
///   inspect!(i8, content="i8 0")
///   inspect!(i16, content="i16 1")
///   inspect!(i32, content="i32 2")
///   inspect!(i64, content="i64 16")
/// }
/// ```
pub struct ConstantUInt {
  base : ValueBase
  value : MbtUnsignedEnum
} derive(Eq, Hash)

///|
fn ConstantUInt::new[T : MbtUnsigned](vty : &Type, value : T) -> ConstantUInt {
  guard vty.asTypeEnum() is IntegerType(ity) else {
    unreachable("ConstantUInt::new: vty is not IntegerType")
  }
  let value = match (ity.getBitWidth(), value.asEnum()) {
    (8, UInt8(b)) => UInt8(b)
    (16, UInt16(s)) => UInt16(s)
    (32, UInt32(i)) => UInt32(i)
    (64, UInt64(l)) => UInt64(l)
    (1, _) =>
      unreachable("ConstantUInt::new: i1 type could not create constant int")
    _ => unreachable("ConstantUInt::new: Type MisMatch")
  }
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantUInt::{ base, value }
}

fn ConstantUInt::getValue(self : ConstantUInt) -> MbtUnsignedEnum {
  self.value
}

///| Get the value of this constant as a unsigned 64-bits integer.
///
/// ```moonbit
/// test "ConstantUInt getValueAsUInt64" {
///   let ctx = LLVMContext::new()
///
///   let i8_zero = ctx.getConstUInt8(0)
///   let i16_one = ctx.getConstUInt16(1)
///   let i32_two = ctx.getConstUInt32(2)
///   let i64_four = ctx.getConstUInt64(4)
///
///   assert_eq!(i8_zero.getValueAsUInt64(), 0)
///   assert_eq!(i16_one.getValueAsUInt64(), 1)
///   assert_eq!(i32_two.getValueAsUInt64(), 2)
///   assert_eq!(i64_four.getValueAsUInt64(), 4)
/// }
/// ```
pub fn ConstantUInt::getValueAsUInt64(self : ConstantUInt) -> UInt64 {
  self.value.to_uint64()
}

///| Get the type of constant int value.
///
/// - See LLVM: `ConstantInt::getIntegerType`
///
/// ```moonbit
/// test "ConstantUInt getIntegerType" {
///   let ctx = LLVMContext::new()
///
///   let i8_zero = ctx.getConstUInt8(0)
///   let i16_one = ctx.getConstUInt16(1)
///   let i32_two = ctx.getConstUInt32(2)
///   let i64_four = ctx.getConstUInt64(4)
///
///   inspect!(i8_zero.getIntegerType(), content="i8")
///   inspect!(i16_one.getIntegerType(), content="i16")
///   inspect!(i32_two.getIntegerType(), content="i32")
///   inspect!(i64_four.getIntegerType(), content="i64")
/// }
/// ```
pub fn ConstantUInt::getIntegerType(self : ConstantUInt) -> IntegerType {
  guard self.getType().asTypeEnum() is IntegerType(ity)
  ity
}

///| Compare the value of this constant int with a unsigned integer.
///
/// ```moonbit
/// test "ConstantUInt equals" {
///   let ctx = LLVMContext::new()
///
///   assert_true!(ctx.getConstUInt8(0).equals(0U))
///   assert_true!(ctx.getConstUInt8(1).equals(1U))
///   assert_true!(ctx.getConstUInt8(4).equals(4U))
///   assert_true!(ctx.getConstUInt8(255).equals(255U))
/// }
/// ```
pub fn ConstantUInt::equals[T : MbtUnsigned](
  self : ConstantUInt,
  value : T
) -> Bool {
  self.value.to_uint64() == value.to_uint64()
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
impl Value for ConstantUInt with base(self) {
  self.base
}

///|
impl Value for ConstantUInt with asValueEnum(self) {
  ConstantUInt(self)
}

///|
pub impl Show for ConstantUInt with output(self, logger) {
  let val_str = match self.value {
    UInt8(b) => b.to_uint().to_string()
    _ => self.value.asClass().to_string()
  }
  logger.write_string("\{self.getIntegerType()} \{val_str}")
}

// ====================================================================
// ConstantBool
// ====================================================================

///| ConstantBool.
///
/// ```moonbit
/// test "Constant Bool" {
///   let ctx = LLVMContext::new()
///
///   let true_val = ctx.getConstTrue()
///   let false_val = ctx.getConstFalse()
///
///   inspect!(true_val, content="i1 true")
///   inspect!(false_val, content="i1 false")
///
///   let true_val = ctx.getConstBool(true)
///   let false_val = ctx.getConstBool(false)
///
///   inspect!(true_val, content="i1 true")
///   inspect!(false_val, content="i1 false")
/// }
/// ```
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
impl Value for ConstantBool with base(self) {
  self.base
}

///|
impl Value for ConstantBool with asValueEnum(self) {
  ConstantBool(self)
}

///|
pub impl Show for ConstantBool with output(self, logger) {
  logger.write_string("\{self.getType()} \{self.value}")
}
