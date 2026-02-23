# Stack Support – Microarchitecture Specification

## Stack Model

- 8-bit Stack Pointer (SP)
- Stack stored in main RAM
- Stack grows downward (high → low addresses)
- SP reset value = 0xFF
- Empty stack condition: SP = 0xFF
- PUSH convention: decrement SP, then write
- POP convention: read, then increment SP
- No hardware overflow detection (programmer responsibility)

Note: The Program Counter (PC) increments during the fetch phase.
Therefore, during CALL execution, the PC already contains the correct return address.

---

## Register Transfer Definitions

### PUSH A
SP ← SP - 1  
RAM[SP] ← A  

### POP A
A ← RAM[SP]  
SP ← SP + 1  

### CALL addr
SP ← SP - 1  
RAM[SP] ← PC  
PC ← addr  

### RET
PC ← RAM[SP]  
SP ← SP + 1  

---

## PUSH A – Microstates

| Microstate | Operation            | Control Signals                          |
|------------|---------------------|--------------------------------------------|
| T1         | SP ← SP - 1        | SP_dec                                     |
| T2         | MAR ← SP           | SP_out, RAM_addr_sel=BUS                   |
| T3         | RAM[SP] ← A        | A_out, RAM_write                           |

Execution cycles (execute phase only): 3

---

## POP A – Microstates

| Microstate | Operation            | Control Signals                          |
|------------|---------------------|--------------------------------------------|
| T1         | MAR ← SP           | SP_out, RAM_addr_sel=BUS                   |
| T2         | A ← RAM[SP]        | RAM_read, A_load                           |
| T3         | SP ← SP + 1        | SP_inc                                     |

Execution cycles (execute phase only): 3

---

## CALL addr – Microstates

| Microstate | Operation            | Control Signals                          |
|------------|---------------------|--------------------------------------------|
| T1         | SP ← SP - 1        | SP_dec                                     |
| T2         | RAM[SP] ← PC       | SP_out, PC_out, RAM_write                  |
| T3         | PC ← addr          | Operand_out, PC_load                       |

Execution cycles (execute phase only): 3  
(Does not include operand fetch cycles.)

---

## RET – Microstates

| Microstate | Operation            | Control Signals                          |
|------------|---------------------|--------------------------------------------|
| T1         | MAR ← SP           | SP_out, RAM_addr_sel=BUS                   |
| T2         | PC ← RAM[SP]       | RAM_read, PC_load                          |
| T3         | SP ← SP + 1        | SP_inc                                     |

Execution cycles (execute phase only): 3

---

## Architectural Invariants

- SP always points to the next free stack slot.
- Top element of stack is located at address SP after a PUSH.
- PUSH followed by POP restores A.
- CALL followed by RET restores PC.
- SP is unchanged after a PUSH+POP pair.
- SP is unchanged after a CALL+RET pair.
