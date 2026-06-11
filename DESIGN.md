# Lean 4 EVM Model: Design & Implementation Guide

## 1. Data Structures & Type Design

### Word256: The Core Building Block

**In EVM**, all values are 256-bit unsigned integers. In Lean 4, we model this as:

```lean
abbrev Word256 := Nat
def toWord256 (n : Nat) : Word256 := n % (2^256)
```

**Why `Nat` (not a custom inductive)?**
- ✅ Leverages Lean's built-in arithmetic
- ✅ Automatic support for `+`, `*`, `/`, comparisons
- ✅ Modulo operator handles overflow naturally
- ✅ Minimal boilerplate

**When overflow happens**:
```lean
toWord256 (2^256) = 0  -- wraps around
toWord256 (2^256 + 1) = 1
```

This matches EVM semantics where 256-bit arithmetic naturally wraps.

---

### Stack: Immutable LIFO

```lean
structure Stack where
  items : List Word256
  deriving Repr
```

**Key design: Why `List`?**
- ✅ Immutable by default (functional programming)
- ✅ Each `push` creates a new list (no side effects)
- ✅ Type safety: only `Word256` values allowed
- ✅ Easy to reason about formally

**Stack operations**:

```lean
def Stack.push (s : Stack) (v : Word256) : Option Stack :=
  if s.items.length < 1024 then
    some ⟨v :: s.items⟩  -- prepend to list
  else
    none                   -- stack overflow

def Stack.pop (s : Stack) : Option (Word256 × Stack) :=
  match s.items with
  | [] => none
  | x :: xs => some (x, ⟨xs⟩)  -- Lean 4 pattern matching
```

**Why `Option` (not exceptions)?**
- ✅ Forces caller to handle errors explicitly
- ✅ No hidden control flow
- ✅ Composable with `do` notation:

```lean
do
  let (a, s') ← stack.pop       -- if pop fails, whole do block fails
  let (b, s'') ← s'.pop
  let result ← s''.push (a + b)  -- if push fails, stop
  pure result
```

---

### Memory: Word-Addressed Storage

```lean
structure Memory where
  cells : List Word256

def Memory.read (m : Memory) (addr : Word256) : Word256 :=
  if addr < m.cells.length then
    m.cells.get! addr
  else
    0  -- uninitialized memory returns 0

def Memory.write (m : Memory) (addr : Word256) (v : Word256) : Memory :=
  if addr < m.cells.length then
    ⟨m.cells.set addr v⟩
  else
    let zeros := List.replicate (addr - m.cells.length) 0
    ⟨m.cells ++ zeros ++ [v]⟩
```

**Design choices**:
- **Word-addressed** (not byte): Simplifies implementation while preserving EVM semantics
- **Automatic expansion**: Writes beyond current size expand the list
- **Zero initialization**: Unwritten cells implicitly contain 0
- **Immutable updates**: Creates new list on write (functional semantics)

---

### Storage: Persistent Key-Value Map

```lean
structure Storage where
  slots : List (Word256 × Word256)

def Storage.write (st : Storage) (key : Word256) (v : Word256) : Storage :=
  let slots := st.slots.filter (fun (k, _) => k ≠ key)  -- remove old value
  if v = 0 then
    ⟨slots⟩  -- don't store zeros (gas optimization)
  else
    ⟨slots ++ [(key, v)]⟩  -- append new key-value pair
```

**Design rationale**:
- **List of pairs** (not a map): Minimal dependencies, educational clarity
- **Filter + append**: Implements set semantics (update or insert)
- **Zero omission**: Reflects EVM behavior (zero is default state)
- **O(n) operations**: For a model this is acceptable; real implementations use proper maps

---

## 2. Instructions as an Inductive Type

```lean
inductive Instruction : Type where
  | stop : Instruction
  | add : Instruction
  | mul : Instruction
  | push (v : Word256) : Instruction
  | dup (n : Nat) : Instruction
  | jumpi : Instruction
  deriving Repr, BEq
```

**Why `inductive` (Lean 4 style)?**

❌ **Lean 3 way** (outdated):
```lean
inductive instruction
| stop
| add
| mul
```

✅ **Lean 4 way** (explicit):
```lean
inductive Instruction : Type where
  | stop : Instruction
  | add : Instruction
  | mul : Instruction
```

**Advantages of Lean 4 style**:
1. **Explicit constructor signatures**: Type-safe, no ambiguity
2. **Parametric constructors**: `push (v : Word256)` enforces value is present
3. **Derives**: `deriving Repr, BEq` automatically generates useful instances
4. **No implicit universe levels**: Everything explicit

