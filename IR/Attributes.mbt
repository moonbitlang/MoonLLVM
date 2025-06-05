///|
pub(all) enum Attribute {
  Alignment(Int)
  AllocAlign
  AllocSize(Int)
  AlwaysInline
  Builtin
  ByVal(&Type)
  ByRef(&Type)
  NoAlias
  NonNull
  NoInline
} derive(Hash, Eq)

///|
pub(all) enum FnAttr {
  AllocSize(Int)
  AlwaysInline
  Builtin
  NoInline
} derive(Hash, Eq)

///|
pub(all) enum ArgAttr {
  Alignment(Int)
  AllocAlign
  ByVal(&Type)
  ByRef(&Type)
  NoAlias
  NonNull
} derive(Hash, Eq)

///|
pub(all) enum RetAttr {
  Alignment(Int)
  NoAlias
  NonNull
} derive(Hash, Eq)

///|
pub fn Attribute::try_as_fn_attr(self : Attribute) -> FnAttr? {
  match self {
    Attribute::AllocSize(size) => FnAttr::AllocSize(size) |> Some
    Attribute::AlwaysInline => FnAttr::AlwaysInline |> Some
    Attribute::Builtin => FnAttr::Builtin |> Some
    Attribute::NoInline => FnAttr::NoInline |> Some
    _ => None
  }
}

///|
pub fn Attribute::try_as_param_attr(self : Attribute) -> ArgAttr? {
  match self {
    Attribute::Alignment(size) => ArgAttr::Alignment(size) |> Some
    Attribute::AllocAlign => ArgAttr::AllocAlign |> Some
    Attribute::ByVal(ty) => ArgAttr::ByVal(ty) |> Some
    Attribute::ByRef(ty) => ArgAttr::ByRef(ty) |> Some
    Attribute::NoAlias => ArgAttr::NoAlias |> Some
    Attribute::NonNull => ArgAttr::NonNull |> Some
    _ => None
  }
}

///|
pub fn Attribute::try_as_ret_attr(self : Attribute) -> RetAttr? {
  match self {
    Attribute::Alignment(size) => RetAttr::Alignment(size) |> Some
    Attribute::NoAlias => RetAttr::NoAlias |> Some
    Attribute::NonNull => RetAttr::NonNull |> Some
    _ => None
  }
}

///|
pub impl Show for Attribute with output(self, logger) {
  let str = match self {
    Alignment(a) => "align(\{a})"
    AllocAlign => "allocalign"
    AllocSize(a) => "allocsize(\{a})"
    AlwaysInline => "alwaysinline"
    Builtin => "builtin"
    ByVal(t) => "byval(\{t})"
    ByRef(t) => "byref(\{t})"
    NoAlias => "noalias"
    NonNull => "nonnull"
    NoInline => "noinline"
  }
  logger.write_string(str)
}

///|
pub impl Show for FnAttr with output(self, logger) {
  let str = match self {
    AllocSize(a) => "allocsize(\{a})"
    AlwaysInline => "alwaysinline"
    Builtin => "builtin"
    NoInline => "noinline"
  }
  logger.write_string(str)
}

///|
pub impl Show for ArgAttr with output(self, logger) {
  let str = match self {
    Alignment(a) => "align(\{a})"
    AllocAlign => "allocalign"
    ByVal(t) => "byval(\{t})"
    ByRef(t) => "byref(\{t})"
    NoAlias => "noalias"
    NonNull => "nonnull"
  }
  logger.write_string(str)
}

///|
pub impl Show for RetAttr with output(self, logger) {
  let str = match self {
    Alignment(a) => "align(\{a})"
    NoAlias => "noalias"
    NonNull => "nonnull"
  }
  logger.write_string(str)
}

///|
struct AttributeSet {
  fnAttrs : Set[FnAttr]
  argAttrs : Map[UInt, Set[ArgAttr]]
  retAttrs : Set[RetAttr]
}

///|
fn AttributeSet::new() -> AttributeSet {
  AttributeSet::{
    fnAttrs: Set::new(),
    argAttrs: Map::new(),
    retAttrs: Set::new(),
  }
}
