-- EVM World State
-- Minimal world state mapping addresses to accounts

import EVM.Core
import EVM.Storage

namespace EVM

structure Account where
  nonce : Nat
  balance : Nat
  storage : Storage
  code : List Instruction
  deriving Repr

abbrev Address := String

structure WorldState where
  accounts : List (Address × Account)
  deriving Repr

def WorldState.empty : WorldState := { accounts := [] }

def WorldState.findAccount (w : WorldState) (addr : Address) : Option Account :=
  match w.accounts.find? (fun (a, _) => a = addr) with
  | some (_, acc) => some acc
  | none => none

def WorldState.updateAccount (w : WorldState) (addr : Address) (acc : Account) : WorldState :=
  let others := w.accounts.filter (fun (a, _) => a ≠ addr)
  { accounts := others ++ [(addr, acc)] }

def WorldState.credit (w : WorldState) (addr : Address) (amount : Nat) : WorldState :=
  match w.findAccount addr with
  | some acc => WorldState.updateAccount w addr { acc with balance := acc.balance + amount }
  | none => WorldState.updateAccount w addr { nonce := 0, balance := amount, storage := Storage.empty, code := [] }

def WorldState.incrementNonce (w : WorldState) (addr : Address) : WorldState :=
  match w.findAccount addr with
  | some acc => WorldState.updateAccount w addr { acc with nonce := acc.nonce + 1 }
  | none => WorldState.updateAccount w addr { nonce := 1, balance := 0, storage := Storage.empty, code := [] }

def WorldState.debit (w : WorldState) (addr : Address) (amount : Nat) : Option WorldState :=
  match w.findAccount addr with
  | some acc =>
    if acc.balance >= amount then
      some (WorldState.updateAccount w addr { acc with balance := acc.balance - amount })
    else
      none
  | none => none

end EVM
