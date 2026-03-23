; RAM and arithmetic
LDA 1
STA 3
LDA 2
STA 4
LDA 3
ADD 4
STA 5
SUB 1

; Conditional branching
JZ zero_label
JC carry_label

; Stack and subroutine
PUSH
LDA 0
CALL subroutine
POP

; Keyboard input and output
LDK        ; special: read from keyboard (1E)
OUT        ; special: write to output (2F)

; Main loop
JMP start_loop

; Subroutine
subroutine:
    LDA 1
    ADD 2
    RET

; Branch targets
zero_label:
    NOP

carry_label:
    NOP

; Infinite loop
start_loop:
    JMP start_loop