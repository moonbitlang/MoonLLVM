///|
pub struct InterferenceGraph {
  nodes : Set[Operand]
  edges : Map[Operand, Set[Operand]]
  color_map : Map[Operand, Operand]
  available_int_colors : Set[Operand]
  available_fp_colors : Set[Operand]
  mut spilled_count : Int
}

///|
pub fn InterferenceGraph::new(
  config : ArchConfig,
  spilled_count : Int,
) -> InterferenceGraph {
  let {
    num_arg_regs,
    num_temp_regs,
    num_saved_regs,
    num_arg_fregs,
    num_temp_fregs,
    num_saved_fregs,
    ..,
  } = config
  let available_int_colors : Set[Operand] = Set::new()
  let available_fp_colors : Set[Operand] = Set::new()
  for i in 0..<num_arg_regs {
    available_int_colors.add(IRegister(AReg(i)))
  }
  for i in 0..<(num_temp_regs - 2) {
    available_int_colors.add(IRegister(TReg(i)))
  }
  for i in 0..<num_saved_regs {
    available_int_colors.add(IRegister(SReg(i)))
  }
  for i in 0..<num_arg_fregs {
    available_fp_colors.add(FRegister(FAReg(i)))
  }
  for i in 0..<(num_temp_fregs - 2) {
    available_fp_colors.add(FRegister(FTReg(i)))
  }
  for i in 0..<num_saved_fregs {
    available_fp_colors.add(FRegister(FSReg(i)))
  }
  for i in 0..<spilled_count {
    available_int_colors.add(Mem(FramePtrPrim, i.to_int64() * 8))
    available_fp_colors.add(Mem(FramePtrPrim, i.to_int64() * 8))
  }
  InterferenceGraph::{
    nodes: Set::new(),
    edges: Map::new(),
    color_map: Map::new(),
    available_int_colors,
    available_fp_colors,
    spilled_count,
  }
}

///|
pub impl Show for InterferenceGraph with output(self, logger) {
  logger.write_string("Interference Graph:\n")
  logger.write_string("Nodes:\n")
  for i, node in self.nodes.iter() {
    logger.write_string("\{node}")
    if i % 10 != 9 && i != self.nodes.length() - 1 {
      logger.write_string(", ")
    } else {
      logger.write_string("\n")
    }
  }
  logger.write_string("Edges:\n")
  for pair in self.edges {
    let (node, neighbors) = pair
    let neighbor_str = neighbors.iter().map(n => "\{n}").join(", ")
    logger.write_string("  \{node}: \{neighbor_str}\n")
  }
}

///|
pub fn InterferenceGraph::add_node(
  self : InterferenceGraph,
  node : Operand,
) -> Unit {
  // No need to check if nodes contains node.
  self.nodes.add(node)
  if !self.edges.contains(node) {
    self.edges[node] = Set::new()
  }
}

///|
pub fn InterferenceGraph::add_edge(
  self : InterferenceGraph,
  node1 : Operand,
  node2 : Operand,
) -> Unit {
  self..add_node(node1)..add_node(node2)
  if node1 == node2 {
    return
  }
  // No need to check if nodes contains node1 or node2.
  self.edges[node1].add(node2)
  self.edges[node2].add(node1)
}

///|
pub fn InterferenceGraph::find_uncolored_vreg_with_greatest_uncolored_degree(
  self : InterferenceGraph,
) -> Operand? {
  let mut max_degree = -1
  let mut candidate : Operand? = None
  for node in self.nodes {
    if !(node is IRegister(VReg(_))) {
      continue
    }
    if self.color_map.contains(node) {
      continue
    }
    let degree = self.edges[node]
      .iter()
      .filter(n => !n.is_fp_operand() && !self.color_map.contains(n))
      .collect()
      .length()
    if degree > max_degree {
      max_degree = degree
      candidate = Some(node)
    }
  }
  candidate
}

///|
pub fn InterferenceGraph::find_uncolored_vfreg_with_greatest_uncolored_degree(
  self : InterferenceGraph,
) -> Operand? {
  let mut max_degree = -1
  let mut candidate : Operand? = None
  for node in self.nodes {
    if !(node is FRegister(VFReg(_))) {
      continue
    }
    if self.color_map.contains(node) {
      continue
    }
    let degree = self.edges[node]
      .iter()
      .filter(n => n.is_fp_operand() && !self.color_map.contains(n))
      .collect()
      .length()
    if degree > max_degree {
      max_degree = degree
      candidate = Some(node)
    }
  }
  candidate
}

