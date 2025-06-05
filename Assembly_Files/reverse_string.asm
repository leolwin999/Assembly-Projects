section .data
        SYS_READ equ 0                                  ; syscall number for read
        SYS_WRITE equ 1                                 ; syscall number for write
        SYS_EXIT equ 60                                 ; syscall number for exit


        STDIN equ 0                                     ; Standard input
        STDOUT equ 1                                    ; Standard output

        prompt_msg db "Enter a text: ", 0               ; Prompt message
        prompt_msg_len equ $ - prompt_msg -1            ; Length of Prompt ("-1" is for excluding null terminator) 

        reversed_msg db "Reversed text: ", 0            ; Reverse message

        reversed_msg_len equ $ - reversed_msg -1        ;Length of Reverse (Also, "-1" is for excluding null terminator)

        newline_char db 0Ah                             ; Newline character ('\n')
        newline_char_len equ 1


section .bss
        BUFFER_SIZE equ 256                             ; Buffer
        input_buffer resb BUFFER_SIZE                   ; Reserved


section .text
        global _start                                   ; This make the entry point visible to the linker

_start:
        ; Display message
        mov rax, SYS_WRITE                              ; Syscall for write
        mov rdi, STDOUT                                 ; Stdout
        lea rsi, [prompt_msg]                           ; Message to write
        mov rdx, prompt_msg_len                         ; Message length
        syscall                                         ; Call kernel


        ; Read user input
        mov rax, SYS_READ                               ; Syscall for read
        mov rdi, STDIN                                  ; Stdin
        lea rsi, [input_buffer]                         ; Buffer to store the input
        mov rdx, BUFFER_SIZE -1                         ; Max bytes to read 
        syscall                                         ; Call kernel



        mov r10, rax                                    ; Store the number of bytes read in r10

        cmp r10, 0                                      ; Compare bytes read if it's 0
        jle _exit_program                               ; If rax <= 0 (no input) then exit


        ; The read syscall includes the newline character if the user presses Enter ('\n' or '0A')
        dec r10                                         ; decrease by 1 which is to remove new line character 
        ; Now r10 contains the actual length of the string (without new line)



        lea rsi, [input_buffer]                         ; Pointer to the start of the string
        lea rdi, [input_buffer]                         ; Pointer to the  string
        add rdi, r10                                    ; Point to one byte past the ned
        dec rdi                                         ; Point to the last actual character (Now rdi points to the end of the string)

        ; Set up counter for the loop: length / 2
        ; We use rcx as the loop counter

        mov rcx, r10                                    ; Store number of bytes in rcx
        shr rcx, 1                                      ; Divide rcx by 2 (Shift Right)

        jz _print_reversed_prefix                       ; If rcx is 0, jump to print

reverse_loop:
        ; Loop to reverse the string
        mov al, [rsi]                                   ; Get char from start (byte in al)
        mov bl, [rdi]                                   ; Get char from end (byte in bl)
        mov [rsi], bl                                   ; Put char from end at start position
        mov [rdi], al                                   ; Put char from start at end position
        inc rsi                                         ; Move start pointer forward
        dec rdi                                         ; Move end pointer backward

        loop reverse_loop                               ; Decrese rcx, if rcx != 0, jump to reverse_loop again


_print_reversed_prefix:
        ; Print "Reversed string: "
        mov rax, SYS_WRITE                              ; Syscall for write
        mov rdi, STDOUT                                 ; Stdout
        lea rsi, [reversed_msg]                         ; Message
        mov rdx, reversed_msg_len                       ; Length of the message
        syscall                                         ; Call kernel


        ; Print the reversed string
        mov rax, SYS_WRITE                              ; Syscall for write
        mov rdi, STDOUT                                 ; Stdout
        lea rsi, [input_buffer]                         ; Reversed string which is now in buffer
        mov rdx, r10                                    ; Length of the reversed string
        syscall                                         ; Call kernel


        ; Print a newline character
        mov rax, SYS_WRITE                              ; Syscall for write
        mov rdi, STDOUT                                 ; Stdout
        lea rsi, [newline_char]                         ; Newline character
        mov rdx, newline_char_len                       ; Newline character length
        syscall                                         ; Call kernel


_exit_program:
        mov rax, SYS_EXIT                               ; syscall for exit
        xor rdi, rdi                                    ; exit code 0 
        syscall                                         ; Call kernel

