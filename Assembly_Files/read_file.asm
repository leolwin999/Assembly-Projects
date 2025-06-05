;Usage: Please provide the full path to the file if it's not in the same directory (e.g. /home/user/test.txt) 

section .data
        file_content_buffer_size equ 1024                       ; Size of the buffer to hold file content
        error_open_msg db "Error opening the file", 0xA         ; Error message (0xA is newline)
        error_open_msg_len equ $ - error_open_msg               ; Length of message
        error_read_msg db "Error reading the file", 0xA         ; Error message 
        error_read_msg_len equ $ - error_read_msg               ; Length of message
        prompt_msg db "Enter filename: ", 0                     ; Filename request message
        prompt_len equ $ - prompt_msg                           ; Length of message



section .bss
        file_content_buffer resb file_content_buffer_size       ; Reserve for file content
        filename_buffer resb 256                                ; Reserve for user input file name 


section .text
        global _start                                           ; This make the entry point visible to the linker

_start:
        ; Ask user for filename
        mov rax, 1                                              ; Syscall for write
        mov rdi, 1                                              ; File Descriptor - stdout
        mov rsi, prompt_msg                                     ; Message
        mov rdx, prompt_len                                     ; Length of Message
        syscall                                                 ; Call kernel

        ; Read filename
        mov rax, 0                                              ; Syscall for read
        mov rdi, 0                                              ; File Descriptor - stdin
        mov rsi, filename_buffer                                ; Buffer for File name
        mov rdx, 255                                            ; Length of buffer (Leave space for null terminator)
        syscall                                                 ; Call kernel

        ; The 'read' syscall will include the newline if user presses Enter, so we need to find the newline and replace it with a null terminator.
        ; rsi is filename_buffer and rax includes actual file name, so subtract 1 to remove newline and replace null terminator
        mov byte [rsi + rax -1], 0                              ; Replace newline or add null terminator


        ; Open the file
        mov rax, 2                                              ; Syscall for open
        mov rdi, filename_buffer                                ; const char *filename
        mov rsi, 0                                              ; Read-only flag (O_RDONLY)
        mov rdx, 0                                              ; mode (not need for O_RDONLY)
        syscall                                                 ; After kernel call, rax will contain the file descriptor or -1 if error

        cmp rax, 0                                              ; Check if syscall returned an error (negative value if error)
        jl _error_open                                          ; Jump to _error_open if rax < 0

        mov rdi, rax                                            ; Save the file descriptor(FD) for later (FD is now in rdi)

        ; Read the file content
        mov rax, 0                                              ; Syscall for read
                                                                ; rdi already contains the FD
        mov rsi, file_content_buffer                            ; Buffer for file content
        mov rdx, file_content_buffer_size                       ; Size for file content buffer
        syscall                                                 ; After kernel call, rax will contain number of bytes read or -1 if error

        cmp rax, 0                                              ; Check rax
        jl _error_read                                          ; Jump to _error_read if rax < 0

        mov rdx, rax                                            ; Save the number of bytes (length) to rdx

        ; Write the file content to stdout
        mov rax, 1                                              ; Syscall for write
        mov rdi, 1                                              ; File Descriptor - stdout
        mov rsi, file_content_buffer                            ; File contents
                                                                ; rdx has already a length (number of bytes to read)
        syscall                                                 ; Call kernel

        ; Close the file
        mov rax, 3                                              ; Syscall for close
                                                                ; rdi still holds the file descriptor from the open call
        syscall                                                 ; Call kernel

        jmp _exit                                               ; Jump to exit


_error_open:
        mov rax, 1                                              ; Syscall for write
        mov rdi, 2                                              ; File Descriptor - stderr
        mov rsi, error_open_msg                                 ; Message
        mov rdx, error_open_msg_len                             ; Message Length
        syscall                                                 ; Call kernel
        jmp _exit_error                                         ; Jump to _exit_error


_error_read:
        mov rax, 1                                              ; Syscall for write
        mov rdi, 2                                              ; File Descriptor - stderr
        mov rsi, error_read_msg                                 ; Message
        mov rdx, error_read_msg_len                             ; Message Length
        syscall                                                 ; Call kernel

        ; We still need to close the file
        mov rax, 3                                              ; Syscall for close
        syscall                                                 ; Call kernel

        jmp _exit_error                                         ; Jump to _exit_error

_exit:
        mov rax, 60                                             ; Syscall for exit
        xor rdi, rdi                                            ; Exit Code 0
        syscall                                                 ; Call kernel

_exit_error:
        mov rax, 60                                             ; Syscall for exit
        mov rdi, 1                                              ; Exit Code 1 (error)
        syscall
