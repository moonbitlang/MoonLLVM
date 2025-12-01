# MoonLLVM – A Tiny, Friendly Companion to LLVM

[中文说明 / Chinese Version](#moonllvm--轻量但强大的-llvm-好伙伴)

MoonLLVM is a *tiny* re-implementation of selected LLVM concepts in pure MoonBit.  
It is **not** a replacement for upstream LLVM, but a lightweight, well-structured companion that is:

- Easy to read and reason about
- Fast to compile and start
- Great for learning IR, compiler construction, and LLVM’s internal design
- Designed to interoperate closely with the official LLVM via [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt)

If you want to use the full power of upstream LLVM (all targets, all optimizations, etc.), you should use [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt).  
If you want a clean, modular, MoonBit-native “Tiny LLVM” that compiles to **Native / Wasm / JavaScript**, MoonLLVM is for you (๑>◡<๑)

---

## Key Ideas

### Tiny LLVM, Written in MoonBit

- **Pure MoonBit implementation:** MoonLLVM re-implements much of LLVM’s *data structures* and *IR-building APIs* directly in MoonBit.
- **Multiple backends:** Because it is written in MoonBit, MoonLLVM itself can be compiled to:
  - Native
  - WebAssembly
  - JavaScript
- **No heavyweight dependency:** You can generate LLVM IR without installing the full LLVM toolchain.

> Need to generate *assembly* or machine code? For that, MoonLLVM works hand‑in‑hand with [MoonMIR](https://github.com/moonbitlang/MoonMIR), a separate library that takes IR to target-specific assembly.

### Designed as the Best Companion to LLVM, Not a Competitor

MoonLLVM is **not** trying to “beat” LLVM in optimizations or platform coverage. That would be unrealistic and also unnecessary (｡•́︿•̀｡)

Instead, the vision is:

> **MoonLLVM = The best complement to LLVM for MoonBit developers.**

We embrace a long‑term design where MoonLLVM and the official LLVM ecosystem are tightly connected via [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt):

1. **Aligned APIs with `llvm.mbt`:**  
   The public APIs of MoonLLVM are intentionally kept *very similar* to those of [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt) (the MoonBit bindings to real LLVM via `llvm-c`).  
   In many cases, you can switch from MoonLLVM to real LLVM by simply updating your `moon.pkg.json` imports. (The reverse direction may not always work.)
   - We maintain **hundreds of test cases** to ensure this compatibility.

2. **Interoperable IR & Bitcode (in progress):**
   - Today, MoonLLVM can emit `.ll` LLVM IR that is accepted by the official LLVM toolchain (`opt`, `llc`, etc.).
   - We are actively working on:
     1. Emitting `.bc` LLVM bitcode that the LLVM toolchain can understand and compile.
     2. Parsing LLVM IR text (first fully for MoonLLVM‑generated `.ll`, then partially for upstream LLVM IR).
     3. Decoding/encoding LLVM bitcode (first for MoonLLVM‑generated `.bc`, then partially for upstream LLVM bitcode).

3. **C++‑inspired API design:**
   - Both MoonLLVM and [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt) **closely mirror the original LLVM C++ API design**.
   - This means:
     - If you know LLVM C++ APIs, you will feel at home.
     - In many cases, you can almost translate MoonLLVM code back to C++ LLVM code one‑to‑one.

### Performance & Developer Experience

Because MoonLLVM is small and focused:

- **Fast compilation & startup:**  
  In realistic scenarios, using MoonLLVM currently gives about **7× faster compile and startup times** compared to using upstream LLVM via [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt) (measured in our own experiments).
- **Still room to grow:**  
  We have an ongoing roadmap of performance improvements to make it even faster.

This makes MoonLLVM a great choice for:

- Rapid prototyping of languages and IRs
- Interactive tools
- In‑browser / embedded compilation scenarios

### Clean Architecture, Made for Learning and Hacking

MoonLLVM’s internal architecture is heavily inspired by upstream LLVM, but:

- **Flatter structure:** fewer layers of indirection, more direct data flows.
- **More documentation & explanations:** many modules include rich comments and examples.
- **Doc tests:** many docs include runnable examples; they are part of our test suite.
- **High code quality:** written with readability and clarity in mind, not C++ template wizardry.

If you’ve ever felt that “you must be a C++ wizard to understand LLVM,” MoonLLVM tries to be the opposite (●'◡'●)  
It is an excellent playground for:

- Learning LLVM IR and compiler passes
- Experimenting with IR transforms
- Teaching compiler courses in MoonBit

### Highly Modular, Built to Stay Lightweight

MoonLLVM focuses on **IR data structures and IR building**. Compilation to assembly is intentionally moved into separate modules:

- **MoonLLVM**: IR data structures and core APIs
- **[MoonMIR](https://github.com/moonbitlang/MoonMIR)**: lowers LLVM‑like IR to target assembly (e.g., `riscv64`, `aarch64`, and more)
- Future planned components as **separate libraries**:
  - IR parser
  - Bitcode encoder/decoder
  - Pass framework
  - Assembler
  - Linker
  - Debugging utilities

This means:

- If you *only need IR construction*, you just depend on MoonLLVM — often just a few hundred KB in a Wasm/JS build.
- For browser or embedded environments, you can pick exactly the pieces you need, keeping your binary small and focused.

### Deliberate Simplicity: Not All Features, Not All Platforms

MoonLLVM intentionally **does not** aim to support:

- All of LLVM’s targets
- All corner‑case features (e.g., C’s VLA, scalable vector types, very exotic platforms)

This “subtractive” approach lets us:

- Avoid a lot of complexity and fragile edge cases
- Keep the code base much easier to understand
- Focus on the most useful subset for most MoonBit use cases

---

## Relationship to Other MoonBit Compiler Projects

- **[`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt)**  
  MoonBit bindings to *real* LLVM 19 via `llvm-c`.  
  - Use this when you need full upstream LLVM power: all targets, all optimizations, all tools.
  - MoonLLVM is designed to align with its APIs and interoperate via IR and bitcode.

- **[`MoonMIR`](https://github.com/moonbitlang/MoonMIR)**  
  MoonBit implementation of the lowering pipeline from LLVM‑style IR to assembly (currently `riscv64` and `aarch64`, with more planned).  
  - Use MoonMIR alongside MoonLLVM when you want to go all the way from IR to assembly in pure MoonBit.

- **[`MiniMoonbit2025`](https://github.com/moonbitlang/MiniMoonbit2025)**  
  A serious, non‑toy subset language of MoonBit, featuring:
  - Basic operations, control flow, structs, ADTs, pattern matching
  - Good error messages
  - Backends to LLVM IR, `aarch64`, and `riscv64` assembly  
  It serves as a concrete, real‑world example of building a compiler front‑end on top of MoonLLVM + MoonMIR — including complex examples like ray tracing, SVD, and even a Lisp interpreter.

---

## Current Status

Today, MoonLLVM can:

- Build LLVM‑style IR (modules, functions, basic blocks, instructions, types, etc.)
- Print `.ll` text that is accepted by the LLVM toolchain
- Interoperate conceptually with [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt) by sharing similar APIs

It does **not yet**:

- Emit `.bc` bitcode (planned)
- Parse upstream LLVM IR in full generality (partial support planned)
- Include a built‑in assembler / linker / debugger — these will live in separate libraries (MoonMIR, future assembler, linker, etc.)

---

## Getting Started

### Installation

```bash
moon update
moon add Kaida-Amethyst/MoonLLVM
```

### Minimal Example

A small example that creates a module with an `add` function:

```moonbit
fn main {
  // 1. Set up the context and IR builder.
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("demo")
  let builder = IRBuilder::new()

  // 2. Define the function type: i32 add(i32, i32).
  let i32_t = ctx.getInt32Ty()
  let f_type = ctx.getFunctionType(i32_t, [i32_t, i32_t])

  // 3. Add the function to the module and create an entry block.
  let f = mod.addFunction(f_type, "add")
  let bb = f.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  // 4. Get the function args and name them.
  let x = f.getArg(0).unwrap()
  x.setName("x")
  let y = f.getArg(1).unwrap()
  y.setName("y")

  // 5. Create the add instruction and return.
  let sum = builder.createAdd(x, y, name="sum")
  builder.createRet(sum)

  // 6. Print the generated LLVM IR.
  println(mod)
}
```

Run and redirect to a `.ll` file:

```bash
moon run main.mbt > add.ll
```

Compile the IR to assembly using the official LLVM toolchain:

```bash
llc -o add.s add.ll
```

---

## Roadmap

Planned next steps for MoonLLVM and its ecosystem:

1. **C compiler `mbtcc` built on MoonLLVM**  
2. **Assembler & linker** as standalone, MoonBit‑native components  
3. **Bitcode (.bc) support**: emit, decode, and re‑encode bitcode  
4. **LLVM IR parser** with strong support for MoonLLVM‑generated IR and partial support for upstream IR  
5. **Solid support for mainstream targets**: `x86_64`, `aarch64`, `riscv64`  
6. **Continuous improvement**:
   - Better documentation and tutorials
   - Higher test coverage (including doc tests)
   - Faster build and execution times

Contributions and ideas are very welcome — especially around documentation, teaching materials, and new experimental passes ヾ(•ω•`)o

---

# MoonLLVM —— 轻量但强大的 LLVM 好伙伴

> [Back to English](#moonllvm--a-tiny-friendly-companion-to-llvm)

MoonLLVM 是一个用 **MoonBit** 重新实现 LLVM 核心概念的「迷你版 LLVM」。  
它**不试图取代**官方 LLVM，而是定位为：

> 🌟 **MoonBit 开发者眼中，最舒服、最易懂的 LLVM 补充。**

相比官方 LLVM，MoonLLVM 的特点是：

- 体积小、结构清晰、代码可读性高；
- 编译和启动速度非常快（目前实测比通过 `llvm.mbt` 使用真 LLVM 快约 7 倍左右）；
- 非常适合作为：教学、研究、原型开发、浏览器/嵌入式上的轻量编译平台。

如果你要做工业级的重度优化、全平台支持，推荐直接使用真 LLVM 的 MoonBit binding —— [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt)。  
如果你想要一个 MoonBit 写的 “Tiny LLVM”，能跑在 Native / Wasm / JS 环境里，MoonLLVM 会让你十分顺手 (๑>◡<๑)

---

## 核心理念

### Tiny LLVM，纯 MoonBit 实现

- **纯 MoonBit 实现：** 直接在 MoonBit 中实现 LLVM 的各类数据结构和 IR 构造 API。
- **多种后端：** MoonLLVM 自身可以被编译到：
  - 原生（Native）
  - WebAssembly
  - JavaScript
- **无需庞大依赖：** 生成 IR 不需要在本地安装完整的 LLVM 工具链。

> 需要生成汇编 / 机器码？  
> 请搭配 [MoonMIR](https://github.com/moonbitlang/MoonMIR) 使用，它是一个用 MoonBit 实现的后端管线，可以把 IR 降成具体架构的汇编代码。

### MoonLLVM 的愿景：LLVM 的最佳「补充」，而不是对手

很现实地说，MoonLLVM **不可能也不打算**在优化水平、平台覆盖上超越 LLVM。  
这并不是失败，而是有意为之 (｡•́︿•̀｡)

MoonLLVM 的定位是：

> **与 LLVM 紧密互操作的轻量伙伴，为 MoonBit 生态补齐「好读、好学、好改」的那一块。**

这主要通过以下方式和 [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt)（真 LLVM 的 MoonBit binding）保持长期协同：

1. **接口设计与 `llvm.mbt` 高度一致：**  
   - MoonLLVM 的 API 设计刻意与 [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt) 保持相似。
   - 多数情况下，只需要修改 `moon.pkg.json` 中的 imports，就能把后端从 MoonLLVM 换成真 LLVM。（反过来未必总是成立。）
   - 为此我们会维护上百个测试用例，保证两者行为尽可能一致。

2. **IR / 字节码互操作（进行中）：**
   - 当前，MoonLLVM 生成的 `.ll` IR 已经可以被官方 LLVM 工具链（`opt`, `llc` 等）识别并编译。
   - 正在推进的方向包括：
     1. 产出能够被 LLVM 工具链识别的 `.bc` 字节码；
     2. IR 解析：优先支持解析 MoonLLVM 自己生成的 `.ll`，并逐步兼容一部分真 LLVM 生成的 IR；
     3. 字节码 decode / encode：首先支持 MoonLLVM 自己生成的 `.bc`，随后支持部分真 LLVM 的字节码。

3. **模仿原版 C++ API 的接口设计：**
   - MoonLLVM 和 [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt) 的接口设计都高度模仿 **原版 C++ LLVM API**。
   - 这意味着：
     - 熟悉 LLVM C++ 的开发者可以很快上手；
     - 很多 MoonLLVM 项目基本可以「一对一」翻译回 C++ 版本的 LLVM 代码。

### 性能与开发体验

由于 MoonLLVM 足够精简：

- **编译 & 启动更快：**  
  当前实测，在同等场景下，使用 MoonLLVM 的编译/启动速度大约是通过 `llvm.mbt` 使用真 LLVM 的 **7 倍左右**。
- **还有优化空间：**  
  我们已经在规划一系列提速计划，未来会继续挖潜。

这使得 MoonLLVM 特别适合：

- 快速语言原型、IR 原型开发；
- 交互式工具、REPL；
- 浏览器 / 嵌入式环境中的轻量编译器。

### 内部架构更扁平、更好读，非常适合学习和研究

MoonLLVM 在整体结构上大量参考了原版 LLVM，但做了许多「去复杂化」的选择：

- **结构更扁平：** 少一点间接层，更直接的数据流。
- **更多文档和注释：** 关键模块都有详尽说明。
- **文档即测试：** 许多文档中的示例是可运行的 doc test，直接纳入测试体系。
- **代码质量高、可读性优先：** 避免 C++ 模板魔法那种「非人类可读」写法。

如果你曾经觉得「看 LLVM 源码必须先成为 C++ 魔法大师」，那么 MoonLLVM 旨在让你**不需要**这样 (●'◡'●)  
它很适合作为：

- 学习 LLVM IR 和编译器 Pass 的教材；
- 编译原理课程的实战项目；
- 用 MoonBit 来研究 LLVM 内部结构和设计思想的入口。

### 更加模块化：按需引入，极致轻量

MoonLLVM 将「IR 构造」和「后端生成」刻意拆分：

- **MoonLLVM：** 只负责 LLVM 风格 IR 的数据结构与构造 API；
- **[MoonMIR](https://github.com/moonbitlang/MoonMIR)：** 负责将 IR 降到具体平台的汇编（目前支持 `riscv64` / `aarch64` 等）；
- 未来的组件会尽可能做成独立的 MoonBit 库，例如：
  - Pass 框架；
  - IR Parser；
  - Bytecode 编解码器；
  - Assembler；
  - Linker；
  - 调试工具等。

这样做的好处：

- 只需要 IR？那就只 `add MoonLLVM`，在浏览器/Wasm/嵌入式环境下可能只有几百 KB。
- 真正需要生成汇编时，再视需要引入 MoonMIR 和相关组件。
- 不像真 LLVM 那样「要用一点东西，就要拉一大坨依赖、编半天」。

### 有意做减法：不追求全平台、不追求所有特性

MoonLLVM 明确 **不会**支持 LLVM 的所有特性和所有平台，例如：

- C 语言的 VLA（变长数组）；
- 非常复杂的 Scalable Vector 类型；
- 各种极为偏门的目标架构。

我们刻意做减法，以换取：

- 更低的复杂度；
- 更容易读懂和维护的代码；
- 更贴合大多数 MoonBit 使用场景的实践体验。

---

## 与其他 MoonBit 编译项目的关系

- **[`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt)**  
  使用 `llvm-c` 构建的真 LLVM 19 的 MoonBit binding。
  - 当你需要真 LLVM 的全部能力（所有平台、所有优化、成熟的工具链）时，请使用它。
  - MoonLLVM 的接口设计和它高度对齐，并通过 IR / 字节码与其协作。

- **[`MoonMIR`](https://github.com/moonbitlang/MoonMIR)**  
  用 MoonBit 实现的，从 LLVM 风格 IR 到汇编的后端管线（目前支持 `riscv64`, `aarch64` 等）。
  - 当你需要从 MoonLLVM 的 IR 一路编到汇编时，和 MoonMIR 搭配使用即可。

- **[`MiniMoonbit2025`](https://github.com/moonbitlang/MiniMoonbit2025)**  
  一个并不「玩具」的 MoonBit 语言子集，拥有：
  - 基本运算、控制流；
  - 结构体、ADT、模式匹配；
  - 友好的错误提示；
  - LLVM IR / `aarch64` / `riscv64` 汇编后端。  
  它展示了如何基于 MoonLLVM + MoonMIR 搭建一个可以运行严肃例子的编译器（包括光线追踪、SVD 分解、Lisp 解释器等），非常适合作为学习范例与真实项目参考。

---

## 当前状态

目前，MoonLLVM 已经可以：

- 构建 LLVM 风格的 IR（模块、函数、基本块、指令、类型等）；
- 打印出可以被 LLVM 工具链接受的 `.ll` 文本；
- 在设计上与 [`llvm.mbt`](https://github.com/moonbitlang/llvm.mbt) 保持高度一致，方便互相迁移。

暂未完成、正在规划的部分包括：

- `.bc` 字节码的产出；
- 对真 LLVM IR 的全面解析（会从支持 MoonLLVM 自身 IR 开始，逐步扩展）；
- 内建的 assembler / linker / debugger（这些会作为独立库存在，例如 MoonMIR 及后续组件）。

---

## 快速上手

### 安装

```bash
moon update
moon add Kaida-Amethyst/MoonLLVM
```

### 简单示例

下面是一个最小示例，创建一个 `add` 函数模块：

```moonbit
fn main {
  // 1. 创建上下文和 IR builder。
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()

  // 2. 定义函数类型：i32 add(i32, i32)。
  let i32_t = ctx.getInt32Ty()
  let f_type = ctx.getFunctionType(i32_t, [i32_t, i32_t])

  // 3. 向模块中添加函数并创建入口基本块。
  let f = mod.addFunction(f_type, "add")
  let bb = f.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  // 4. 获取参数并命名。
  let x = f.getArg(0).unwrap()
  x.setName("x")
  let y = f.getArg(1).unwrap()
  y.setName("y")

  // 5. 创建加法指令和返回指令。
  let sum = builder.createAdd(x, y, name="sum")
  let _ = builder.createRet(sum)

  // 6. 打印生成的 LLVM IR。
  println(mod)
}
```

运行并输出到 `.ll` 文件：

```bash
moon run main.mbt > add.ll
```

使用官方 LLVM 的 `llc` 编译成汇编：

```bash
llc -o add.s add.ll
```

---

## 未来规划

MoonLLVM 及其相关生态的下一步计划包括：

1. **基于 MoonLLVM 的 C 编译器：`mbtcc`**  
2. **Assembler 与 Linker：** 以独立库形式提供的 MoonBit 原生汇编器与链接器  
3. **Bytecode 支持：** 产出 / decode / encode `.bc` 字节码  
4. **LLVM IR Parser：** 优先支持 MoonLLVM 自己生成的 IR，逐步兼容更多真 LLVM IR  
5. **主流平台支持完善：** 包括 `x86_64`、`aarch64` 和 `riscv64`  
6. **进一步打磨：**
   - 更好的文档与教程；
   - 更高的测试覆盖率（含 doc test）；
   - 更快的编译和运行速度。

欢迎一起讨论和贡献，尤其是教程、文档、教学用例、实验性 Pass 之类的内容。希望 MoonLLVM 能让更多人快乐地学/用 LLVM，也为 MoonBit 和开源世界贡献一点力量 🎉
