
pub struct LLVMContext {
  priv hashkey: Int // only for hashing
  priv mut pimpl: LLVMContextImpl?
}

pub impl Hash for LLVMContext with hash (self) {
  self.hashkey
}

pub impl Hash for LLVMContext with hash_combine(self, hasher) {
  hasher.combine_int(self.hashkey)
}

struct LLVMContextImpl {
  
  /// OwnedModules - The set of modules instantiated in this context, and which
  /// will be automatically deleted if this context is deleted.
  //ownedModules: Array[Module]
}

pub fn LLVMContext::new() -> LLVMContext {
  let ctx = LLVMContext :: {
    hashkey: @random.new().int(),
    pimpl: None
  }
  let pimpl = LLVMContextImpl :: {
  }
  ctx.pimpl = Some(pimpl)
  ctx
}

// pub fn LLVMContext::addModule(self: LLVMContext, m: Module) {
//   self.pimpl.ownedModules.push(m)
// }
