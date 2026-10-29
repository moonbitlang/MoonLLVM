// ====================================================================
// Aggregate Types, AggregateType && AggregateTypeEnum
// ====================================================================

///|
pub trait AggregateType: Type {
  fn asAggregateTypeEnum(Self) -> AggregateTypeEnum
  fn getIndexedType(Self, idxs : ArrayView[Int32]) -> &Type? = _
}

///|
impl AggregateType with fn getIndexedType(self, idxs : ArrayView[Int32]) -> &Type? {
  self.asAggregateTypeEnum().getIndexedType(idxs)
}

///|
pub enum AggregateTypeEnum {
  StructType(StructType)
  ArrayType(ArrayType)
  VectorType(VectorType)
  ScalableVectorType(ScalableVectorType)
} derive(Eq, Show)

///|
pub fn AggregateTypeEnum::toTypeEnum(self : AggregateTypeEnum) -> TypeEnum {
  match self {
    StructType(sty) => StructType(sty)
    ArrayType(arr) => ArrayType(arr)
    VectorType(vec) => VectorType(vec)
    ScalableVectorType(vec) => ScalableVectorType(vec)
  }
}

///|
pub fn AggregateTypeEnum::asTypeClass(self : Self) -> &Type {
  match self {
    StructType(sty) => (sty : &Type)
    ArrayType(arr) => arr
    VectorType(vec) => vec
    ScalableVectorType(vec) => vec
  }
}

///|
pub fn AggregateTypeEnum::getIndexedType(
  self : Self,
  idxs : ArrayView[Int32],
) -> &Type? {
  match self {
    StructType(sty) => sty.getIndexedType(idxs)
    ArrayType(arr) =>
      when(
        idxs.length() == 1 && idxs[0] >= 0 && idxs[0] < arr.getElementCount(),
        fn() { arr.getElementType() },
      )
    VectorType(arr) =>
      when(
        idxs.length() == 1 && idxs[0] >= 0 && idxs[0] < arr.getElementCount(),
        fn() { arr.getElementType() },
      )
    ScalableVectorType(arr) =>
      when(
        idxs.length() == 1 && idxs[0] >= 0, // no need to check upper bound
        fn() { arr.getElementType() },
      )
  }
}
