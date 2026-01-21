# 8-Bit CPU Project

## Overview

This project implements a custom-designed 8-bit CPU built in Logisim, accompanied by a Python-based assembler. The CPU is designed as a **multi-cycle, bus-based architecture** that prioritizes simplicity, correctness, and architectural clarity over raw performance. Rather than duplicating hardware to increase throughput, the design reuses a small set of functional units across multiple clock cycles, mirroring the structure of early educational and historical CPU designs.

The project serves both as a functional processor and as an exploration of core computer architecture concepts, including instruction sequencing, control logic, memory access, condition flags, and program control flow. It is intended as a strong foundational project for further experimentation with I/O, microcode, and pipelining.

### Current Features
- 8-bit accumulator-based architecture
- Shared system data bus
- Multi-cycle instruction execution
- Arithmetic and logic operations via a single ALU
- Conditional and unconditional branching
- Memory-mapped input and output
- Python assembler for translating assembly to machine code

---

## CPU Block Diagram

```text
              +--------------------+
+------------>|  Program Counter   | 
|             +--------------------+                        
|                       |                                   
|                       v                                  
|              +------------------+                          
|              |   Program ROM    |                          
|              | (Instructions)   |                          
|              +--------+---------+                         
|                       |
|                       v
|            +-----------------------+
|            | Instruction Register  |
|            +----------+------------+
|                       |
|                       v
|  +------+     +------------------+     +--------------+
|  | RAM  |<--->|     Data Bus     |<--->|  Register A  |
|  +------+     +------------------+     +--------------+
|                       ^
|                       |               
|                       v
|               +----------------+
|               |      ALU       |
|               | ADD SUB AND OR |
|               +-------+--------+ 
|                       |
|                       v
|                +-------------+
+----------------+ Flags (Z,C) |
                 +-------------+
```
---

## Instruction Format
Each instruction is 8 bits:

```text
[ OPCODE (4 bits) ] [OPERAND (4 bits)]
```
---

## Opcode Table

| Opcode | Mnemonic | Operand | Description |
|------:|----------|---------|-------------|
| 0000 | NOP | — | No operation |
| 0001 | LDA | addr | A ← RAM[addr] |
| 0010 | STA | addr | RAM[addr] ← A |
| 0011 | ADD | addr | A ← A + RAM[addr] |
| 0100 | SUB | addr | A ← A − RAM[addr] |
| 0101 | JZ  | addr | PC ← addr if Zero flag = 1 |
| 0110 | JC  | addr | PC ← addr if Carry flag = 1 |
| 1110 | JMP | addr | PC ← addr |
| 1111 | HLT | — | Halt CPU |

---

## Assembler Usage

Run the assembler from the command line:

```bash
python assembler.py test.asm
```
---

## Example Program 1 (Loop)

### Assembly Code
```text
LDA 2
loop:
ADD 3
JMP loop
HLT
```

### Machine Code
```text
00010010
00110011
11100001
11110000
```

### Explanation
- `LDA 2` loads the value at RAM address 2 into Register A
- `ADD 3` continuously adds the value at RAM address 3 to Register A
- `JMP loop` causes execution to repeat indefinitely
- `HLT` is unreachable in this program

---

## Example Program 2 (Conditional)

### Assembly Code
``` text
LDA 0
SUB 1
JZ done
LDA 2
done:
HLT
```
### Machine Code
``` text
00010000
01000001
01010100
00010010
11110000
```

### Explanation
- Subtracts RAM[1] from RAM[0]
- If the result is zero, execution jumps to `done`
- Otherwise, RAM[2] is loaded into Register A

---

## Execution Model (Microarchitecture)

This CPU is implemented as a **multi-cycle architecture**. Each instruction is executed over multiple clock cycles using shared hardware resources rather than duplicated functional units. This design minimizes hardware complexity while increasing control logic complexity.

---

## Instruction Phases

Instruction execution is divided into four sequential phases, with exactly one phase occurring per clock cycle:

| Phase | Description |
|------|-------------|
| Fetch | PC supplies address to ROM; instruction loaded into IR; PC increments |
| Decode | Opcode is decoded into control signals |
| Execute 1 | Instruction-specific computation or memory access |
| Execute 2 | Write-back to registers or PC update |

This phased approach enables reuse of the ALU, RAM, and system bus.

---

## Instruction Timing Examples

### LDA (Load Accumulator)

| Cycle | Action |
|------|--------|
| T0 | Fetch instruction into IR |
| T1 | Decode LDA |
| T2 | Output RAM data onto the data bus |
| T3 | Load data from bus into Register A |

### ADD (Add to Accumulator)

| Cycle | Action |
|------|--------|
| T0 | Fetch instruction |
| T1 | Decode ADD |
| T2 | ALU computes A + RAM[addr] |
| T3 | Load ALU result into Register A |

### JMP (Jump)

| Cycle | Action |
|------|--------|
| T0 | Fetch instruction |
| T1 | Decode JMP |
| T2 | Idle / wait |
| T3 | Load PC with operand |

### JZ / JC (Conditional Jump)

| Cycle | Action |
|------|--------|
| T0 | Fetch instruction |
| T1 | Decode JZ or JC |
| T2 | Evaluate Zero or Carry flag |
| T3 | If condition is true, load PC with operand |

---

## State Storage Between Cycles

Several storage elements allow instructions to span multiple clock cycles:

- **Instruction Register (IR):** Holds the current instruction
- **Register A:** Stores intermediate and final ALU results
- **RAM:** Stores program data and operands
- **Program Counter (PC):** Tracks the next instruction address
- **Flags (Zero, Carry):** Preserve ALU status for conditional execution

---

## Memory-Mapped I/O

This CPU implements basic input and output using memory-mapped I/O:

- **Address 14:** Input Register 
- **Address 15:** Output Register

Executing `LDA 14` reads Input Register into Register A.  
Executing `STA 15` writes Register A to Output Register.

This approach avoids specialized I/O instructions and keeps the instruction set minimal.

---

## Pipeline Thought Experiment

Although this CPU is not pipelined, it naturally separates execution into fetch, decode, execute, and writeback phases. A pipelined variant could overlap these phases across multiple instructions to improve throughput.

### Flag Dependencies
Arithmetic instructions update flags that are consumed by conditional jumps. In a pipelined design, this introduces data hazards if a jump reads flags before they are updated.

### Control Hazards
Jump instructions disrupt sequential instruction flow and may require instruction flushing if pipelined.

### Real CPU Mitigations
- Stalling
- Forwarding
- Flushing

---

## Design Tradeoffs

This CPU prioritizes simplicity and determinism over performance. While slower than pipelined designs, it provides a clear and correct execution model that is well-suited for architectural exploration and extension.

---


## Architectural Summary

The CPU employs a multi-cycle execution model in which each instruction fully completes before the next begins. This avoids data and control hazards entirely and simplifies the control logic, at the cost of lower instruction throughput compared to pipelined designs.

---

## Future Expansions

Planned and potential extensions include:

- **Microcoded Control Unit:** Replace hardwired control logic with a microcode ROM to simplify instruction sequencing and enable easier ISA expansion.
- **Enhanced Keyboard Input:** Support multi-digit decimal input using iterative accumulation logic (`value ← value × 10 + digit`). **(IN PROGRESS)**
- **Expanded Control Flow:** Add additional conditional branches such as JNZ and JNC.
- **Pipelined Variant:** Implement a pipelined version of the CPU to explore hazard detection and mitigat


