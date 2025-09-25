section .data
        prompt_msg db "Enter a number: ", 0                     ; Message for asking a number

        is_prime_msg db "It's a prime number! :)", 10, 0        ; Message for prime (10 is newline)

        not_prime_msg db "It's not a prime number! :)", 10, 0   ; Message for not a prime (10 is newline)

section .bss
        input_buffer resb 16                                    ; Reserved 16 bytes for user input

section .text
        global _start                                           ; This make the entry point visible to the linker

print_string:
        push rax                                                ; Save rax in stack
        push rsi                                                ; Save rsi in stack
        push rdi                                                ; Save rdi in stack

        xor rdx, rdx                                            ; Clear rdx for calculating string length

.loop:
        cmp byte[rdi + rdx], 0                                  ; Compare rdi+rdx with 0
        je .end                                                 ; If 0, jump to end
        inc rdx                                                 ; If not 0, increase rdx
        jmp .loop                                               ; Jump to loop again 
                                                                ; rdx will increasing according to string length

.end:
        mov rax, 1                                              ; Syscall number for write 
        mov rsi, rdi                                            ; Address of string
                                                                ; rdx has the string length already
        mov rdi, 1                                              ; File descriptor for stdout
        syscall                                                 ; Call kernel

        pop rdx                                                 ; Restore rdx register from stack
                                                                ; (Notice we pushed rdx last and now poped first)
        pop rsi                                                 ; Restore rsi register from stack
        pop rax                                                 ; Restore rax register from stack
        ret                                                     ; Return

ascii_to_int:
        xor rax, rax                                            ; Clear rax (Our result will be stored here) (It's our result accumulator)
        xor rcx, rcx                                            ; Clear rcx (Our character counter)

.loop:
        movzx rdx, byte[rsi + rcx]                              ; Get the character
        cmp rdx, '0'                                            ; Compare with ASCII '0' (48 in integer)
        jl .done                                                ; If less than '0', it's not a digit
        cmp rdx, '9'                                            ; Compare with ASCII  '9' (57 in integer)
        jg .done                                                ; If greater than '9', it's not a digit

        sub rdx, '0'                                            ; Convert ASCII digit to integer value
        imul rax, 10                                            ; Multiply accumulator by 10
        ; IMUL (integer multiply) treats them as signed numbers, handling both positive and negative values correctly
        add rax, rdx                                            ; Add the new digit
        inc rcx                                                 ; Increase rcx by 1
                                                                ; It's basically increasing the address of rsi by 1 in start of our loop
        jmp .loop                                               ; Jump back to loop

.done:
        ret                                                     ; Return 

_start:
        mov rdi, prompt_msg                                     ; Prompt Message
        call print_string                                       ; Call print string function

        mov rax, 0                                              ; Syscall for read
        mov rdi, 0                                              ; File descriptor for stdin
        mov rsi, input_buffer                                   ; Buffer to store input
        mov rdx, 16                                             ; Max bytes to read
        syscall                                                 ; Call kernel

        mov rsi, input_buffer                                   ; Move user's ASCII input into rsi
        call ascii_to_int                                       ; Call ASCII to Integer function
        mov rbx, rax                                            ; Store the number in rbx for checking

        ; Prime Check Logic
        ; A whole number greater than 1 that cannot be exactly divided by any whole number other than itself and 1 (e.g. 2, 3, 5, 7, 11).
        ; Handle edge cases: 0 and 1 are not prime


        cmp rbx, 1                                              ; Compare rbx (Stored number)  with 1
        jle .not_prime                                          ; If lower or equal to 1, it's not prime

        cmp rbx, 2                                              ; Compare rbx (Stored number) with 2
        je .is_prime                                            ; If 2, it's prime

        mov rax, rbx                                            ; Move rbx (Stored number) into rax
        and rax, 1                                              ; Do AND operation with 1
        jz .not_prime                                           ; If the last bit is 0, it's even and not prime

        ; The last bit can be used to determine if the number is even or not.
        ; e.g. 13 = 1101, 53 = 110101, 285 = 100011101 (Notice the last bit is always 1)
        ; e.g. 12 = 1100, 54 = 110110, 812 = 1100101100 (Notice the last bit is always 0)

        ; By doing AND operation with 1, we either got 0 or 1 in only last bit. Others will be 0.
        ; 010110 
        ; 000001 (AND)
        ; ------------
        ; 000000 (Result)

        mov rcx, 3                                              ; Start divisor at 3
.check_loop:
        ; We check if rcx*rcx > rbx instead of rcx > sqrt(rbx) to avoid floating point math
        mov rax, rcx                                            ; Move rcx (divisor) to rax 
        mul rcx                                                 ; rax = rcx * rcx
        cmp rax, rbx                                            ; Compare rax (rcx*rcx) with our stored number
        jg .is_prime                                            ; If rcx*rcx > number, we're done, it's prime

        mov rax, rbx                                            ; Move rbx (stored number) into rax
        xor rdx, rdx                                            ; Clear out rdx for storing remainder
        div rcx                                                 ; rax = rbx / rcx (remainder is stored in rdx)

        cmp rdx, 0                                              ; Check if rdx (remainder) is 0
        je .not_prime                                           ; If remainder is 0, it's divisible, so not prime

        add rcx, 2                                              ; Move to the next odd divisor (We don't use even number as divisor)
        jmp .check_loop                                         ; Loop again

.is_prime:
        mov rdi, is_prime_msg                                   ; Message for prime
        call print_string                                       ; Call the print string function 
        jmp .exit                                               ; Jump to exit

.not_prime:
        mov rdi, not_prime_msg                                  ; Message for not prime
        call print_string                                       ; Call the print string function 
        jmp .exit                                               ; Jump to exit

.exit:
        mov rax, 60                                             ; Syscall number for exit
        xor rdi, rdi                                            ; Exit code 0
        syscall                                                 ; Call kernel
