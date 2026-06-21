# The Comprehensive Mathematical Specification of the Ethereum Yellow Paper

This document provides a rigorous, exhaustive deconstruction of the mathematical formulas, notations, and spaces defined in the Ethereum Yellow Paper (originally authored by Dr. Gavin Wood). It serves as a complete reference for understanding the state transition mechanics, cryptography, and execution loop of the Ethereum Virtual Machine (EVM).

---

## 1. Foundational Mathematical Spaces & Notations

The Yellow Paper uses formal set theory and sequence notation to define boundaries, data lengths, and value fields across the network architecture.

### 1.1 The Byte and Scalar Spaces
* $\mathbb{B}$: The set of all sequences of bytes of any arbitrary length.
* $\mathbb{B}_n$: The set of all byte sequences of a specific length $n$. 
  * An Ethereum address belongs to the space $\mathbb{B}_{20}$ (160 bits).
  * A cryptographic hash or storage key belongs to the space $\mathbb{B}_{32}$ (256 bits).
* $\mathbb{N}$: The set of natural numbers (positive integers).
* $\mathbb{N}_0$: The set of non-negative integers (including zero).
* $\mathbb{P}$: The set of scalars representable as 256-bit unsigned integers ($0 \le x < 2^{256}$).

### 1.2 Sequence Operations
For indexing byte sequences, arrays, or transaction data payloads, the following mathematical definitions apply:
* $x[i]$: The structural element at index $i$ of a sequence $x$ (0-indexed).
* $x[i .. j]$: A contiguous subsequence of $x$ starting from index $i$ inclusive up to index $j$ exclusive.
* $|x|$: The exact cardinality or length of the sequence $x$.

---

## 2. The Formal Anatomy of the World State ($\sigma$)

Ethereum is characterized as a transaction-based state machine. The global ledger state is denoted by the lowercase Greek letter sigma ($\sigma$).

### 2.1 The World State Function Mapping
The world state $\sigma$ is a mapping (a function) that takes an address $a \in \mathbb{B}_{20}$ and evaluates to a 4-tuple account structure $S$:

$$\sigma: A \to S$$
$$\sigma(a) \equiv (n, b, s, c)$$

Where individual attributes within an account are formally retrieved using bold subscript indicators:
1. **Account Nonce ($\,\sigma(a)_{\mathbf{n}} \in \mathbb{N}_0\,$):** A scalar value equal to the number of transactions sent from this account (or the number of contracts created by it).
2. **Account Balance ($\,\sigma(a)_{\mathbf{b}} \in \mathbb{N}_0\,$):** A scalar value equal to the exact number of Wei owned by this address.
3. **Storage Root ($\,\sigma(a)_{\mathbf{s}} \in \mathbb{B}_{32}\,$):** A 256-bit hash of the root node of an independent Keccak-256 Merkle Patricia Trie that encodes the key-value storage slots belonging to this specific account ($\mathbb{P} \to \mathbb{P}$).
4. **Code Hash ($\,\sigma(a)_{\mathbf{c}} \in \mathbb{B}_{32}\,$):** The Keccak-256 hash of the EVM bytecode associated with this account. Formally stated as:
   $$\sigma(a)_{\mathbf{c}} = \mathtt{KEC}(\mathtt{b}) \quad \text{where } \mathtt{b} \in \mathbb{B} \text{ is the raw EVM code sequence.}$$

### 2.2 The Empty Account Condition
An account is mathematically defined as empty if its balance is zero, its nonce is zero, and its code hash resolves to the hash of an empty string:

$$\mathtt{EMPTY}(\sigma, a) \equiv \sigma(a)_{\mathbf{n}} = 0 \wedge \sigma(a)_{\mathbf{b}} = 0 \wedge \sigma(a)_{\mathbf{c}} = \mathtt{KEC}(())$$

---

## 3. The Complete Transaction Tuple ($T$)

A transaction $T$ is an structured element that represents an instruction to mutate the state. It is represented as an $n$-tuple containing the following precise indices:

