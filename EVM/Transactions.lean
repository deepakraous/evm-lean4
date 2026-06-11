-- EVM/Transactions.lean
-- Minimal transaction representation for the EVM model

namespace EVM.Transactions

structure Transaction where
  sender : String
  nonce : Nat
  gasPrice : Nat
  gasLimit : Nat
  to : Option String
  value : Nat
  data : List UInt8
  deriving Repr

end EVM.Transactions
