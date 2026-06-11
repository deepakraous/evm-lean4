-- Quick Reference: Extending the EVM Model
-- Common patterns and how to add new features

import EVM

namespace EVM.QuickRef

-- ==============================================================================
-- 1. ADDING A NEW INSTRUCTION
-- ==============================================================================

-- Step 1: Add to Instruction inductive (in Instructions.lean)
-- (Example: adding ADDMOD - add with modulo)

-- inductive Instruction : Type where
--   | ...
--   | addmod : Instruction  -- NEW

-- Step 2: Implement in executeInstruction (in Execution.lean)

-- def executeInstruction (instr : Instruction) (state : ExecutionState) : ... := do
--   match instr with
--   | ...
--   | Instruction.addmod =>
--       -- Pop three values: (a, b, m)
--       let s ← state.stack.pop
--       let (m, s') ← s.2
--       let (b, s'') ← Stack.pop s'
--       let (a, s''') ← Stack.pop s''
--       -- Compute (a + b) mod m, handle m = 0
--       let result := if m = 0 then 0 else (a + b) % m
--       let s4 ← s'''.push result
--       pure (ExecutionResult.ok, { state with stack := s4 })

-- ==============================================================================
-- 2. ADDING A NEW INSTRUCTION THAT ACCESSES MEMORY
-- ==============================================================================

-- Pattern: Pop address, perform operation, push result

-- Example: MSIZE (get memory size in 32-byte words)
-- | Instruction.msize =>
--     let size := Memory.size state.memory
--     let s ← state.stack.push size
--     pure (ExecutionResult.ok, { state with stack := s })

-- ==============================================================================
-- 3. SIGNED ARITHMETIC
-- ==============================================================================

-- Helper functions already defined in Execution.lean:
-- - toSigned : Word256 → Int      (convert to signed 256-bit)
-- - fromSigned : Int → Word256    (convert back to unsigned)

-- Example: SLT (signed less than)
-- | Instruction.slt =>
--     let s ← state.stack.pop
--     let (b, s') ← s.2
--     let (a, s'') ← Stack.pop s'
--     let result := if toSigned a < toSigned b then 1 else 0
--     let s''' ← s''.push result
--     pure (ExecutionResult.ok, { state with stack := s''' })

-- ==============================================================================
-- 4. WORKING WITH STACK (DUP, SWAP)
-- ==============================================================================

-- DUP n: Duplicate the nth item on stack
-- SWAP n: Exchange top and nth item

-- Helper: Get nth item from stack (1-indexed, where 1 = top)
def Stack.getNth (s : Stack) (n : Nat) : Option Word256 :=
  if n > 0 && n ≤ s.items.length then
    s.items.get? (n - 1)
  else
    none

-- Example: DUP 1 (duplicate top)
-- | Instruction.dup 1 =>
--     match state.stack.peek with
--     | some v =>
--         let s ← state.stack.push v
--         pure (ExecutionResult.ok, { state with stack := s })
--     | none => none  -- stack underflow

-- ==============================================================================
-- 5. CONTROL FLOW (JUMPDEST TRACKING)
-- ==============================================================================

-- Challenge: JUMPI requires checking if target is valid JUMPDEST

-- Current simple implementation: any address is valid
-- Better implementation: precompute all JUMPDEST locations

-- Example: Precompute valid jump destinations
def findJumpDests (bytecode : List Instruction) : List Nat :=
  bytecode.indexWhere fun instr =>
    match instr with
    | Instruction.jumpdest => true
    | _ => false
  |> fun indices => indices.filter (· ≠ none)

-- Use in JUMPI:
-- | Instruction.jumpi =>
--     let s ← state.stack.pop
--     let (cond, s') ← s.2
--     let (target, s'') ← Stack.pop s'
--     let valid_jumpdests := findJumpDests state.code
--     if valid_jumpdests.contains target then
--       let new_pc := if cond ≠ 0 then target else state.pc + 1
--       pure (ExecutionResult.ok, { state with stack := s'', pc := new_pc })
--     else
--       none  -- invalid jump target

-- ==============================================================================
-- 6. PATTERN: THREE-ARGUMENT OPERATIONS
-- ==============================================================================

-- Template for operations that pop 3 values
def pop_three (state : ExecutionState) :
    Option (Word256 × Word256 × Word256 × ExecutionState) := do
  let s ← state.stack.pop
  let (c, s') ← s.2
  let (b, s'') ← Stack.pop s'
  let (a, s''') ← Stack.pop s''
  pure (a, b, c, s''')

-- Usage:
-- | Instruction.addmod =>
--     let ⟨a, b, m, s'⟩ ← pop_three state
--     let result := if m = 0 then 0 else (a + b) % m
--     let s'' ← s'.push result
--     pure (ExecutionResult.ok, { state with stack := s'' })

-- ==============================================================================
-- 7. TESTING NEW INSTRUCTIONS
-- ==============================================================================

-- Example test: Verify ADDMOD works correctly

#eval
  let program : List Instruction :=
    [
      Instruction.push 7,       -- 7
      Instruction.push 3,       -- 3
      Instruction.push 5,       -- 5 (modulo)
      -- Expected: (7 + 3) % 5 = 10 % 5 = 0
      -- Note: Need to implement addmod first!
      Instruction.stop
    ]
  let (result, state) := execute program 10000 1000
  (result, state.stack)

-- ==============================================================================
-- 8. COMMON ERROR PATTERNS
-- ==============================================================================

-- ❌ DON'T: Try to access stack items directly without checking
-- let value := state.stack.items[0]  -- might fail!

-- ✅ DO: Use Stack.pop or Stack.peek with Option
-- match state.stack.pop with
-- | some (v, s') => ...
-- | none => ...

-- ❌ DON'T: Modify state in place
-- state.stack = new_stack  -- syntax error in Lean 4!

-- ✅ DO: Create new state with updates
-- { state with stack := new_stack, pc := state.pc + 1 }

-- ❌ DON'T: Forget to handle Word256 overflow
-- let result := a + b  -- might overflow in Nat!

-- ✅ DO: Use toWord256 for wrapping
-- let result := toWord256 (a + b)

-- ==============================================================================
-- 9. DEBUGGING TIPS
-- ==============================================================================

-- Use #eval to inspect execution results
#eval
  let (result, state) := execute [Instruction.push 42, Instruction.stop] 1000 100
  state.stack

-- Use Repr to print structures
#eval
  let program := [Instruction.push 5, Instruction.push 3, Instruction.add]
  program

-- Check execution step-by-step by reducing fuel
#eval
  let (result, state) := execute [Instruction.push 5, Instruction.push 3, Instruction.add, Instruction.stop] 1000 1
  state  -- only executes 1 instruction

-- ==============================================================================
-- 10. GAS METERING (Future Enhancement)
-- ==============================================================================

-- Current: We use "fuel" to limit computation
-- Better: Track actual gas costs per instruction

-- Gas cost table:
-- - STOP: 0
-- - ADD, SUB, etc: 3
-- - MUL: 5
-- - MLOAD, MSTORE: 3
-- - SLOAD: 200
-- - SSTORE: 20000

-- def gasOfInstruction : Instruction → Nat
--   | Instruction.stop => 0
--   | Instruction.add => 3
--   | Instruction.mload => 3
--   | Instruction.sload => 200
--   | _ => 1

-- def executeInstruction' (instr : Instruction) (state : ExecutionState) :
--     Option (ExecutionResult × ExecutionState) := do
--   let cost := gasOfInstruction instr
--   let state' ← ExecutionState.deductGas state cost
--   executeInstruction instr state'

end EVM.QuickRef
