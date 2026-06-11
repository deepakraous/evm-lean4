-- EVM Instructions (Opcodes)
-- This module defines all EVM instructions and their semantics

import EVM.Core

namespace EVM

-- **Instruction**: Represents all EVM instructions
-- We organize them by category for clarity
inductive Instruction : Type where
  -- Stop and arithmetic
  | stop : Instruction
  | add : Instruction
  | mul : Instruction
  | sub : Instruction
  | div : Instruction
  | sdiv : Instruction  -- signed division
  | mod : Instruction
  | smod : Instruction
  | addmod : Instruction
  | mulmod : Instruction
  
  -- Comparison
  | lt : Instruction   -- less than
  | gt : Instruction   -- greater than
  | eq : Instruction   -- equal
  | slt : Instruction  -- signed less than
  | sgt : Instruction  -- signed greater than
  
  -- Bitwise operations
  | and : Instruction
  | or : Instruction
  | xor : Instruction
  | not : Instruction
  
  -- Stack operations
  | pop : Instruction
  | dup (n : Nat) : Instruction    -- duplicate nth stack item (1-16)
  | swap (n : Nat) : Instruction   -- swap top with nth item (1-16)
  
  -- Memory operations
  | mload : Instruction   -- load from memory
  | mstore : Instruction  -- store to memory
  | msize : Instruction   -- get memory size
  
  -- Storage operations
  | sload : Instruction   -- load from storage
  | sstore : Instruction  -- store to storage
  
  -- Constant operations
  | push (v : Word256) : Instruction
  
  -- Jump operations
  | jump : Instruction
  | jumpi : Instruction   -- conditional jump
  | jumpdest : Instruction
  
  -- Control flow
  | ret : Instruction     -- return
  | revert : Instruction  -- revert with error
  
  deriving Repr, BEq

end EVM
