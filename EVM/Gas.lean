-- EVM/Gas.lean
-- Minimal gas accounting helpers (scaffold)

namespace EVM.Gas

open EVM

/- Minimal gas cost table for common instructions. This is a simplified
   educational approximation of the Yellow Paper cost table. -/
def costOf : Instruction -> Nat
  | Instruction.stop => 0
  | Instruction.add => 3
  | Instruction.mul => 5
  | Instruction.sub => 3
  | Instruction.div => 5
  | Instruction.sdiv => 5
  | Instruction.mod => 5
  | Instruction.smod => 5
  | Instruction.addmod => 8
  | Instruction.mulmod => 8
  | Instruction.lt => 3
  | Instruction.gt => 3
  | Instruction.eq => 3
  | Instruction.slt => 3
  | Instruction.sgt => 3
  | Instruction.and => 3
  | Instruction.or => 3
  | Instruction.xor => 3
  | Instruction.not => 3
  | Instruction.pop => 2
  | Instruction.dup _ => 3
  | Instruction.swap _ => 3
  | Instruction.mload => 3
  | Instruction.mstore => 12
  | Instruction.msize => 2
  | Instruction.sload => 50
  | Instruction.sstore => 20000
  | Instruction.push _ => 3
  | Instruction.jump => 8
  | Instruction.jumpi => 10
  | Instruction.jumpdest => 1
  | Instruction.ret => 0
  | Instruction.revert => 0

end EVM.Gas
