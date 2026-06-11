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

  -- **SDIV**: signed division
  | Instruction.sdiv =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    if b = 0 then
      let s''' ← s''.push 0
      pure (ExecutionResult.ok, { state with stack := s''' })
    else
      let ra := toSigned a
      let rb := toSigned b
      let q := ra / rb
      let s''' ← s''.push (fromSigned q)
      pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **LT**: Pop a, b; push 1 if a < b else 0
  | Instruction.lt =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := if a < b then 1 else 0
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })

  -- **GT**: Pop a, b; push 1 if a > b else 0
  | Instruction.gt =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := if a > b then 1 else 0
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

  -- **XOR**: Bitwise XOR
  | Instruction.xor =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := a ^^^ b
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })

  -- **NOT**: Bitwise NOT (ones' complement)
  | Instruction.not =>
    let s ← state.stack.pop
    let (a, s') ← Stack.pop s.2
    let result := toWord256 (2^256 - 1 - a)
    let s'' ← s'.push result
    pure (ExecutionResult.ok, { state with stack := s'' })
  
  -- **POP**: Remove top stack item
  | Instruction.pop =>
    let _s ← state.stack.pop
    pure (ExecutionResult.ok, { state with stack := _s.2 })

  -- **DUP**: Duplicate Nth stack item (1-based)
  | Instruction.dup n =>
    let s0 := state.stack
    let idx := n - 1
    if idx < s0.items.length then
      let v := s0.items.get! idx
      let s' ← s0.push v
      pure (ExecutionResult.ok, { state with stack := s' })
    else
      none

  -- **SWAP**: Swap top with Nth (1-based)
  | Instruction.swap n =>
    let s0 := state.stack
    let idx := n
    if idx < s0.items.length then
      let top := s0.items.head!
      let nth := s0.items.get! idx
      let items := s0.items.set 0 nth |>.set idx top
      pure (ExecutionResult.ok, { state with stack := { items := items } })
    else
      none
  
  -- **MLOAD**: Pop address, push memory value
  | Instruction.mload =>
    let s ← state.stack.pop
    let (addr, s') ← s.2
    let value := Memory.read state.memory addr
    let s'' ← s'.push value
    pure (ExecutionResult.ok, { state with stack := s'' })

  -- **MSIZE**: Push memory size
  | Instruction.msize =>
    let sz := toWord256 state.memory.size
    let s ← state.stack.push sz
    pure (ExecutionResult.ok, { state with stack := s })
  
  -- **MSTORE**: Pop value and address, write to memory
  | Instruction.mstore =>
    let s ← state.stack.pop
    let (value, s') ← s.2
    let (addr, s'') ← Stack.pop s'
    let mem' := Memory.write state.memory addr value
    let state' := { state with stack := s'', memory := mem' }
    pure (ExecutionResult.ok, state'.log s!"mstore addr={addr} value={value}")
  
  -- **SLOAD**: Pop key, push storage value
  | Instruction.sload =>
    let s ← state.stack.pop
    let (key, s') ← s.2
    let value := Storage.read state.storage key
    let s'' ← s'.push value
    let state' := { state with stack := s'' }
    pure (ExecutionResult.ok, state'.log s!"sload key={key} value={value}")
  
  -- **SSTORE**: Pop value and key, write to storage
  | Instruction.sstore =>
    let s ← state.stack.pop
    let (value, s') ← s.2
    let (key, s'') ← Stack.pop s'
    let stor' := Storage.write state.storage key value
    let state' := { state with stack := s'', storage := stor' }
    pure (ExecutionResult.ok, state'.log s!"sstore key={key} value={value}")

  -- **MOD**: unsigned modulo
  | Instruction.mod =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := if b = 0 then 0 else a % b
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })

  -- **SMOD**: signed modulo
  | Instruction.smod =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    if b = 0 then
      let s''' ← s''.push 0
      pure (ExecutionResult.ok, { state with stack := s''' })
    else
      let ra := toSigned a
      let rb := toSigned b
      let r := ra % rb
      let s''' ← s''.push (fromSigned r)
      pure (ExecutionResult.ok, { state with stack := s''' })

  -- **ADDMOD**: (a + b) % m
  | Instruction.addmod =>
    let s ← state.stack.pop
    let (m, s') ← Stack.pop s.2
    let (b, s'') ← Stack.pop s'.2
    let (a, s''') ← Stack.pop s''.2
    let result := if m = 0 then 0 else (a + b) % m
    let s4 ← s'''.push result
    pure (ExecutionResult.ok, { state with stack := s4 })

  -- **MULMOD**: (a * b) % m
  | Instruction.mulmod =>
    let s ← state.stack.pop
    let (m, s') ← Stack.pop s.2
    let (b, s'') ← Stack.pop s'.2
    let (a, s''') ← Stack.pop s''.2
    let result := if m = 0 then 0 else (a * b) % m
    let s4 ← s'''.push result
    pure (ExecutionResult.ok, { state with stack := s4 })

  -- **SLT**: signed less than
  | Instruction.slt =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := if toSigned a < toSigned b then 1 else 0
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })

  -- **SGT**: signed greater than
  | Instruction.sgt =>
    let s ← state.stack.pop
    let (b, s') ← Stack.pop s.2
    let (a, s'') ← Stack.pop s'.2
    let result := if toSigned a > toSigned b then 1 else 0
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })
  
  -- **PUSH**: Push a constant onto stack
  | Instruction.push v =>
    let s ← state.stack.push v
    pure (ExecutionResult.ok, { state with stack := s })

  -- **JUMPDEST**: Marker for valid jump target (no-op)
  | Instruction.jumpdest =>
    pure (ExecutionResult.ok, state)
  
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
