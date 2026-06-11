# EVM Simulator (JavaScript)

This is a tiny interactive EVM-like simulator for educational purposes.

Quick start:

```bash
cd simulator-js
node index.js
```

Commands:
- `push <n>`: push a number onto the stack
- `add`, `sub`, `mul`, `div`: arithmetic ops
- `mstore`, `mload`: memory ops (use stack for addr/value)
- `sstore`, `sload`: storage ops (use stack for key/value)
- `msize`: push current memory size
- `run <instr...>`: execute a sequence of instructions, e.g. `run push 5 push 7 add`
- `dump`: show VM state
- `stop` / `exit`: exit

Note: This simulator is minimal and for learning only. It uses 256-bit word wrapping.
