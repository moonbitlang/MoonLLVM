// ```c
// int arr[2];
// int k = 100;
// const int s = 200;
//
// void init_arr() {
//   arr[0] = 42;
//   arr[1] = 63;
//   return ;
// }
//
// int main() {
//   init_arr();
//   int res = arr[0] + arr[1] + k + s;
//   return res;
// }
// ```


///|
//test "Global Value" {
//  let ctx = Context::new();
//  let mod = ctx.addModule("demo")
//
//  // init type
//  let i32ty = ctx.getInt32Ty();
//  let arr_ty = ctx.getArrayType(i32ty, 2);
//  let void_ty = ctx.getVoidTy();
//
//  // init global variable
//  let arr = mod.addGlobalVariable(arr_ty, "arr");
//  let const100 = ctx.getConstInt32(100)
//  let k = mod.addGlobalVariable(i32ty, "k", initializer=const100);
//  let const200 = ctx.getConstInt32(200)
//  let s = mod.addGlobalConstant(i32ty, "s", const200);
//
//  // init function
//  let init_arr_fty = ctx.getFunctionType(void_ty, []);
//  let _ = mod.addFunction(init_arr_fty, "init_arr");
//
//  // main function
//  let main_fty = ctx.getFunctionType(i32ty, []);
//  let _ = mod.addFunction(main_fty, "main");
//
//  mod.dump()
//}