$$T \equiv (R_{\mathbf{x}}, T_{\mathbf{n}}, T_{\mathbf{p}}, T_{\mathbf{g}}, T_{\mathbf{t}}, T_{\mathbf{v}}, T_{\mathbf{i}}, T_{\mathbf{w}}, T_{\mathbf{r}}, T_{\mathbf{s}})$$

Where:
* $R_{\mathbf{x}}$: The transaction chain identifier.
* $T_{\mathbf{n}}$: The nonce of the transaction sender ($\mathbb{N}_0$).
* $T_{\mathbf{p}}$: The gas price (or maximum fee rate) offered by the sender ($\mathbb{N}_0$).
* $T_{\mathbf{g}}$: The gas limit, representing the absolute maximum units of gas allocated for execution ($\mathbb{N}_0$).
* $T_{\mathbf{t}}$: The destination address ($T_{\mathbf{t}} \in \mathbb{B}_{20} \cup \{()\}$). If $T_{\mathbf{t}} = ()$ (the empty set), it signifies a **Contract Creation** transaction.
* $T_{\mathbf{v}}$: The value in Wei to be transferred to the recipient ($\mathbb{N}_0$).
* $T_{\mathbf{i}}$: The initialization bytecode payload ($\mathbb{B}$), evaluated *only* if $T_{\mathbf{t}} = ()$.
* $T_{\mathbf{d}}$: The data payload sequence ($\mathbb{B}$), evaluated *only* if $T_{\mathbf{t}} \neq ()$.
* $T_{\mathbf{w}}, T_{\mathbf{r}}, T_{\mathbf{s}}$: The cryptographic structural components of the ECDSA signature.

---

## 4. Comprehensive State Transition Mechanics ($\Upsilon$)

A block $B$ updates the current state $\sigma_t$ to a subsequent state $\sigma_{t+1}$ using a global transition function $\Upsilon$.

$$\sigma_{t+1} = \Upsilon(\sigma_t, B)$$

This execution cycles sequentially through all transactions in the block:

$$\sigma_0 = \sigma_{t}$$
$$\sigma_{i+1} = \Psi(\sigma_i, B_{\mathbf{T}}[i]) \quad \text{for } i = 0, 1, \dots, |B_{\mathbf{T}}| - 1$$

Where $\Psi$ represents the single transaction execution function.

### 4.1 Upfront Cost Validation
Before code can execute, the sender's account balance ($\,\sigma[T_{\mathbf{f}}]_{\mathbf{b}}\,$, where $T_{\mathbf{f}}$ is the derived sender address) must satisfy the following inequality constraint:

$$\sigma[T_{\mathbf{f}}]_{\mathbf{b}} \ge T_{\mathbf{g}} \cdot T_{\mathbf{p}} + T_{\mathbf{v}}$$

If true, the upfront gas fees are deducted immediately prior to execution:

$$\sigma_0 \equiv \sigma \quad \text{except } \sigma_0[T_{\mathbf{f}}]_{\mathbf{b}} \equiv \sigma[T_{\mathbf{f}}]_{\mathbf{b}} - T_{\mathbf{g}} T_{\mathbf{p}}$$

### 4.2 Complete Intrinsic Gas Formulation ($g_0$)
The mandatory baseline gas required for data processing and inclusion before execution begins is formalized as:

$$g_0 \equiv \sum_{i=0}^{|T_{\mathbf{d}}|-1} \tau(T_{\mathbf{d}}[i]) + \begin{cases} G_{\text{txcreate}} & \text{if } T_{\mathbf{t}} = () \\ 0 & \text{otherwise} \end{cases} + G_{\text{transaction}}$$

Where the per-byte data evaluation function $\tau(x)$ behaves as follows:

\tau(x) \equiv \begin{cases} G_{\text{txdatazero}} & \text{if } x = 0 \\ G_{\text{txdatanonzero}} & \text{if } x \neq 0 \end{cases}

### 4.3 Execution Substate ($A$) and Gas Refunds
Gas refunds obtained from clearing memory arrays or storage locations are captured inside an execution substate $A$:

