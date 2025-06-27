section .data

        msg_waiting db "Server is listening on port 8080...", 0ah       ; Listening message
        msg_waiting_len equ $ - msg_waiting                             ; Message length

        msg_received db "Message from Client: ", 0ah                    ; Indicator message
        msg_received_len equ $ - msg_received                           ; Message length

        msg_reply db "Hey There Client! Wassup! ", 0ah                  ; Message for client
        msg_reply_len equ $ - msg_reply                                 ; Message length

        err_socket_msg db "Error! Could not create socket.", 0ah        ; Error message for socket
        err_socket_msg_len equ $ - err_socket_msg                       ; Message length
        err_bind_msg db "Error! Could not bind to port.", 0ah           ; Error message for binding
        err_bind_msg_len equ $ - err_bind_msg                           ; Message length
        err_listen_msg db "Error! Could not listen on socket.", 0ah     ; Error message for listening
        err_listen_msg_len equ $ - err_listen_msg                       ; Message length
        err_accept_msg db "Error! Could not accept connection.", 0ah    ; Error message for accepting
        err_accept_msg_len equ $ - err_accept_msg                       ; Message length


section .bss
        client_msg_buffer resb 1024                                     ; Buffer for client message

section .text
        global _start                                                   ; This make the entry point visible to the linker

_start:

        mov rax, 41                                                     ; Syscall number for socket
        mov rdi, 2                                                      ; AF_INET for IPv4
        mov rsi, 1                                                      ; SOCK_STREAM for TCP
        xor rdx, rdx                                                    ; Default Protocol (Sets rdx to 0) 
        syscall                                                         ; Call kernel

        cmp rax, 0
        jl _socket_error                                                ; If rax < 0, jump to the error handler

        mov r12, rax                                                    ; Save the socket file descriptor in r12



        ; The following steps are exactly just like client

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
        push rdx                                                        ; Top of the stack becomes our values
        mov rsi, rsp                                                    ; rsi now points to the top of the stack

        mov rax, 49                                                     ; Syscall number for bind
        mov rdi, r12                                                    ; File descriptor from r12 (socket file descriptor)

        mov rdx, 16                                                     ; Size of our struct (values)
        syscall                                                         ; Call kernel


        cmp rax, 0                                                      ; Check connection errors
        jl _bind_error                                                  ; If rax < 0, jump to the error handler


        ; The stack pointer (rsp) was only used to point to the struct
        ; We can now clean up the stack by adding 8 bytes
        add rsp, 8


        mov rax, 50                                                     ; Syscall number for listen
        mov rdi, r12                                                    ; File descriptor from r12 (socket file descriptor)
        mov rsi, 10                                                     ; Backlog (Max number of pending connections in queue)

        syscall                                                         ; Call kernel

        cmp rax, 0                                                      ; If rax < 0, jump to error handler
        jl _listen_error

        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File descriptor for STDOUT
        mov rsi, msg_waiting                                            ; Message
        mov rdx, msg_waiting_len                                        ; Message_len
        syscall                                                         ; Call kernel


        mov rax, 43                                                     ; Syscall number for accept
        mov rdi, r12                                                    ; File descriptor from r12 (socket file descriptor)
        xor rsi, rsi                                                    ; NULL (0)
        xor rdx, rdx                                                    ; NULL (0)
        syscall                                                         ; Call kernel

        cmp rax, 0                                                      ; if rax < 0, jump to error handler
        jl _accept_error

        ; The new file descriptor for the client is now in rax
        mov r13, rax                                                    ; Save the file descriptor in r13


        mov rax, 0                                                      ; Syscall number for read
        mov rdi, r13                                                    ; File descriptor from r13 (client file descriptor)
        mov rsi, client_msg_buffer                                      ; Buffer to store client message
        mov rdx, 1024                                                   ; Max length for buffer
        syscall                                                         ; Call kernel



        mov r14, rax                                                    ; Save the number of bytes read in r14



        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File descriptor for STDOUT
        mov rsi, msg_received                                           ; Message
        mov rdx, msg_received_len                                       ; Message length 
        syscall                                                         ; Call kernel


        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 1                                                      ; File descriptor for STDOUT
        mov rsi, client_msg_buffer                                      ; Message from the client
        mov rdx, r14                                                    ; Message length that is stored in r14
        syscall                                                         ; Call kernel


        mov rax, 1                                                      ; Syscall number for write
        mov rdi, r13                                                    ; File descriptor from r13 (client file descriptor)
        mov rsi, msg_reply                                              ; Message to client 
        mov rdx, msg_reply_len                                          ; Message length
        syscall                                                         ; Call kernel


_close_sockets:
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

_bind_error:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 2                                                      ; File descriptor for STDERR
        mov rsi, err_bind_msg                                           ; Error Message
        mov rdx, err_bind_msg_len                                       ; Message length
        syscall                                                         ; Call kernel
        jmp _close_listening_socket_on_error                            ; Jump to the error

_listen_error:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 2                                                      ; File descriptor for STDERR
        mov rsi, err_listen_msg                                         ; Error message
        mov rdx, err_listen_msg_len                                     ; Message length
        syscall                                                         ; Call kernel
        jmp _close_listening_socket_on_error                            ; Jump to the error

_accept_error:
        mov rax, 1                                                      ; Syscall number for write
        mov rdi, 2                                                      ; File descriptor for STDERR
        mov rsi, err_accept_msg                                         ; Error Message
        mov rdx, err_accept_msg_len                                     ; Message Length
        syscall                                                         ; Call kernel
; Don't need to jump here, just fall through to close the listening socket

_close_listening_socket_on_error:
        mov rax, 3                                                      ; Syscall number for close
        mov rdi, 12                                                     ; File descriptor from r12 (socket file descriptor)
        syscall                                                         ; Call kernel
        jmp _exit                                                       ; Jump to exit

_exit:
        mov rax, 60                                                     ; Syscall number for exit
        mov rdi, rdi                                                    ; Sets rdi to 0
        syscall                                                         ; Call kernel

