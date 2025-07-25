# MoonLLVM

一个在 Moonbit 中生成 LLVM IR 的库。它的 API 设计与 LLVM 原始的 C++ 库相似。

## MGPIC竞赛须知

1. `MoonLLVM`与`llvm.mbt`的差别，`llvm.mbt`是真llvm的moonbit语言binding，需要链接到llvm库，并保证llvm版本在llvm-19以上，只能使用native后端，可以使用llvm的一些高级功能，但缺少一些直接操控内部数据结构的手段。`MoonLLVM`是moonbit语言的llvm简单复刻，不需要链接到llvm库，可以输出到所有moonbit支持的后端，可以直接操控一些数据结构，但缺少一些高级功能。

2. `MoonLLVM`与`llvm.mbt`的接口类型，尽管有一定的差别，但开发者切换二者的成本很低。

3. 竞赛期间MoonLLVM仍然保持更新，但从8月10日起到比赛结束，进入暂时的稳定状态，对breaking change将保持克制，使用deprecated warning来进行提示，并且其中的warning信息将可能与比赛相关。比赛结束后，MoonLLVM将会恢复到不稳定的状态。

## 特性

- **纯 Moonbit 实现:** 完全由 Moonbit 编写。
- **无依赖:** 生成 IR 无需在本地安装 LLVM。
- **熟悉的 API:** 接口设计借鉴了 LLVM 的 C++ API，对于熟悉 LLVM 的开发者来说学习成本更低。

## 当前状态

MoonLLVM 目前可以生成 LLVM 中间表示 (IR)。但是，它尚未内置编译器来生成汇编或机器码。您需要使用像 `llc` 这样的外部工具来编译生成的 `.ll` 文件。

## 快速上手

### 安装

要将 MoonLLVM 添加到您的项目中，请在项目根目录中运行以下命令：

```bash
moon update
moon add moonbitlang/MoonLLVM
```

### 使用方法

以下是一个简单的示例，展示如何创建一个包含 `add` 函数的模块，该函数接收两个 `i32` 整数并返回它们的和。

1.  创建一个 `main.mbt` 文件：

    ```moonbit
    fn main {
      // 1. 设置上下文、程序（模块）和 IR 构建器。
      let ctx = @IR.Context::new()
      let mod = ctx.addModule("my_module")
      let builder = IRBuilder::new()

      // 2. 定义函数签名：i32 add(i32, i32)。
      let i32_t = ctx.getInt32Ty()
      let f_type = ctx.getFunctionType(i32_t, [i32_t, i32_t])

      // 3. 将函数添加到模块，并创建入口基本块。
      let f = mod.addFunction(f_type, "add")
      let bb = f.addBasicBlock("entry")
      builder.setInsertPoint(bb)

      // 4. 获取函数参数并命名。
      let x = f.getArg(0).unwrap()
      x.setName("x")
      let y = f.getArg(1).unwrap()
      y.setName("y")

      // 5. 创建加法指令和返回指令。
      let sum = builder.createAdd(x, y, "sum")
      builder.createRet(sum)

      // 6. 将生成的 LLVM IR 打印到控制台。
      println(prog)
    }
    ```

2.  运行 Moonbit 程序并将输出保存到 `.ll` 文件：

    ```bash
    moon run main.mbt > add.ll
    ```

    这会生成一个名为 `add.ll` 的文件，内容如下：

    ```llvm
    ; ModuleID = 'my_module'
    source_filename = "my_module"

    define i32 @add(i32 %x, i32 %y) {
    entry:
      %sum = add i32 %x, %y
      ret i32 %sum
    }
    ```

3.  将 IR 编译为汇编代码：

    现在你有了 `add.ll` 文件，可以使用 `llc` 将它编译成汇编文件：

    ```bash
    llc -o add.s add.ll
    ```

    这会生成 `add.s` 文件，其中包含适用于您目标架构的汇编代码。

------

# MoonLLVM

A library for generating LLVM IR in Moonbit. Its API is designed to be similar to the original LLVM C++ library.

## Features

- **Pure Moonbit:** Written entirely in Moonbit.
- **No Dependencies:** Does not require a local installation of LLVM to generate IR.
- **Familiar API:** Inspired by LLVM's C++ API for a lower learning curve for those familiar with LLVM.

## Current Status

MoonLLVM can generate LLVM Intermediate Representation (IR). However, it does not yet have a built-in compiler to produce assembly or machine code. You will need to use an external tool like `llc` to compile the generated `.ll` file.

## Getting Started

### Installation

To add MoonLLVM to your project, run the following commands in your project's root directory:

```bash
moon update
moon add moonbitlang/MoonLLVM
```

### Usage

Here is a simple example of how to create a module with an `add` function that takes two `i32` integers and returns their sum.

1.  Create a file `main.mbt`:

    ```moonbit
    fn main {
      // 1. Set up the context, program (module), and IR builder.
      let ctx = @IR.LLVMContext::new()
      let prog = ctx.addProgram("my_module")
      let builder = IRBuilder::new()

      // 2. Define the function signature: i32 add(i32, i32).
      let i32_t = ctx.getInt32Ty()
      let f_type = ctx.getFunctionType(i32_t, [i32_t, i32_t])

      // 3. Add the function to the module and create an entry basic block.
      let f = prog.addFunction(f_type, "add")
      let bb = f.addBasicBlock("entry")
      builder.setInsertPoint(bb)

      // 4. Get the function's arguments and name them.
      let x = f.getArg(0).unwrap()
      x.setName("x")
      let y = f.getArg(1).unwrap()
      y.setName("y")

      // 5. Create the add instruction and a return instruction.
      let sum = builder.createAdd(x, y, "sum")
      builder.createRet(sum)

      // 6. Print the generated LLVM IR to the console.
      println(prog)
    }
    ```

2.  Run the Moonbit program and save the output to a `.ll` file:

    ```bash
    moon run main.mbt > add.ll
    ```

    This will generate a file named `add.ll` with the following content:

    ```llvm
    ; ModuleID = 'my_module'
    source_filename = "my_module"

    define i32 @add(i32 %x, i32 %y) {
    entry:
      %sum = add i32 %x, %y
      ret i32 %sum
    }
    ```

3.  Compile the IR to assembly:

    Now that you have `add.ll`, you can compile it to an assembly file using `llc`:

    ```bash
    llc -o add.s add.ll
    ```

    This will produce `add.s` containing the assembly code for your target architecture.

---