$$A \equiv (A_{\mathbf{s}}, A_{\mathbf{l}}, A_{\mathbf{m}}, A_{\mathbf{r}})$$

Where:
* $A_{\mathbf{s}}$: The set of addresses scheduled for deletion via `SELFDESTRUCT`.
* $A_{\mathbf{l}}$: The cumulative log series (events emitted).
* $A_{\mathbf{m}}$: The set of touched accounts.
* $A_{\mathbf{r}}$: The internal accumulated gas refund counter ($\mathbb{N}_0$).

#### Final Gas Accounting
Upon termination, the net gas consumption ($g_{\text{consumed}}$) is adjusted via the refund mechanism up to a structural cap:

$$g_{\text{refund}} = \min\left(\lfloor \frac{g_{\text{consumed}}}{2} \rfloor, A_{\mathbf{r}}\right)$$
$$g' = T_{\mathbf{g}} - g_{\text{consumed}} + g_{\text{refund}}$$

The sender's final balance calculation yields:

$$\sigma_{\text{final}}[T_{\mathbf{f}}]_{\mathbf{b}} = \sigma_0[T_{\mathbf{f}}]_{\mathbf{b}} + g' \cdot T_{\mathbf{p}}$$

---

## 5. Rigorous Machine State and the EVM Loop ($O$)

The EVM behaves as an iterative state machine that mutates its internal state step-by-step through an operational transition function $O$.

### 5.1 Formal Machine State Architecture ($\mu$)
At any given execution step, the volatile machine state $\mu$ is modeled as a 5-tuple:

$$\mu \equiv (g, pc, m, i, s)$$

1. $g \in \mathbb{N}_0$: Available remaining gas.
2. $pc \in \mathbb{N}_0$: The program counter specifying the index of the next instruction byte.
3. $m \in \mathbb{H}$: Memory array ($\mathbb{H} \equiv \mathbb{B}_{\infty}$), an infinite, zero-filled byte sequence.
4. $i \in \mathbb{N}_0$: The maximum word index of memory touched so far.
5. $s \in \mathbb{L}$: The machine stack, structured as a bounded array of 256-bit scalar values where $|s| \le 1024$.

### 5.2 The Operational Step Function
The execution environment updates using structural parameters ($I$) and state fields:

