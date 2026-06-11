# Ethereum Yellow Paper Mermaid Reference

This file maps the core Ethereum Yellow Paper structure and EVM models into GitHub Mermaid diagrams.
It is a visual reference, not a verbatim reproduction. For the full formal specification, see:
https://ethereum.github.io/yellowpaper/paper.pdf

## 1. Yellow Paper structure map

```mermaid
flowchart TB
  A[Introduction & Notation] --> B[Definitions & Symbols]
  B --> C[World State σ]
  C --> D[Machine State μ]
  D --> E[EVM Execution Model]
  E --> F[Transaction Processing]
  F --> G[Block Processing & Final State]
  G --> H[Gas, Fees, & Costs]
  H --> I[Appendices & Formal Notes]
```

## 2. Yellow Paper symbol reference table

| Symbol | Meaning | Formal context | Notes |
|---|---|---|---|
| `σ` | World state | Mapping from accounts to account state | Global state of the Ethereum network; updated by transactions |
| `σ[a]` | Account state for address `a` | `σ[a] = (nonce, balance, storageRoot, codeHash)` | Includes balance, contract storage root, contract code hash |
| `μ` | Machine state | `μ = (pc, gas, memory, stack, storage, code, address, origin, caller, value, input)` | Runtime environment inside the EVM |
| `Υ` | State transition function | `σ_{t+1} = Υ(σ_t, T)` | Applies transaction `T` to world state `σ_t` |
| `T` | Transaction | `T = (nonce, gasPrice, gasLimit, to, value, data, v, r, s)` | Either message call or contract creation |
| `I` | Execution environment | Contains `origin`, `caller`, `value`, `input`, `address`, `gasPrice`, `gasLimit`, `code` | External execution parameters for the current call |
| `H` | Block header | `H = (parentHash, ommersHash, beneficiary, stateRoot, transactionsRoot, receiptsRoot, logsBloom, difficulty, number, gasLimit, gasUsed, timestamp, extraData, mixHash, nonce)` | Block metadata used by Ethereum consensus and execution |
| `B` | Block | `B = (H, transactions, uncleHeaders)` | Full block with header plus body |
| `L` | Block gas limit | `L = H.gasLimit` | Maximum total gas available in block |
| `n` | Block number | `n = H.number` | Height of the block in the chain |
| `p` | Program counter | `p = μ.pc` | Current instruction index in bytecode |
| `g` | Gas remaining | `g = μ.gas` | Remaining gas during execution |
| `m` | Memory | `m = μ.memory` | Transient machine memory, zero-initialized, byte-addressed |
| `s` | Stack | `s = μ.stack` | Last-in first-out word stack, max depth 1024 |
| `S` | Storage | `S = μ.storage` | Persistent contract storage mapping key->value |
| `A` | Account | Addressable identity in `σ` | Externally owned or contract account |
| `c` | Code / bytecode | `c = μ.code` | Sequence of EVM instructions executed by the machine |
| `v` | Value | Transaction or call value in Wei | Ether amount transferred with the call |
| `ρ` | Receipt | Transaction execution result | Includes state root, gas used, logs, and status |
| `ω` | Block header values | Environment values taken from `H` | Used by EVM opcodes and gas rules |
| `Δ` | State diff | Difference between states | Used to represent changes from `σ_t` to `σ_{t+1}` |
| `z` | Zero value | Empty or uninitialized storage/memory word | Often represented by `0` |

## 3. Yellow Paper math and model explanation

The Yellow Paper defines Ethereum as a deterministic state machine. The main mathematical object is the state transition function:

```text
σ_{t+1} = Υ(σ_t, T)
```

- `σ_t` is the world state before the transaction.
- `T` is the transaction being processed.
- `Υ` computes the new world state after executing `T`.

The world state `σ` is a mapping from account addresses `a` to account state records:

```text
σ[a] = (nonce, balance, storageRoot, codeHash)
```

