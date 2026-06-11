-- EVM Execution Engine
-- This module implements the core interpreter

import EVM.Core
import EVM.Instructions
import EVM.State
import EVM.Gas

namespace EVM

-- Helper: Interpret a signed 256-bit number (two's complement)
def toSigned (w : Word256) : Int :=
  if w < 2^255 then
    w
  else
    (w : Int) - (2^256 : Int)

-- Helper: Convert signed Int back to Word256
def fromSigned (i : Int) : Word256 :=
  let n := if i ≥ 0 then i else 2^256 + i
  toWord256 n.natAbs

-- **executeInstruction**: Execute a single instruction
-- Returns (result_status, new_state)
def executeInstruction (instr : Instruction) (state : ExecutionState) :
    Option (ExecutionResult × ExecutionState) := do
  -- Deduct gas cost for this instruction up-front
  let cost := EVM.Gas.costOf instr
  let state := (state.deductGas cost) ? none

  match instr with
  
  -- **STOP**: End execution
  | Instruction.stop =>
    pure (ExecutionResult.ok, state)
  
  -- **ADD**: Pop two values, push their sum
  | Instruction.add =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let sum := toWord256 (a + b)
    let s''' ← s''.push sum
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **MUL**: Pop two values, push their product
  | Instruction.mul =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let prod := toWord256 (a * b)
    let s''' ← s''.push prod
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **SUB**: Pop a, b; push (a - b)
  | Instruction.sub =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let diff := toWord256 (if a ≥ b then a - b else 2^256 + a - b)
    let s''' ← s''.push diff
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **DIV**: Pop a, b; push (a / b), or 0 if b = 0
  | Instruction.div =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := if b = 0 then 0 else a / b
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **LT**: Pop a, b; push 1 if a < b else 0
  | Instruction.lt =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := if a < b then 1 else 0
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **EQ**: Pop a, b; push 1 if a == b else 0
  | Instruction.eq =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := if a == b then 1 else 0
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **AND**: Bitwise AND
  | Instruction.and =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := a &&& b  -- Lean 4 bitwise AND
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **OR**: Bitwise OR
  | Instruction.or =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := a ||| b  -- Lean 4 bitwise OR
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **POP**: Remove top stack item
  | Instruction.pop =>
    let _s ← state.stack.pop
    pure (ExecutionResult.ok, { state with stack := _s.2 })
  
  -- **MLOAD**: Pop address, push memory value
  | Instruction.mload =>
    let s ← state.stack.pop
    let (addr, s') ← s.2
    let value := Memory.read state.memory addr
    let s'' ← s'.push value
    pure (ExecutionResult.ok, { state with stack := s'' })
  
  -- **MSTORE**: Pop address and value, write to memory
  | Instruction.mstore =>
    let s ← state.stack.pop
    let (addr, s') ← s.2
    let (value, s'') ← Stack.pop s'
    let mem' := Memory.write state.memory addr value
    pure (ExecutionResult.ok, { state with stack := s'', memory := mem' })
  
  -- **SLOAD**: Pop key, push storage value
  | Instruction.sload =>
    let s ← state.stack.pop
    let (key, s') ← s.2
    let value := Storage.read state.storage key
    let s'' ← s'.push value
    pure (ExecutionResult.ok, { state with stack := s'' })
  
  -- **SSTORE**: Pop key and value, write to storage
  | Instruction.sstore =>
    let s ← state.stack.pop
    let (key, s') ← s.2
    let (value, s'') ← Stack.pop s'
    let stor' := Storage.write state.storage key value
    pure (ExecutionResult.ok, { state with stack := s'', storage := stor' })
  
  -- **PUSH**: Push a constant onto stack
  | Instruction.push v =>
    let s ← state.stack.push v
    pure (ExecutionResult.ok, { state with stack := s })
  
  -- **JUMP**: Pop target address and jump
  | Instruction.jump =>
    let s ← state.stack.pop
    let (target, s') ← s.2
    pure (ExecutionResult.ok, { state with stack := s', pc := target })
  
  -- **JUMPI**: Pop target and condition, conditional jump
  | Instruction.jumpi =>
    let s ← state.stack.pop
    let (cond, s') ← s.2
    let (target, s'') ← Stack.pop s'
    let new_pc := if cond ≠ 0 then target else state.pc + 1
    pure (ExecutionResult.ok, { state with stack := s'', pc := new_pc })
  
  -- **RET**: End execution successfully
  | Instruction.ret =>
    pure (ExecutionResult.ok, state)
  
  -- **REVERT**: End execution with revert
  | Instruction.revert =>
    pure (ExecutionResult.revert, state)
  
  -- Default: unsupported instruction
  | _ => none

-- **execute**: Run bytecode until completion or error
-- Uses fuel to prevent infinite loops
def execute (bytecode : List Instruction) (gas : Gas) (fuel : Nat) :
    ExecutionResult × ExecutionState := do
  let initial := ExecutionState.init bytecode gas
  let rec loop (state : ExecutionState) (fuel : Nat) : ExecutionResult × ExecutionState :=
    match fuel with
    | 0 => (ExecutionResult.outOfGas, state)
    | fuel + 1 =>
      match ExecutionState.currentInstruction state with
      | none => (ExecutionResult.ok, state)
      | some instr =>
        match executeInstruction instr state with
        | none => (ExecutionResult.revert, state)
        | some (ExecutionResult.ok, state') =>
          loop (state'.nextPc) fuel
        | some (result, state') =>
          (result, state')
  loop initial fuel

end EVM
