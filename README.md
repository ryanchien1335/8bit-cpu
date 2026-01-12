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

