# 8-Bit Microcoded CPU

A custom-designed **8-bit CPU built in Logisim** with a **Python assembler**, supporting **microcoded control flow, stack-based subroutines, and memory-mapped I/O**.

This project explores the internal architecture of a simple processor and demonstrates how complex behaviors such as **keyboard input routines and subroutine calls** can be implemented entirely through **microcode sequencing**.

---

# Table of Contents

- Overview
- Architecture
- CPU Block Diagram
- Instruction Format
- Instruction Set
- Stack Architecture
- CALL and RET
- Execution Model
- Microcode Architecture
- Example Microcode (ADD Instruction)
- Instruction Cycle Timing
- Keyboard Input Routine
- Example Programs
- Assembler
- Memory Map
- Design Philosophy
- Future Improvements

---

# Overview

This CPU implements a **multi-cycle microcoded architecture** designed to prioritize **clarity, correctness, and extensibility** rather than raw performance.

The processor executes instructions across multiple clock cycles using a **shared data bus** and a **microprogrammed control unit**. Each instruction is broken into smaller micro-operations stored in a **microcode ROM**.

Key architectural ideas explored in this project include:

- Microcoded control units
- Stack-based subroutine calls
- Memory-mapped I/O
- Conditional branching
- Shared-bus architectures
- Multi-cycle instruction execution

The project also includes a **Python assembler** capable of translating assembly code into machine instructions compatible with the CPU.

---

# Architecture

The CPU is built around a **single shared 8-bit data bus**. All components communicate through this bus and are enabled by control signals produced by the microcode ROM.

Major components include:

- Program Counter (PC)
- Instruction Register (IR)
- Microprogram Counter (uPC)
- Microcode ROM
- Arithmetic Logic Unit (ALU)
- Register A (Accumulator)
- Register B
- RAM
- Stack Pointer
- Output Register
- Keyboard Input Hardware

Because hardware resources are reused across cycles, instructions execute across **multiple clock cycles**.

---

# CPU Block Diagram

```
              +----------------------+
              |   Program Counter    |
              +----------+-----------+
                         |
                         v
                +------------------+
                |    Program ROM   |
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
                |   Counter (uPC)  |
                +---------+--------+
                          |
                          v
                +------------------+
                |   Microcode ROM  |
                +---------+--------+
                          |
                    CONTROL SIGNALS
                          |
          -------------------------------------
          |            |           |          |
          v            v           v          v
     Register A    Register B     ALU        RAM
          |            |           |          |
          ------------ DATA BUS ---------------
                          |
                    Output Register
                          |
                       LED Output
```

---

# Instruction Format

Each instruction is **8 bits**:

```
[ OPCODE (4 bits) ] [ OPERAND (4 bits) ]
```

Example:

```
0001 0010
```

```
0001 → LDA
0010 → address 2
```

---

# Instruction Set

| Opcode | Instruction | Description |
|------|------|------|
|0000|NOP|No operation|
|0001|LDA addr|Load accumulator from memory|
|0010|STA addr|Store accumulator into memory|
|0011|ADD addr|Add memory value to accumulator|
|0100|SUB addr|Subtract memory value from accumulator|
|0101|PUSH A|Push accumulator onto stack|
|0110|POP A|Pop value from stack into accumulator|
|0111|CALL addr|Call subroutine|
|1000|RET|Return from subroutine|
|1100|JZ addr|Jump if zero flag set|
|1101|JC addr|Jump if carry flag set|
|1110|JMP addr|Unconditional jump|
|1111|HLT|Halt CPU|

---

# Stack Architecture

Subroutines are implemented using a **stack stored in RAM**.

A **Stack Pointer (SP)** keeps track of the top of the stack.

## PUSH Operation

```
SP ← SP - 1
RAM[SP] ← value
```

## POP Operation

```
value ← RAM[SP]
SP ← SP + 1
```

The stack grows **downward in memory**.

---

# CALL Instruction

`CALL addr` performs the following sequence:

```
Push PC onto stack
PC ← addr
```

Execution continues at the subroutine.

Example:

```
CALL multiply
```

---

# RET Instruction

`RET` performs the reverse operation:

```
Pop return address from stack
PC ← popped value
```

Execution resumes at the instruction **after the original CALL**.

---

# Execution Model

The CPU executes instructions through a **multi-cycle microcoded execution model**.

