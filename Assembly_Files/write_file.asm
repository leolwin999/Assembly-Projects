 section .data

        filename db "text.txt", 0                                       ; File name with null-terminated

        content db "Hello Friend!", 0xA                                 ; Texts to write to file
        content_len equ $ - content                                     ; Length of the content

        error_open_msg db "Error! Couldn't open or create a file.", 0xA ; Error message for open
        error_open_msg_len equ $ - error_open_msg                       ; Error message length

        error_write_msg db "Error! Couldn't write to a file.", 0xA      ; Error message for write
        error_write_msg_len equ $ - error_write_msg                     ; Error message length

section .text
        global _start                                                   ; Make the entry point visible to the linker

_start:
        ; 'Open' syscall needs specific flags to write, create and truncate (overwrite).
        ; O_WRONLY (write-only) = 1
        ; O_CREAT (create if not exists) = 64 
        ; O_TRUNC (truncate to zero length if exists) = 512 
        ; truncate means removing characters, digits, or bytes from the end.
        ; Combine them: 1 + 64 + 512 = 577
        ; Why Combine them? Imagine they are switches and we need to turn them on.
        ; Each switch is represented by a single bit in a number.

        ;  ...000000000001  (1, write-only)
        ;  ...000100000000  (64, create)
        ;+ ...100000000000  (512, truncate) 
        ;------------------
        ;  ...100100000001  (577, all three switches are turned on by changing bits from 0 to 1)

        ; Basically, we've performed a bitwise 'OR' operation

        ; The mode (permissions) is required when using O_CREAT.
        ; 0644o means owner can read/write, group can read, others can read
        ; Same as `chmod 644 text.txt`

        mov rax, 2                                                      ; Syscall number for 'open'
        mov rdi, filename                                               ; 1st arg: address of the filename string.
        mov rsi, 577                                                    ; 2nd arg: flags (O_WRONLY + O_CREAT + O_TRUNC)
        mov rdx, 0644o                                                  ; 3rd arg: mode (permissions), 'o' is for octal
        syscall                                                         ; Call kernel

        ; Registers are used differently here. Please refer to "purpose_of_registers.md" for more info.

                                                                        ; rax will hold the file descriptor or an error
        cmp rax, 0                                                      ; Compare return value in rax with 0
        jl _error_open                                                  ; If rax is less than 0 (error), jump to error handler



        mov rdi, rax                                                    ; Save the file descriptor in rdi for next syscall

        mov rax, 1                                                      ; Syscall number for 'write'
                                                                        ; rdi already contains the file descriptor
        mov rsi, content                                                ; address of the content to write
        mov rdx, content_len                                            ; Number of bytes to write (length)
        syscall                                                         ; Call kernel

        cmp rax, 0                                                      ; Check for an error (Negative value returned)
        jl _error_write                                                 ; Jump to the write error handler


        mov rax, 3                                                      ; Syscall number for 'close'
                                                                        ; rdi still holds the file descriptor
        syscall                                                         ; Call kernel

        jmp _exit                                                       ; Jump to the normal exit routine


_error_open:
        mov rax, 1                                                      ; Syscall number for 'write'
        mov rdi, 2                                                      ; File Descriptor for 'stderr'
        mov rsi, error_open_msg                                         ; Address of the error message
        mov rdx, error_open_msg_len                                     ; Length of the message
        syscall                                                         ; Call kernel
        jmp _exit_error                                                 ; Jump to the error exit

_error_write:
        mov rax, 1                                                      ; Syscall number for 'write'
        mov rdi, 2                                                      ; File Descriptor for 'stderr'
        mov rsi, error_write_msg                                        ; Address of the error message
        mov rdx, error_write_msg_len                                    ; Length of the message
        syscall                                                         ; Call kernel

        ; We should close the file, even if writing failed.
        mov rax, 3                                                      ; Syscall number for 'close'
                                                                        ; rdi still has a file descriptor from earlier
        syscall                                                         ; Call kernel

        jmp _exit_error                                                 ; Jump to the error exit

_exit:
        mov rax, 60                                                     ; Syscall number for 'exit'
        xor rdi, rdi                                                    ; Exit code 0 for success
        syscall                                                         ; Call kernel

_exit_error:
        mov rax, 60                                                     ; Syscall number for 'exit'
        mov rdi, 1                                                      ; Exit code 1 for error
        syscall                                                         ; Call kernel
