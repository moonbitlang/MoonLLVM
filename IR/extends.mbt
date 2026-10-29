///|
pub extend AbstractTypeEnum with Show::{to_string, output}

///|
pub extend AddressSpace with Default::{default}

///|
pub extend AddressSpace with Eq::{not_equal, equal}

///|
pub extend AddressSpace with Hash::{hash, hash_combine}

///|
pub extend AddressSpace with Show::{to_string, output}

///|
pub extend AggregateTypeEnum with Eq::{not_equal, equal}

///|
pub extend AggregateTypeEnum with Show::{to_string, output}

///|
pub extend Align with Eq::{not_equal, equal}

///|
pub extend Align with Show::{to_string, output}

///|
pub extend AllocaInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend AllocaInst with Show::{to_string, output}

///|
pub extend AllocaInst with UnaryInst::{asUnaryInstEnum}

///|
pub extend AllocaInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend Argument with Show::{to_string, output}

///|
pub extend Argument with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ArrayType with AggregateType::{asAggregateTypeEnum, getIndexedType}

///|
pub extend ArrayType with Eq::{not_equal, equal}

///|
pub extend ArrayType with Hash::{hash, hash_combine}

///|
pub extend ArrayType with Show::{to_string, output}

///|
pub extend ArrayType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend AtomicOrdering with Eq::{not_equal, equal}

///|
pub extend AtomicOrdering with Hash::{hash, hash_combine}

///|
pub extend AtomicOrdering with Show::{to_string, output}

///|
pub extend BFloatType with Eq::{not_equal, equal}

///|
pub extend BFloatType with FPType::{getFPMantissaWidth, asFPTypeEnum}

///|
pub extend BFloatType with Hash::{hash, hash_combine}

///|
pub extend BFloatType with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend BFloatType with Show::{to_string, output}

///|
pub extend BFloatType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend BasicBlock with Eq::{not_equal, equal}

///|
pub extend BasicBlock with Hash::{hash, hash_combine}

///|
pub extend BasicBlock with Show::{to_string, output}

///|
pub extend BasicBlock with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend BinaryInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend BinaryInst with Show::{to_string, output}

///|
pub extend BinaryInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend BinaryInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend BinaryOpFlags with Eq::{not_equal, equal}

///|
pub extend BinaryOpFlags with Hash::{hash, hash_combine}

///|
pub extend BinaryOpFlags with Show::{to_string, output}

///|
pub extend BinaryOps with Eq::{not_equal, equal}

///|
pub extend BinaryOps with Hash::{hash, hash_combine}

///|
pub extend BinaryOps with Show::{to_string, output}

///|
pub extend BranchInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend BranchInst with Show::{to_string, output}

///|
pub extend BranchInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend BranchInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend CallInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend CallInst with Show::{to_string, output}

///|
pub extend CallInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend CallInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend CastInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend CastInst with Show::{to_string, output}

///|
pub extend CastInst with UnaryInst::{asUnaryInstEnum}

///|
pub extend CastInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend CastInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend CastOps with Eq::{not_equal, equal}

///|
pub extend CastOps with Hash::{hash, hash_combine}

///|
pub extend CastOps with Show::{to_string, output}

///|
pub extend ConstantArray with Constant::{asConstantEnum}

///|
pub extend ConstantArray with Eq::{not_equal, equal}

///|
pub extend ConstantArray with Show::{to_string, output}

///|
pub extend ConstantArray with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ConstantEnum with Eq::{not_equal, equal}

///|
pub extend ConstantFP with Constant::{asConstantEnum}

///|
pub extend ConstantFP with Eq::{not_equal, equal}

///|
pub extend ConstantFP with Show::{to_string, output}

///|
pub extend ConstantFP with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ConstantInt with Constant::{asConstantEnum}

///|
pub extend ConstantInt with Eq::{not_equal, equal}

///|
pub extend ConstantInt with Show::{to_string, output}

///|
pub extend ConstantInt with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ConstantPointerNull with Constant::{asConstantEnum}

///|
pub extend ConstantPointerNull with Eq::{not_equal, equal}

///|
pub extend ConstantPointerNull with Show::{to_string, output}

///|
pub extend ConstantPointerNull with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ConstantString with Constant::{asConstantEnum}

