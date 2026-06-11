-- EVM/Storage.lean
-- Minimal storage map scaffold

namespace EVM.Storage

abbrev Slot := Nat
abbrev Value := Nat

structure Storage where
  map : List (Slot × Value)

def empty : Storage := { map := [] }

def get (s : Storage) (k : Slot) : Option Value :=
  match s.map.find? (fun (k', _) => k' = k) with
  | some (_, v) => some v
  | none => none

def set (s : Storage) (k : Slot) (v : Value) : Storage :=
  { s with map := (k, v) :: s.map }

end EVM.Storage