Each instruction is implemented as a sequence of **microinstructions**.

Typical execution phases:

| Phase | Description |
|------|------|
|Fetch|Load instruction from program memory|
|Decode|Microcode selects instruction routine|
|Execute|Perform instruction logic|
|Completion|Return to fetch cycle|

---

# Microcode Architecture

The microcode ROM is addressed using:

```
[ OPCODE (4 bits) ][ SUBSTATE (5 bits) ]
```

This provides:

```
16 instructions
×
32 microinstructions each
```

Each microinstruction generates control signals for:

- Register enables
- Bus drivers
- ALU operations
- Memory access
- Stack pointer updates
- Microcode branching

---

# Example Microcode (ADD Instruction)

The ADD instruction performs a memory-based addition:

```
A ← A + RAM[addr]
```

Because instructions store their operand in the **next byte of program ROM**, the CPU performs an additional operand fetch before the ALU operation.

The ADD microcode begins at **microcode address 0x62** and ends at **0x67**.

| uPC | Operation |
|----|----|
|062|Fetch operand from program ROM into OPERAND register|
|063|Increment PC to point to the next instruction|
|064|Send OPERAND value to MAR (Memory Address Register)|
|065|Load RAM[MAR] into register B|
|066|ALU computes A + B|
|067|Store ALU result into A and branch uPC back to instruction fetch|

---

# Instruction Cycle Timing

Instructions execute across multiple clock cycles using the microcoded control unit.

Most instructions use a **two-step fetch process**:

1. Fetch the instruction opcode
2. Fetch the operand byte from program memory

Example: **ADD instruction**

```
Cycle 1  Fetch instruction opcode
Cycle 2  Decode opcode
Cycle 3  Fetch operand byte
Cycle 4  Read RAM operand
Cycle 5  Perform ALU addition
Cycle 6  Write result to accumulator
```

Example: **CALL instruction**

```
Cycle 1  Fetch instruction opcode
Cycle 2  Decode opcode
Cycle 3  Fetch operand byte (target address)
Cycle 4  Push PC to stack
Cycle 5  Load PC with target address
```

Example: **RET instruction**

```
Cycle 1  Fetch instruction opcode
Cycle 2  Decode opcode
Cycle 3  Pop return address from stack
Cycle 4  Load PC
```

---

# Keyboard Input Routine

Address **14** is mapped to keyboard input.

Executing:

```
LDA 14
```

activates a microcoded routine that reads a **multi-digit decimal number**.

Algorithm:

```
A ← 0

loop:
    read keyboard
    if not digit → exit

    digit ← ascii - 48
    A ← A * 10 + digit
    repeat
```

Example input:

```
123
```

Result:

```
A = 123
```

---

# Memory Map

The CPU uses **memory-mapped I/O**, meaning certain addresses do not correspond to physical RAM but instead interact with hardware devices.

| Address | Purpose |
|------|------|
|0–13|General-purpose RAM|
|14|Keyboard input (memory-mapped I/O)|
|15|Output register (memory-mapped I/O)|

Addresses **14 and 15** are intercepted by hardware rather than the RAM module.

Examples:

```
LDA 14
```

Loads the current value from the **keyboard input hardware** into the accumulator.

```
STA 15
```

Writes the accumulator value to the **output register**, which drives the LED display.

This approach allows I/O devices to be accessed using the same instructions as normal memory.
---

# Example Program

### Infinite Loop

```asm
LDA 2
loop:
ADD 3
JMP loop
HLT
```

Machine Code

```
00010010
00110011
11100001
11110000
```

---

# Python Assembler

Assembly programs are converted into machine code using a **Python assembler**.

Run with:

```
python assembler.py program.asm
```

Features:

- Label resolution
- Opcode encoding
- Binary output generation

---

# Design Philosophy

This CPU emphasizes:

- **Clarity over performance**
- **Microcode-driven behavior**
- **Minimal hardware duplication**

By avoiding pipelining and executing one instruction at a time, the architecture eliminates:

- Data hazards
- Control hazards
- Pipeline stalls

This makes the design ideal for learning **core CPU architecture concepts**.

---

# Future Improvements

Potential expansions include:

- Interrupt handling
- Hardware multiplication
- Larger RAM address space
- Pipelined CPU variant
- Cache hierarchy experiments
- Branch prediction research
