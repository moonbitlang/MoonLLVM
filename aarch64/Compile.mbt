///|
pub struct AArch64Module {
  insts : Array[AArch64Asm]
}

///|
pub impl Show for AArch64Module with output(self, logger) {
  self.insts.map(inst => "\{inst}\n").join("")
  |> &Logger::write_string(logger, _)
}

///|
pub fn compile(mod : @IR.Module) -> AArch64Module raise {
  let mir_mod = @MachineIR.Module::new(@MachineIR.ArchConfig::aarch64())
  mir_mod.translate_llvm_module(mod)
  mir_mod.legalize()
  mir_mod.alloc_register()
  mir_mod.post_ra()
  let insts = mir_module_to_aarch64(mir_mod)
  AArch64Module::{ insts, }
}