///|
pub extend ConstantString with Eq::{not_equal, equal}

///|
pub extend ConstantString with Show::{to_string, output}

///|
pub extend ConstantString with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ConstantStruct with Constant::{asConstantEnum}

///|
pub extend ConstantStruct with Eq::{not_equal, equal}

///|
pub extend ConstantStruct with Show::{to_string, output}

///|
pub extend ConstantStruct with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ConstantVector with Constant::{asConstantEnum}

///|
pub extend ConstantVector with Eq::{not_equal, equal}

///|
pub extend ConstantVector with Show::{to_string, output}

///|
pub extend ConstantVector with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend Context with Eq::{not_equal, equal}

///|
pub extend Context with Hash::{hash, hash_combine}

///|
pub extend DoubleArray with Eq::{not_equal, equal}

///|
pub extend DoubleArray with Hash::{hash, hash_combine}

///|
pub extend DoubleArray with Show::{to_string, output}

///|
pub extend DoubleType with Eq::{not_equal, equal}

///|
pub extend DoubleType with FPType::{getFPMantissaWidth, asFPTypeEnum}

///|
pub extend DoubleType with Hash::{hash, hash_combine}

///|
pub extend DoubleType with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend DoubleType with Show::{to_string, output}

///|
pub extend DoubleType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend ExtractValueInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend ExtractValueInst with Show::{to_string, output}

///|
pub extend ExtractValueInst with UnaryInst::{asUnaryInstEnum}

///|
pub extend ExtractValueInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend ExtractValueInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend FCmpInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend FCmpInst with Show::{to_string, output}

///|
pub extend FCmpInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend FCmpInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend FNegInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend FNegInst with Show::{to_string, output}

///|
pub extend FNegInst with UnaryInst::{asUnaryInstEnum}

///|
pub extend FNegInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend FNegInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend FP128Type with Eq::{not_equal, equal}

///|
pub extend FP128Type with FPType::{getFPMantissaWidth, asFPTypeEnum}

///|
pub extend FP128Type with Hash::{hash, hash_combine}

///|
pub extend FP128Type with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend FP128Type with Show::{to_string, output}

///|
pub extend FP128Type with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend FPTypeEnum with Eq::{not_equal, equal}

///|
pub extend FPTypeEnum with Show::{to_string, output}

///|
pub extend FastMathFlag with Eq::{not_equal, equal}

///|
pub extend FastMathFlag with Hash::{hash, hash_combine}

///|
pub extend FastMathFlag with Show::{to_string, output}

///|
pub extend FloatArray with Eq::{not_equal, equal}

///|
pub extend FloatArray with Hash::{hash, hash_combine}

///|
pub extend FloatArray with Show::{to_string, output}

///|
pub extend FloatPredicate with Show::{to_string, output}

///|
pub extend FloatType with Eq::{not_equal, equal}

///|
pub extend FloatType with FPType::{getFPMantissaWidth, asFPTypeEnum}

///|
pub extend FloatType with Hash::{hash, hash_combine}

///|
pub extend FloatType with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend FloatType with Show::{to_string, output}

///|
pub extend FloatType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend FloatingEnum with Eq::{not_equal, equal}

///|
pub extend FloatingEnum with Hash::{hash, hash_combine}

///|
pub extend FloatingEnum with Show::{to_string, output}

///|
pub extend FnAttr with Eq::{not_equal, equal}

///|
pub extend FnAttr with Hash::{hash, hash_combine}

///|
pub extend FnAttr with Show::{to_string, output}

///|
pub extend Function with Eq::{not_equal, equal}

///|
pub extend Function with GlobalValue::{
  setLinkage,
  getGlobalValueBase,
  setUnnamedAddr,
  asGlobalValueEnum,
  getLinkage,
}

///|
pub extend Function with Show::{to_string, output}

///|
pub extend Function with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend FunctionType with AbstractType::{asAbstractTypeEnum}

///|
pub extend FunctionType with Eq::{not_equal, equal}

///|
pub extend FunctionType with Hash::{hash, hash_combine}

///|
pub extend FunctionType with Show::{to_string, output}

///|
pub extend FunctionType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend GetElementPtrInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend GetElementPtrInst with Show::{to_string, output}

