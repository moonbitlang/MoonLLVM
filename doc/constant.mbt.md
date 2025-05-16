
# Constant

In cpp LLVM, we use `Constant::get` to get a constant, like:

```cpp
#include <llvm/IR/LLVMContext.h>
#include <llvm/Support/raw_ostream.h>
#include <memory>

using namespace llvm;

int main() {
  std::unique_ptr<LLVMContext> context;

  // Int32
  Type *i32ty = Type::getInt32Ty(context.get());
  outs() << *ConstantInt::get(i32ty, 0) << "\n";
  outs() << *ConstantInt::get(i32ty, 1) << "\n";
  outs() << *ConstantInt::get(i32ty, -1) << "\n";

  outs() << *ConstantInt::get(i32ty, 0, false) << "\n";
  outs() << *ConstantInt::get(i32ty, 1, false) << "\n";
  outs() << *ConstantInt::get(i32ty, 128, false) << "\n";

  return 0;
}
```

In Aether, to create a constant integer:

```Moonbit
test "Get a constant" {
  let ctx = LLVMContext::new()

  inspect!(ctx.getConstInt32(0), content="i32 0")
  inspect!(ctx.getConstInt32(1), content="i32 1")
  inspect!(ctx.getConstInt32(-1), content="i32 -1")

  inspect!(ctx.getConstUInt32(0), content="i32 0")
  inspect!(ctx.getConstUInt32(1), content="i32 1")
  inspect!(ctx.getConstUInt32(128), content="i32 128")
}
```

to create a constant floating point:

Notice that for floating point, we have special values, like negative zero,
negative infinity, nan, we provide some special apis.

```Moonbit
test "Get Floating Point Constants" 
  let ctx = LLVMContext::new()

  inspect!(ctx.getConstFloat(1.0), content="float 0x3FF0000000000000")
  inspect!(ctx.getConstDouble(1.0), content="double 0x3FF0000000000000")

  inspect!(ctx.getConstZeroFloat(), content="float 0x0")
  inspect!(ctx.getConstZeroFloat(isNegative=true), content="float 0x8000000000000000")

  inspect!(ctx.getConstZeroDouble(), content="double 0x0")
  inspect!(ctx.getConstZeroDouble(isNegative=true), content="double 0x8000000000000000")

  inspect!(ctx.getConstNaNFloat(), content="float 0x7FF8000000000000")
  inspect!(ctx.getConstNaNFloat(isNegative=true), content="float 0xFFF8000000000000")

  inspect!(ctx.getConstNaNDouble(), content="double 0x7FF8000000000000")
  inspect!(ctx.getConstNaNDouble(isNegative=true), content="double 0xFFF8000000000000")

  inspect!(ctx.getConstQNaNFloat(), content="float 0x7FF8000000000000")
  inspect!(ctx.getConstQNaNFloat(isNegative=true), content="float 0xFFF8000000000000")

  inspect!(ctx.getConstQNaNDouble(), content="double 0x7FF8000000000000")
  inspect!(ctx.getConstQNaNDouble(isNegative=true), content="double 0xFFF8000000000000")

  inspect!(ctx.getConstInfFloat(), content="float 0x7FF0000000000000")
  inspect!(ctx.getConstInfFloat(isNegative=true), content="float 0xFFF0000000000000")

  inspect!(ctx.getConstInfDouble(), content="double 0x7FF0000000000000")
  inspect!(ctx.getConstInfDouble(isNegative=true), content="double 0xFFF0000000000000")
}
```
