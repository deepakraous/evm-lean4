#!/usr/bin/env node
// Minimal interactive EVM-like simulator in JavaScript

const readline = require('readline');

class VM {
  constructor() {
    this.stack = [];
    this.memory = {};
    this.storage = {};
    this.pc = 0;
    this.running = true;
  }

  push(v) { this.stack.push(BigInt(v)); }
  pop() { return this.stack.length ? this.stack.pop() : null; }

  add() { let b=this.pop(); let a=this.pop(); if(a==null||b==null) return false; this.push((a+b)&((1n<<256n)-1n)); return true }
  sub() { let b=this.pop(); let a=this.pop(); if(a==null||b==null) return false; this.push((a-b)&((1n<<256n)-1n)); return true }
  mul() { let b=this.pop(); let a=this.pop(); if(a==null||b==null) return false; this.push((a*b)&((1n<<256n)-1n)); return true }
  div() { let b=this.pop(); let a=this.pop(); if(a==null||b==null) return false; this.push(b===0n?0n:(a/b)); return true }

  mstore(addr, v) { this.memory[addr] = v; }
  mload(addr) { return this.memory[addr] ?? 0n }
  sstore(k, v) { this.storage[k] = v }
  sload(k) { return this.storage[k] ?? 0n }

  runInstr(instr, args) {
    switch(instr) {
      case 'push': this.push(args[0]); break;
      case 'add': if(!this.add()) return 'stack underflow'; break;
      case 'sub': if(!this.sub()) return 'stack underflow'; break;
      case 'mul': if(!this.mul()) return 'stack underflow'; break;
      case 'div': if(!this.div()) return 'stack underflow'; break;
      case 'pop': if(!this.pop()) return 'stack underflow'; break;
      case 'mstore': { let v=this.pop(); let a=this.pop(); if(v==null||a==null) return 'stack underflow'; this.mstore(a.toString(), v); } break;
      case 'mload': { let a=this.pop(); if(a==null) return 'stack underflow'; this.push(this.mload(a.toString())); } break;
      case 'sstore': { let v=this.pop(); let k=this.pop(); if(v==null||k==null) return 'stack underflow'; this.sstore(k.toString(), v); } break;
      case 'sload': { let k=this.pop(); if(k==null) return 'stack underflow'; this.push(this.sload(k.toString())); } break;
      case 'stop': this.running=false; break;
      default: return 'unknown instruction: '+instr;
    }
    return 'ok';
  }

  dump() {
    return {
      stack: this.stack.map(x=>x.toString()),
      memory: this.memory,
      storage: this.storage
    }
  }
}

const vm = new VM();

const rl = readline.createInterface({ input: process.stdin, output: process.stdout, prompt: 'evm> ' });

const parseInstruction = (token, args) => {
  if (token === 'push') {
    if (args.length < 1) return { error: 'push requires a value' }
    return { instr: 'push', args: [BigInt(args[0])] }
  }
  if (['add','sub','mul','div','pop','mstore','mload','sstore','sload','msize','stop','dump','exit','help'].includes(token)) {
    return { instr: token, args };
  }
  return { error: `unknown instruction: ${token}` };
};

console.log('Interactive EVM simulator. Commands: push <n>, add, sub, mul, div, mstore, mload, sstore, sload, pop, msize, run, dump, help');
rl.prompt();

rl.on('line', (line) => {
  const parts = line.trim().split(/\s+/);
  const cmd = parts[0];
  if(!cmd) { rl.prompt(); return }
  if(cmd === 'help') {
    console.log('Commands: push <n>, add, sub, mul, div, pop, mstore, mload, sstore, sload, msize, run <instr...>, dump, exit');
    rl.prompt(); return
  }
  if(cmd === 'exit' || cmd === 'stop') { console.log('Stopping.'); rl.close(); return }
  if(cmd === 'dump') { console.log(JSON.stringify(vm.dump(), null, 2)); rl.prompt(); return }
  if(cmd === 'run') {
    const tokens = parts.slice(1);
    let i = 0;
    while (i < tokens.length) {
      const token = tokens[i];
      const args = [];
      if (token === 'push') {
        if (i + 1 >= tokens.length) {
          console.log('run: push requires a value');
          break;
        }
        args.push(tokens[i + 1]);
        i += 2;
      } else {
        i += 1;
      }
      const parsed = parseInstruction(token, args);
      if (parsed.error) {
        console.log(parsed.error);
        break;
      }
      const res = vm.runInstr(parsed.instr, parsed.args);
      console.log(`${token} -> ${res}`);
    }
    rl.prompt();
    return
  }
  const parsed = parseInstruction(cmd, parts.slice(1));
  if(parsed.error) {
    console.log(parsed.error);
    rl.prompt();
    return
  }
  const res = vm.runInstr(parsed.instr, parsed.args);
  console.log(res);
  rl.prompt();
}).on('close', () => {
  process.exit(0);
});