**Pattern matching**:

```lean
def opcode_name : Instruction → String := fun
  | Instruction.stop => "STOP"
  | Instruction.add => "ADD"
  | Instruction.push v => s!"PUSH {v}"
  | _ => "UNKNOWN"
```

---

## 3. The Execution Engine with `match` Statements

### Core Principle: Pure Functional Execution

```lean
def executeInstruction (instr : Instruction) (state : ExecutionState) :
    Option (ExecutionResult × ExecutionState) := do
  match instr with
  | Instruction.add => ...
  | Instruction.push v => ...
```

**Why `match` (not if-else or recursion)?**
- ✅ Pattern matching ensures all cases covered
- ✅ Exhaustiveness checking (compiler warns if you miss a case)
- ✅ Clear, readable code structure
- ✅ Natural for inductive types

### Example: ADD instruction

```lean
| Instruction.add =>
    -- Pop b (top of stack)
    let s ← state.stack.pop
    
    -- Destructure result: (value, new_stack)
    let (b, s') ← Stack.pop s.2
    
    -- Pop a (second from top)
    let (a, s'') ← Stack.pop s'.2
    
    -- Compute sum with wrapping
    let sum := toWord256 (a + b)
    
    -- Push result
    let s''' ← s''.push sum
    
    -- Return (success status, updated state)
    pure (ExecutionResult.ok, { state with stack := s''' })
```

**Step by step**:

1. `state.stack.pop` returns `Option (Word256 × Stack)`
2. `let s ← ...` unwraps the `Option`; if `None`, entire function returns `None`
3. Pattern match with `let (b, s') ← Stack.pop s.2` extracts both values
4. `{ state with stack := s''' }` creates new state with updated stack (immutable)
5. `pure (...)` wraps result in `Option`

**Error handling**:
```lean
do
  let s ← state.stack.pop                    -- fails if stack empty
  let (b, s') ← Stack.pop s.2                -- fails if only 1 item
  let (a, s'') ← Stack.pop s'.2              -- fails if only 2 items
  ...
```

If **any** pop fails, entire operation returns `none` (execution stops).

---

### Example: Conditional Jump (JUMPI)

```lean
| Instruction.jumpi =>
    let s ← state.stack.pop                  -- pop condition
    let (cond, s') ← s.2
    let (target, s'') ← Stack.pop s'        -- pop target address
    let new_pc := if cond ≠ 0 then target else state.pc + 1
    pure (ExecutionResult.ok, { state with stack := s'', pc := new_pc })
```

**Control flow logic**:
- Condition ≠ 0 → jump to target
- Condition = 0 → continue to next instruction

---

## 4. The Main Execution Loop

```lean
def execute (bytecode : List Instruction) (gas : Gas) (fuel : Nat) :
    ExecutionResult × ExecutionState := do
  let initial := ExecutionState.init bytecode gas
  let rec loop (state : ExecutionState) (fuel : Nat) :
      ExecutionResult × ExecutionState :=
    match fuel with
    | 0 => (ExecutionResult.outOfGas, state)
    | fuel + 1 =>
        match ExecutionState.currentInstruction state with
        | none => (ExecutionResult.ok, state)
        | some instr =>
            match executeInstruction instr state with
            | none => (ExecutionResult.revert, state)
            | some (ExecutionResult.ok, state') =>
                loop (state'.nextPc) fuel  -- continue with next instruction
            | some (result, state') =>
                (result, state')  -- execution ended
  loop initial fuel
```

**Key components**:

1. **Fuel parameter**: Prevents infinite loops
   - Counts down with each instruction
   - Returns `outOfGas` when `fuel = 0`
   - Actual EVM uses real gas costs; we use `fuel` for simplicity

2. **Pattern matching on fuel**:
   - `fuel + 1` syntax: "fuel is successor of some value"
   - Destructures naturally in recursive calls

3. **Instruction fetching**:
   ```lean
   match ExecutionState.currentInstruction state with
   | none => (ExecutionResult.ok, state)      -- end of code
   | some instr => ...                         -- execute instruction
   ```

4. **Execution result handling**:
   ```lean
   match executeInstruction instr state with
   | none => (ExecutionResult.revert, state)               -- error
   | some (ExecutionResult.ok, state') =>
       loop (state'.nextPc) fuel                           -- continue
   | some (result, state') => (result, state')             -- stop
   ```

---

## 5. State Management (Immutable Updates)