$$(\sigma', A', g', pc', m', i', s') = O(\sigma, A, I, \mu)$$

Where the immutable execution environment context $I$ contains:
$$I \equiv (I_{\mathbf{a}}, I_{\mathbf{o}}, I_{\mathbf{p}}, I_{\mathbf{d}}, I_{\mathbf{s}}, I_{\mathbf{e}}, I_{\mathbf{b}}, I_{\mathbf{H}}, I_{\mathbf{v}}, I_{\mathbf{x}})$$
* $I_{\mathbf{a}}$: The current account address owning the executing code.
* $I_{\mathbf{o}}$: The original transaction initiator.
* $I_{\mathbf{p}}$: The transaction gas price.
* $I_{\mathbf{d}}$: The byte array representing incoming data.
* $I_{\mathbf{s}}$: The immediate caller address.
* $I_{\mathbf{e}}$: The present call stack depth.
* $I_{\mathbf{b}}$: The raw byte sequence of the active execution code.

---

## 6. Mathematical Model of Core EVM Opcodes

All stack and memory mutations within the EVM loop occur over a finite field bounded by modulo $2^{256}$.

### 6.1 Arithmetic Operations Under $\pmod{2^{256}}$
* **Addition (`ADD`):**
  $$\mu'_s[0] = (\mu_s[0] + \mu_s[1]) \pmod{2^{256}}$$
* **Multiplication (`MUL`):**
  $$\mu'_s[0] = (\mu_s[0] \cdot \mu_s[1]) \pmod{2^{256}}$$
* **Division (`DIV`):**
  $$\mu'_s[0] = \begin{cases} 0 & \text{if } \mu_s[1] = 0 \\ \lfloor \mu_s[0] / \mu_s[1] \rfloor & \text{if } \mu_s[1] \neq 0 \end{cases}$$

### 6.2 Storage Read/Write Operations (`SLOAD` / `SSTORE`)
* **`SLOAD`:** Retrieves the 32-byte value located at the popped key parameter from the account's internal trie state:
  $$\mu'_s[0] = \sigma(I_{\mathbf{a}})_{\mathbf{s}}[\mu_s[0]]$$
* **`SSTORE`:** Binds a key and value sequence directly into the account's localized trie storage domain:
  $$\sigma'(I_{\mathbf{a}})_{\mathbf{s}}[\mu_s[0]] = \mu_s[1]$$

#### Gas Function for Storage Mutations
The piecewise cost function $C_{\text{SSTORE}}$ evaluates gas dynamically depending on state-clearing transitions:

$$C_{\text{SSTORE}} = \begin{cases} 
G_{\text{sset}} & \text{if } \sigma(I_{\mathbf{a}})_{\mathbf{s}}[\mu_s[0]] = 0 \wedge \mu_s[1] \neq 0 \\ 
G_{\text{sreset}} & \text{if } \sigma(I_{\mathbf{a}})_{\mathbf{s}}[\mu_s[0]] \neq 0 \wedge \mu_s[1] = 0 \\
G_{\text{sreset}} & \text{if } \sigma(I_{\mathbf{a}})_{\mathbf{s}}[\mu_s[0]] \neq 0 \wedge \mu_s[1] \neq 0 
\end{cases}$$

If a non-zero storage slot is zeroed out, a refund is injected into the execution substate:
$$A'_{\mathbf{r}} = A_{\mathbf{r}} + R_{\text{sclear}}$$

### 6.3 Memory Expansion Cost Function
Memory expansion costs scales quadratically. The word calculation function $M$ for an instruction reading/writing $s$ bytes at starting offset $f$ is:

$$M(m, f, s) \equiv \max(m, \lceil (f + s) / 32 \rceil)$$

The total gas pricing function for an allocated memory volume of $a$ words is:

$$C_{\text{mem}}(a) \equiv G_{\text{memory}} \cdot a + \lfloor \frac{a^2}{512} \rfloor$$

The net memory gas deducted across the execution transition is:

$$\Delta g = C_{\text{mem}}(b) - C_{\text{mem}}(a)$$

---

## 7. The Cryptographic Merkle Patricia Trie Math

Ethereum utilizes a Hexary Merkle Patricia Trie structure to compute deterministic roots for states, transactions, and receipts. Let $Y$ represent a set of key-value associations. The root hash generation is defined as:

$$\mathtt{TRIE}(Y) \equiv \mathtt{KEC}(\mathtt{RLP}(c(Y, \emptyset)))$$

Where $c(Y, \hat{k})$ is the multi-path structural composition function acting over shared nibble paths $\hat{k}$.

### 7.1 Structural Node Composition Equations

1. **Leaf Node:** Evaluates when keys share a path terminating entirely at a value:
   $$c(Y, \hat{k}) \equiv \left( \mathtt{HP}(p, \text{true}), v \right)$$
   Where $p$ indicates the residual nibble path sequence and $\mathtt{HP}$ represents Hex-Prefix encoding.

2. **Extension Node:** Evaluates when keys share a prefix but branch further down the trie structure:
   $$c(Y, \hat{k}) \equiv \left( \mathtt{HP}(p, \text{false}), \mathtt{KEC}(\mathtt{RLP}(c(Y', \hat{k} \cdot p))) \right)$$

3. **Branch Node:** Evaluates when elements diverge directly at the current hex digit (nibble), generating a 17-item index sequence:
   $$c(Y, \hat{k}) \equiv (n_0, n_1, \dots, n_{15}, v)$$
   Where each index slot $n_i$ computes sub-trie components iteratively:
   $$n_i = c(\{ (k, v) \mid (k, v) \in Y \wedge k[0] = i \}, \hat{k} \cdot i)$$
