-- Example EVM Programs
-- Demonstrates the EVM model in action

import EVM.Core
import EVM.Instructions
import EVM.Execution

namespace EVM.Examples

-- **Example 1**: Simple arithmetic: push 5, push 3, add
-- Expected: stack has [8] at the end
def example_add : List Instruction :=
  [
    Instruction.push 5,
    Instruction.push 3,
    Instruction.add,
    Instruction.stop
  ]

-- **Example 2**: Store to memory and load back
-- Push 42, store at address 0, load from address 0
def example_memory : List Instruction :=
  [
    Instruction.push 42,
    Instruction.push 0,
    Instruction.mstore,
    Instruction.push 0,
    Instruction.mload,
    Instruction.stop
  ]

-- **Example 3**: Conditional jump (simplified)
-- If 1, jump to target instruction
def example_conditional : List Instruction :=
  [
    Instruction.push 5,           -- target address
    Instruction.push 1,           -- condition (true)
    Instruction.jumpi,            -- conditional jump
    Instruction.push 100,         -- skipped if jump taken
    Instruction.push 200,         -- target: jumped here
    Instruction.stop
  ]

-- **Run example and inspect stack**
#eval
  let (result, state) := execute example_add 10000 1000
  (result, state.stack)

#eval
  let (result, state) := execute example_memory 10000 1000
  (result, state.memory)

#eval
  let (result, state) := execute example_conditional 10000 1000
  (result, state.stack)

end EVM.Examples