///|
pub extend GetElementPtrInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend GetElementPtrInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend GlobalConstant with GlobalValue::{
  setLinkage,
  getGlobalValueBase,
  setUnnamedAddr,
  asGlobalValueEnum,
  getLinkage,
  getModule,
}

///|
pub extend GlobalConstant with Show::{to_string, output}

///|
pub extend GlobalConstant with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend GlobalVariable with GlobalValue::{
  setLinkage,
  getGlobalValueBase,
  setUnnamedAddr,
  asGlobalValueEnum,
  getLinkage,
  getModule,
}

///|
pub extend GlobalVariable with Show::{to_string, output}

///|
pub extend GlobalVariable with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend HalfType with Eq::{not_equal, equal}

///|
pub extend HalfType with FPType::{getFPMantissaWidth, asFPTypeEnum}

///|
pub extend HalfType with Hash::{hash, hash_combine}

///|
pub extend HalfType with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend HalfType with Show::{to_string, output}

///|
pub extend HalfType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend ICmpInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend ICmpInst with Show::{to_string, output}

///|
pub extend ICmpInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend ICmpInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend InsertValueInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend InsertValueInst with Show::{to_string, output}

///|
pub extend InsertValueInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend InsertValueInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend Int16Array with Eq::{not_equal, equal}

///|
pub extend Int16Array with Hash::{hash, hash_combine}

///|
pub extend Int16Array with Show::{to_string, output}

///|
pub extend Int16Type with Eq::{not_equal, equal}

///|
pub extend Int16Type with Hash::{hash, hash_combine}

///|
pub extend Int16Type with IntegerType::{
  getSignBit,
  getBitMask,
  asIntegerTypeEnum,
}

///|
pub extend Int16Type with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend Int16Type with Show::{to_string, output}

///|
pub extend Int16Type with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend Int1Type with Eq::{not_equal, equal}

///|
pub extend Int1Type with Hash::{hash, hash_combine}

///|
pub extend Int1Type with IntegerType::{
  getSignBit,
  getBitMask,
  asIntegerTypeEnum,
  getExtendedType,
}

///|
pub extend Int1Type with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend Int1Type with Show::{to_string, output}

///|
pub extend Int1Type with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend Int32Array with Eq::{not_equal, equal}

///|
pub extend Int32Array with Hash::{hash, hash_combine}

///|
pub extend Int32Array with Show::{to_string, output}

///|
pub extend Int32Type with Eq::{not_equal, equal}

///|
pub extend Int32Type with Hash::{hash, hash_combine}

///|
pub extend Int32Type with IntegerType::{
  getSignBit,
  getBitMask,
  asIntegerTypeEnum,
}

///|
pub extend Int32Type with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend Int32Type with Show::{to_string, output}

///|
pub extend Int32Type with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend Int64Array with Eq::{not_equal, equal}

///|
pub extend Int64Array with Hash::{hash, hash_combine}

///|
pub extend Int64Array with Show::{to_string, output}

///|
pub extend Int64Type with Eq::{not_equal, equal}

///|
pub extend Int64Type with Hash::{hash, hash_combine}

///|
pub extend Int64Type with IntegerType::{
  getSignBit,
  getBitMask,
  asIntegerTypeEnum,
  getExtendedType,
}

///|
pub extend Int64Type with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend Int64Type with Show::{to_string, output}

///|
pub extend Int64Type with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend Int8Array with Eq::{not_equal, equal}

///|
pub extend Int8Array with Hash::{hash, hash_combine}

///|
pub extend Int8Array with Show::{to_string, output}

///|
pub extend Int8Type with Eq::{not_equal, equal}

///|
pub extend Int8Type with Hash::{hash, hash_combine}

///|
pub extend Int8Type with IntegerType::{
  getSignBit,
  getBitMask,
  asIntegerTypeEnum,
}

///|
pub extend Int8Type with PrimitiveType::{getBitWidth, asPrimitiveTypeEnum}

///|
pub extend Int8Type with Show::{to_string, output}

///|
pub extend Int8Type with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend IntPredicate with Show::{to_string, output}

///|
pub extend IntegerTypeEnum with Eq::{not_equal, equal}

///|
pub extend IntegerTypeEnum with Hash::{hash, hash_combine}

