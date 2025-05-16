
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

In Aether:

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
