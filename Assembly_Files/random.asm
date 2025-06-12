section .data
        result_msg db "Your random number (0-100) is: ",0       ; Message for result
        result_msg_len equ $ - result_msg                       ; Message length

        newline db 0x0A                                         ; Newline character 


section .bss
        output_buffer resb 20                                   ; Buffer to hold our final number as a string


section .text
global _start                                                   ; This make the entry point visible to the linker

_start:
        ; We will use CPU's RDRAND instruction to generate number
        ; Refer to random_notes.md for more info
        ; NOTE: This requires a modern CPU (Intel Ivy Bridge+ or AMD Ryzen+)

.rdrand_loop:
        rdrand rax                                              ; Attempt to get a hardware random number into rax
        jnc .rdrand_loop                                        ; If Carry Flag is clear, it failed and loop again



        ; We'll use this formula to range between 0 and 100
        ; result = (random_number % range size) + min
        ; range_size = (max - min) + 1 = (100 - 0) + 1 = 101

        mov rbx, 101                                            ; Set the divisor to 101

        ; Division will be rax / rbx and rdx will hold the remainder
        ; rax already has a hardware random number
        xor rdx, rdx                                            ; Clear rdx to 0, where we're going to store our remainder
        div rbx                                                 ; Divide rax by rbx and store remainder in rdx

        mov rax, rdx                                            ; Move the final number into rax for conversion
        call itoa                                               ; Convert the integer into ASCII for printing out

        mov rax, 1                                              ; Syscall number for write
        mov rdi, 1                                              ; File Descriptor for stdout
        mov rsi, result_msg                                     ; Message
        mov rdx, result_msg_len                                 ; Message Length
        syscall                                                 ; Call kernel

        mov rax, 1                                              ; Syscall number for write
        mov rdi, 1                                              ; File Descriptor for stdout
        mov rsi, output_buffer                                  ; Our number
                                                                ; rdx already holds the length from the itoa
        syscall                                                 ; Call kernel

        mov rax, 1                                              ; Syscall number for write
        mov rdi, 1                                              ; File Descriptor for stdout
        mov rsi, newline                                        ; Newline
        mov rdx, 1                                              ; Only 1 length for newline
        syscall                                                 ; Call kernel

        mov rax, 60                                             ; Syscall number for exit
        xor rdi, rdi                                            ; Exit code
        syscall                                                 ; Call kernel


; Helper function to convert integer to ASCII
; Integer is in rax and ASCII value will be placed in output_buffer
; The length of the string will be in rdx
; This time we'll use different way for convertion, unlike we've done in addition.asm
itoa:
        mov rdi, output_buffer + 19                             ; Point to the end of buffer (Size is 20, so it's 20 - 1)
        mov byte [rdi], 0                                       ; Null-terminate the string
        dec rdi                                                 ; Decreasing the pointer
        mov rbx, 10                                             ; Setting a divisor 

        cmp rax, 0                                              ; See if the integer is fully converted or not (0 if done)
        jne .convert_loop                                       ; Jump to convert_loop
        mov byte [rdi], '0'                                     ; If number is 0, just put '0'
        dec rdi                                                 ; Decreasing rdi
        jmp .convert_done                                       ; Jump to end of our function



.convert_loop:
        xor rdx, rdx                                            ; Clear rdx for division
        div rbx                                                 ; rax / rbx (rax / 10), remainder is in rdx
        add rdx, '0'                                            ; Convert remainder (0-9) to ASCII ('0'-'9')
        mov [rdi], dl                                           ; Store the character in buffer
        dec rdi                                                 ; Move to the previous position in buffer
        cmp rax, 0                                              ; Is rax already 0? (i.e. operation over?)
        jne .convert_loop                                       ; If not, repeat the process

.convert_done:
        inc rdi                                                 ; Point back to the start of the number string
        mov rsi, rdi                                            ; rsi now holds the start address of the string

        mov rdx, output_buffer + 20                             ; Prepare to calculate the length of the string
        sub rdx, rsi                                            ; Length = (end of buffer + 1) - (start of string)
        ret                                                     ; Return to printing