The machine state `μ` contains the EVM execution context:

```text
μ = (pc, gas, memory, stack, storage, code, address, origin, caller, value, input)
```

- `pc`: program counter within the code.
- `gas`: remaining gas for execution.
- `memory`: transient byte-addressable buffer.
- `stack`: last-in first-out stack used by opcodes.
- `storage`: contract storage visible to `SSTORE` / `SLOAD`.
- `code`: contract bytecode being executed.
- `address`: current executing account address.
- `origin`: original transaction sender.
- `caller`: immediate caller address.
- `value`: Wei sent with the call.
- `input`: calldata or init code for the current execution.

Gas accounting is expressed by subtracting instruction cost from remaining gas:

```text
g' = g - cost(opcode)
```

If the machine does not have enough gas, execution aborts with an out-of-gas condition.

The block header `H` contains fields used by state transition and gas calculations, for example:

```text
H = (parentHash, ommersHash, beneficiary, stateRoot, transactionsRoot, receiptsRoot,
     logsBloom, difficulty, number, gasLimit, gasUsed, timestamp, extraData, mixHash, nonce)
```

Transaction `T` fields include:

```text
T = (nonce, gasPrice, gasLimit, to, value, data, v, r, s)
```

The execution of `T` can be either a message call or contract creation. In both cases, the EVM uses `μ` and the environment `I` to step through opcodes and update `σ`.

## 4. State transition function

```mermaid
flowchart LR
  SigmaT[[σ_t\nWorld state]] -->|Transaction T| Upsilon["Υ(σ_t, T)\nState transition"] --> SigmaT1[[σ_t+1\nWorld state]]
```

## 5. Machine state μ components

```mermaid
flowchart TB
  MU["Machine state μ"] --> PC["Program counter (PC)"]
  MU --> Stack["Stack (LIFO)"]
  MU --> Memory["Memory (temporary)"]
  MU --> Storage["Storage (persistent)"]
  MU --> Gas["Gas remaining"]
  MU --> Code["Code / bytecode"]
  MU --> Addr["Active account / recipient"]
```

## 6. Transaction type classification

```mermaid
flowchart LR
  Transaction["Transaction T"] -->|Message call| Call["Message Call"]
  Transaction -->|Contract creation| Create["Contract Creation"]
  Call --> Execute["EVM execution"]
  Create --> Deploy["Contract code deployment"]
```

## 7. EVM execution lifecycle

```mermaid
flowchart LR
  Start["Begin transaction execution"] --> Fetch["Fetch opcode"]
  Fetch --> Decode["Decode instruction"]
  Decode --> Execute["Execute opcode"]
  Execute --> Update["Update μ and σ"]
  Update --> Next["Advance PC or halt"]
  Next --> End["Return / revert / stop"]
```

## 6. Account state model

```mermaid
flowchart LR
  Account["Account state"] --> Nonce["nonce"]
  Account --> Balance["balance"]
  Account --> StorageRoot["storage root"]
  Account --> CodeHash["code hash"]
```

## 7. Block processing overview

```mermaid
flowchart LR
  Parent["Parent block hash"] --> Block["Block header & body"]
  Block --> Transactions["Transactions list"]
  Transactions --> State["World state update σ_{t+1}"]
  Block --> Receipts["Receipts & logs"]
  State --> Root["New state root"]
```

## 8. Gas accounting summary

```mermaid
flowchart LR
  StartGas["Starting gas"] --> Instruction["Opcode cost"]
  Instruction --> GasUsed["Gas used"]
  GasUsed --> GasLeft["Remaining gas"]
  GasLeft --> Refund["Possible gas refund"]
  Refund --> EndGas["Final gas refund / burn"]
```

## 9. How to read this reference

- Use this file to map key Yellow Paper models into diagrams.
- Each Mermaid graph is a visual summary of core Yellow Paper concepts.
- For formal definitions, consult the official Yellow Paper directly.
