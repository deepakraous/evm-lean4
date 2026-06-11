import EVM.Examples

/-
  Simple smoke tests for EVM examples. These use `#eval` to print results
  when running `lake build` or evaluating in the editor.
-/

#eval
  let (result, state) := EVM.execute EVM.Examples.example_add 10000 1000
  (result, state.stack)

#eval
  let (result, state) := EVM.execute EVM.Examples.example_memory 10000 1000
  (result, state.memory)

#eval
  let (result, state) := EVM.execute EVM.Examples.example_conditional 10000 1000
  (result, state.stack)

#eval
  match EVM.Υ EVM.Examples.example_world EVM.Examples.example_tx 1000 with
  | none => ("tx failed", 0)
  | some (σ', r) => ("tx ok", r.cumulativeGasUsed)
