# 8-Bit Microcoded CPU

A custom-designed 8-bit CPU built in Logisim with a Python assembler, supporting microcoded control flow, stack-based subroutines, and memory-mapped I/O.

This project explores the internal architecture of a simple processor and demonstrates how complex behaviors such as keyboard input routines and subroutine calls can be implemented entirely through microcode sequencing.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [CPU Block Diagram](#cpu-block-diagram)
- [Instruction Format](#instruction-format)
- [Instruction Set](#instruction-set)
- [Stack Architecture](#stack-architecture)
- [CALL and RET](#call-and-ret)
- [Execution Model](#execution-model)
- [Microcode Architecture](#microcode-architecture)
- [Example Microcode (ADD Instruction)](#example-microcode-add-instruction)
- [Instruction Cycle Timing](#instruction-cycle-timing)
- [Keyboard Input Routine](#keyboard-input-routine)
- [Memory Map](#memory-map)
- [Example Program](#example-program)
- [Assembler](#assembler)
- [Design Philosophy](#design-philosophy)
- [Future Improvements](#future-improvements)

---

## Overview

This CPU implements a multi-cycle microcoded architecture designed to prioritize clarity, correctness, and extensibility rather than raw performance.

The processor executes instructions across multiple clock cycles using a shared data bus and a microprogrammed control unit. Each instruction is broken into smaller micro-operations stored in a microcode ROM.

Key architectural ideas explored in this project include:

- Microcoded control units
- Stack-based subroutine calls
- Memory-mapped I/O
- Conditional branching
- Shared-bus architectures
- Multi-cycle instruction execution

The project also includes a Python assembler capable of translating assembly code into machine instructions compatible with the CPU.

---

## Architecture

The CPU is built around a single shared 8-bit data bus. All components communicate through this bus and are enabled by control signals produced by the microcode ROM.

Major components include:

- Program Counter (PC)
- Instruction Register (IR)
- Operand Register
- Microprogram Counter (uPC)
- Microcode ROM
- Arithmetic Logic Unit (ALU)
- Register A (Accumulator)
- Register B
- RAM (256 bytes, 8-bit address space)
- Stack Pointer
- Output Register
- Keyboard Input Hardware

Because hardware resources are reused across cycles, instructions execute across multiple clock cycles.

---

## CPU Block Diagram
```
+----------------------+
|   Program Counter    |
+----------+-----------+
           |
           v
+------------------+
|   Program ROM    |
+---------+--------+
          |
          v
+------------------+
| Instruction Reg  |
+---------+--------+
          |
          v
+------------------+
|  Microprogram    |
|  Counter (uPC)   |
+---------+--------+
          |
          v
+------------------+
|  Microcode ROM   |
+---------+--------+
          |
   CONTROL SIGNALS
          |
  -----------------------------------------
  |             |            |            |
  v             v            v            v
Register A  Register B      ALU          RAM
  |             |            |            |
  ---------------- DATA BUS ---------------
                       |
                Output Register
                       |
                  LED Output
```

---

## Instruction Format

Instructions are composed of either 1 byte or 2 bytes. The CPU automatically performs an additional fetch cycle when an instruction requires an operand.

### Single-Byte Instruction

These instructions contain only an opcode. The lower 4 bits are ignored.
```
[ OPCODE (4 bits) ][ UNUSED (4 bits) ]

 7   6   5   4   3   2   1   0
OP3 OP2 OP1 OP0  X   X   X   X
```

Used by: `NOP`, `HLT`, `PUSH`, `POP`, `RET`

### Two-Byte Instruction

Instructions that reference memory or program addresses use a second byte for a full 8-bit operand.
```
Byte 1: [ OPCODE (4 bits) ][ UNUSED (4 bits) ]
Byte 2: [ OPERAND (8 bits) ]

Byte 1:  7   6   5   4   3   2   1   0
        OP3 OP2 OP1 OP0  X   X   X   X

Byte 2:  7   6   5   4   3   2   1   0
         A7  A6  A5  A4  A3  A2  A1  A0
```

Used by: `LDA`, `STA`, `ADD`, `SUB`, `CALL`, `JMP`, `JZ`, `JC`

---

## Instruction Set

| Opcode | Instruction | Description |
|--------|-------------|-------------|
| 0000   | NOP         | No operation |
| 0001   | LDA addr    | A <- RAM[addr] |
| 0010   | STA addr    | RAM[addr] <- A |
| 0011   | ADD addr    | A <- A + RAM[addr] |
| 0100   | SUB addr    | A <- A - RAM[addr] |
| 0101   | PUSH        | Push Register A onto stack |
| 0110   | POP         | Pop stack value into Register A |
| 0111   | CALL addr   | Push PC to stack and jump to addr |
| 1000   | RET         | Pop return address from stack into PC |
| 1100   | JZ addr     | Jump if Zero flag = 1 |
| 1101   | JC addr     | Jump if Carry flag = 1 |
| 1110   | JMP addr    | Unconditional jump |
| 1111   | HLT         | Halt CPU |

---

## Stack Architecture

Subroutines are implemented using a stack stored in RAM. A Stack Pointer (SP) keeps track of the top of the stack.

### PUSH Operation
```
SP <- SP - 1
RAM[SP] <- value
```

### POP Operation
```
value <- RAM[SP]
SP <- SP + 1
```

The stack grows downward in memory.

---

## CALL and RET

### CALL Instruction

`CALL addr` performs the following sequence:

1. Push PC onto stack
2. PC <- addr

Execution continues at the subroutine.

Example:
```
CALL multiply
```

### RET Instruction

`RET` performs the reverse operation:

1. Pop return address from stack
2. PC <- popped value

Execution resumes at the instruction after the original `CALL`.

---

## Execution Model

The CPU executes instructions through a multi-cycle microcoded execution model. Each instruction is implemented as a sequence of microinstructions.

Typical execution phases:

| Phase | Description |
|-------|-------------|
| Fetch | Load instruction opcode from program memory |
| Decode | Microcode selects instruction routine |
| Operand Fetch | Retrieve operand from program memory (two-byte instructions only) |
| Execute | Perform instruction logic |
| Completion | Return to fetch cycle |

---

## Microcode Architecture

The microcode ROM is addressed using:
```
[ OPCODE (4 bits) ][ SUBSTATE (5 bits) ]
```

This provides 16 instructions x 32 microinstructions each.

Each microinstruction generates control signals for:

- Register enables
- Bus drivers
- ALU operations
- Memory access
- Stack pointer updates
- Microcode branching

---

## Example Microcode (ADD Instruction)

The `ADD` instruction performs a memory-based addition:
```
A <- A + RAM[addr]
```

Because instructions store their operand in the next byte of program ROM, the CPU performs an additional operand fetch before the ALU operation. The ADD microcode begins at microcode address `0x62` and ends at `0x67`.

| uPC | Operation |
|-----|-----------|
| 062 | Fetch operand from program ROM into OPERAND register |
| 063 | Increment PC to point to the next instruction |
| 064 | Send OPERAND value to MAR (Memory Address Register) |
| 065 | Load RAM[MAR] into register B |
| 066 | ALU computes A + B |
| 067 | Store ALU result into A and branch uPC back to instruction fetch |

---

## Instruction Cycle Timing

Instructions execute across multiple clock cycles using the microcoded control unit.

**Example: ADD instruction**

| Cycle | Action |
|-------|--------|
| 1 | Fetch instruction opcode |
| 2 | Decode opcode |
| 3 | Fetch operand byte |
| 4 | Read RAM operand |
| 5 | Perform ALU addition |
| 6 | Write result to accumulator |

**Example: CALL instruction**

| Cycle | Action |
|-------|--------|
| 1 | Fetch instruction opcode |
| 2 | Decode opcode |
| 3 | Fetch operand byte (target address) |
| 4 | Push PC to stack |
| 5 | Load PC with target address |

**Example: RET instruction**

| Cycle | Action |
|-------|--------|
| 1 | Fetch instruction opcode |
| 2 | Decode opcode |
| 3 | Pop return address from stack |
| 4 | Load PC |

---

## Keyboard Input Routine

Address 14 is mapped to keyboard input. Executing:
```
LDA 14
```

activates a microcoded routine that reads a multi-digit decimal number.

The routine accepts ASCII digits `0-9`, accumulates them as a decimal number, and terminates on Enter (`0x0D`) or invalid input. The final value is stored in Register A.

Algorithm:
```
A <- 0

loop:
    read keyboard
    if not digit -> exit

    digit <- ascii - 48
    A <- A * 10 + digit
    repeat
```

Example input: `123`
Result: `A = 123`

---

## Memory Map

The CPU uses memory-mapped I/O, meaning certain addresses interact with hardware devices rather than physical RAM.

| Address | Purpose |
|---------|---------|
| 0 - 13  | General-purpose RAM |
| 14      | Keyboard input (memory-mapped I/O) |
| 15      | Output register (memory-mapped I/O) |
| 16 - 255 | General-purpose RAM |

Examples:
```
LDA 14   ; Load value from keyboard input hardware into A
STA 15   ; Write A to the output register (LED display)
```

---

## Example Program

### Infinite Loop
```
start:
    LDA 0
    ADD 1
    STA 2
    JMP start
```

### Machine Code
```
00000001 00000000
00000011 00000001
00000010 00000010
11100000 00000000
```

*(Each two-byte instruction shown as two bytes.)*

---

## Assembler

Assembly programs are converted into machine code using a Python assembler.

Run with:
```
python assembler.py program.asm
```

Features:

- Label resolution
- Opcode encoding
- Binary output generation

---

## Design Philosophy

This CPU emphasizes:

- Clarity over performance
- Microcode-driven behavior
- Minimal hardware duplication

By avoiding pipelining and executing one instruction at a time, the architecture eliminates data hazards, control hazards, and pipeline stalls. This makes the design ideal for learning core CPU architecture concepts.

---

## Future Improvements

Potential expansions include:

- Interrupt handling
- Hardware multiplication
- Larger RAM address space
- Pipelined CPU variant
- Cache hierarchy experiments
- Branch prediction research
