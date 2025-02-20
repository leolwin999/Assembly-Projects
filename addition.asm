section .data
    prompt1 db "Enter the first number: ", 0
    prompt1_len equ $ - prompt1
    prompt2 db "Enter the second number: ", 0
    prompt2_len equ $ - prompt2
    result_msg db "The result is: ", 0xA, 0
    result_msg_len equ $ - result_msg
    buffer db 10          ; Buffer for storing the result as a string

section .bss
    input1 resb 10        ; Reserve space for first number input
    input2 resb 10        ; Reserve space for second number input

section .text
    global _start

_start:
    ; Asking for the first number
    mov rax, 1              ; syscall: write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, prompt1        ; pointer to first prompt
    mov rdx, prompt1_len    ; length of the message
    syscall

    ; Read the first number
    mov rax, 0              ; syscall: read
    mov rdi, 0              ; file descriptor: stdin
    mov rsi, input1         ; buffer to store input
    mov rdx, 10             ; max bytes to read
    syscall

    ; Ask for the second number
    mov rax, 1              ; syscall: write
    mov rdi, 1		        ; file descriptor: stdout
    mov rsi, prompt2	    ; pointer to second prompt
    mov rdx, prompt2_len    ; length of the message
    syscall

    ; Read the second number
    mov rax, 0              ; syscall: read
    mov rdi, 0		        ; file descriptor: stdin
    mov rsi, input2   	    ; buffer to store input
    mov rdx, 10		        ; max bytes to read
    syscall

    ; Convert first input from ASCII to integer
    mov rsi, input1	        ; move input to rsi register
    call atoi  		        ; call the function
    mov rbx, rax            ; store first number in rbx

    ; Convert second input from ASCII to integer
    mov rsi, input2	        ; move input to rsi register
    call atoi      	        ; call the function
    add rax, rbx            ; add the two numbers

    ; Clear the buffer before using it
    mov rdi, buffer	        ; Move buffer to rdi
    mov rcx, 10		        ; Make the loop 10 times
clear_buffer:
    mov byte [rdi], 0       ; Clear buffer by writing 0
    inc rdi	                ; Adds 1 to the register
    loop clear_buffer	    ; For looping 10 times

    ; Convert the result back to a string
    mov rsi, buffer	        ; Move buffer to rsi
    call itoa	    	    ; Call the function

    ; Print the result
    mov rax, 1		        ; syscall: write
    mov rdi, 1		        ; file descriptor: stdout
    mov rsi, result_msg     ; pointer to the result message
    mov rdx, result_msg_len ; length of the message
    syscall

    mov rax, 1		        ; syscall: write
    mov rdi, 1		        ; file descriptor: stdout
    mov rsi, buffer	        ; pointer to the actual result
    mov rdx, 10             ; max bytes to write
    syscall

    ; Exit the program
    mov rax, 60             ; syscall: exit
    xor rdi, rdi            ; exit code 0
    syscall

; Function: atoi (Convert ASCII to integer)
atoi:
    xor rax, rax            ; Clear rax (this will hold the result)
    xor rcx, rcx            ; Clear rcx (optional, sometimes used for a multiplier)
atoi_loop:
    movzx rdx, byte [rsi]   ; Load the next byte (character) from memory into rdx
    cmp rdx, 0xA            ; Check if the character is a newline ('\n')
    je atoi_done            ; Exit loop if newline
    sub rdx, '0'            ; Convert ASCII digit to number by subtracting e.g. 51 (Integer value for ASCII 3) - 48 (Integer value for ASCII 0) = 3 (Expected Integer Value)
    imul rax, rax, 10       ; Multiply current result by 10 (Shift digits left e.g. 3 * 10 = 30)
    add rax, rdx            ; Add the current digit to the result 
    inc rsi                 ; Move to the next character in the input string
    jmp atoi_loop	        ; Repeat the loop
atoi_done:
    ret			            ; Return from the function

; Function: itoa (Convert integer to ASCII)
itoa:
    xor rbx, rbx            ; Clear rbx (used as a counter)
itoa_loop:
    xor rdx, rdx            ; Clear rdx (rdx will store the remainder)
    mov rbx, 10             ; Divisor is 10 (decimal base)
    div rbx                 ; Divide rax by 10 (result in rax, remainder in rdx)
    add rdx, '0'            ; Convert remainder to ASCII by adding ASCII '0'  e.g. 3 + 48 (ASCII value for 0) = 51 (ASCII result for 3)
    dec rsi                 ; Move buffer pointer back
    mov [rsi], dl           ; Store the ASCII result character
    test rax, rax           ; Check if quotient is 0
    jnz itoa_loop           ; Repeat if not 0
    mov byte [rsi - 1], 0   ; Add null terminator
    ret			            ; Return from the function