///|
pub extend IntegerTypeEnum with Show::{to_string, output}

///|
pub extend LLVMTypeError with Show::{to_string, output}

///|
pub extend LLVMValueError with Show::{to_string, output}

///|
pub extend LabelType with AbstractType::{asAbstractTypeEnum}

///|
pub extend LabelType with Eq::{not_equal, equal}

///|
pub extend LabelType with Hash::{hash, hash_combine}

///|
pub extend LabelType with Show::{to_string, output}

///|
pub extend LabelType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend Linkage with Show::{to_string, output}

///|
pub extend LoadInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend LoadInst with Show::{to_string, output}

///|
pub extend LoadInst with UnaryInst::{asUnaryInstEnum}

///|
pub extend LoadInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend LoadInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend MDNode with Metadata::{asMetadataEnum}

///|
pub extend MDNode with Show::{to_string, output}

///|
pub extend MDString with Metadata::{asMetadataEnum}

///|
pub extend MDString with Show::{to_string, output}

///|
pub extend MetadataType with AbstractType::{asAbstractTypeEnum}

///|
pub extend MetadataType with Eq::{not_equal, equal}

///|
pub extend MetadataType with Hash::{hash, hash_combine}

///|
pub extend MetadataType with Show::{to_string, output}

///|
pub extend MetadataType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend Module with Show::{to_string, output}

///|
pub extend NumberArrayEnum with Eq::{not_equal, equal}

///|
pub extend NumberArrayEnum with Hash::{hash, hash_combine}

///|
pub extend NumberArrayEnum with Show::{to_string, output}

///|
pub extend PHINode with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend PHINode with Show::{to_string, output}

///|
pub extend PHINode with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend PHINode with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ParamAttr with Eq::{not_equal, equal}

///|
pub extend ParamAttr with Hash::{hash, hash_combine}

///|
pub extend ParamAttr with Show::{to_string, output}

///|
pub extend PointerType with Eq::{not_equal, equal}

///|
pub extend PointerType with Hash::{hash, hash_combine}

///|
pub extend PointerType with Show::{to_string, output}

///|
pub extend PointerType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend PrimitiveTypeEnum with Eq::{not_equal, equal}

///|
pub extend PrimitiveTypeEnum with Show::{to_string, output}

///|
pub extend RetAttr with Eq::{not_equal, equal}

///|
pub extend RetAttr with Hash::{hash, hash_combine}

///|
pub extend RetAttr with Show::{to_string, output}

///|
pub extend ReturnInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend ReturnInst with Show::{to_string, output}

///|
pub extend ReturnInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend ReturnInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend ScalableVectorType with AggregateType::{
  asAggregateTypeEnum,
  getIndexedType,
}

///|
pub extend ScalableVectorType with Eq::{not_equal, equal}

///|
pub extend ScalableVectorType with Hash::{hash, hash_combine}

///|
pub extend ScalableVectorType with Show::{to_string, output}

///|
pub extend ScalableVectorType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend SelectInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend SelectInst with Show::{to_string, output}

///|
pub extend SelectInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend SelectInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend SignedEnum with Eq::{not_equal, equal}

///|
pub extend SignedEnum with Hash::{hash, hash_combine}

///|
pub extend SignedEnum with Show::{to_string, output}

///|
pub extend StoreInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend StoreInst with Show::{to_string, output}

///|
pub extend StoreInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend StoreInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend StructType with AggregateType::{asAggregateTypeEnum}

///|
pub extend StructType with Eq::{not_equal, equal}

///|
pub extend StructType with Hash::{hash, hash_combine}

///|
pub extend StructType with Show::{to_string, output}

///|
pub extend StructType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend SwitchInst with Instruction::{
  getBasicBlock,
  isIndependent,
  insertAfter,
  getParent,
  moveBefore,
  getInstBase,
  next,
  getInstName,
  removeFromParent,
  moveAfter,
  getModule,
  isTerminator,
  prev,
  insertBefore,
  asInstEnum,
  eraseFromParent,
}

///|
pub extend SwitchInst with Show::{to_string, output}

///|
pub extend SwitchInst with User::{
  getUserBase,
  asUserEnum,
  getNumOperands,
  getOperand,
  getOperands,
}

