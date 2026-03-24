# Interrupt Architecture

## Overview

This document describes the interrupt architecture used by the 8-bit CPU.

The goal of this design is to provide a simple but extensible interrupt mechanism
that allows external devices to request CPU attention while minimizing hardware
complexity.

The architecture currently uses a **single interrupt line with fixed vectoring**.
Interrupts are checked at the **end of each instruction** and, if enabled,
control is transferred to a predefined interrupt service routine (ISR).

This design prioritizes simplicity while leaving room for future expansion
(such as multiple interrupt sources or vectored interrupts).

---

## Design Goals

The interrupt system was designed with the following goals:

- Minimal additional hardware
- Predictable interrupt timing
- Compatibility with the stack-based call/return system
- Easy future expansion

---

## Interrupt Signal

The CPU exposes a single external interrupt input:
```
INT
```

External hardware asserts this line when it requires service from the CPU.

### Interrupt Conditions

An interrupt is taken only when all of the following are true:

1. The `INT` signal is asserted  
2. Interrupts are enabled  
3. The CPU has completed executing the current instruction  

If these conditions are met, the CPU begins the interrupt handling sequence.

---

## Interrupt Check Timing

Interrupts are checked **only after an instruction finishes executing**.

This ensures:

- Instructions are never partially executed  
- CPU state remains consistent  
- Interrupt behavior is predictable  

Conceptually the instruction cycle becomes:
```
FETCH → DECODE → EXECUTE → CHECK_INTERRUPT → FETCH
```

If no interrupt is pending, execution continues normally.

---

## Interrupt Entry Sequence

When an interrupt is accepted, the CPU performs the following steps:

1. Push the current Program Counter (PC) onto the stack  
2. Disable further interrupts  
3. Load the interrupt vector into the PC  
4. Begin executing the interrupt service routine  

Example micro-operations:
```
SP ← SP - 1
RAM[SP] ← PC

PC ← INTERRUPT_VECTOR
INT_ENABLE ← 0
```

---

## Interrupt Vector

This CPU uses a **fixed interrupt vector**.

When an interrupt occurs, the Program Counter is set to:
```
0xF0
```

This address marks the start of the interrupt service routine.

Example memory layout:
```
0x00 – 0xEF   Program code
0xF0 – 0xFF   Interrupt service routines
```

---

## Interrupt Service Routine (ISR)

The interrupt service routine is responsible for:

- Handling the interrupting device  
- Clearing the interrupt source  
- Returning control to the interrupted program  

Typical ISR structure:
```
ISR_START:
    ; service hardware
    ; clear interrupt source

    IRET
```

---

## Returning From an Interrupt

Interrupt service routines return using the `IRET` instruction.

`IRET` performs the following operations:

1. Restore the saved Program Counter from the stack  
2. Re-enable interrupts  
3. Resume execution of the interrupted program  

Example micro-operations:
```
PC ← RAM[SP]
SP ← SP + 1

INT_ENABLE ← 1
```

---

## Stack Interaction

Interrupt handling uses the CPU stack to store the return address.

Stack operations follow the existing push/pop mechanism:

Push operation:
```
SP ← SP - 1
RAM[SP] ← value
```

Pop operation:
```
value ← RAM[SP]
SP ← SP + 1
```

Because the stack grows downward from high memory, interrupt pushes integrate
naturally with the call/return architecture.

---

## Nested Interrupts

Nested interrupts are **disabled by default**.

When an interrupt is taken:
```
INT_ENABLE ← 0
```

This prevents another interrupt from interrupting the ISR.

Future versions of the CPU could support nested interrupts by allowing
interrupts to be re-enabled within the ISR.

---

## Interrupt Overhead

Interrupt handling introduces a fixed control-flow overhead due to the
entry and return sequences.

The total interrupt overhead consists of:

- interrupt entry (push PC and redirect execution)  
- interrupt return (`IRET`)  

Approximate cycle cost:
```
Entry ≈ 5 cycles
IRET  = 12 cycles
Total ≈ 17 cycles
```

This overhead is incurred before any useful work is performed inside the ISR.

Compared to standard subroutine calls, interrupts introduce slightly higher
overhead due to additional control flow handling and interrupt state management.

Cycle counts are derived from the current microcode implementation and may
change if the microarchitecture is modified.

---

## Future Extensions

The interrupt architecture is intentionally simple but allows for expansion.

Possible future improvements include:

- Multiple interrupt lines  
- Interrupt priority encoding  
- Vectored interrupts  
- Interrupt masking registers  
- Interrupt acknowledge signals  

These additions can be implemented without fundamentally changing the current
interrupt mechanism.

---

## Summary

The interrupt architecture provides a simple mechanism for handling
asynchronous external events.

Key characteristics:

- Single interrupt input  
- Fixed interrupt vector  
- Stack-based return address storage  
- Interrupt check after each instruction  
- Nested interrupts disabled by default  

This design keeps the hardware simple while still allowing responsive
interaction with external devices.
