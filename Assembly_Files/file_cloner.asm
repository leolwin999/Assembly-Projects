section .data
        source_file db "source.txt", 0                                          ; Source File name
        dest_file db "destination.txt", 0                                       ; Destination File name

        success_msg db "File cloned successfully :)", 0xA                       ; Successful message
        success_msg_len equ $ - success_msg                                     ; Message length

        error_open_source_msg db "Couldn't open the source file :(",0xA         ; Error open source message
        error_open_source_msg_len equ $ - error_open_source_msg                 ; Message length

        error_open_dest_msg db "Couldn't open the destination file :(",0xA      ; Error open destination message
        error_open_dest_msg_len equ $ - error_open_dest_msg                     ; Message length

        error_read_msg db "Couldn't read from the source file :(",0xA           ; Error read from source message
        error_read_msg_len equ $ - error_read_msg                               ; Message length

        error_write_msg db "Couldn't write to the destination file :(",0xA      ; Error write to destination message
        error_write_msg_len equ $ - error_write_msg                             ; Message length

        BUFFER_SIZE equ 4096                                                    ; A 4KB buffer for I/O (read and write)

section .bss
        buffer resb BUFFER_SIZE                                                 ; The temporary storage for copying data
        source_fd resq 1                                                        ; To store source file descriptor
        dest_fd resq 1                                                          ; To store destination file descriptor

section .text
        global _start                                                           ; This make the entry point visible to the linker


_start:
        mov rax, 2                                                              ; Syscall for open
        mov rdi, source_file                                                    ; File to open
        mov rsi, 0                                                              ; Flags (0 = O_RDONLY, read-only)
        syscall                                                                 ; Call kernel
        cmp rax, 0                                                              ; Check for error
        jl _error_open_source                                                   ; If rax is negative, jump to error handler
        mov [source_fd], rax                                                    ; rax contains the source file descriptor, so save it

        mov rax, 2                                                              ; Syscall for open
        mov rdi, dest_file                                                      ; File to create/open
        mov rsi, 577                                                            ; Flags (O_WRONLY | O_CREAT | O_TRUNC) 
        mov rdx, 0644o                                                          ; Mode (Permissions in octal)
        syscall                                                                 ; Call kernel
        cmp rax, 0                                                              ; Check for error
        jl _error_open_dest                                                     ; If rax is negative, jump to error handler
        mov [dest_fd], rax                                                      ; rax contains the destination file descriptor, so save it

_copy_loop:
        mov rax, 0                                                              ; Syscall for read
        mov rdi, [source_fd]                                                    ; File descriptor for read from
        mov rsi, buffer                                                         ; Store read data into buffer
        mov rdx, BUFFER_SIZE                                                    ; Max number of bytes to read
        syscall                                                                 ; Call kernel

        cmp rax, 0                                                              ; Compare rax with 0
        jl _error_read                                                          ; If rax is negative, jump to error handler
        je _success                                                             ; If rax is 0, we've reached the end of the file. Finish it!

        mov r10, rax                                                            ; Save the number of bytes read into r10

        mov rax, 1                                                              ; Syscall for write
        mov rdi, [dest_fd]                                                      ; File descriptor to write to
        mov rsi, buffer                                                         ; Write data from buffer(Source file contents)
        mov rdx, r10                                                            ; Number of bytes to write 
        syscall                                                                 ; Call kernel

        cmp rax, 0                                                              ; Compare rax with 0
        jl _error_write                                                         ; If rax is zero, jump to error handler

        jmp _copy_loop                                                          ; Go back to the start of the loop for the next chunk 

_success:
        mov rax, 3                                                              ; Syscall for close
        mov rdi, [source_fd]                                                    ; File descriptor for source file
        syscall                                                                 ; Call kernel

        mov rax, 3                                                              ; Syscall for close
        mov rdi, [dest_fd]                                                      ; File descriptor for destination file
        syscall                                                                 ; Call kernel

        mov rax, 1                                                              ; Syscall for write
        mov rdi, 1                                                              ; File descriptor for stdout
        mov rsi, success_msg                                                    ; Message for success
        mov rdx, success_msg_len                                                ; Message length
        syscall                                                                 ; Call kernel

        jmp _exit                                                               ; Jump to exit

_error_open_source:
        mov rax, 1                                                              ; Syscall for write
        mov rdi, 2                                                              ; File descriptor for stderr
        mov rsi, error_open_source_msg                                          ; Message for Error
        mov rdx, error_open_source_msg_len                                      ; Message length
        syscall                                                                 ; Call kernel
        jmp _exit_error                                                         ; Jump to error exit

_error_open_dest:
        mov rax, 1                                                              ; Syscall for write
        mov rdi, 2                                                              ; File descriptor for stderr
        mov rsi, error_open_dest_msg                                            ; Message for Error
        mov rdx, error_open_dest_msg_len                                        ; Message length
        syscall                                                                 ; Call kernel

        ; Close the source file before exiting (Must!)
        mov rax, 3                                                              ; Syscall for close
        mov rdi, [source_fd]                                                    ; File descriptor for source file
        syscall                                                                 ; Call kernel
        jmp _exit_error                                                         ; Jump to error exit

_error_read:
        mov rax, 1                                                              ; Syscall for write
        mov rdi, 2                                                              ; File descriptor for stderr
        mov rsi, error_read_msg                                                 ; Message for Error
        mov rdx, error_read_msg_len                                             ; Message length
        syscall                                                                 ; Call kernel
        jmp _close_files_and_exit_error                                         ; Jump to specific error

_error_write:
        mov rax, 1                                                              ; Syscall for write
        mov rdi, 2                                                              ; File descriptor for stderr
        mov rsi, error_write_msg                                                ; Message for Error
        mov rdx, error_write_msg_len                                            ; Message length
        syscall                                                                 ; Call kernel
        ; Fall through to close files and exit

_close_files_and_exit_error:
        mov rax, 3                                                              ; Syscall for close
        mov rdi, [source_fd]                                                    ; File descriptor for source file
        syscall                                                                 ; Call kernel

        mov rax, 3                                                              ; Syscall for close
        mov rdi, [dest_fd]                                                      ; File descriptor for destination file
        syscall                                                                 ; Call kernel
        jmp _exit_error                                                         ; Jump to error exit

_exit:
        ; normal exit
        mov rax, 60                                                             ; Syscall for exit
        xor rdi, rdi                                                            ; Exit code 0
        syscall                                                                 ; Call kernel

_exit_error:
        ; error exit
        mov rax, 60                                                             ; Syscall for exit
        xor rdi, rdi                                                            ; Exit code 0
        syscall                                                                 ; Call kernel
