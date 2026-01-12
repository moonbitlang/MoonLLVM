///|
pub(all) struct GlobalValue {
  label : String
  content : GlobalValueContent
  mod : Module
  mut llvm_gv : &@IR.GlobalValue?
}

///|
pub(all) enum GlobalValueContent {
  String(String)
  Zero(UInt) // size in bytes
  Data(Array[GlobalValueData])
}

///|
pub(all) enum GlobalValueData {
  Quad(UInt64)
  Word(UInt)
  Half(UInt16)
  Byte(Byte)
}

///|
pub impl Show for GlobalValue with output(self, logger) {
  logger.write_string("global \{self.label} {\n")
  match self.content {
    String(s) => logger.write_string("  \"\{s}\"\n")
    Zero(size) => logger.write_string("  .zero \{size}\n")
    Data(data) =>
      for d in data {
        match d {
          Quad(q) => logger.write_string("  .quad \{q}\n")
          Word(w) => logger.write_string("  .word \{w}\n")
          Half(h) => logger.write_string("  .half \{h}\n")
          Byte(b) => logger.write_string("  .byte \{b.to_int()}\n")
        }
      }
  }
  logger.write_string("}\n")
}
