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
  let n := if i ≥ 0 then i else (2^256 : Int) + i
  toWord256 n.natAbs

-- Execute a single instruction and return the updated state.
def executeInstruction (instr : Instruction) (state : ExecutionState) :
    Option (ExecutionResult × ExecutionState) := do
  let state ← state.deductGas (EVM.Gas.costOf instr) ? none
  match instr with
  | Instruction.stop =>
    pure (ExecutionResult.ok, state)

  | Instruction.add =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (toWord256 (a + b))
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.mul =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (toWord256 (a * b))
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.sub =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (toWord256 (if a ≥ b then a - b else 2^256 + a - b))
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.div =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if b = 0 then 0 else a / b)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.sdiv =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if b = 0 then 0 else fromSigned ((toSigned a) / (toSigned b)))
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.mod =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if b = 0 then 0 else a % b)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.smod =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if b = 0 then 0 else fromSigned ((toSigned a) % (toSigned b)))
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.addmod =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let (m, stack3) ← Stack.pop stack2
    let stack4 ← Stack.push stack3 (if m = 0 then 0 else (a + b) % m)
    pure (ExecutionResult.ok, { state with stack := stack4 })

  | Instruction.mulmod =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let (m, stack3) ← Stack.pop stack2
    let stack4 ← Stack.push stack3 (if m = 0 then 0 else (a * b) % m)
    pure (ExecutionResult.ok, { state with stack := stack4 })

  | Instruction.lt =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if a < b then 1 else 0)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.gt =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if a > b then 1 else 0)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.eq =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if a == b then 1 else 0)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.slt =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if toSigned a < toSigned b then 1 else 0)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.sgt =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (if toSigned a > toSigned b then 1 else 0)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.and =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (a &&& b)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.or =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (a ||| b)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.xor =>
    let (a, stack1) ← Stack.pop state.stack
    let (b, stack2) ← Stack.pop stack1
    let stack3 ← Stack.push stack2 (a ^^^ b)
    pure (ExecutionResult.ok, { state with stack := stack3 })

  | Instruction.not =>
    let (a, stack1) ← Stack.pop state.stack
    let stack2 ← Stack.push stack1 (toWord256 ((2^256 : Nat) - 1 - a))
    pure (ExecutionResult.ok, { state with stack := stack2 })

  | Instruction.pop =>
    let (_, stack1) ← Stack.pop state.stack
    pure (ExecutionResult.ok, { state with stack := stack1 })

  | Instruction.dup n =>
    if n = 0 then
      none
    else
      match state.stack.items.get? (n - 1) with
      | none => none
      | some value =>
        let stack1 ← Stack.push state.stack value
        pure (ExecutionResult.ok, { state with stack := stack1 })

  | Instruction.swap n =>
    if n = 0 then
      none
    else if n < state.stack.items.length then
      let top := state.stack.items.head!
      let nth := state.stack.items.get! n
      let items := state.stack.items.set 0 nth |>.set n top
      pure (ExecutionResult.ok, { state with stack := { items := items } })
    else
      none

  | Instruction.mload =>
    let (addr, stack1) ← Stack.pop state.stack
    let value := Memory.read state.memory addr
    let stack2 ← Stack.push stack1 value
    pure (ExecutionResult.ok, { state with stack := stack2 })

  | Instruction.mstore =>
    let (value, stack1) ← Stack.pop state.stack
    let (addr, stack2) ← Stack.pop stack1
    let memory' := Memory.write state.memory addr value
    let state' := { state with memory := memory', stack := stack2 }
    pure (ExecutionResult.ok, state'.log s!"mstore addr={addr} value={value}")

  | Instruction.msize =>
    let stack1 ← Stack.push state.stack (toWord256 state.memory.size)
    pure (ExecutionResult.ok, { state with stack := stack1 })

  | Instruction.sload =>
    let (key, stack1) ← Stack.pop state.stack
    let value := Storage.read state.storage key
    let stack2 ← Stack.push stack1 value
    pure (ExecutionResult.ok, { state with stack := stack2 }.log s!"sload key={key} value={value}")

  | Instruction.sstore =>
    let (value, stack1) ← Stack.pop state.stack
    let (key, stack2) ← Stack.pop stack1
    let storage' := Storage.write state.storage key value
    let state' := { state with storage := storage', stack := stack2 }
    pure (ExecutionResult.ok, state'.log s!"sstore key={key} value={value}")

  | Instruction.push v =>
    let stack1 ← Stack.push state.stack v
    pure (ExecutionResult.ok, { state with stack := stack1 })

  | Instruction.jumpdest =>
    pure (ExecutionResult.ok, state)

  | Instruction.jump =>
    let (target, stack1) ← Stack.pop state.stack
    pure (ExecutionResult.ok, { state with stack := stack1, pc := target })

  | Instruction.jumpi =>
    let (target, stack1) ← Stack.pop state.stack
    let (cond, stack2) ← Stack.pop stack1
    let state' := if cond ≠ 0 then { state with stack := stack2, pc := target }
                 else { state with stack := stack2, pc := state.pc + 1 }
    pure (ExecutionResult.ok, state')

  | Instruction.ret =>
    pure (ExecutionResult.ok, state)

  | Instruction.revert =>
    pure (ExecutionResult.revert, state)

  | _ => none

-- Run bytecode until termination, out-of-gas, or error.
def execute (bytecode : List Instruction) (gas : Gas) (fuel : Nat) :
    ExecutionResult × ExecutionState :=
  let initial := ExecutionState.init bytecode gas
  let rec loop (state : ExecutionState) (fuel : Nat) : ExecutionResult × ExecutionState :=
    match fuel with
    | 0 => (ExecutionResult.outOfGas, state)
    | fuel + 1 =>
      match ExecutionState.currentInstruction state with
      | none => (ExecutionResult.ok, state)
      | some instr =>
        match executeInstruction instr state with
        | none => (ExecutionResult.outOfGas, state)
        | some (result, state') =>
          match instr with
          | Instruction.stop | Instruction.ret | Instruction.revert => (result, state')
          | _ =>
            let nextState := if state'.pc == state.pc then state'.nextPc else state'
            loop nextState fuel
  loop initial fuel

end EVM
