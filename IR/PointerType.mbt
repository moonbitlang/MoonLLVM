// ====================================================================
// PointerType
// ====================================================================

///|
/// Memory address space of a pointer type.
pub struct AddressSpace(UInt) derive(Hash, Show, Eq, Default)

///|
pub fn AddressSpace::new(v : UInt) -> AddressSpace {
  AddressSpace(v)
}

///|
/// PointerType
/// **Note**: Before LLVM17, TypedPointer is supported. After LLVM17, all pointer
/// are opaque pointer, and typed pointer is deprecated.
///
/// In Moonbit Aether framework, we follow the design of LLVM20, so all pointer is
/// also opaque pointer, and will not mark type for pointer.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   inspect(ctx.getPtrTy(), content="ptr")
///   let addressSpace = AddressSpace::new(0)
///   let ptr = ctx.getPtrTy(addressSpace~)
///   inspect(ptr, content="ptr")
///   let i32ty = ctx.getInt32Ty()
///   assert_true(PointerType::isLoadableOrStorableType(i32ty))
///   let voidty = ctx.getVoidTy()
///   assert_false(PointerType::isLoadableOrStorableType(voidty))
/// }
/// ```
pub struct PointerType {
  ctx : Context
  addressSpace : AddressSpace
} derive(Eq, Hash)

///|
fn PointerType::new(ctx : Context, addressSpace~ : AddressSpace) -> PointerType {
  PointerType::{ ctx, addressSpace }
}

///|
pub fn PointerType::getAddressSpace(self : PointerType) -> AddressSpace {
  self.addressSpace
}

///|
fn PointerType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    VoidType(_) | LabelType(_) | MetadataType(_) | TokenType(_) => false
    _ => true
  }
}

///|
pub fn PointerType::isLoadableOrStorableType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    FunctionType(_) => false
    _ => PointerType::isValidElementType(eleTy)
  }
}

///|
pub impl Show for PointerType with output(_, logger : &Logger) {
  logger.write_string("ptr")
}

///|
pub impl Type for PointerType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::PointerType(self)
}

///|
pub impl Type for PointerType with getContext(self) -> Context {
  self.ctx
}
