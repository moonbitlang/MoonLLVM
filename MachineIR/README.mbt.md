# MoonMIR

MoonMIR is a compiler backend for [MoonLLVM](https://github.com/Kaida-Amethyst/MoonLLVM), designed to translate MoonLLVM's intermediate representation (IR) into assembly code. The entire project is written in MoonBit, ensuring seamless integration with the MoonBit ecosystem. Currently, MoonMIR supports `riscv64` and `aarch64` as compilation targets.

[中文版](#zh-cn)

## Features

- **Pure MoonBit:** Developed entirely in MoonBit for excellent compatibility and performance within the MoonBit environment.
- **MoonLLVM Backend:** Acts as a compiler backend, transforming MoonLLVM IR into human-readable assembly code.
- **Cross-Architecture Support:** Currently supports `riscv64` and `aarch64` architectures, with plans to expand.

## Getting Started

### Prerequisites

Before using MoonMIR, you need a MoonBit project that already utilizes `Kaida-Amethyst/MoonLLVM`.

### Installation

First, update your package index and then add MoonMIR to your project by running the following commands in your project's root directory:

```bash
moon update
moon add Kaida-Amethyst/MoonMIR
```

### Configuration

To enable a specific target architecture, you must add its corresponding package to your `moon.pkg.json` file. For example, to compile to `riscv64`, modify your `imports` section as follows:

```json
{
  "imports": [
    "Kaida-Amethyst/MoonLLVM/IR",
    "Kaida-Amethyst/MoonMIR/riscv64"
  ]
}
```

If you need to target `aarch64`, simply replace `riscv64` with `aarch64`.

## Usage Example

Here is a complete example demonstrating how to generate `riscv64` assembly from MoonLLVM IR.

1.  **Configure `moon.pkg.json`:**

    ```json
    {
      "imports": [
        "Kaida-Amethyst/MoonLLVM/IR",
        "Kaida-Amethyst/MoonMIR/riscv64"
      ]
    }
    ```

2.  **Write the MoonBit code:**

    The following code snippet creates a simple `add` function using MoonLLVM and then compiles it to `riscv64` assembly using MoonMIR.

    ```moonbit skip
    ///|
    fn main_err() -> Unit raise {
      // 1. Set up MoonLLVM context, module, and IR builder.
      let ctx = @IR.Context::new()
      let mod = ctx.addModule("my_module")
      let builder = IRBuilder::new()

      // 2. Define function signature: i32 add(i32, i32).
      let i32_t = ctx.getInt32Ty()
      let f_type = ctx.getFunctionType(i32_t, [i32_t, i32_t])

      // 3. Add the function and create an entry basic block.
      let f = mod.addFunction(f_type, "add")
      let bb = f.addBasicBlock("entry")
      builder.setInsertPoint(bb)

      // 4. Name the function arguments.
      let x = f.getArg(0).unwrap()
      x.setName("x")
      let y = f.getArg(1).unwrap()
      y.setName("y")

      // 5. Create the add and return instructions.
      let sum = builder.createAdd(x, y, "sum")
      builder.createRet(sum)

      // 6. Compile the LLVM module to RISC-V 64 assembly.
      let rv_mod = @riscv64.compile(mod)

      // 7. Print the resulting assembly code.
      println(rv_mod)
    }

    ///|
    fn main {
      try main_err() catch {
        e => println(e)
      } noraise {
        _ => ()
      }
    }
    ```

## Future Plans

- **Expanded Architecture Support:** Add more backends, with `x86_64` as a priority.
- **Assembler and Linker:** Develop a custom assembler (`MoonAs`) and linker (`MoonLD`) to create a complete toolchain.
- **Debugging Support:** Integrate debugging capabilities.

---

<a name="zh-cn"></a>

# MoonMIR

MoonMIR 是一个为 [MoonLLVM](https://github.com/Kaida-Amethyst/MoonLLVM) 设计的编译器后端，用于将 MoonLLVM 的中间表示（IR）转换为汇编代码。整个项目完全由 MoonBit 语言编写，确保了与 MoonBit 生态系统的无缝集成。目前，MoonMIR 支持 `riscv64` 和 `aarch64` 作为编译目标。

## 特性

- **纯 MoonBit 实现:** 完全使用 MoonBit 开发，在 MoonBit 环境中具有出色的兼容性和性能。
- **MoonLLVM 后端:** 作为编译器后端，将 MoonLLVM IR 转换为人类可读的汇编代码。
- **跨架构支持:** 目前支持 `riscv64` 和 `aarch64` 架构，并计划在未来扩展。

## 快速上手

### 先决条件

在使用 MoonMIR 之前，您需要一个已经使用 `Kaida-Amethyst/MoonLLVM` 的 MoonBit 项目。

### 安装

首先，更新您的包索引，然后在项目根目录中运行以下命令，将 MoonMIR 添加到您的项目中：

```bash
moon update
moon add Kaida-Amethyst/MoonMIR
```

### 配置

要启用特定的目标架构，您必须将其对应的包添加到您的 `moon.pkg.json` 文件中。例如，要编译到 `riscv64`，请按如下方式修改您的 `imports` 部分：

```json
{
  "imports": [
    "Kaida-Amethyst/MoonLLVM/IR",
    "Kaida-Amethyst/MoonMIR/riscv64"
  ]
}
```

如果您需要针对 `aarch64`，只需将 `riscv64` 替换为 `aarch64`。

## 使用示例

以下是一个完整的示例，演示了如何从 MoonLLVM IR 生成 `riscv64` 汇编代码。

1.  **配置 `moon.pkg.json`:**

    ```json
    {
      "imports": [
        "Kaida-Amethyst/MoonLLVM/IR",
        "Kaida-Amethyst/MoonMIR/riscv64"
      ]
    }
    ```

2.  **编写 MoonBit 代码:**

    以下代码片段使用 MoonLLVM 创建一个简单的 `add` 函数，然后使用 MoonMIR 将其编译为 `riscv64` 汇编。

    ```moonbit skip
    ///|
    fn main_err() -> Unit raise {
      // 1. 设置 MoonLLVM 上下文、模块和 IR 构建器。
      let ctx = @IR.Context::new()
      let mod = ctx.addModule("my_module")
      let builder = IRBuilder::new()

      // 2. 定义函数签名：i32 add(i32, i32)。
      let i32_t = ctx.getInt32Ty()
      let f_type = ctx.getFunctionType(i32_t, [i32_t, i32_t])

      // 3. 添加函数并创建入口基本块。
      let f = mod.addFunction(f_type, "add")
      let bb = f.addBasicBlock("entry")
      builder.setInsertPoint(bb)

      // 4. 命名函数参数。
      let x = f.getArg(0).unwrap()
      x.setName("x")
      let y = f.getArg(1).unwrap()
      y.setName("y")

      // 5. 创建加法和返回指令。
      let sum = builder.createAdd(x, y, "sum")
      builder.createRet(sum)

      // 6. 将 LLVM 模块编译为 RISC-V 64 汇编。
      let rv_mod = @riscv64.compile(mod)

      // 7. 打印生成的汇编代码。
      println(rv_mod)
    }

    ///|
    fn main {
      try main_err() catch {
        e => println(e)
      } noraise {
        _ => ()
      }
    }
    ```

## 未来计划

- **扩展架构支持:** 添加更多后端，优先支持 `x86_64`。
- **汇编器和链接器:** 开发自定义的汇编器（`MoonAs`）和链接器（`MoonLD`），以构建完整的工具链。
- **调试支持:** 集成调试功能。
