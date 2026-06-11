-- Example EVM Programs
-- Demonstrates the EVM model in action

import EVM.Core
import EVM.Instructions
import EVM.Execution

namespace EVM.Examples

-- **Example 1**: Simple arithmetic: push 5, push 3, add
-- Expected: stack has [8] at the end
def example_add : List Instruction :=
  [
    Instruction.push 5,
    Instruction.push 3,
    Instruction.add,
    Instruction.stop
  ]

-- **Example 2**: Store to memory and load back
-- Push 42, store at address 0, load from address 0
def example_memory : List Instruction :=
  [
    Instruction.push 42,
    Instruction.push 0,
    Instruction.mstore,
    Instruction.push 0,
    Instruction.mload,
    Instruction.stop
  ]

-- **Example 3**: Conditional jump (simplified)
-- If 1, jump to target instruction
def example_conditional : List Instruction :=
  [
    Instruction.push 5,           -- target address
    Instruction.push 1,           -- condition (true)
    Instruction.jumpi,            -- conditional jump
    Instruction.push 100,         -- skipped if jump taken
    Instruction.push 200,         -- target: jumped here
    Instruction.stop
  ]

-- **Run example and inspect stack**
#eval
  let (result, state) := execute example_add 10000 1000
  (result, state.stack)

#eval
  let (result, state) := execute example_memory 10000 1000
  (result, state.memory)

#eval
  let (result, state) := execute example_conditional 10000 1000
  (result, state.stack)

-- **Example 4**: Simple transaction application
open EVM

def example_world : WorldState :=
  let sender : Address := "alice"
  let recipient : Address := "bob"
  let senderAcc := { nonce := 0, balance := 100000, storage := Storage.empty, code := [] }
  let recipientAcc := { nonce := 0, balance := 0, storage := Storage.empty, code := example_add }
  { accounts := [(sender, senderAcc), (recipient, recipientAcc)] }

def example_tx : Transaction :=
  { from := "alice", nonce := 0, gasPrice := 1, gasLimit := 1000, to := some "bob", value := 10, data := [] }

#eval
  match Υ example_world example_tx 1000 with
  | none => ("tx failed", 0)
  | some (σ', r) => ("tx ok", r.cumulativeGasUsed)

-- **Example 5**: Contract execution with storage logs
-- A contract account stores value 42 at key 0 and then reads it back.
def example_storage_contract : List Instruction :=
  [ Instruction.push 0,
    Instruction.push 42,
    Instruction.sstore,
    Instruction.push 0,
    Instruction.sload,
    Instruction.stop ]

def example_contract_world : WorldState :=
  let sender : Address := "alice"
  let contract : Address := "contract"
  let senderAcc := { nonce := 0, balance := 100000, storage := Storage.empty, code := [] }
  let contractAcc := { nonce := 0, balance := 0, storage := Storage.empty, code := example_storage_contract }
  { accounts := [(sender, senderAcc), (contract, contractAcc)] }

def example_contract_tx : Transaction :=
  { from := "alice", nonce := 0, gasPrice := 1, gasLimit := 1000, to := some "contract", value := 0, data := [] }

#eval
  match Υ example_contract_world example_contract_tx 1000 with
  | none => ("contract tx failed", 0)
  | some (σ', r) => ("contract tx ok", r.cumulativeGasUsed, r.logs)

end EVM.Examples
