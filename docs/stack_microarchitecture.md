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

---

## Program Counter Timing Model

All instructions follow a uniform two-phase execution model.

### Fetch Phase

1. MAR ← PC  
2. IR ← RAM[MAR]  
3. PC ← PC + 1  

At the beginning of the execute phase, the PC already points to the next sequential instruction.

### Architectural Implications

- During CALL execution, the PC contains the correct return address and must be pushed as-is.
- No additional increment is required.
- During RET, the PC is overwritten with the value restored from the stack.

---

## Register Transfer Definitions

### PUSH A

```
SP ← SP - 1
MAR ← SP
RAM[MAR] ← A
```

### POP A

```
MAR ← SP
A ← RAM[MAR]
SP ← SP + 1
```

### CALL addr

```
SP ← SP - 1
MAR ← SP
RAM[MAR] ← PC
PC ← addr
```

### RET

```
MAR ← SP
PC ← RAM[MAR]
SP ← SP + 1
```

---

## PUSH A – Microstates

| Microstate | Operation         | Control Signals      |
|------------|------------------|----------------------|
| T1         | SP ← SP - 1      | SP_dec               |
| T2         | MAR ← SP         | SP_out, MAR_load     |
| T3         | RAM[MAR] ← A     | A_out, RAM_write     |

Execution cycles (execute phase only): 3

---

## POP A – Microstates

| Microstate | Operation         | Control Signals      |
|------------|------------------|----------------------|
| T1         | MAR ← SP         | SP_out, MAR_load     |
| T2         | A ← RAM[MAR]     | RAM_read, A_load     |
| T3         | SP ← SP + 1      | SP_inc               |

Execution cycles (execute phase only): 3

---

## CALL addr – Microstates

| Microstate | Operation         | Control Signals      |
|------------|------------------|----------------------|
| T1         | SP ← SP - 1      | SP_dec               |
| T2         | MAR ← SP         | SP_out, MAR_load     |
| T3         | RAM[MAR] ← PC    | PC_out, RAM_write    |
| T4         | PC ← addr        | Operand_out, PC_load |

Execution cycles (execute phase only): 4  
(Does not include operand fetch cycles.)

---

## RET – Microstates

| Microstate | Operation         | Control Signals      |
|------------|------------------|----------------------|
| T1         | MAR ← SP         | SP_out, MAR_load     |
| T2         | PC ← RAM[MAR]    | RAM_read, PC_load    |
| T3         | SP ← SP + 1      | SP_inc               |

Execution cycles (execute phase only): 3

---

## Control-Flow Overhead

Using the stack-based control-flow operations defined above, subroutine calls
incur a fixed execution overhead.

A full subroutine call consists of a `CALL` followed by a `RET`.

Total cycle cost:

```
CALL = 8 cycles
RET  = 7 cycles
Total = 15 cycles
```

This represents the minimum overhead required to invoke and return from a subroutine,
excluding the execution of the subroutine body itself.

The cost arises from:

- saving the return address onto the stack
- updating the Program Counter
- restoring the Program Counter on return

Cycle counts include instruction fetch, decode, and execution phases, and are derived
from the current microcode implementation.

---

## Architectural Invariants

- SP points to the top element of the stack when the stack is non-empty.
- SP = 0xFF represents an empty stack.
- PUSH followed by POP restores A.
- CALL followed by RET restores PC.
- SP is unchanged after a PUSH+POP pair.
- SP is unchanged after a CALL+RET pair.
- PC is incremented only during fetch unless explicitly loaded during execute.
