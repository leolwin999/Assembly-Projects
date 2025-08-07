section .data
        ask_password db "Enter the password: ", 0                       ; Message to ask the password
        ask_password_len equ $ - ask_password                           ; Message length

        access_g db "Access Granted!", 0xA                              ; Message for access granted
        access_g_len equ $ - access_g                                   ; Message length

        access_d db "Access Denied...", 0xA                             ; Message for access denied
        access_d_len equ $ - access_d                                   ; Message length

        real_password db "youareawesome999", 0xA                        ; Hard Coded password
        real_password_len equ $ - real_password                         ; Password length

section .bss
        user_input resb 100                                             ; Reserve 100 bytes for user input

section .text
        global _start                                                   ; Make the entry point visible to the linker

_start:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File Descriptor for stdout
        mov rsi, ask_password                                           ; Message to ask the password
        mov rdx, ask_password_len                                       ; Message length
        syscall                                                         ; Call kernel

        mov rax, 0                                                      ; Syscall number for read
        mov rdi, 0                                                      ; File Descriptor for stdin
        mov rsi, user_input                                             ; User input
        mov rdx, 100                                                    ; 100 bytes length for user input
        syscall                                                         ; Call kernel

        ; Note: 'read' returns the number of bytes read in RAX.
        ; This includes the newline character from pressing Enter.

        mov rsi, user_input                                             ; Points to the user input
        mov rdi, real_password                                          ; Points to the correct password
        mov rcx, real_password_len                                      ; rcx holds number of bytes to compare
        repe cmpsb                                                      ; repeat compare string byte-by-byte while they are equal

        ; REPE (repeat while equal) 
        ; In x86 assembly language, CMPSB (Compare Byte)  is a string instruction used to compare two bytes in memory.
        ; Unlike typical CMP instructions that take explicit operands, CMPSB uses implicit operands:

        ; The first byte to be compared is located at the memory address pointed to by DS:SI 
        ; (or DS:ESI in 32-bit mode, or RSI in 64-bit mode).
        ; The second byte to be compared is located at the memory address pointed to by ES:DI 
        ; (or ES:EDI in 32-bit mode, or RDI in 64-bit mode).

        ; The 'repe cmpsb' instruction compares bytes from [RSI] and [RDI]
        ; It decrements RCX for each byte compared.
        ; It stops if the bytes are not equal or if RCX becomes 0.
        ; If the passwords match for the full length, the Zero Flag (ZF) will be set.



        jne .denied                                                     ; Jump if Not Equal (ZF=0). Jump to the deny label.

.granted:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File Descriptor for stdout
        mov rsi, access_g                                               ; Access granted message
        mov rdx, access_g_len                                           ; Message length
        syscall                                                         ; Call kernel

.exit:
        mov rax, 60                                                     ; Syscall number for exit
        xor rdi, rdi                                                    ; Exit Code 0
        syscall                                                         ; Call kernel

.denied:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File Descriptor for stdout
        mov rsi, access_d                                               ; Access denied message
        mov rdx, access_d_len                                           ; Message length
        syscall                                                         ; Call kernel
        jmp .exit                                                       ; Jump to exit
