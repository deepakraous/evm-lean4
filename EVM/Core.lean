-- Core EVM Types and Data Structures
-- This module defines the fundamental types used in the EVM model

namespace EVM

-- **Word256**: 256-bit values (core EVM word type)
-- We represent these as natural numbers, modulo 2^256
abbrev Word256 := Nat

-- Helper: maximum value for Word256
def MAX_WORD256 : Word256 := 2^256 - 1

-- Helper: safely wrap a Nat to Word256 range
def toWord256 (n : Nat) : Word256 := n % (2^256)

/- Basic Word256 arithmetic with wrapping -/
def Word256.add (a b : Word256) : Word256 :=
  toWord256 (a + b)

def Word256.sub (a b : Word256) : Word256 :=
  toWord256 (if a >= b then a - b else (2^256 + a) - b)

def Word256.mul (a b : Word256) : Word256 :=
  toWord256 (a * b)

def Word256.eq (a b : Word256) : Bool :=
  a == b

def Word256.lt (a b : Word256) : Bool :=
  a < b


-- **Gas**: Represents computational cost
abbrev Gas := Nat

-- **Stack**: LIFO data structure, max 1024 items, each 256 bits
structure Stack where
  items : List Word256
  deriving Repr

-- Create an empty stack
def Stack.empty : Stack := ⟨[]⟩

-- Push a value onto the stack
def Stack.push (s : Stack) (v : Word256) : Option Stack :=
  if s.items.length < 1024 then
    some ⟨v :: s.items⟩
  else
    none -- Stack overflow

-- Pop from stack
def Stack.pop (s : Stack) : Option (Word256 × Stack) :=
  match s.items with
  | [] => none
  | x :: xs => some (x, ⟨xs⟩)

-- Peek at top of stack without removing
def Stack.peek (s : Stack) : Option Word256 :=
  s.items.head?

-- Stack depth
def Stack.depth (s : Stack) : Nat := s.items.length

-- **Memory**: Byte-addressable storage (32-byte words)
-- We represent it as a mapping from word addresses to 256-bit values
structure Memory where
  cells : List Word256  -- cells[i] = value at address i*32 (in bytes)
  deriving Repr

def Memory.empty : Memory := ⟨[]⟩

-- Read a 256-bit word from memory at a given address (in 32-byte word units)
def Memory.read (m : Memory) (addr : Word256) : Word256 :=
  if addr < m.cells.length then
    m.cells.get! addr
  else
    0

-- Write a 256-bit word to memory
def Memory.write (m : Memory) (addr : Word256) (v : Word256) : Memory :=
  let addr_nat := addr
  if addr_nat < m.cells.length then
    ⟨m.cells.set addr_nat v⟩
  else
    -- Extend the list with zeros up to addr, then add v
    let zeros := List.replicate (addr_nat - m.cells.length) 0
    ⟨m.cells ++ zeros ++ [v]⟩

-- Memory size in 32-byte words
def Memory.size (m : Memory) : Nat := m.cells.length

-- **Storage**: Persistent key-value store (per smart contract)
-- Maps 256-bit keys to 256-bit values
structure Storage where
  slots : List (Word256 × Word256)
  deriving Repr

def Storage.empty : Storage := ⟨[]⟩

-- Read from storage
def Storage.read (st : Storage) (key : Word256) : Word256 :=
  match st.slots.find? (fun (k, _) => k == key) with
  | some (_, v) => v
  | none => 0

-- Write to storage
def Storage.write (st : Storage) (key : Word256) (v : Word256) : Storage :=
  let slots := st.slots.filter (fun (k, _) => k ≠ key)
  if v = 0 then
    ⟨slots⟩  -- Don't store zero values (gas optimization)
  else
    ⟨slots ++ [(key, v)]⟩

end EVM