///|
pub extend SwitchInst with Value::{
  tryAsInst,
  tryAsConstantEnum,
  tryAsGlobalValueEnum,
  getType,
  tryAsConstant,
  addUser,
  getName,
  tryAsUserEnum,
  getUsers,
  tryAsInstEnum,
  setName,
  replaceAllUsersWith,
  tryAsUser,
  getNameOrSlotStr,
  tryAsGlobalValue,
  getValueRepr,
  removeName,
  getNameOrSlot,
  getValueBase,
  asValueEnum,
  getContext,
  user_empty,
}

///|
pub extend TailCallKind with Show::{to_string, output}

///|
pub extend TokenType with AbstractType::{asAbstractTypeEnum}

///|
pub extend TokenType with Eq::{not_equal, equal}

///|
pub extend TokenType with Hash::{hash, hash_combine}

///|
pub extend TokenType with Show::{to_string, output}

///|
pub extend TokenType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend TypeEnum with Eq::{not_equal, equal}

///|
pub extend TypeEnum with Hash::{hash, hash_combine}

///|
pub extend TypeEnum with Show::{to_string, output}

///|
pub extend TypeSize with Eq::{not_equal, equal}

///|
pub extend UInt16Array with Eq::{not_equal, equal}

///|
pub extend UInt16Array with Hash::{hash, hash_combine}

///|
pub extend UInt16Array with Show::{to_string, output}

///|
pub extend UInt32Array with Eq::{not_equal, equal}

///|
pub extend UInt32Array with Hash::{hash, hash_combine}

///|
pub extend UInt32Array with Show::{to_string, output}

///|
pub extend UInt64Array with Eq::{not_equal, equal}

///|
pub extend UInt64Array with Hash::{hash, hash_combine}

///|
pub extend UInt64Array with Show::{to_string, output}

///|
pub extend UInt8Array with Eq::{not_equal, equal}

///|
pub extend UInt8Array with Hash::{hash, hash_combine}

///|
pub extend UInt8Array with Show::{to_string, output}

///|
pub extend UnSignedEnum with Eq::{not_equal, equal}

///|
pub extend UnSignedEnum with Hash::{hash, hash_combine}

///|
pub extend UnSignedEnum with Show::{to_string, output}

///|
pub extend UnnamedAddr with Show::{to_string, output}

///|
pub extend &User with Eq::{not_equal, equal}

///|
pub extend UserBase with Eq::{not_equal, equal}

///|
pub extend &Value with Eq::{not_equal, equal}

///|
pub extend &Value with Hash::{hash, hash_combine}

///|
pub extend ValueBase with Eq::{not_equal, equal}

///|
pub extend VectorType with AggregateType::{asAggregateTypeEnum, getIndexedType}

///|
pub extend VectorType with Eq::{not_equal, equal}

///|
pub extend VectorType with Hash::{hash, hash_combine}

///|
pub extend VectorType with Show::{to_string, output}

///|
pub extend VectorType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}

///|
pub extend Visibility with Show::{to_string, output}

///|
pub extend VoidType with AbstractType::{asAbstractTypeEnum}

///|
pub extend VoidType with Eq::{not_equal, equal}

///|
pub extend VoidType with Hash::{hash, hash_combine}

///|
pub extend VoidType with Show::{to_string, output}

///|
pub extend VoidType with Type::{
  tryAsIntTypeEnum,
  isIEEELikeFPTy,
  isIntOrPtrTy,
  isValidGEPType,
  getScalarSizeInBits,
  tryAsIntType,
  tryAsAbstractType,
  tryAsAggregateTypeEnum,
  isAggregateType,
  getScalarType,
  tryAsFPType,
  tryAsAbstractTypeEnum,
  canLosslesslyBitCastTo,
  tryAsAggregateType,
  tryAsPrimitiveType,
  isIntOrIntVectorTy,
  asTypeEnum,
  isFirstClassType,
  isScalableTy,
  isSized,
  isScalableTargetExtTy,
  isEmptyTy,
  is16bitFPTy,
  isPtrOrPtrVectorTy,
  tryAsPrimitiveTypeEnum,
  tryAsFPTypeEnum,
  getContext,
  isSingleValueType,
  getPrimitiveSizeInBits,
  isFloatingPointTy,
  isFPOrFPVectorTy,
}
