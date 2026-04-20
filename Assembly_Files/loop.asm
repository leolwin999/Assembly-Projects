DEFAULT REL                     ;Tell NASM to use RIP-relative addressing by default

section .bss
        buffer resb 20          ; Reserve a 20-byte buffer in memory to hold our string of characters

section .text
        global _start           ; This make the entry point visible to linker

_start:
        mov r12, 0              ; Initialize our counter (i = 0). We use r12 because our print function won't touch it. (Callee saved register)

.while_condition:
        cmp r12, 10             ; Check if i > 10
        jg .end_loop            ; If so, break out of the loop

        mov rax, r12            ; Pass the value into rax, which is where our print_int function expects the input
        call print_int          ; Convert and print

        inc r12                 ; increase the value by 1 (i++) 
        jmp .while_condition    ; Jump to top of loop

.end_loop:
        mov rax, 60             ; Syscall for exit
        xor rdi, rdi            ; Exit code 0
        syscall                 ; Call kernel 

print_int:
        mov rcx, 19             ; Start near the end of our 20-byte buffer
        mov byte [buffer+19], 10; Put a newline character (ASCII 10) at the very end
        mov rbx, 10             ; We will be dividing by 10

.convert_loop:
        xor rdx, rdx            ; Clear rdx before division (rdx is used for reminder) 
        div rbx                 ; Divide rax by 10. Quotient goes into rax, reminder is in rdx

        add dl, '0'             ; Convert the reminder (dl, which is the lowest byte of rdx) to an ASCII character ('0' has an ASCII value 48. '0' != 0) 

        dec rcx                 ; Move one step backward in our buffer
        mov [buffer+rcx], dl    ; Store the ASCII character in the buffer

        test rax, rax           ; Check if the quotient (in rax) is 0
        jnz .convert_loop       ; Loop again if we still have digits left

        mov rax, 1              ; Syscall for write 
        mov rdi, 1              ; File descriptor for stdout
        lea rsi, [buffer+rcx]   ; Load Effective Address: point rsi to where our string starts in the buffer

        mov rdx, 20             ; To calculate the length of the string to print (20 - rcx)
        sub rdx, rcx            ; rdx now holds the exact number of bytes to print

        syscall                 ; Call kernel
        ret                     ; Return to main loop 
