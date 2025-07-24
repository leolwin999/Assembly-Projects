section .data
        domain equ 2                                            ; AF_INET (IPv4)
        type equ 1                                              ; SOCK_STREAM (TCP)
        protocol equ 0                                          ; Default protocol (IP)
        port equ 80                                             ; HTTP port

        ; IP address for google.com (142.250.4.100)
        ; In memory, this is stored in little-endian format.
        ; 100.4.250.142 --> 64.04.fa.8e(hex) --> 0x6404fa8e
        ; dd stands for Define Doubleword
        ip_addr dd 0x6404fa8e


        ; HTTP GET Request
        ; `\r\n` CRLF (Carriage Return and Line Feed) used to mark the end of a line in HTTP headers and to separate headers from the message body.
        ; CR (Carriage Return) - Represented by \r or %0d(13), it moves the cursor to the beginning of the current line without moving to the next line. 
        ; LF (Line Feed) - Represented by \n or %0a(10), it moves the cursor down to the next line without returning to the beginning of the line. 
        ; CRLF (\r\n) - This combination moves the cursor to the beginning of the next line, effectively creating a line break. 

        request: db "GET / HTTP/1.1", 13, 10
                 db "Host: google.com",13, 10
                 db "Connection: close",13, 10, 13, 10          ; Extra CRLF to end headers
        req_len: equ $ - request                                ; Request length

        msg_connecting: db "Connecting to google.com...", 10    ; Message for connecting
        msg_connecting_len: equ $ - msg_connecting              ; Message Length 

        msg_connected: db "Connected! Sending request...", 10   ; Message for connected 
        msg_connected_len: equ $ - msg_connected                ; Message Length

        msg_response: db 10, "---Server Response---",10         ; Message for respond
        msg_response_len: equ $ - msg_response                  ; Message Length

        msg_error: db "An error occurred!", 10                  ; Message for error
        msg_error_len: equ $ - msg_error                        ; Message Length

section .bss
        response_buf: resb 8192                                 ; Should be large enough for a simple homepage
        socket_fd: resq 1                                       ; Store socket file descriptor


section .text
        global _start                                           ; Make the entry point visible to the linker

_start:
        mov rax, 1                                              ; Syscall number for write
        mov rdi, 1                                              ; File descriptor for stdout
        mov rsi, msg_connecting                                 ; message to write
        mov rdx, msg_connecting_len                             ; message length
        syscall                                                 ; Call kernel

        mov rax, 41                                             ; Syscall number for socket (TCP socket)
        mov rdi, domain                                         ; AF_INET
        mov rsi, type                                           ; SOCK_STREAM
        mov rdx, 0                                              ; protocol (0 for IP)
        syscall                                                 ; Call kernel

        cmp rax, 0                                              ; Check for errors (negative value if error)
        jl _error_handler                                       ; Jump to error handler if rax is negative(error)

        mov [socket_fd], rax                                    ; Save the socket file descriptor in rax

        ; Prepare the server address structure (socketaddr_in)
        ; This structure tells the connect syscall where to connect.
        ; struct_sockaddr_in {
        ;       sa_family_t     sin_family;     // 2 bytes 
        ;       in_port_t       sin_port;       // 2 bytes
        ;       struct in_addr  sin_addr;       // 4 bytes
        ; };
        ; We gonna build this on the stack
        sub rsp, 16                                             ; Allocate space on the stack
        mov rdi, rsp                                            ; rdi now points to the start of our struct

        mov word [rdi], domain                                  ; sin_family = AF_INET (value=2) //2 bytes

        ; Port 80 will be big-endian (network byte order)
        ; 80 = 0x5000 (No need to change for 0x0050, which is little endian)
        ; Why 80 and not 443(https)? In 80(http), all communication is in plain, unencrypted text. This is simple and easy to work with
        mov word [rdi + 2], 0x5000                              ; sin_port = htons(80) // 2 bytes
        ; Why + 2? Because we have already allocated 2 bytes in sin_family
        ; The htons() function makes sure that numbers are stored in memory in network byte order
        ; htons() function is just an example for C. Don't get confused for that :) 

        mov eax, [ip_addr]                                      ; IP address is already in network byte order
        mov dword [rdi + 4], eax                                ; sin_addr

        mov rax, 42                                             ; Syscall number for connect
        mov rdi, [socket_fd]                                    ; Socket file descriptor (The sys_connect syscall requires its "first" argument to be the socket file descriptor)
                                                                ; rdi's values are struct and rdi's address is socket file descriptor
        mov rsi, rsp                                            ; Pointer to our sockaddr_in struct (rsp points to the start of our struct) 
        mov rdx, 16                                             ; size of the struct
        syscall                                                 ; Call kernel


        add rsp, 16                                             ; Clean up the stack

        cmp rax, 0                                              ; Check for error (negative value if error)
        jl _error_handler                                       ; Jump to error handler if rax is negative

        mov rax, 1                                              ; Syscall number for write
        mov rdi, 1                                              ; File descriptor for stdout
        mov rsi, msg_connected                                  ; Message for connected
        mov rdx, msg_connected_len                              ; Message length 
        syscall                                                 ; Call kernel

        mov rax, 44                                             ; Syscall number for send (sys_sendto)
        mov rdi, [socket_fd]                                    ; File descriptor for socket
        mov rsi, request                                        ; The request string
        mov rdx, req_len                                        ; Request string length
        mov r10, 0                                              ; Flags (use the standard, default behavior)
        syscall                                                 ; Call kernel

        mov rax, 1                                              ; Syscall number for write
        mov rdi, 1                                              ; File descriptor for stdout
        mov rsi, msg_response                                   ; Message for response
        mov rdx, msg_response_len                               ; Message length
        syscall                                                 ; Call kernel

_read_loop:
        mov rax, 45                                             ; Syscall number for receive (sys_recvfrom)
        mov rdi, [socket_fd]                                    ; File descriptor for socket
        mov rsi, response_buf                                   ; Buffer to store data
        mov rdx, 8192                                           ; Max buffer size
        mov r10, 0                                              ; Flags (use the standard, default behavior)
        syscall                                                 ; Call kernel

        ; rax now contains the number of bytes received
        ; if rax is 0, the server has closed the connection
        ; If rax is negative, there's an error
        cmp rax, 0                                              ; Check
        jle _close_socket                                       ; if rax <= 0, we are done reading

        mov rdx, rax                                            ; Move number of bytes to write to rdx (length)
        mov rax, 1                                              ; Syscall number for write
        mov rdi, 1                                              ; File descriptor for stdout
        mov rsi, response_buf                                   ; The buffer with the data
        syscall                                                 ; Call kernel


        jmp _read_loop                                          ; Go back and read more data


_error_handler:
        mov rax, 1                                              ; Syscall number for write
        mov rdi, 1                                              ; File descriptor for stdout
        mov rsi, msg_error                                      ; Message for error
        mov rdx, msg_error_len                                  ; Message Length
        syscall                                                 ; Call kernel
        jmp _exit_program                                       ; Jump to normal exit


_close_socket:
        mov rax, 3                                              ; Syscall number for close
        mov rdi, [socket_fd]                                    ; File descriptor for socket
        syscall                                                 ; Call kernel

_exit_program:
        mov rax, 60                                             ; Syscall number for exit
        xor rdi, rdi                                            ; Exit code 0
        syscall                                                 ; Call kernel

; Summary of steps
; 1) Make Socket
; 2) Create Socket
; 3) Connect
; 4) Send Request
; 5) Receive 
; 6) Close Socket
; 7) Exit
