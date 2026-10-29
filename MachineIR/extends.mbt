///|
pub extend BasicBlock with Eq::{not_equal, equal}

///|
pub extend BasicBlock with Show::{to_string, output}

///|
pub extend BranchOpCode with Eq::{not_equal, equal}

///|
pub extend BranchOpCode with Show::{to_string, output}

///|
pub extend CastOpCode with Eq::{not_equal, equal}

///|
pub extend CastOpCode with Show::{to_string, output}

///|
pub extend FBinaryOpCode with Eq::{not_equal, equal}

///|
pub extend FBinaryOpCode with Show::{to_string, output}

///|
pub extend FCmpOpCode with Eq::{not_equal, equal}

///|
pub extend FCmpOpCode with Show::{to_string, output}

///|
pub extend FRegister with Eq::{not_equal, equal}

///|
pub extend FRegister with Hash::{hash, hash_combine}

///|
pub extend FRegister with Show::{to_string, output}

///|
pub extend FUnaryOpCode with Eq::{not_equal, equal}

///|
pub extend FUnaryOpCode with Show::{to_string, output}

///|
pub extend Function with Show::{to_string, output}

///|
pub extend GlobalValue with Show::{to_string, output}

///|
pub extend IBinaryOpCode with Eq::{not_equal, equal}

///|
pub extend IBinaryOpCode with Show::{to_string, output}

///|
pub extend ICmpOpCode with Eq::{not_equal, equal}

///|
pub extend ICmpOpCode with Show::{to_string, output}

///|
pub extend IRegister with Eq::{not_equal, equal}

///|
pub extend IRegister with Hash::{hash, hash_combine}

///|
pub extend IRegister with Show::{to_string, output}

///|
pub extend IUnaryOpCode with Eq::{not_equal, equal}

///|
pub extend IUnaryOpCode with Show::{to_string, output}

///|
pub extend Instruction with Eq::{not_equal, equal}

///|
pub extend Instruction with Show::{to_string, output}

///|
pub extend InterferenceGraph with Show::{to_string, output}

///|
pub extend MIRError with Show::{to_string, output}

///|
pub extend Module with Show::{to_string, output}

///|
pub extend OpCode with Eq::{not_equal, equal}

///|
pub extend OpCode with Show::{to_string, output}

///|
pub extend Operand with Eq::{not_equal, equal}

///|
pub extend Operand with Hash::{hash, hash_combine}

///|
pub extend Operand with Show::{to_string, output}
