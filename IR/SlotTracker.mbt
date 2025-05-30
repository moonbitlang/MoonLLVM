///|
struct SlotTracker {
  function : Function
  valueMap : Map[&Value, UInt64]
}

///|
fn SlotTracker::new(function : Function) -> SlotTracker {
  SlotTracker::{ function, valueMap: Map::new() }
}

///|
fn SlotTracker::process(self : SlotTracker) -> Unit {
  self.clear()
  let mut slot : UInt64 = 0

  // set slot for arguments
  for arg in self.function.arguments {
    if arg.getName() is None {
      self.valueMap.set(arg, slot)
      slot += 1
    }
  }

  // set slot for basic blocks and instructions
  for bb in self.function.basicBlocks {
    if bb.getName() is None {
      self.valueMap.set(bb, slot)
      slot += 1
    }
    loop bb.head {
      Some(i) if i.getName() is None &&
        not(i.getType().asTypeEnum() is VoidType(_)) => {
        self.valueMap.set(i, slot)
        slot += 1
        continue i.next()
      }
      Some(i) => continue i.next()
      None => break
    }
  }
}

///|
fn SlotTracker::clear(self : SlotTracker) -> Unit {
  self.valueMap.clear()
}

///|
fn SlotTracker::getSlot(self : SlotTracker, value : &Value) -> UInt64? {
  match self.valueMap.get(value) {
    Some(slot) => Some(slot)
    None => {
      self.process()
      match self.valueMap.get(value) {
        Some(slot) => Some(slot)
        None => None
      }
    }
  }
}
