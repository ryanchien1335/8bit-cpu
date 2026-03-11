; ===============================
; 8-Bit CPU Full Instruction Demo
; Demonstrates all current instructions
; ===============================

; Initialize RAM for testing
LDA 1          ; Load RAM[1] into A
STA 3          ; Store A into RAM[3]
LDA 2          ; Load RAM[2] into A
STA 4          ; Store A into RAM[4]

; Basic arithmetic
LDA 3          ; Load RAM[3]
ADD 4          ; Add RAM[4]
STA 5          ; Store result in RAM[5]
SUB 1          ; Subtract RAM[1], result in A

; Conditional jumps
JZ zero_label  ; Jump if result was zero
JC carry_label ; Jump if carry set

; Stack operations
PUSH A         ; Push current A onto stack
LDA 0          ; Load RAM[0] for testing
CALL subroutine ; Call a subroutine
POP A          ; Pop value back into A

; Output and I/O
LDA 14         ; Read a number from keyboard
STA 15         ; Output to LED register

; Loop
JMP start_loop

; ===============================
; Subroutine
; ===============================
subroutine:
    LDA 1
    ADD 2
    RET

; ===============================
; Conditional Labels
; ===============================
zero_label:
    NOP          ; No operation if zero

carry_label:
    NOP          ; No operation if carry

; ===============================
; Infinite loop to end program
; ===============================
start_loop:
    JMP start_loop