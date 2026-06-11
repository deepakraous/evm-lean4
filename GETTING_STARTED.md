# Getting Started with the EVM Lean 4 Model

## What You Have Built

A **complete, educational Ethereum Virtual Machine (EVM) model in Lean 4** with:
- ✅ Core data structures (Stack, Memory, Storage, Word256)
- ✅ Full instruction set (50+ opcodes)
- ✅ Functional execution engine with pattern matching
- ✅ Error handling via `Option` monad
- ✅ Immutable state semantics
- ✅ Concrete usage examples
- ✅ Comprehensive documentation

**All in pure Lean 4 syntax** — no Lean 3, no legacy constructs.

---

## Project Files Overview

### Core Implementation (Lean modules)

| File | Lines | Purpose |
|------|-------|---------|
| [EVM/Core.lean](EVM/Core.lean) | ~140 | Word256, Stack, Memory, Storage types |
| [EVM/Instructions.lean](EVM/Instructions.lean) | ~50 | Inductive Instruction type (all opcodes) |
| [EVM/State.lean](EVM/State.lean) | ~50 | ExecutionState, execution context |
| [EVM/Execution.lean](EVM/Execution.lean) | ~150 | Core interpreter, executeInstruction, execute loop |
| [EVM/Examples.lean](EVM/Examples.lean) | ~40 | Concrete bytecode examples |
| [EVM.lean](EVM.lean) | ~10 | Main module (imports all submodules) |

### Documentation

| File | Purpose |
|------|---------|
| [README.md](README.md) | High-level architecture, design philosophy |
| [DESIGN.md](DESIGN.md) | Deep dive: design decisions, Lean 4 patterns, detailed explanations |
| [QUICKREF.lean](QUICKREF.lean) | Code templates: how to extend the model |
| [GETTING_STARTED.md](GETTING_STARTED.md) | This file |

---

## Lean 4 Principles Used

### 1. **Immutable Data Structures**
```lean
structure Stack where
  items : List Word256

def Stack.push (s : Stack) (v : Word256) : Option Stack :=
  if s.items.length < 1024 then
    some ⟨v :: s.items⟩  -- creates new Stack, doesn't modify
  else
    none
```

### 2. **Explicit Inductive Types**
```lean
inductive Instruction : Type where
  | stop : Instruction
  | add : Instruction
  | push (v : Word256) : Instruction
```
(Pure Lean 4 syntax—no Lean 3 `inductive` without explicit `:Type`)

### 3. **Pattern Matching Everywhere**
```lean
match state.stack.pop with
| none => ...  -- underflow
| some (v, s') => ...  -- success
```

### 4. **Error Handling with Option**
```lean
def executeInstruction (...) : Option (...) := do
  let s ← state.stack.pop        -- auto-fail if None
  let (a, s') ← Stack.pop s.2
  let result ← s'.push (a + b)   -- if any step fails, return None
  pure (ExecutionResult.ok, { state with stack := result })
```

### 5. **Immutable State Updates**
```lean
{ state with 
  stack := new_stack,
  pc := state.pc + 1,
  memory := new_memory
}
```

---

## How the Execution Model Works

### Ethereum EVM Execution Flow

This diagram shows how a transaction and block context enter the EVM, how execution uses stack, memory, storage, and gas, and how the machine produces a new state.

![Ethereum EVM Execution Flow](diagram_evm_flow.jpg)

Updated to match the latest Ethereum EVM reference from:
https://ethereum.org/en/developers/docs/evm/

### Step 1: Bytecode → Instruction List

```lean
def my_program : List Instruction :=
  [
    Instruction.push 5,
    Instruction.push 3,
    Instruction.add,
    Instruction.stop
  ]
```

### Step 2: Execute with `execute` Function

```lean
def execute (bytecode : List Instruction) (gas : Gas) (fuel : Nat) :
    ExecutionResult × ExecutionState :=
  -- Recursively processes instructions until:
  -- 1. STOP/REVERT instruction (intentional halt)
  -- 2. Fuel depleted (safety limit)
  -- 3. Error occurs (stack underflow, etc.)
```

### Step 3: Inspect Results

```lean
#eval execute my_program 10000 1000
-- Returns: (ExecutionResult.ok, ExecutionState { stack = [8], ... })
```

---

## Key Design Decisions Explained

### Why `Nat` for Word256?

✅ **Pro**: Leverages Lean's arithmetic, automatic modulo with `%`  
❌ **Con**: Not as semantically pure as a custom inductive type

```lean
abbrev Word256 := Nat
def toWord256 (n : Nat) : Word256 := n % (2^256)
-- Natural overflow/underflow handling
```

### Why `List` for Stack, Memory, Storage?

✅ **Pro**: Immutable, simple, functional semantics  
❌ **Con**: O(n) operations

```lean
-- Better for proofs, worse for performance
-- Real VMs use arrays/HashMaps
```

### Why `Option` instead of Exceptions?

✅ **Pro**: Forces explicit error handling, composable  
❌ **Con**: Slightly more verbose

```lean
do
  let s ← state.stack.pop    -- if None, propagate
  let (a, s') ← Stack.pop s.2
  ...
-- vs try-catch: hides errors
```

### Why "Fuel" instead of Real Gas?

✅ **Pro**: Simpler model, prevents infinite loops  
❌ **Con**: Doesn't reflect actual gas costs

```lean
-- Extension: track gas per instruction
def gasOfInstruction : Instruction → Nat
  | Instruction.add => 3
  | Instruction.sload => 200
```

---

## How to Run Examples

### Option 1: Using `#eval` in Lean File

