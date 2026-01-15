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


