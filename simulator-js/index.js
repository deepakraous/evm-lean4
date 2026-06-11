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

console.log('Interactive EVM simulator. Commands: push <n>, add, sub, mul, div, mstore, mload, sstore, sload, pop, stop, dump, help');
rl.prompt();

rl.on('line', (line) => {
  const parts = line.trim().split(/\s+/);
  const cmd = parts[0];
  if(!cmd) { rl.prompt(); return }
  if(cmd === 'help') { console.log('Commands: push <n>, add, sub, mul, div, mstore, mload, sstore, sload, pop, stop, dump, exit'); rl.prompt(); return }
  if(cmd === 'exit' || cmd === 'stop') { console.log('Stopping.'); rl.close(); return }
  if(cmd === 'dump') { console.log(JSON.stringify(vm.dump(), null, 2)); rl.prompt(); return }
  if(cmd === 'push') {
    if(parts.length<2) { console.log('push requires a value'); rl.prompt(); return }
    const v = BigInt(parts[1]); console.log(vm.runInstr('push',[v])); rl.prompt(); return
  }
  if(cmd === 'mstore' || cmd === 'mload' || cmd === 'sstore' || cmd === 'sload') {
    const res = vm.runInstr(cmd, parts.slice(1));
    console.log(res);
    rl.prompt(); return
  }
  // other instructions
  const res = vm.runInstr(cmd, parts.slice(1));
  console.log(res);
  rl.prompt();
}).on('close', () => {
  process.exit(0);
});
