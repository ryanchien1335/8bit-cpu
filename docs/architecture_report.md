# Architecture Report

## Overview

This document summarizes the architectural design decisions behind the 8-bit CPU.

The processor is built around a **multi-cycle microcoded control unit** and is designed
to emphasize clarity, correctness, and extensibility rather than raw performance.

Key features include:

- Stack-based subroutine support
- Interrupt handling with fixed vectoring
- Expanded 8-bit memory addressing
- Deterministic instruction timing

The following sections describe the reasoning behind each major architectural component.

---

## Stack Design

The CPU implements a **stack-based control flow mechanism** using an 8-bit stack pointer (SP)
stored in main memory.

### Design Decisions

- **Downward-growing stack**  
  The stack grows from high memory toward low memory. This allows the stack to begin at
  address `0xFF` and expand downward without interfering with low-address program data.

- **SP initialized to 0xFF**  
  This provides a clear definition of an empty stack and simplifies push/pop semantics.

- **Stack stored in main RAM**  
  Reusing main memory avoids the need for dedicated stack hardware and keeps the design minimal.

- **Decrement-then-write convention (PUSH)**  
  This ensures that SP always points to the top element of the stack.

- **Read-then-increment convention (POP)**  
  This restores values cleanly while maintaining consistent stack pointer behavior.

- **No hardware overflow detection**  
  Overflow handling is left to software, reducing hardware complexity.

### Implications

This design enables reliable subroutine calls and interrupt handling while maintaining a
simple hardware implementation. However, it places responsibility on the programmer to
avoid stack overflow conditions.

---

## Interrupt Handling

The CPU supports a **single, maskable interrupt line** with a fixed interrupt vector.

### Design Decisions

- **Interrupts checked after each instruction**  
  This guarantees that instructions are never partially executed, preserving system correctness.

- **Fixed interrupt vector (0xF0)**  
  Using a fixed entry point simplifies hardware and avoids the need for vector tables.

- **Stack-based return address storage**  
  The current program counter is pushed onto the stack during interrupt entry, allowing
  execution to resume seamlessly after the interrupt.

- **Interrupts disabled during ISR execution**  
  This prevents nested interrupts and ensures predictable control flow.

### Interrupt Flow

1. Complete current instruction  
2. Push PC onto stack  
3. Disable interrupts  
4. Jump to ISR at `0xF0`  
5. Execute ISR  
6. Return using `IRET`  

### Implications

This design provides a simple and deterministic interrupt mechanism. While it lacks support
for nested or prioritized interrupts, it is sufficient for basic asynchronous event handling
and can be extended in future versions.

---

## Memory Expansion

The CPU was expanded from a limited address space to a full **8-bit addressable memory system**
supporting 256 bytes of RAM.

### Design Decisions

- **8-bit address space (0–255)**  
  This significantly increases program and data capacity compared to a 4-bit system.

- **Two-byte instruction format for operands**  
  Instructions requiring an operand use a second byte to store a full 8-bit address.

- **Separation of opcode and operand**  
  The first byte encodes the instruction, while the second byte provides the operand.

### Tradeoffs

- **Increased instruction size**  
  Two-byte instructions require additional memory and fetch cycles.

- **Simplified decoding logic**  
  Keeping opcodes fixed at 4 bits allows a clean microcode dispatch structure.

### Implications

This design enables more complex programs and flexible memory usage, at the cost of
additional instruction cycles for operand fetch.

---

## Instruction Timing

The CPU uses a **multi-cycle execution model**, where each instruction is broken into
a sequence of micro-operations.

### Key Characteristics

- Each micro-operation executes in one clock cycle  
- Instructions share common stages:
  - interrupt check  
  - fetch  
  - decode/dispatch  
  - execute  

### Observations

- **Memory operations are relatively expensive**  
  Instructions such as `LDA`, `ADD`, and `SUB` require multiple cycles due to
  operand fetch and memory access.

- **Control-flow instructions are cheaper than memory operations**  
  Instructions like `JMP` execute in fewer cycles because they avoid memory reads.

- **Instruction timing is deterministic**  
  Each instruction follows a fixed sequence of micro-operations, making execution
  predictable.

### Implications

The multi-cycle design simplifies hardware and avoids hazards found in pipelined
architectures, but increases the number of cycles per instruction.

---

## Control-Flow Overhead

Higher-level control flow operations introduce measurable overhead.

### Subroutine Overhead

A full subroutine call consists of a `CALL` followed by a `RET`.

```
CALL = 8 cycles
RET  = 7 cycles
Total = 15 cycles
```

This overhead represents the minimum cost of invoking a subroutine, excluding the
execution of the subroutine body.

### Interrupt Overhead

Interrupt handling includes entry and return:

```
Entry ≈ 5 cycles
IRET  = 12 cycles
Total ≈ 17 cycles
```

### Analysis

- Interrupts are slightly more expensive than subroutine calls due to additional
  control flow handling and interrupt state management.

- Both mechanisms rely on the stack, reinforcing the importance of a correct
  stack implementation.

### Implications

These overheads highlight a key tradeoff in the architecture:

- **Modularity vs performance**  
  While subroutines and interrupts improve structure and responsiveness,
  they introduce non-trivial cycle costs.

---

## Design Philosophy

This CPU prioritizes:

- Simplicity over performance  
- Transparency over optimization  
- Extensibility over specialization  

By using a microcoded, multi-cycle design:

- hardware complexity is reduced  
- control flow is easier to reason about  
- new features can be added through microcode changes  

This makes the system well-suited for learning and experimentation, while still
supporting non-trivial programs.

---

## Summary

The architecture combines:

- a stack-based control flow model  
- a simple but effective interrupt mechanism  
- an expanded memory system  
- deterministic multi-cycle execution  

Together, these components form a cohesive and extensible CPU design.

While not optimized for speed, the architecture provides a clear and complete
implementation of fundamental processor concepts, making it a strong foundation
for further exploration and improvement.
