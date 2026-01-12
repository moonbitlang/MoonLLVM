///|
pub struct Riscv64Module {
  insts : Array[RvAsm]
}

///|
pub impl Show for Riscv64Module with output(self, logger) {
  self.insts.map(inst => "\{inst}\n").join("")
  |> &Logger::write_string(logger, _)
}

///|
pub fn compile(mod : @IR.Module) -> Riscv64Module raise {
  let mir_mod = @MachineIR.Module::new(@MachineIR.ArchConfig::riscv64())
  mir_mod.translate_llvm_module(mod)
  mir_mod.legalize()
  mir_mod.alloc_register()
  mir_mod.post_ra()
  let insts = mir_module_to_riscv(mir_mod)
  Riscv64Module::{ insts, }
}
