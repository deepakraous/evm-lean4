-- EVM Execution State
-- This module defines the execution context and state

import EVM.Core
import EVM.Instructions

namespace EVM

-- **ExecutionMode**: Results of execution (used for return values)
inductive ExecutionResult : Type where
  | ok : ExecutionResult        -- Successful execution
  | revert : ExecutionResult    -- Execution reverted
  | outOfGas : ExecutionResult  -- Ran out of gas
  | stackOverflow : ExecutionResult
  | stackUnderflow : ExecutionResult
  deriving Repr, BEq

-- **ExecutionState**: Complete state of the EVM during execution
structure ExecutionState where
  stack : Stack
  memory : Memory
  storage : Storage
  pc : Nat                -- program counter
  gas : Gas              -- remaining gas
  code : List Instruction -- bytecode
  deriving Repr

-- Create initial execution state
def ExecutionState.init (bytecode : List Instruction) (gas : Gas) : ExecutionState := {
  stack := Stack.empty
  memory := Memory.empty
  storage := Storage.empty
  pc := 0
  gas := gas
  code := bytecode
}

-- Helper: Get current instruction
def ExecutionState.currentInstruction (state : ExecutionState) : Option Instruction :=
  state.code.get? state.pc

-- Helper: Advance program counter
def ExecutionState.nextPc (state : ExecutionState) : ExecutionState :=
  { state with pc := state.pc + 1 }

-- Helper: Jump to address
def ExecutionState.jump (state : ExecutionState) (target : Nat) : ExecutionState :=
  { state with pc := target }

-- Helper: Deduct gas
def ExecutionState.deductGas (state : ExecutionState) (amount : Gas) : Option ExecutionState :=
  if state.gas >= amount then
    some { state with gas := state.gas - amount }
  else
    none

end EVM
