class VM {
  constructor() {
    this.reset();
  }

  reset() {
    this.stack = [];
    this.memory = {};
    this.storage = {};
  }

  push(v) {
    this.stack.push(BigInt(v));
    return 'ok';
  }

  pop() {
    return this.stack.length ? this.stack.pop() : null;
  }

  binaryOp(op) {
    const b = this.pop();
    const a = this.pop();
    if (a === null || b === null) return 'stack underflow';
    this.push(op(a, b));
    return 'ok';
  }

  add() { return this.binaryOp((a, b) => (a + b) & ((1n << 256n) - 1n)); }
  sub() { return this.binaryOp((a, b) => (a - b) & ((1n << 256n) - 1n)); }
  mul() { return this.binaryOp((a, b) => (a * b) & ((1n << 256n) - 1n)); }
  div() { return this.binaryOp((a, b) => b === 0n ? 0n : a / b); }
  mstore() {
    const value = this.pop();
    const addr = this.pop();
    if (value === null || addr === null) return 'stack underflow';
    this.memory[addr.toString()] = value;
    return 'ok';
  }
  mload() {
    const addr = this.pop();
    if (addr === null) return 'stack underflow';
    this.push(this.memory[addr.toString()] ?? 0n);
    return 'ok';
  }
  sstore() {
    const value = this.pop();
    const key = this.pop();
    if (value === null || key === null) return 'stack underflow';
    this.storage[key.toString()] = value;
    return 'ok';
  }
  sload() {
    const key = this.pop();
    if (key === null) return 'stack underflow';
    this.push(this.storage[key.toString()] ?? 0n);
    return 'ok';
  }
  msize() {
    this.push(BigInt(Object.keys(this.memory).length));
    return 'ok';
  }

  dump() {
    return {
      stack: this.stack.map(x => x.toString()),
      memory: Object.fromEntries(Object.entries(this.memory).map(([k,v]) => [k, v.toString()])),
      storage: Object.fromEntries(Object.entries(this.storage).map(([k,v]) => [k, v.toString()]))
    };
  }
}

const vm = new VM();
const commandInput = document.getElementById('command');
const output = document.getElementById('output');
const state = document.getElementById('state');
const runButton = document.getElementById('run');
const dumpButton = document.getElementById('dump');
const resetButton = document.getElementById('reset');

const commands = {
  push: arg => vm.push(arg),
  add: () => vm.add(),
  sub: () => vm.sub(),
  mul: () => vm.mul(),
  div: () => vm.div(),
  mstore: () => vm.mstore(),
  mload: () => vm.mload(),
  sstore: () => vm.sstore(),
  sload: () => vm.sload(),
  msize: () => vm.msize(),
};

const appendOutput = text => {
  output.textContent += `${text}\n`;
  output.scrollTop = output.scrollHeight;
};

const updateState = () => {
  state.textContent = JSON.stringify(vm.dump(), null, 2);
};

const execute = commandText => {
  const tokens = commandText.trim().split(/\s+/);
  const cmd = tokens[0]?.toLowerCase();
  if (!cmd) return;
  const handler = commands[cmd];
  if (!handler) {
    appendOutput(`Unknown command: ${cmd}`);
    return;
  }

  if (cmd === 'push') {
    if (tokens.length < 2) {
      appendOutput('push requires a numeric argument');
      return;
    }
    appendOutput(handler(tokens[1]));
  } else {
    appendOutput(handler());
  }
  updateState();
};

runButton.addEventListener('click', () => {
  execute(commandInput.value);
  commandInput.value = '';
});
dumpButton.addEventListener('click', () => {
  appendOutput('State: ' + JSON.stringify(vm.dump(), null, 2));
});
resetButton.addEventListener('click', () => {
  vm.reset();
  output.textContent = '';
  updateState();
});

document.addEventListener('DOMContentLoaded', () => {
  updateState();
});
