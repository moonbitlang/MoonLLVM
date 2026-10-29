///|
pub extend FReg with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend FReg with Eq::{not_equal, equal}

///|
pub extend FReg with Hash::{hash, hash_combine}

///|
pub extend FReg with Show::{to_string, output}

///|
pub extend MIRToRiscvError with Show::{to_string, output}

///|
pub extend Mem with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Mem with Eq::{not_equal, equal}

///|
pub extend Mem with Hash::{hash, hash_combine}

///|
pub extend Mem with Show::{to_string, output}

///|
pub extend Reg with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Reg with Eq::{not_equal, equal}

///|
pub extend Reg with Hash::{hash, hash_combine}

///|
pub extend Reg with Show::{to_string, output}

///|
pub extend Riscv64Module with Show::{to_string, output}

///|
pub extend RvAsm with Show::{to_string, output}