///|
pub fn Function::build_interference_graph(self : Function) -> InterferenceGraph {
  let config = self.mod.arch_config
  let graph = InterferenceGraph::new(config, self.spilled_count)
  for inst in self.inst_iter() {
    for def in inst.defs {
      if !(def is (IRegister(_) | FRegister(_))) {
        continue
      }
      graph.add_node(def)
    }
    for use_op in inst.uses {
      if !(use_op is (IRegister(_) | FRegister(_))) {
        continue
      }
      graph.add_node(use_op)
    }
    for op1 in inst.live_in {
      for op2 in inst.live_in {
        graph.add_edge(op1, op2)
      }
    }
  }
  graph
}

///|
///
/// Move Bias
pub fn Function::build_preference_list(
  self : Function,
) -> Map[Operand, Deque[Operand]] {
  let preference_list : Map[Operand, Deque[Operand]] = Map::new()
  for inst in self.inst_iter() {
    match inst {
      { opcode: IMove(_) | FMove(_), defs: [dst], uses: [src], .. } => {
        let entry = match preference_list.get(dst) {
          Some(deque) => deque
          None => {
            let new_deque = Deque::new()
            preference_list.set(dst, new_deque)
            new_deque
          }
        }
        entry.push_back(src)
        let entry = match preference_list.get(src) {
          Some(deque) => deque
          None => {
            let new_deque = Deque::new()
            preference_list.set(src, new_deque)
            new_deque
          }
        }
        entry.push_back(dst)
      }
      _ => ()
    }
  }
  preference_list
}

// Return color_map and number of spills

///|
pub fn InterferenceGraph::coloring(
  self : Self,
  preference_list : Map[Operand, Deque[Operand]],
) -> (Map[Operand, Operand], Int) {
  // for debugging infinite loop
  // TODO: remove this guard after confirmed no infinite loop
  let mut exit_guard = 0
  while self.find_uncolored_vreg_with_greatest_uncolored_degree() is Some(node) {
    exit_guard += 1
    if exit_guard > 500 {
      println("Compiler ICE: Infinite loop in graph coloring.")
      panic()
    }
    let preferred_colors = preference_list.get(node).unwrap_or(Deque::new())
    let avaliable_int_colors = self.available_int_colors.copy()
    for neighbor in self.edges[node] {
      match neighbor {
        IRegister(VReg(_)) if self.color_map.contains(neighbor) => {
          let color = self.color_map[neighbor]
          avaliable_int_colors.remove(color)
        }
        IRegister(_) => avaliable_int_colors.remove(neighbor)
        FRegister(_) => ()
        _ => {
          println(
            "Compiler ICE: Graph coloring should not have non register nodes.",
          )
          panic()
        }
      }
    }
    for color in preferred_colors {
      if avaliable_int_colors.contains(color) {
        self.color_map[node] = color
        break
      }
    } else {
      if avaliable_int_colors.is_empty() {
        // Spill
        self.color_map[node] = Mem(
          FramePtrPrim,
          self.spilled_count.to_int64() * 8,
        )
        self.spilled_count += 1
      } else {
        self.color_map[node] = avaliable_int_colors.iter().take(1).collect()[0]
      }
    }
  }
  exit_guard = 0
  while self.find_uncolored_vfreg_with_greatest_uncolored_degree() is Some(node) {
    exit_guard += 1
    if exit_guard > 500 {
      println("Compiler ICE: Infinite loop in graph coloring.")
      panic()
    }
    let preferred_colors = preference_list.get(node).unwrap_or(Deque::new())
    let avaliable_fp_colors = self.available_fp_colors.copy()
    for neighbor in self.edges[node] {
      match neighbor {
        FRegister(VFReg(_)) if self.color_map.contains(neighbor) => {
          let color = self.color_map[neighbor]
          avaliable_fp_colors.remove(color)
        }
        FRegister(_) => avaliable_fp_colors.remove(neighbor)
        IRegister(_) => ()
        _ => {
          println(
            "Compiler ICE: Graph coloring should not have non register nodes.",
          )
          panic()
        }
      }
    }
    for color in preferred_colors {
      if avaliable_fp_colors.contains(color) {
        self.color_map[node] = color
        break
      }
    } else {
      if avaliable_fp_colors.is_empty() {
        // Spill
        self.color_map[node] = Mem(
          FramePtrPrim,
          self.spilled_count.to_int64() * 8,
        )
        self.spilled_count += 1
      } else {
        self.color_map[node] = avaliable_fp_colors.iter().take(1).collect()[0]
      }
    }
  }
  (self.color_map, self.spilled_count)
}
