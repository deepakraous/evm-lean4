-- EVM State Transition (Υ)
-- Minimal application of a transaction to a world state

import EVM.World
import EVM.Transactions
import EVM.Execution

open EVM.Transactions
open EVM.Execution

namespace EVM

structure Receipt where
  postStateRoot : Nat -- placeholder for trie root
  cumulativeGasUsed : Nat
  logsBloom : Nat -- placeholder
  logs : List String
  status : ExecutionResult
  deriving Repr

/-- Execute a transaction against a world state using a simple model.
    This is a minimal, educational implementation — not production-grade. -/
def Υ (σ : WorldState) (T : Transaction) (fuel : Nat) : Option (WorldState × Receipt) := do
  -- Basic balance check: require sender can pay upfront (value + gasLimit*gasPrice)
  let upfront := T.value + T.gasLimit * T.gasPrice
  let senderAcc ← σ.findAccount T.sender
  if senderAcc.balance < upfront then
    none
  else
    -- Debit the upfront from sender (we will refund unused gas later)
    let σ1 ← σ.debit T.sender upfront
    let σ1 := σ1.incrementNonce T.sender
    -- Determine recipient account (create if missing)
    let recipient := match T.to with | some a => a | none => "" -- for creation, use empty address placeholder
    let recipientAcc := σ1.findAccount recipient |> Option.getD { nonce := 0, balance := 0, storage := Storage.empty, code := [] }
    -- If recipient has code, execute it; otherwise, plain value transfer
    if recipientAcc.code = [] then
      -- simple transfer, credit recipient and refund all unused gas
      let σ2 := σ1.credit recipient T.value
      let σ3 := σ2.credit T.sender (T.gasLimit * T.gasPrice)
      let receipt : Receipt := { postStateRoot := 0, cumulativeGasUsed := 0, logsBloom := 0, logs := [], status := ExecutionResult.ok }
      some (σ3, receipt)
    else
      -- execute recipient code with provided gasLimit
      let (res, execState) := execute recipientAcc.code T.gasLimit fuel
      let gasUsed := T.gasLimit - execState.gas
      let refund := execState.gas * T.gasPrice
      let σ2 := σ1.credit T.sender refund
      let σ3 := if res = ExecutionResult.ok then σ2.credit recipient T.value else σ2
      let receipt : Receipt := { postStateRoot := 0, cumulativeGasUsed := gasUsed, logsBloom := 0, logs := execState.logs, status := res }
      some (σ3, receipt)

end EVM
