section .data
        prompt_msg db "Enter the number to count down (in seconds): ",0 ; Prompt Message
        prompt_msg_len equ $ - prompt_msg                               ; Message Length

        newline db 0x0A                                                 ; Newline character '\n'

section .bss
        input_buffer resb 16                                            ; Buffer to store user input (e.g. "100\n")
        num_buffer resb 20                                              ; Buffer to store numbers for printing

section .text
        global _start

_start:
        mov rax, 1                                                      ; Syscall number for sys_write
        mov rdi, 1                                                      ; File descriptor for stdout
        mov rsi, prompt_msg                                             ; Address of the message
        mov rdx, prompt_msg_len                                         ; Message length
        syscall                                                         ; Call kernel

        mov rax, 0                                                      ; Syscall number for sys_read
        mov rdi, 0                                                      ; File descriptor for stdin
        mov rsi, input_buffer                                           ; Buffer to store input
        mov rdx, 16                                                     ; Max number of bytes to read
        syscall                                                         ; Call kernel

        mov rsi, input_buffer                                           ; rsi points to the start of input string
        mov rbx, 0                                                      ; rbx will hold the final integer value (our counter)
        mov rcx, rax                                                    ; rcx will hold the length of bytes (rcx is loop counter)
        sub rcx, 1                                                      ; Decrement to ignore the newline character at the end

convert_loop:
        movzx rdx, byte [rsi]                                           ; Get the current character
        sub rdx, '0'                                                    ; Convert ASCII to integer

        ; '0' is an ASCII digit. In integer, its value is 48. Assembly works with integer values only.
        ; Use "man ascii" to observe the table

        cmp rdx, 0                                                      ; Check rdx
        jl conversion_done                                              ; If less than 0, it's not a digit
        cmp rdx, 9                                                      ; Check rdx
        jg conversion_done                                              ; If greater than 9, it's not a digit

        imul rbx, 10                                                    ; Multiply current total by 10 (e.g. 2 -> 20) 
        add rbx, rdx                                                    ; Add the new digit (e.g. 20 + 1 -> 21)
        inc rsi                                                         ; Move to the next character in the buffer
        loop convert_loop                                               ; Loop until rcx is 0

        ; 'loop' instruction automatically decrements the value in the RCX. If RCX is zero, the loop terminates.

conversion_done:
        ; rbx now holds the number of seconds entered by the user in integer format


countdown_loop:
        cmp rbx, 0                                                      ; Compare the counter with 0
        jle exit_program                                                ; If it's less than or equal to 0, we've done

        mov rax, rbx                                                    ; Move the number to rax for conversion
        mov rdi, num_buffer + 19                                        ; Point to the end of our number buffer
        mov byte [rdi], 0x0A                                            ; Place a newline at the end
        dec rdi                                                         ; Move back one position
        mov rcx, 10                                                     ; Divisor is 10

convert_to_string_loop:
        xor rdx, rdx                                                    ; Clear rdx to store the remainder
        div rcx                                                         ; rax = rax / rcx, rdx = remainder
        add rdx, '0'                                                    ; Covert remainder to ASCII digit
        mov [rdi], dl                                                   ; Store the digit in our buffer
        dec rdi                                                         ; Move to the previous position in the buffer
                                                                        ; We're moving backwards here
        cmp rax, 0                                                      ; Is the quotient zero? 
        jne convert_to_string_loop                                      ; If not, repeat the process

        mov rax, 1                                                      ; Syscall number for sys_write
        mov rdx, num_buffer + 20                                        ; Point to the end of our buffer
        sub rdx, rdi                                                    ; Calculate the length of the number string
        sub rdx, 1                                                      ; Adjust length
        mov rsi, rdi                                                    ; Point rsi to the number string
        inc rsi                                                         ; Point rsi to the start of the number string
        mov rdi, 1                                                      ; File descriptor for stdout
        syscall                                                         ; Call kernel

        ; We will be using nanosleep syscall, which needs a pointer to a timespec struct.
        ; struct timespec {
        ;       long tv_sec;    /* seconds */
        ;       long tv_nsec;   /* nanoseconds */
        ; };
        ; We'll build this struct on the stack.
        sub rsp, 16                                                     ; Reserve 16 bytes space on the stack for struct
        mov qword [rsp], 1                                              ; tv_sec = 1
        mov qword [rsp+8], 1                                            ; tv_nsec = 0

        mov rax, 35                                                     ; Syscall number for sys_nanosleep
        mov rdi, rsp                                                    ; rdi points to our timespec struct on the stack
        syscall                                                         ; Call kernel

        add rsp, 16                                                     ; Clean up the stack by adding

        dec rbx                                                         ; Decrement the main counter
        jmp countdown_loop                                              ; Jump back to the start of our loop


exit_program:
        mov rax, 60                                                     ; Syscall number for exit
        xor rdi, rdi                                                    ; Exit code 0
        syscall                                                         ; Call kernel
