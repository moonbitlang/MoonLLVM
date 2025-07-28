///|
pub(all) enum FnAttr {
  AllocKind(Int)
  AllocSize(Int)
  AlwaysInline
  Builtin
  Cold
  Convergent
  Hot
  DisableSanitizerInstrumentation
  FnRetThunkExtern
  HybridPatchable
  InlineHint
  JumpTable
  Memory(Int)
  MinSize
  Naked
  NoBuiltin
  NoCallback
  NoDivergenceSource
  NoDuplicate
  NoFree
  NoImplicitFloat
  NoInline
  NonLazyBind
  NoMerge
  NoRecurse
  NoRedZone
  NoReturn
  NoSync
  NoCfCheck
  NoProfile
  SkipProfile
  NoUnwind
  NoSanitizeBounds
  NoSanitizeCoverage
  NullPointerIsValid
  OptimizeForDebugging
  OptForFuzzing
  OptimizeForSize
  OptimizeNone
  Preallocated(&Type)
  ReturnTwice
  SafeStack
  ShadowCallStack
  StackAlignment(Int)
  Speculatable
  StackProtect
  StackProtectReq
  StackProtectStrong
  StrictFP
  SanitizeAddress
  SanitizeThread
  SanitizeType
  SanitizeMemory
  SanitizeHWAddress
  SanitizeMemTag
  SanitizeNumericalStability
  SanitizeRealtime
  SanitizeRealtimeBlocking
  SpeculativeLoadHardening
  UWTable(Int)
  VScaleRange(Int)
  WillReturn
  MustProgress
  PresplitCoroutine
  CoroDestroyOnlyWhenComplete
  CoroElideSafe
  DenormalFPMath
  DenormalFPMathF32
} derive(Hash, Eq)

///|
///
///  TODO: Initializes is a ConstantRangeListAttr
///  TODO: Range is a ConstantRangeAttr
pub(all) enum ParamAttr {
  Alignment(Int)
  AllocAlign
  AllocatedPointer 
  ByVal(&Type)
  ByRef(&Type)
  NoUndef
  Dereferenceable(Int)
  DereferenceableOrNull(Int)
  ElementType(&Type)
  InAlloca(&Type)
  Initializes
  InReg
  NoFPClass
  Nest
  NoAlias
  Captures
  NoExt
  NoFree
  DeadOnUnwind
  NonNull
  Preallocated(&Type)
  Range
  ReadNone
  ReadOnly
  Returned
  ImmArg
  SExt
  StackAlignment(Int)
  StructRet
  SwiftError
  SwiftSelf
  SwiftAsync
  Writable
  WriteOnly
  ZExt
} derive(Hash, Eq)

///|
pub(all) enum RetAttr {
  Alignment(Int)
  NoUndef
  Dereferenceable(Int) 
  DereferenceableOrNull(Int)
  InReg
  NoFPClass
  NoAlias
  NoExt
  NonNull
  SExt
  StackAlignment(Int)
  ZExt
} derive(Hash, Eq)

