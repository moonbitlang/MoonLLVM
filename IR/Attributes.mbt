///|
pub(all) enum FnAttr {
  
  /// Describes behavior of an allocator function in terms of known properties.
  AllocKind(Int)

  /// The result of the function is guaranteed to point to a number of bytes that
  /// we can determine if we know the value of the function's arguments.
  AllocSize(Int)

  /// inline=always.
  AlwaysInline

  /// Callee is recognized as a builtin, despite nobuiltin attribute on its
  /// declaration.
  Builtin

  /// Marks function as being in a cold path.
  Cold

  /// Can only be moved to control-equivalent blocks.
  /// NB: Could be IntersectCustom with "or" handling.
  Convergent

  /// Marks function as being in a hot path and frequently called.
  Hot

  /// Do not instrument function with sanitizers.
  DisableSanitizerInstrumentation

  /// Whether to keep return instructions, or replace with a jump to an external symbol.
  FnRetThunkExtern

  /// Function has a hybrid patchable thunk.
  HybridPatchable

  /// Source said inlining was desirable.
  InlineHint

  /// Build jump-instruction tables and replace refs.
  JumpTable

  /// Build jump-instruction tables and replace refs.
  Memory(Int)

  /// Function must be optimized for size first.
  MinSize

  /// Naked function.
  Naked

  /// Callee isn't recognized as a builtin.
  NoBuiltin

  /// Function cannot enter into caller's translation unit.
  NoCallback

  /// Function is not a source of divergence.
  NoDivergenceSource

  /// Call cannot be duplicated.
  NoDuplicate

  /// Function does not deallocate memory.
  NoFree

  /// Disable implicit floating point insts.
  NoImplicitFloat

  /// inline=never.
  NoInline

  /// Function is called early and/or often, so lazy binding isn't worthwhile.
  NonLazyBind

  /// Disable merging for specified functions or call sites.
  NoMerge

  /// The function does not recurse.
  NoRecurse

  /// Disable redzone.
  NoRedZone

  /// Mark the function as not returning.
  NoReturn

  /// Function does not synchronize.
  NoSync

  /// Disable Indirect Branch Tracking.
  NoCfCheck

  /// Function should not be instrumented.
  NoProfile

  /// This function should not be instrumented but it is ok to inline profiled functions into it.
  SkipProfile

  /// Function doesn't unwind stack.
  NoUnwind

  /// No SanitizeBounds instrumentation.
  NoSanitizeBounds

  /// No SanitizeCoverage instrumentation.
  NoSanitizeCoverage

  /// Null pointer in address space zero is valid.
  NullPointerIsValid

  /// Select optimizations that give decent debug info.
  OptimizeForDebugging

/// Select optimizations for best fuzzing signal.
  OptForFuzzing

/// opt_size.
  OptimizeForSize

  /// Function must not be optimized.
  OptimizeNone

  /// Similar to byval but without a copy.
  Preallocated(&Type)

  /// Function can return twice.
  ReturnTwice

  /// Safe Stack protection.
  SafeStack

  /// Shadow Call Stack protection.
  ShadowCallStack

  /// Alignment of stack for function (3 bits)  stored as log2 of alignment with
  /// +1 bias 0 means unaligned (different from alignstack=(1)).
  StackAlignment(Int)

  /// Function can be speculated.
  Speculatable

  /// Stack protection.
  StackProtect

/// Stack protection required.
  StackProtectReq

  /// Strong Stack protection.
  StackProtectStrong

  /// Function was called in a scope requiring strict floating point semantics.
  StrictFP

  /// AddressSanitizer is on.
  SanitizeAddress

  /// ThreadSanitizer is on.
  SanitizeThread

  /// TypeSanitizer is on.
  SanitizeType

  /// MemorySanitizer is on.
  SanitizeMemory

  /// HWAddressSanitizer is on.
  SanitizeHWAddress

  /// MemTagSanitizer is on.
  SanitizeMemTag

  /// NumericalStabilitySanitizer is on.
  SanitizeNumericalStability

  /// RealtimeSanitizer is on.
  SanitizeRealtime

  /// RealtimeSanitizer should error if a real-time unsafe function is invoked
  /// during a real-time sanitized function (see `sanitize_realtime`).
  SanitizeRealtimeBlocking

  /// Speculative Load Hardening is enabled.
  ///
  /// Note that this uses the default compatibility (always compatible during
  /// inlining) and a conservative merge strategy where inlining an attributed
  /// body will add the attribute to the caller. This ensures that code carrying
  /// this attribute will always be lowered with hardening enabled.
  SpeculativeLoadHardening

