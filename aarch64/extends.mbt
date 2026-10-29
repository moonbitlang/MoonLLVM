///|
pub extend AArch64Asm with Show::{to_string, output}

///|
pub extend AArch64Module with Show::{to_string, output}

///|
pub extend FReg with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend FReg with Eq::{not_equal, equal}

///|
pub extend FReg with Hash::{hash, hash_combine}

///|
pub extend FReg with Show::{to_string, output}

///|
pub extend MIRToAArch64Error with Show::{to_string, output}

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
pub extend WReg with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend WReg with Eq::{not_equal, equal}

///|
pub extend WReg with Hash::{hash, hash_combine}

///|
pub extend WReg with Show::{to_string, output}
