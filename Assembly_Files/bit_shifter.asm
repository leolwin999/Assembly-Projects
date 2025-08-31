section .data
        msg db "Hello Friend", 10                       ; Message to be shifted
        msg_len equ $ - msg                             ; Length of the message

        ; The '$' symbol represents the current address.
        ; '$$' represents the address of the beginning of the current section.

section .text
        global _start                                   ; Make the entry point visible to the linker

_start:
        mov rcx, msg_len                                ; Use rcx as a counter, initialized with the message length
        mov rsi, msg                                    ; rsi now points to the beginning of our message

shift_loop:
        movzx eax, byte [rsi]                           ; movzx loads a byte from memory [rsi] into a larger register (eax) and zero-extends it.
        ; We use a 32-bit register (eax) because there's no direct memory-to-memory 'rol' for single bytes. al is the lowest 8 bits of rax/eax.

        ; ROL stands for "Rotate Left". This instruction rotates the bits in the AL register to the left by 1 position. The bit that falls off the left end is wrapped around to the right end. This is a simple form of encryption
        ; For e.g. 1100 is shifted to 1001 
        rol al, 1                                       ; Shift to left by 1 bit

        mov [rsi], al                                   ; Move the modified byte from al to the original character's memory 

        inc rsi                                         ; Increment the pointer to move to the next character
        dec rcx                                         ; Decrement the loop counter
        jnz shift_loop                                  ; Jump if rcx is 0

        mov rax, 1                                      ; Syscall number for write
        mov rdi, 1                                      ; File descriptor for stdout
        mov rsi, msg                                    ; The address of the (shifted) string to write
        mov rdx, msg_len                                ; The length of the (shifted) string
        syscall                                         ; Call kernel

        mov rax, 60                                     ; Syscall number for exit
        xor rdi, rdi                                    ; Exit code 0
        syscall                                         ; Call kernel