### Lean 4 Struct Update Syntax

```lean
structure ExecutionState where
  stack : Stack
  memory : Memory
  pc : Nat

-- Normal way (verbose)
let state' := {
  stack := new_stack
  memory := state.memory
  pc := state.pc + 1
}

-- Lean 4 way (concise) - update only changed fields
let state' := { state with stack := new_stack, pc := state.pc + 1 }
```

**Why immutability matters**:
- ✅ No side effects: function behavior is deterministic
- ✅ Easy to reason about: "what state do I have at each step?"
- ✅ Thread-safe by design (not relevant for sequential code, but good practice)
- ✅ Easier to prove properties

---

## 6. Error Handling with `Option`

### The `do` Notation Monad

```lean
def executeInstruction (instr : Instruction) (state : ExecutionState) :
    Option (ExecutionResult × ExecutionState) := do
  match instr with
  | Instruction.add =>
      let s ← state.stack.pop           -- unwraps Option
      let (b, s') ← Stack.pop s.2       -- if any operation returns None,
      let (a, s'') ← Stack.pop s'.2     -- the whole do block fails
      let sum := toWord256 (a + b)
      let s''' ← s''.push sum
      pure (ExecutionResult.ok, { state with stack := s''' })
```

**How `do` notation works**:
```lean
do
  x ← computation_that_returns_Option
  -- if computation returns None, entire do block returns None
  -- if computation returns Some value, x gets that value
```

**Equivalent to**:
```lean
match state.stack.pop with
| none => none
| some s =>
    match Stack.pop s.2 with
    | none => none
    | some (b, s') =>
        -- ... continue
```

The `do` version is much cleaner!

---

## 7. Pure Functional Semantics

### Why No Mutable State?

```lean
-- ❌ NOT in our model: mutable references
-- state.stack.push(5)  -- would modify state in place

-- ✅ Our model: immutable updates
let state' := { state with stack := state.stack.push 5 }
```

**Benefits for EVM**:
1. **Determinism**: Same bytecode + state always gives same result
2. **Reversibility**: Can trace execution backwards
3. **Provability**: Can prove properties using induction
4. **Debuggability**: Each step creates a new state snapshot

---

## 8. Example: Building a Program Step-by-Step

```lean
-- Program: push 5, push 3, add
def program : List Instruction :=
  [Instruction.push 5, Instruction.push 3, Instruction.add, Instruction.stop]

-- Execute
#eval execute program 10000 1000

-- Trace manually:
-- Initial: stack = [], pc = 0
-- After push 5: stack = [5], pc = 1
-- After push 3: stack = [3, 5], pc = 2
-- After add: stack = [8], pc = 3
-- After stop: stack = [8], pc = 3, status = ok
```

**In Lean 4**:
- Each `push` creates a new stack list
- Operations are deterministic (always same result for same input)
- Can inspect final state, stack contents, memory, storage

---

## Key Lean 4 Syntax Summary

| Feature | Syntax | Purpose |
|---------|--------|---------|
| Inductive | `inductive T : Type where \| C : T` | Define instruction types |
| Pattern match | `match x with \| p1 => e1 \| p2 => e2` | Dispatch instructions |
| Option monad | `do let x ← opt_val; ...` | Handle errors cleanly |
| Struct update | `{ s with field := value }` | Immutable state updates |
| Lambda | `fun x => expr` | Anonymous functions |
| Destructuring | `let (a, b) := pair` | Unpack tuples |
| Namespace | `namespace EVM ... end EVM` | Module organization |

---

## Testing & Verification Opportunities

### Example Test Properties

```lean
-- Property: ADD preserves stack length - 1
example : ∀ (a b : Word256) (s : Stack),
  match s.push a with
  | some s' =>
      match s'.push b with
      | some s'' =>
          match executeInstruction Instruction.add {stack := s'' with ...} with
          | some (_, s''') => s'''.stack.depth = s.depth + 1
```

### Future Proofs

- Stack depth invariants
- Memory safety properties
- Gas accounting correctness
- Bytecode halting properties

---

## Next Steps for Extension

1. **Add more instructions**: `dup`, `swap`, signed arithmetic
2. **Implement gas metering**: Track actual costs per instruction
3. **Add calldata**: Support function calls with arguments
4. **Prove properties**: Use Lean's tactic proof system
5. **Optimize**: Replace `List` with `Array` for performance

---

**Remember**: This model prioritizes **clarity and correctness** over performance. Every design decision is intentional and can be explained step-by-step.
