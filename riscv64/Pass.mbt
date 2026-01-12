// some emulator need to modify `ret` in main
// to `li a7, 93; ecall` to exit properly

///|
//fn modify_main_ret_to_ecall(insts : Array[RvAsm]) -> Unit {
//  let mut in_main_func = false
//  let mut idx = -1
//  for i, inst in insts {
//    if inst is Label("main") {
//      in_main_func = true
//    }
//    if in_main_func && inst is Ret {
//      idx = i
//      break
//    }
//  }
//  if idx == -1 {
//    return
//  }
//  insts[idx] = Li(A7, "93")
//  insts.insert(idx + 1, Ecall)
//}
