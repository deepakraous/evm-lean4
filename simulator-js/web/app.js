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
  }

  pop() {
    return this.stack.length ? this.stack.pop() : null;
  }

  add() { return this.binaryOp((a, b) => (a + b) & ((1n << 256n) - 1n)); }
  sub() { return this.binaryOp((a, b) => (a - b) & ((1n << 256n) - 1n)); }
  mul() { return this.binaryOp((a, b) => (a * b) & ((1n << 256n) - 1n)); }
  div() {
    return this.binaryOp((a, b) => b === 0n ? 0n : a / b);
  }

  binaryOp(fn) {
    const b = this.pop();
    const a = this.pop();
    if (a === null || b === null) return 'stack underflow';
    this.push(fn(a, b));
    return 'ok';
  }

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
      memory: Object.fromEntries(Object.entries(this.memory).map(([k, v]) => [k, v.toString()])),
      storage: Object.fromEntries(Object.entries(this.storage).map(([k, v]) => [k, v.toString()]))
    };
  }
}

const vm = new VM();
const commandInput = document.getElementById('command-input');
const outputBox = document.getElementById('output');
const stateBox = document.getElementById('state');
const runBtn = document.getElementById('run-btn');
const dumpBtn = document.getElementById('dump-btn');
const resetBtn = document.getElementById('reset-btn');

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
  outputBox.textContent += `${text}\n`;
  outputBox.scrollTop = outputBox.scrollHeight;
};

const refreshState = () => {
  stateBox.textContent = JSON.stringify(vm.dump(), null, 2);
};

const executeCommand = (commandText) => {
  const tokens = commandText.trim().split(/\s+/);
  if (!tokens[0]) return;
  const cmd = tokens[0].toLowerCase();
  const arg = tokens[1];
  if (!commands[cmd]) {
    appendOutput(`Unknown command: ${cmd}`);
    return;
  }

  if (cmd === 'push') {
    if (!arg) {
      appendOutput('push requires a numeric argument');
      return;
    }
    const result = commands.push(arg);
    appendOutput(result || 'ok');
  } else {
    const result = commands[cmd]();
    appendOutput(result || 'ok');
  }
  refreshState();
};

runBtn.addEventListener('click', () => {
  executeCommand(commandInput.value);
  commandInput.value = '';
});

dumpBtn.addEventListener('click', () => {
  appendOutput('State dump:\n' + JSON.stringify(vm.dump(), null, 2));
});

resetBtn.addEventListener('click', () => {
  vm.reset();
  outputBox.textContent = '';
  refreshState();
});

document.addEventListener('DOMContentLoaded', () => {
  refreshState();
});
