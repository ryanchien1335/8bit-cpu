# 8-Bit CPU Project

## Overview
This project implements a simple 8-bit CPU in Logisim, along with a Python assembler. 
The CPU currently supports basic arithmetic, logic operations, memory access, and program control using a small instruction set.
Additionals features will be added in the future to allow for more complex operations.

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

## Instruction Format
Each instruction is 8 bits:

```text
[ OPCODE (4 bits) ] [OPERAND (4 bits)]
```

## Opcode Table
| Opcode | Mnemonic | Operand | Description         |
|--------|----------|---------|---------------------|
| 0000   | NOP      | —       | No operation        |
| 0001   | LDA      | addr    | A ← RAM[addr]       |
| 0010   | STA      | addr    | RAM[addr] ← A       |
| 0011   | ADD      | addr    | A ← A + RAM[addr]   |
| 0100   | SUB      | addr    | A ← A − RAM[addr]   |
| 1110   | JMP      | addr    | PC ← addr           |
| 1111   | HLT      | —       | Halt CPU            |

## Assembler Usage

Run the assembler from the command line:

```bash
python assembler.py test.asm
```

## Example Program

Assembly code:
1. LDA 2
2. loop:
3. ADD 3
4. JMP loop
5. HLT

```text
Machine code:
00010010
00110011
11100001
11110000
```
Explanation: 
1. LDA 2 loads the value of the RAM at address 2 into A
2. ADD 3 adds the value of the RAM at address 3 to A
3. JMP loop jumps back to the ADD 3 instruction, causing a loop
4. HLT stops the program by halting the CPU

# Execution Model (Microarchitecture)

This CPU is implemented as a **multi-cycle architecture**. Each instruction is executed over several clock cycles using shared hardware resources rather than duplicated functional units. This design choice reduces hardware complexity at the cost of increased control logic.

## Instruction Phases

Instruction execution is divided into four sequential phases, with exactly one phase occurring per clock cycle:

| Phase | Description |
|------|-------------|
| Fetch | The Program Counter (PC) supplies an address to ROM, the instruction is loaded into the Instruction Register (IR), and the PC increments |
| Decode | The opcode is decoded and translated into control signals |
| Execute 1 | Instruction-specific actions occur (ALU operation or memory access) |
| Execute 2 | Results are written back to registers or the PC is updated |

This phased approach allows components such as the ALU, RAM, and system bus to be reused across multiple cycles.

## Instruction Timing Examples

The following examples illustrate how individual instructions are executed across multiple cycles.

### LDA (Load Accumulator)

LDA loads a value from memory into Register A. Because memory access and register write-back occur in separate steps, LDA spans multiple cycles.

| Cycle | Action |
|------|-------|
| T0 | Fetch instruction from ROM into IR |
| T1 | Decode instruction as LDA |
| T2 | Output RAM data onto the data bus |
| T3 | Load data from the bus into Register A |

### ADD (Add to Accumulator)

ADD adds the value at the specified RAM address to Register A using the ALU.

| Cycle | Action |
|------|-------|
| T0 | Fetch instruction from ROM into IR |
| T1 | Decode instruction as ADD |
| T2 | Perform ALU addition and output result onto the data bus |
| T3 | Load ALU result from the bus into Register A |

### JMP (Jump)

JMP updates the Program Counter to the address specified by the instruction operand.

| Cycle | Action |
|------|-------|
| T0 | Fetch instruction from ROM into IR |
| T1 | Decode instruction as JMP |
| T2 | Waiting cycle (no data movement) |
| T3 | Load PC with the operand value |

## State Storage Between Cycles

Several storage elements allow instructions to span multiple clock cycles without losing intermediate state:

- **Instruction Register (IR):** Holds the current instruction during decode and execution
- **Register A:** Stores intermediate and final results of ALU operations
- **RAM:** Stores program data and operands across instructions
- **Program Counter (PC):** Holds the address of the next instruction and may be updated incrementally or via jumps
- **Flags (Zero, Carry):** Preserve ALU status information for use by subsequent instructions

These elements enable multi-cycle execution without requiring hardware duplication.

## Architectural Summary

This CPU employs a multi-cycle execution model in which instructions complete over multiple clock cycles using shared hardware resources. This approach simplifies the datapath and avoids pipeline hazards at the cost of lower instruction throughput compared to pipelined designs.

# Pipeline Thought Experiment

## Pipeline Stages
As my current CPU stands, it separates instructions into four phases — **fetch, decode, execute, and writeback** — and executes them sequentially, one phase per clock cycle. Although my CPU is not pipelined, these distinct stages already exist in its control flow. A pipelined design would retain this four-phase structure but would overlap these phases across multiple instructions, allowing for higher overall instruction throughput.

**Mental Model:**
| Instruction     | Cycle 1 | Cycle 2 | Cycle 3 | Cycle 4 | Cycle 5 | Cycle 6 |
|-----------------|---------|---------|---------|---------|---------|---------|
| Instruction N   | FE      | DE      | EX      | WB      | —       | —       |
| Instruction N+1 | —       | FE      | DE      | EX      | WB      | —       |
| Instruction N+2 | —       | —       | FE      | DE      | EX      | WB      |



## Flag Dependencies
My CPU design implements flags that are affected by arithmetic instructions directed toward the ALU (such as ADD and SUB) and that influence conditional jump instructions (such as JZ and JC). This introduces a major issue if pipelining were to be implemented. Because pipelining fetches new instructions before previous instructions have fully completed — rather than waiting until the prior instruction finishes — there is a risk of using incomplete or stale data.

For example, if an ADD instruction is immediately followed by a JZ instruction, the JZ instruction may attempt to read the Zero flag before the ADD instruction has finished updating it. This results in a **data hazard**, since the jump instruction is expected to evaluate the flag only after the preceding instruction has completed.


## Control Hazards
The inclusion of jump instructions (JMP, JZ, and JC) further complicates pipelining in my CPU. Since a pipelined CPU fetches instructions ahead of execution, it may fetch several instructions after a jump instruction before the jump decision has been resolved. If the jump is taken, these prefetched instructions are incorrect and must be discarded. This situation represents a **control hazard**, as changes to the Program Counter disrupt the assumption of sequential instruction flow.


## How Real CPUs Handle Pipeline Hazards
Real CPUs mitigate pipeline hazards using a combination of techniques:

- **Stalling:** Pausing execution until required data becomes available  
- **Forwarding:** Passing results directly between pipeline stages without waiting for writeback  
- **Flushing:** Discarding incorrectly fetched instructions following a jump or branch  


## Design Tradeoffs
My current CPU design prioritizes simplicity and correctness over raw throughput. By executing only one instruction at a time and ensuring that each instruction fully completes before the next begins, the design avoids data and control hazards entirely. While this multi-cycle approach limits performance compared to a pipelined architecture, it significantly simplifies control logic. Implementing pipelining in this CPU would require substantial architectural changes, including additional state storage and more complex hazard management.


