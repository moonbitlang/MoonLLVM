// ====================================================================
// StructType
// ====================================================================

///|
/// Struct Type
///
/// - See LLVM: `StructType::get`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let i8ty = ctx.getInt8Ty()
///   let i16ty = ctx.getInt16Ty()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let sty = ctx.getStructType([i32ty, f32ty], name="foo")
///   inspect(sty.full_info(), content="%foo = type { i32, float }")
///   let sty = ctx.getStructType([i8ty, i16ty], name="bar", isPacked=true)
///   inspect(sty.full_info(), content="%bar = type <{ i8, i16 }>")
/// }
/// ```
pub struct StructType {
  ctx : Context
  priv mut name : String?
  elements : Array[&Type]
  priv mut isPacked : Bool
  priv mut isSized : Bool?
  //priv mut containsScalableVector: Bool
  //priv mut containsNonGlobalTargetExtType: Bool
  //priv mut containsNonLocalTargetExtType: Bool
} derive(Hash)

///|
/// Create a StructType.
/// FIXME: this is may different from LLVM Cpp
fn StructType::new(
  ctx : Context,
  elements : Array[&Type],
  name~ : String?,
  isPacked~ : Bool,
) -> StructType raise LLVMTypeError {
  if name is None && elements.is_empty() {
    raise OpaqueStructMustHaveName
  }
  let elements = elements.copy()
  let namedStructTypes = ctx.pimpl.unwrap().namedStructTypes
  let name = match name {
    Some("") => raise InValidStructName("")
    Some(n) if namedStructTypes.contains(n) => raise DuplicateStructName(n)
    Some(n) => Some(n)
    None => None
  }
  //let containsScalableVector = false
  //let containsNonGlobalTargetExtType = false
  //let containsNonLocalTargetExtType = false
  let sty = StructType::{ ctx, name, elements, isPacked, isSized: None }
  //containsScalableVector,
  //containsNonGlobalTargetExtType,
  //containsNonLocalTargetExtType
  if name is Some(n) {
    ctx.pimpl.unwrap().namedStructTypes.set(n, sty)
  }
  sty
}

///|
/// Check struct is a literal type.
///
/// literal type means the struct only has body but has no name.
///
/// - See LLVM: `StructType::isLiteral`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let foo = ctx.getStructType([i32ty, f32ty])
///   let bar = ctx.getStructType([i32ty, f32ty], name="bar")
///   assert_true(foo.isLiteral())
///   assert_false(bar.isLiteral())
/// }
/// ```
pub fn StructType::isLiteral(self : StructType) -> Bool {
  self.name is None
}

///|
/// Check struct is a opaque type.
/// Return true if this is a type with an identity that has no body specified
/// yet. These prints as 'opaque' in .ll files.
///
/// - See LLVM: `StructType::isOpaque`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let foo = ctx.getStructType([], name="foo")
///   let bar = ctx.getStructType([i32ty, f32ty], name="bar")
///   assert_true(foo.isOpaque())
///   assert_false(bar.isOpaque())
/// }
/// ```
pub fn StructType::isOpaque(self : StructType) -> Bool {
  self.elements.is_empty()
}

///|
/// Check if this is a packed struct type.
///
/// - See LLVM: `StructType::isPacked`.
///
/// Packed struct means the struct has no padding between its elements.
pub fn StructType::isPacked(self : StructType) -> Bool {
  self.isPacked
}

///|
pub fn StructType::isSized(self : StructType) -> Bool {
  if self.isSized is Some(sized) {
    return sized
  }
  if self.isOpaque() {
    return false
  }
  if self.elements().iter().any(ty => ty.isScalableTy() || not(ty.isSized())) {
    return false
  }
  self.isSized = Some(true)
  true
}

///|
/// Get the elements of the struct.
///
/// - See LLVM: `StructType::elements`.
pub fn StructType::elements(self : StructType) -> Array[&Type] {
  self.elements
}

///|
///
/// - See LLVM: `StructType::element_begin` and `StructType::element_end`.
pub fn StructType::element_iter(self : StructType) -> Iter[&Type] {
  self.elements.iter()
}

