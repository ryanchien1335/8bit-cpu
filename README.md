# 8-Bit CPU Project

## Overview

This project implements a custom-designed 8-bit CPU built in Logisim, accompanied by a Python-based assembler. The CPU is designed as a **multi-cycle, bus-based architecture** that prioritizes simplicity, correctness, and architectural clarity over raw performance. Rather than duplicating hardware to increase throughput, the design reuses a small set of  units across multiple clock cycles, mimicking the structure of early educational and historical CPU designs.

The project serves both as a functional processor and as an exploration of core computer architecture concepts, including instruction sequencing, control logic, memory access, condition flags, and program control flow. It is intended as a strong foundational project for further experimentation with I/O, microcode, and pipelining.

### Current Features
- 8-bit accumulator-based architecture
- Shared data bus
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
|            +-----------------------+   +-----------------+
|            | Instruction Register  |   | Keyboard Input  |
|            +----------+------------+   +--------+--------+
|                       |                         |
|                       v                         v
|  +------+     +------------------+     +--------------+     +------------------+
|  | RAM  |<--->|     Data Bus     |<--->|  Register A  +---->|  Output Register |
|  +------+     +------------------+     +--------------+     +------------------+
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

This CPU follows a **multi-cycle architecture** design. Each instruction is executed over multiple clock cycles using shared hardware resources rather than duplicated units. However, more complex instructions may introduce dedicated hardware to properly execute. Still, instruction behavior is majorly determined by control logic.

---
## Control Unit Architecture

This CPU now uses a **microcoded control unit** rather than the previously implemented hardwired logic. Each instruction is composed of a sequence of microinstructions stored in a control ROM.

### Microcode ROM Structure

- **Address Format**: `[OPCODE (4 bits)][Substate (4 bits)]`
- Each instruction occupies a block of microcode starting at address `OPCODE << 4`
- Microinstructions contain control signals for all CPU components

### Conditional Microcode Branching

The microcode supports conditional branches based on:
- Zero flag (`is_Z`)
- Carry flag (`is_C`)
- Special operand detection (`is_LDA_KBD` for operand == 14)
- Keyboard input validation (`kbd_digit_valid`)

This allows complex instructions like multi-digit keyboard input to be implemented entirely in microcode alone along with the other instructions.

## Instruction Execution Model

Instruction execution is controlled by a **microcode ROM**. Each instruction is decomposed into a sequence of microinstructions, with each microinstruction executing in one clock cycle.

While instructions conceptually follow a fetch-decode-execute pattern, the exact number of cycles and internal operations are determined by the microcode sequence for each instruction.

### Typical Instruction Flow

| Phase | Description |
|------|-------------|
| Fetch | PC sends address to ROM; instruction loaded into IR |
| Decode | Opcode decoded; microcode jumps to instruction-specific routine |
| Execute | Variable-length microcode sequence performs instruction logic |
| Completion | Control returns to fetch phase for next instruction |

The microcode architecture allows instructions to take varying numbers of cycles based on their complexity.

---

## Instruction Timing Examples

### LDA (Load Accumulator)

| Microinstruction | Action |
|------------------|--------|
| Fetch | Fetch instruction into IR |
| Decode | Decode LDA, jump to LDA microcode block |
| Execute | Output RAM data onto bus, load into Register A |

**Total cycles**: 3-4 (depending on microcode implementation)

### ADD (Add to Accumulator)

| Microinstruction | Action |
|------------------|--------|
| Fetch | Fetch instruction into IR |
| Decode | Decode ADD, jump to ADD microcode block |
| Execute | Load RAM operand, ALU computes A + operand |
| Writeback | Store ALU result into Register A |

**Total cycles**: 4-5

### JMP (Jump)

| Microinstruction | Action |
|------------------|--------|
| Fetch | Fetch instruction into IR |
| Decode | Decode JMP, jump to JMP microcode block |
| Execute | Load PC with operand address |

**Total cycles**: 3

### JZ / JC (Conditional Jump)

| Microinstruction | Action |
|------------------|--------|
| Fetch | Fetch instruction into IR |
| Decode | Decode JZ/JC, jump to conditional jump microcode |
| Execute | Evaluate flag condition; conditionally update PC |

**Total cycles**: 3

### LDA 14 (Keyboard Input)

| Microinstruction | Action |
|------------------|--------|
| Fetch | Fetch instruction into IR |
| Decode | Decode LDA 14, jump to keyboard microcode block |
| Execute | Variable-length loop: read keyboard, validate input, accumulate digits |
| Completion | Exit loop on termination condition; accumulated value remains in Register A |

**Total cycles**: Variable (depends on number of digits entered)

---

## Keyboard Input Instruction (LDA 14)

LDA 14 is implemented as a **microcoded multi-digit decimal input routine**.

### Microcode Sequence

The instruction executes the following substates in a loop:

| Substate | Operation |
|----------|-----------|
| Init | Clear Register A |
| 000 | Read keyboard (RAM[14]) → TEMP, check for exit/valid digit |
| 001 | Convert ASCII to digit (TEMP - 0x30) → DIGIT |
| 010 | A << 3 → TEMP1 (multiply A by 8) |
| 011 | A << 1 → TEMP2 (multiply A by 2) |
| 100 | TEMP1 + TEMP2 → TEMP3 (A × 10) |
| 101 | TEMP3 + DIGIT → A, loop back to 000 |

### Termination

- **Valid digit (0-9)**: Loop continues
- **Else**: Exit loop, final value remains in A


### Example

Typing `1`, `2`, `3`, `Enter`:
1. First digit: A = 0×10 + 1 = 1
2. Second digit: A = 1×10 + 2 = 12
3. Third digit: A = 12×10 + 3 = 123
4. Enter: Exit with A = 123

### Execution Behavior
- Initialization occurs during the Decode phase
- Input processing loops during Execute
- When the instruction terminates, the Register A contains the final numeric value.


### Design Rationale
This instruction demonstrates how complex I/O behavior can be implemented using a multi-cycle execution model without expanding the base instruction set.

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

This CPU implements input and output using memory-mapped I/O:

- **Address 14:** Input Register (keyboard input)
- **Address 15:** Output Register

Executing `STA 15` writes Register A to Output Register.
Executing `LDA 14` initiates a specialized keyboard input sequence involving a variable amount of cycles and writes accumulated output to Register A.

This approach avoids specialized I/O instructions while still enabling complex I/O behavior.

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

The CPU inherits a multi-cycle execution model in which each instruction fully completes before the next instruction begins. This avoids data and control hazards entirely and simplifies the control logic, at the cost of lower instruction throughput compared to pipelined designs.

---

## Future Expansions

Planned and potential extensions include:

- **✓ Microcoded Control Unit**: Implemented microcode ROM with conditional branching support
- **Expanded Control Flow:** Add additional conditional branches such as JNZ and JNC.
- **Pipelined Variant:** Implement a pipelined version of the CPU to explore hazard detection and mitigation techniques.


