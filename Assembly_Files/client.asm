; Before running this program, make sure you've started a simple server to listen for our client:
; nc -l -p 8080 -k
; -l = listen mode
; -p = port (8080)
; -k = Forces nc to stay listening for another connection after its current connection is completed.


section .data
        msg db "Hello Server! This is client speaking..." , 0ah         ; The message to send to server
        msg_len equ $ - msg                                             ; Message length

        err_socket_msg db "Error! Creating socket failed.", 0ah         ; Socket creation failed error message
        err_socket_msg_len equ $ - err_socket_msg                       ; Message length
        err_connect_msg db "Error! Connecting to server failed.", 0ah   ; Server connection failed error message
        err_connect_msg_len equ $ - err_connect_msg                     ; Message length
        err_write_msg db "Error! Writing to socket failed.", 0ah        ; Write to socket failed error message
        err_write_msg_len equ $ - err_write_msg                         ; Message length
        err_read_msg db "Error! Reading from socket failed.", 0ah       ; Read from socket failed error message
        err_read_msg_len equ $ - err_read_msg                           ; Message length


section .bss
        response_buffer resb 1024                                       ; A 1KB buffer to store server's response

section .text
        global _start                                                   ; This make the entry point visible to the linker

_start:
        mov rax, 41                                                     ; Syscall number for socket
        mov rdi, 2                                                      ; AF_INET for IPv4
        mov rsi, 1                                                      ; SOCK_STREAM for TCP
        xor rdx, rdx                                                    ; Default Protocol (Sets rdx to 0) 
        syscall                                                         ; Call kernel

        ; The socket descriptor (a file handle) is returned in rax.
        ; We need to check for errors as syscall returns a negative value on error
        cmp rax, 0
        jl _socket_error                                                ; If rax < 0, jump to the error handler

        mov r12, rax                                                    ; Save the socket file descriptor in r12
                                                                        ; r12 is a callee-saved register


        ; sockaddr_in is a protocol-specific structure for IPv4


        ; We need to create the 'sockaddr_in' structure on the stack.
        ; struct sockaddr_in {
        ;   sa_family_t    sin_family; /* address family: AF_INET */
        ;   in_port_t      sin_port;   /* port in network byte order */
        ;   struct in_addr sin_addr;   /* internet address */
        ; };


        ; We have to build this structure ourselves in memory. 
        ; All values must be in network byte order (Big Endian).
        ; IP Address: 127.0.0.1 --> (in hex) 0x7F000001
        ; Port: 8080 --> (in hex)  0x1F90
        ; Family AF_INET for IPv4: 2 --> (in hex) 0x2000


        ; The whole struct in one go (Little-endian storage)
        ; 0x0100007F + 0x901F + 0x0002

        mov rdx, 0x0100007F901F0002                                     ; Move the whole values into rdx


        ; We cleverly push all 16 bytes of this structure (values) onto the stack with a single push instruction
        push rdx                                                        ; Top of the stack becomes our values pointed by rsi
        mov rsi, rsp                                                    ; rsi now points to the top of the stack

        mov rax, 42                                                     ; Syscall number for connect
        mov rdi, r12                                                    ; File descriptor from r12 (socket file descriptor)

        mov rdx, 16                                                     ; Size of our struct (values)
        syscall                                                         ; Call kernel

        cmp rax, 0                                                      ; Check connection errors
        jl _connect_error                                               ; If rax < 0, jump to the error handler


        ; The stack pointer (rsp) was only used to point to the struct
        ; We can now clean up the stack by adding 8 bytes
        add rsp, 8


        mov rax, 1                                                      ; Syscall number for write
        mov rdi, r12                                                    ; File descriptor from r12 (socket file descriptor)
        mov rsi, msg                                                    ; Pointer to our message
        mov rdx, msg_len                                                ; Length of our message
        syscall                                                         ; Call kernel

        cmp rax, 0                                                      ; Check error
        jl _write_error                                                 ; If rax < 0, jump to the error handler


        mov rax, 0                                                      ; Syscall number for read
        mov rdi, r12                                                    ; File descriptor from r12 (socket file descriptor)
        mov rsi, response_buffer                                        ; Pointer to our buffer
        mov rdx, 1024                                                   ; Size of our buffer
        syscall                                                         ; Call kernel

        cmp rax, 0                                                      ; Check error
        jl _read_error                                                  ; If rax < 0, jump to error handler


        ; rax will hold the number of bytes read. We need this value for later.
        mov r13, rax                                                    ; Save byte count in r13

        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File descriptor for STDOUT
        mov rsi, response_buffer                                        ; Pointer to our buffer (where message was stored)
        mov rdx, r13                                                    ; Number of bytes read from the socket (stored in r13)
        syscall                                                         ; Call kernel

_close:
        mov rax, 3                                                      ; Syscall number for close
        mov rdi, r12                                                    ; File descriptor from r12 (socket file descriptor)
        syscall                                                         ; Call kernel
        jmp _exit                                                       ; Jump to the main exit routine


_socket_error:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 2                                                      ; File descriptor for STDERR
        mov rsi, err_socket_msg                                         ; Error Message
        mov rdx, err_socket_msg_len                                     ; Message Length
        syscall                                                         ; Call kernel
        jmp _exit                                                       ; Jump to the main exit routine

_connect_error:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 2                                                      ; File descriptor for STDERR
        mov rsi, err_connect_msg                                        ; Error Message
        mov rdx, err_connect_msg_len                                    ; Message Length
        syscall                                                         ; Call kernel
        jmp _close                                                      ; Still try to close the socket if fails

_write_error:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 2                                                      ; File descriptor for STDERR
        mov rsi, err_write_msg                                          ; Error Message
        mov rdx, err_write_msg_len                                      ; Message Length
        syscall                                                         ; Call kernel
        jmp _close                                                      ; Still try to close the socket if fails

_read_error:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 2                                                      ; File descriptor for STDERR
        mov rsi, err_read_msg                                           ; Error Message
        mov rdx, err_read_msg_len                                       ; Message Length
        syscall                                                         ; Call kernel
        jmp _close                                                      ; Still try to close the socket if fails


_exit:
        mov rax, 60                                                     ; Syscall number for write
        mov rdi, rdi                                                    ; Sets rdi to 0
        syscall                                                         ; Call kernel