///|
/// Set the body of the struct.
///
/// Only Opaque struct can be set body.
///
/// - See LLVM: `StructType::setBody`.
pub fn StructType::setBody(
  self : StructType,
  elements : Array[&Type],
  isPacked? : Bool = false,
) -> Unit raise LLVMTypeError {
  // only opaque struct can be set body.
  guard self.isOpaque() else { raise SetBodyForNonOpaqueStruct }

  // No recursive struct.
  for element in elements {
    if element.asTypeEnum() is StructType(sty) && sty == self {
      raise RecursiveStructDefinition
    }
  }
  self.isPacked = isPacked
  self.elements.clear()
  elements.each(ty => self.elements.push(ty))
}

///|
/// Get the name of the struct.
///
/// If the struct is literal, return None.
///
/// - See LLVM: `StructType::getName`.
pub fn StructType::getName(self : StructType) -> String? {
  self.name
}

///|
/// Set the name of the struct.
///
/// **Note**: 
///   
///   - If the new_name is "" (empty string), the struct will be a literal type.
///   - If the new_name has same name with old name, nothing will be changed.
///   - If context has already have a struct with the given new name, it will raise error.
///
/// - See LLVM: `StructType::setName`.
pub fn StructType::setName(
  self : StructType,
  new_name : String,
) -> Unit raise LLVMTypeError {
  if new_name.is_empty() {
    raise StructTypeNameCannotBeEmpty
  }
  let ctx = self.getContext().pimpl.unwrap()
  let namedStructTypes = ctx.namedStructTypes
  match (self.name, new_name) {
    (Some(old_name), new_name) if old_name == new_name => return
    (_, new_name) if namedStructTypes.contains(new_name) =>
      raise DuplicateStructName(new_name)
    (None, new_name) => {
      self.name = Some(new_name)
      namedStructTypes.set(new_name, self)
    }
    (Some(old_name), new_name) => {
      namedStructTypes..remove(old_name)..set(new_name, self)
      self.name = Some(new_name)
    }
  }
}

///|
pub fn StructType::removeName(self : StructType) -> Unit {
  guard self.name is Some(name) else { return }
  let ctx = self.getContext().pimpl.unwrap()
  ctx.namedStructTypes.remove(name)
  self.name = None
}

///|
pub fn StructType::getIndexedType(self : Self, idxs : ArrayView[Int]) -> &Type? {
  guard self.elements.get(idxs[0]) is Some(ty) else { return None }
  if idxs.length() == 1 {
    return Some(ty)
  }
  if ty.tryAsAggregateTypeEnum() is Some(aggTy) {
    aggTy.getIndexedType(idxs[1:])
  } else {
    None
  }
}

///|
pub fn StructType::body_str(self : Self) -> String {
  let s = self.elements.iter().map(ty => ty.to_string()).join(", ")
  match self.isPacked() {
    true => "<{ \{s} }>"
    false => "{ \{s} }"
  }
}

///|
pub fn StructType::full_info(self : Self) -> String {
  match self.getName() {
    Some(ident) =>
      "%\{ident} = " +
      (match self.isOpaque() {
        true => "opaque"
        false => "type " + self.body_str()
      })
    None => self.body_str()
  }
}

///|
pub impl Show for StructType with output(self, logger : &Logger) {
  let s = match self.getName() {
    Some(name) => "%\{name}"
    None => self.body_str()
  }
  logger.write_string(s)
}

///|
pub impl Eq for StructType with equal(self, other) {
  match (self.name, other.name) {
    (Some(n1), Some(n2)) => n1 == n2
    (Some(_), None) => false
    (None, Some(_)) => false
    (None, None) => self.elements == other.elements
  }
}

///|
pub impl Type for StructType with asTypeEnum(self) -> TypeEnum {
  StructType(self)
}

///|
pub impl Type for StructType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl AggregateType for StructType with asAggregateTypeEnum(self) -> AggregateTypeEnum {
  StructType(self)
}