///|
pub impl Show for FnAttr with output(self, logger) {
  let str = match self {
    AllocSize(a) => "allocsize(\{a})"
    AlwaysInline => "alwaysinline"
    Builtin => "builtin"
    NoInline => "noinline"
    AllocKind(i) => "allockind(\{i})"
    Cold => "cold"
    Convergent => "convergent"
    Hot => "hot"
    DisableSanitizerInstrumentation => "disable_sanitizer_instrumentation"
    FnRetThunkExtern => "fn_ret_thunk_extern"
    HybridPatchable => "hybrid_patchable"
    InlineHint => "inlinehint"
    JumpTable => "jumptable"
    Memory(i) => "memory(\{i})"
    MinSize => "minsize"
    Naked => "naked"
    NoBuiltin => "nobuiltin"
    NoCallback => "nocallback"
    NoDivergenceSource => "nodivergence_source"
    NoDuplicate => "noduplicate"
    NoFree => "nofree"
    NoImplicitFloat => "noimplicitfloat"
    NonLazyBind => "nonlazybind"
    NoMerge => "nomerge"
    NoRecurse => "norecurse"
    NoRedZone => "noredzone"
    NoReturn => "noreturn"
    NoSync => "nosync"
    NoCfCheck => "nocfcheck"
    NoProfile => "noprofile"
    SkipProfile => "skipprofile"
    NoUnwind => "nounwind"
    NoSanitizeBounds => "no_sanitize_bounds"
    NoSanitizeCoverage => "no_sanitize_coverage"
    NullPointerIsValid => "null_pointer_is_valid"
    OptimizeForDebugging => "optimize_for_debugging"
    OptForFuzzing => "opt_for_fuzzing"
    OptimizeForSize => "optimize_for_size"
    OptimizeNone => "optimize_none"
    Preallocated(ty) => "preallocated(\{ty})"
    ReturnTwice => "return_twice"
    SafeStack => "safestack"
    ShadowCallStack => "shadow_call_stack"
    StackAlignment(i) => "stack_alignment(\{i})"
    Speculatable => "speculatable"
    StackProtect => "stackprotect"
    StackProtectReq => "stackprotectreq"
    StackProtectStrong => "stackprotectstrong"
    StrictFP => "strictfp"
    SanitizeAddress => "sanitize_address"
    SanitizeThread => "sanitize_thread"
    SanitizeType => "sanitize_type"
    SanitizeMemory => "sanitize_memory"
    SanitizeHWAddress => "sanitize_hwaddress"
    SanitizeMemTag => "sanitize_memtag"
    SanitizeNumericalStability => "sanitize_numerical_stability"
    SanitizeRealtime => "sanitize_realtime"
    SanitizeRealtimeBlocking => "sanitize_realtime_blocking"
    SpeculativeLoadHardening => "speculative_load_hardening"
    UWTable(i) => "uwtable(\{i})"
    VScaleRange(i)  => "vscale_range(\{i})"
    WillReturn => "will_return"
    MustProgress => "must_progress"
    PresplitCoroutine => "presplit_coroutine"
    CoroDestroyOnlyWhenComplete => "coro_destroy_only_when_complete"
    CoroElideSafe => "coro_elide_safe"
    DenormalFPMath => "denormal_fpmath"
    DenormalFPMathF32 => "denormal_fpmath_f32"
  }
  logger.write_string(str)
}

///|
pub impl Show for ParamAttr with output(self, logger) {
  let str = match self {
    Alignment(a) => "align(\{a})"
    AllocAlign => "allocalign"
    ByVal(t) => "byval(\{t})"
    ByRef(t) => "byref(\{t})"
    NoAlias => "noalias"
    NonNull => "nonnull"
    AllocatedPointer => "allocated_pointer" 
    NoUndef => "noundef"
    Dereferenceable(i) => "dereferenceable(\{i})"
    DereferenceableOrNull(i) => "dereferenceable_or_null(\{i})"
    ElementType(ty) => "element_type(\{ty})"
    InAlloca(ty) => "inalloca(\{ty})"
    Initializes => "initializes"
    InReg => "inreg"
    NoFPClass => "nofpclass"
    Nest => "nest"
    Captures => "captures"
    NoExt => "noext"
    NoFree => "nofree"
    DeadOnUnwind => "dead_on_unwind"
    Preallocated(ty) => "preallocated(\{ty})"
    Range => "range"
    ReadNone => "readnone"
    ReadOnly => "readonly"
    Returned => "returned"
    ImmArg => "immarg"
    SExt => "sext"
    StackAlignment(i) => "stack_alignment(\{i})"
    StructRet => "structret"
    SwiftError => "swift_error"
    SwiftSelf => "swift_self"
    SwiftAsync => "swift_async"
    Writable => "writable"
    WriteOnly => "writeonly"
    ZExt => "zext"
  }
  logger.write_string(str)
}

///|
pub impl Show for RetAttr with output(self, logger) {
  let str = match self {
    Alignment(a) => "align(\{a})"
    NoUndef => "noundef"
    Dereferenceable(i) => "dereferenceable(\{i})"
    DereferenceableOrNull(i) => "dereferenceable_or_null(\{i})"
    InReg => "inreg"
    NoFPClass => "nofpclass"
    NoAlias => "noalias"
    NoExt => "noext"
    NonNull => "nonnull"
    SExt => "sext"
    StackAlignment(i) => "stack_alignment(\{i})"
    ZExt => "zext"
  }
  logger.write_string(str)
}

///|
struct AttributeSet {
  fnAttrs : Set[FnAttr]
  paramAttrs : Map[UInt, Set[ParamAttr]]
  retAttrs : Set[RetAttr]
}

///|
fn AttributeSet::new() -> AttributeSet {
  AttributeSet::{
    fnAttrs: Set::new(),
    paramAttrs: Map::new(),
    retAttrs: Set::new(),
  }
}
