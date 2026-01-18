# Instruction Set Architecture (ISA)
## Overview
This document defines the Instruction Set Architecture for a custom-made 8-bit CPU. This CPU follows a multi-cycle microarchitecture; however, instruction timing and internal execution phases are not architecturally visible. All software targeting this CPU must conform to the rules defined in this document.


## Instruction Format
Each instruction is 8 bits wide and is formatted as shown:
* First 4 bits (0-3): OPERAND
* Last 4 bits (4-7): OPCODE

| 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|---|---|---|---|---|---|---|---|
| O[3] | O[2] | O[1] | O[0] | A[3] | A[2] | A[1] | A[0] |

## Instruction Set
| OPCODE | Instruction | Description |
|:-----------|:------------:|------------:|
| 0000     | NOP       | Do nothing      |
| 0001     | LDA       | Load A from RAM     |
| 0010     | STA       | Store A to RAM  |
| 0011     | ADD       | Add RAM to A and store result in A      |
| 0100     | SUB       | Sub RAM from A and store result in A    |
| 0101     | JZ        | Jump to PC address if Z = 1    |
| 0110     | JC        | Jump to PC address if C = 1     |
| 1110     | JMP       | Jump to PC address      |
| 1111     | HLT       | Halt CPU     |


## Operand Semantics
* The operand field is a 4-bit unsigned value (0–15).
* For memory instructions, the operand represents a RAM address.
* For jump instructions, the operand represents a ROM address.
* For instructions that do not use an operand (NOP, HLT), the operand bits are ignored.


## Example Program
0. LDA 0
1. ADD 1
2. ADD 1
3. STA 0
4. LDA 2
5. ADD 3
6. STA 2
7. SUB 4
8. JZ 10
9. JMP 0
10. HLT
