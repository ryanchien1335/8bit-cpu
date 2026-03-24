# Instruction Set Architecture (ISA)

## Overview

This document defines the Instruction Set Architecture for a custom 8-bit CPU.

The processor uses a **multi-cycle microcoded control unit**.

While internal microcode states and control signals are not architecturally visible 
to software, each instruction executes over a well-defined sequence of clock cycles.

Instruction timing is therefore deterministic and is documented to support 
performance analysis and deeper architectural understanding.

Instructions may be either **single-byte** or **two-byte**, depending on whether an operand is required.

All software targeting this CPU must conform to the rules defined in this document.

---

## Instruction Encoding

Instructions are composed of either **1 byte** or **2 bytes**.

The CPU automatically performs an additional fetch cycle when an instruction
requires an extended operand.

---

## Instruction Formats

### Single-Byte Instruction

These instructions contain only an opcode. The lower 4 bits are ignored.

```
[ OPCODE (4 bits) ][ UNUSED (4 bits) ]
```

#### Bit Layout

```
7   6   5   4   3   2   1   0
OP3 OP2 OP1 OP0  X   X   X   X
```

#### Used by

- NOP
- HLT
- PUSH
- POP
- RET
- IRET
- EI
- LDK
- OUT

---

### Two-Byte Instruction

Instructions that reference memory or program addresses perform a **double fetch**
to obtain an **8-bit operand**.

#### Byte 1

```
[ OPCODE (4 bits) ][ UNUSED (4 bits) ]
```

#### Byte 2

```
[ OPERAND (8 bits) ]
```

#### Bit Layout

```
Byte 1
7   6   5   4   3   2   1   0
OP3 OP2 OP1 OP0  X   X   X   X

Byte 2
7   6   5   4   3   2   1   0
A7  A6  A5  A4  A3  A2  A1  A0
```

The operand is taken entirely from the **second byte**.

#### Used by

- LDA
- STA
- ADD
- SUB
- CALL
- JMP
- JZ
- JC

---

## Instruction Set

| Opcode | Instruction | Description |
|------|------|------|
| 0000 | (reserved) | Internal microcode entry (interrupt check / fetch / decode) |
| 0001 | LDA addr | A ← RAM[addr] |
| 0010 | STA addr | RAM[addr] ← A |
| 0011 | ADD addr | A ← A + RAM[addr] |
| 0100 | SUB addr | A ← A − RAM[addr] |
| 0101 | PUSH | Push Register A onto stack |
| 0110 | POP | Pop stack value into Register A |
| 0111 | CALL addr | Push PC to stack and jump to addr |
| 1000 | RET | Pop return address from stack into PC |
| 1001 | NOP | No operation |
| 1010 | IRET | Return from interrupt |
| 1011 | EI | Enable interrupts |
| 1100 | JZ addr | Jump if Zero flag = 1 |
| 1101 | JC addr | Jump if Carry flag = 1 |
| 1110 | JMP addr | Unconditional jump |
| 1111 | HLT | Halt CPU |

---

## Operand Semantics

For two-byte instructions, the operand is an **8-bit unsigned value (0–255)**.

The operand is stored entirely in the **second byte** of the instruction.

Operand usage depends on the instruction type.

---

### Memory Instructions

The operand represents a **RAM address**.

```
LDA addr
STA addr
ADD addr
SUB addr
```

---

### Jump Instructions

The operand represents a **program memory address**.

```
JMP addr
JZ addr
JC addr
CALL addr
```

---

### Stack Instructions

These instructions do **not** use the operand field:

```
PUSH
POP
RET
```

The **lower 4 bits of the first instruction byte are ignored**.

---

## Special I/O Instructions

In addition to memory-mapped I/O, the CPU provides dedicated single-byte instructions
for input and output.

---

### LDK — Keyboard Input

```
LDK
```

Encoding: `0x1E`

Reads a multi-digit decimal number from the keyboard input device and stores the result
in **Register A**.

---

### OUT — Output Register

```
OUT
```

Encoding: `0x2F`

Writes the value in **Register A** to the **output hardware (LED display)**.

---

## Memory-Mapped I/O

This CPU implements **input and output using memory-mapped registers**.

---

### Address 14 — Keyboard Input Register

Executing:

```
LDA 14
```

initiates a **keyboard input routine implemented entirely in microcode**.

The routine:

- accepts ASCII digits `0–9`
- accumulates digits as a **decimal number**
- terminates on **Enter (`0x0D`)** or invalid input

The final numeric value is stored in **Register A**.

Execution time depends on the number of digits entered.

---

### Address 15 — Output Register

Executing:

```
STA 15
```

writes the value in **Register A** to the **output hardware (LED display)**.

---

### Note

Equivalent functionality is also available through dedicated instructions (`LDK`, `OUT`)
for more compact instruction encoding.

---

## Example Program

The following program repeatedly adds two numbers and stores the result.

```
start:
    LDA 0
    ADD 1
    STA 2
    JMP start
```

---

## Architectural Notes

- All arithmetic instructions update the **Zero (Z)** and **Carry (C)** flags.
- Conditional jumps read these flags to determine program flow.
- Stack behavior is controlled by the hardware **stack pointer register**.
- Instruction execution time is determined by the underlying **microcode sequence**.
- Two-byte instructions automatically trigger a **second fetch cycle**.

---

## Instruction Timing

Although the internal microcode implementation is not architecturally visible,
each instruction executes over a deterministic number of clock cycles.

These cycle counts include:

- interrupt check
- instruction fetch
- decode/dispatch
- execution micro-operations

### Cycle Table

| Instruction | Bytes | Cycles | Notes |
|------------|------|--------|------|
| LDA addr   | 2    | 9      | Includes operand fetch and memory read |
| STA addr   | 2    | 7      | Includes memory write |
| ADD addr   | 2    | 9      | Includes memory read and ALU operation |
| SUB addr   | 2    | 9      | Includes memory read and ALU operation |
| PUSH       | 1    | 6      | Stack write (SP decrement + RAM write) |
| POP        | 1    | 6      | Stack read (RAM read + SP increment) |
| CALL addr  | 2    | 8      | Push return address + jump |
| RET        | 1    | 7      | Pop return address into PC |
| NOP        | 1    | 4      | No operation |
| IRET       | 1    | 12     | Restores PC and interrupt state |
| EI         | 1    | 4      | Enable interrupts |
| JMP addr   | 2    | 5      | Direct PC update |
| JZ addr    | 2    | 5–6    | 5 if not taken, 6 if taken |
| JC addr    | 2    | 5–6    | 5 if not taken, 6 if taken |
| HLT        | 1    | 4      | Enters halt state |

### Notes

- All instructions include a shared **fetch and dispatch overhead**.
- Conditional branches take **one additional cycle when the branch is taken**.
- I/O instructions such as `LDK` have **variable execution time** depending on input.
- Cycle counts are derived from the current microcode implementation and may change if the microarchitecture is modified.
