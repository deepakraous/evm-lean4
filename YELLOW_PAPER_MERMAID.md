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

## 2. State transition function

```mermaid
flowchart LR
  SigmaT[[σ_t\nWorld state]] -->|Transaction T| Upsilon["Υ(σ_t, T)\nState transition"] --> SigmaT1[[σ_t+1\nWorld state]]
```

## 3. Machine state μ components

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

## 4. Transaction type classification

```mermaid
flowchart LR
  Transaction["Transaction T"] -->|Message call| Call["Message Call"]
  Transaction -->|Contract creation| Create["Contract Creation"]
  Call --> Execute["EVM execution"]
  Create --> Deploy["Contract code deployment"]
```

## 5. EVM execution lifecycle

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