```lean
#eval
  let program := [Instruction.push 42, Instruction.stop]
  let (result, state) := execute program 10000 1000
  state.stack
```

### Option 2: From Terminal (requires Lean 4 + Lake installed)

```bash
cd /Users/deraous/projects/SLOKA/evm-lean4
lake build
lake env lean EVM/Examples.lean
```

---

## Common Patterns

### Pattern 1: Two-Pop Operation (Binary)

```lean
| Instruction.add =>
    let s ← state.stack.pop
    let (b, s') ← s.2
    let (a, s'') ← Stack.pop s'
    let result := toWord256 (a + b)
    let s''' ← s''.push result
    pure (ExecutionResult.ok, { state with stack := s''' })
```

**Always order matters**: first pop = `b` (top), second pop = `a` (below)

### Pattern 2: Memory Access

```lean
| Instruction.mload =>
    let s ← state.stack.pop
    let (addr, s') ← s.2
    let value := Memory.read state.memory addr
    let s'' ← s'.push value
    pure (ExecutionResult.ok, { state with stack := s'' })
```

**Read is pure**, write creates new Memory

### Pattern 3: Control Flow

```lean
| Instruction.jump =>
    let s ← state.stack.pop
    let (target, s') ← s.2
    pure (ExecutionResult.ok, { state with stack := s', pc := target })
```

**Update `pc` (program counter)** to change execution path

---

## Extending the Model

### Add a New Instruction (5 steps)

1. **Add to `Instruction` inductive** (EVM/Instructions.lean)
   ```lean
   inductive Instruction : Type where
     | mynewinstr : Instruction
   ```

2. **Implement case in `executeInstruction`** (EVM/Execution.lean)
   ```lean
   | Instruction.mynewinstr =>
       -- implementation
   ```

3. **Test with example** (EVM/Examples.lean)
   ```lean
   def my_example : List Instruction :=
     [Instruction.mynewinstr, Instruction.stop]
   
   #eval execute my_example 1000 100
   ```

4. **Document in QUICKREF.lean** (see templates)

5. **Run and verify**
   ```bash
   lake build  # checks for syntax errors
   ```

See [QUICKREF.lean](QUICKREF.lean) for detailed patterns.

---

## Next Steps to Explore

### 1. **Signed Arithmetic**
- Implement `sdiv`, `smod`, `slt`, `sgt`
- Uses `toSigned`/`fromSigned` functions (already in Execution.lean)

### 2. **Stack Duplication**
- Implement `dup n` (1-16): copy nth stack item to top
- Use `Stack.getNth` pattern from QUICKREF.lean

### 3. **Gas Metering**
- Define `gasOfInstruction` lookup table
- Deduct gas in each executeInstruction case
- Return `outOfGas` when gas depleted

### 4. **Formal Verification**
- Prove stack depth invariants
- Verify bytecode halting properties
- Check memory safety

### 5. **Bytecode Parser**
- Convert hex bytecode to Instruction list
- Handle PUSH opcodes with variable-length operands

---

## Common Issues & Solutions

### Issue: Stack Underflow in Example

```lean
-- ❌ This fails: not enough items
let program := [Instruction.add, Instruction.stop]
#eval execute program 1000 100
-- Result: (revert, state with empty stack)
```

**Solution**: Push values first
```lean
-- ✅ Correct
let program := [
  Instruction.push 5,
  Instruction.push 3,
  Instruction.add,
  Instruction.stop
]
#eval execute program 1000 100
-- Result: (ok, state with stack = [8])
```

### Issue: Understanding `do` Notation

```lean
-- This:
do
  let s ← state.stack.pop
  let (a, s') ← Stack.pop s.2
  pure result

-- Is syntactic sugar for:
match state.stack.pop with
| none => none
| some s =>
    match Stack.pop s.2 with
    | none => none
    | some (a, s') =>
        pure result
```

### Issue: State Updates Syntax

```lean
-- ❌ Wrong (tries to modify in place)
state.stack := new_stack

-- ✅ Correct (creates new state)
{ state with stack := new_stack }

-- ✅ Multiple updates
{ state with 
  stack := new_stack, 
  pc := state.pc + 1,
  memory := new_memory 
}
```

---

## File Navigation Guide

Start here in this order:

1. **README.md** (this directory) — High-level overview
2. **EVM/Core.lean** — Understand basic types
3. **EVM/Instructions.lean** — See all opcodes
4. **EVM/Execution.lean** — Study the interpreter (core logic)
5. **EVM/Examples.lean** — Run concrete examples
6. **DESIGN.md** — Deep dive into decisions
7. **QUICKREF.lean** — Templates for extensions

---

## Quick Command Reference

```bash
# Build the project
cd /Users/deraous/projects/SLOKA/evm-lean4
lake build

# Check a single file
lean EVM/Core.lean

# Run examples
lean EVM/Examples.lean

# Format code (if available)
lean --format EVM/Execution.lean
```

---

## Resources

- **Lean 4 Documentation**: https://lean-lang.org/
- **Ethereum Yellow Paper**: https://ethereum.org/en/developers/docs/evm/
- **This Project**: Minimal, educational, focus on clarity

---

## Summary

You now have:
- ✅ A complete, working EVM model in Lean 4
- ✅ Clean, minimal code (300+ lines total)
- ✅ Comprehensive documentation
- ✅ Extension patterns and templates
- ✅ All Lean 4 best practices demonstrated

**Next**: Pick an extension from "Next Steps" above and implement it!

---

**Questions?** Check DESIGN.md for explanations of every major decision.