  /// Function must be in a unwind table.
  UWTable(Int)

  /// Minimum/Maximum vscale value for function.
  VScaleRange(Int)

  /// Function always comes back to callsite.
  WillReturn

  /// Function is required to make Forward Progress.
  MustProgress

  /// Function is a presplit coroutine.
  PresplitCoroutine

  /// The coroutine would only be destroyed when it is complete.
  CoroDestroyOnlyWhenComplete

  /// The coroutine call meets the elide requirement. Hint the optimization
  /// pipeline to perform elide on the call or invoke instruction.
  CoroElideSafe

  DenormalFPMath
  DenormalFPMathF32
} derive(Hash, Eq)

///|
///
///  TODO: Initializes is a ConstantRangeListAttr
///  TODO: Range is a ConstantRangeAttr
pub(all) enum ParamAttr {

  /// Alignment of parameter (5 bits) stored as log2 of alignment with +1 bias.
  /// 0 means unaligned (different from align(1)).
  Alignment(Int)

  /// Parameter of a function that tells us the alignment of an allocation, as in
  /// aligned_alloc and aligned ::operator::new.
  AllocAlign

  /// Parameter is the pointer to be manipulated by the allocator function.
  AllocatedPointer 

  /// Pass structure by value.
  ByVal(&Type)

  /// Mark in-memory ABI type.
  ByRef(&Type)

  /// Parameter or return value may not contain uninitialized or poison bits.
  NoUndef

  /// Pointer is known to be dereferenceable.
  Dereferenceable(Int)

  /// Pointer is either null or dereferenceable.
  DereferenceableOrNull(Int)

  /// Provide pointer element type to intrinsic.
  ElementType(&Type)

  /// Pass structure in an alloca.
  InAlloca(&Type)

  /// Pointer argument memory is initialized.
  Initializes

  /// Force argument to be passed in register.
  InReg

  /// Forbidden floating-point classes.
  NoFPClass

  /// Nested function static chain.
  Nest

  /// Considered to not alias after call.
  NoAlias

  /// Specify how the pointer may be captured.
  Captures

  /// No extension needed before/after call (high bits are undefined).
  NoExt

  /// Function does not deallocate memory.
  NoFree

  /// Argument is dead if the call unwinds.
  DeadOnUnwind

  /// Pointer is known to be not null.
  NonNull

  /// Similar to byval but without a copy.
  Preallocated(&Type)

  /// Parameter or return value is within the specified range.
  Range

  /// Function does not access memory.
  ReadNone

  /// Function only reads from memory.
  ReadOnly

  /// Return value is always equal to this argument.
  Returned

  /// Parameter is required to be a trivial constant.
  ImmArg

  /// Sign extended before/after call.
  SExt

  /// Alignment of stack for function (3 bits)  stored as log2 of alignment with
  /// +1 bias 0 means unaligned (different from alignstack=(1)).
  StackAlignment(Int)

  /// Hidden pointer to structure to return.
  StructRet

  /// Argument is swift error.
  SwiftError

  /// Argument is swift self/context.
  SwiftSelf

  /// Argument is swift async context.
  SwiftAsync

  /// Pointer argument is writable.
  Writable

  /// Function only writes to memory.
  WriteOnly

  /// Zero extended before/after call.
  ZExt
} derive(Hash, Eq)

///|
pub(all) enum RetAttr {

  /// Alignment of parameter (5 bits) stored as log2 of alignment with +1 bias.
  /// 0 means unaligned (different from align(1)).
  Alignment(Int)

  /// Parameter or return value may not contain uninitialized or poison bits.
  NoUndef

  /// Pointer is known to be dereferenceable.
  Dereferenceable(Int) 

  /// Pointer is either null or dereferenceable.
  DereferenceableOrNull(Int)

  /// Force argument to be passed in register.
  InReg

  /// Forbidden floating-point classes.
  NoFPClass

  /// Considered to not alias after call.
  NoAlias

  /// No extension needed before/after call (high bits are undefined).
  NoExt

  /// Pointer is known to be not null.
  NonNull

  /// Sign extended before/after call.
  SExt

  /// Alignment of stack for function (3 bits)  stored as log2 of alignment with
  /// +1 bias 0 means unaligned (different from alignstack=(1)).
  StackAlignment(Int)

  /// Zero extended before/after call.
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
