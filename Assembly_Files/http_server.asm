section .data
        ; -- HTTP Response Templates --
        ; Raw bytes that we'll be sending back to the browser

        ; CR = Carriage Return ( \r , 0x0d in hexadecimal, 13 in decimal) moves the cursor to the beginning of the line without advancing to the next line. 
        ; LF = Line Feed ( \n , 0x0a in hexadecimal, 10 in decimal) moves the cursor down to the next line without returning to the beginning of the line.

        ;The specific order in \r\n is crucial in the context of network protocols that adhere to the CRLF standard. Adhering to the \r\n convention ensures proper communication and avoids potential issues arising from non-standard line ending sequences.

        ; HTTP/1.1 200 OK response header
        http_200_header: db 'HTTP/1.1 200 OK', 0x0d, 0x0a, 'Content-Type: text/html', 0x0d, 0x0a, 'Connection: close', 0x0d, 0x0a
        len_http_200_header: equ $ - http_200_header

        ; HTTP/1.1 404 Not Found response
        http_404_response: db 'HTTP/1.1 404 Not Found', 0x0d, 0x0a, 'Connection: close', 0x0d, 0x0a, 'Content-Type: text/html', 0x0d, 0x0a, 0x0d, 0x0a, '<h1> 404 Not Found :( </h1>'
        len_http_404_response: equ $ - http_404_response

        ; String for the Content-Length header part
        content_len_str: db 'Content-Length: '
        len_content_len_str: equ $ - content_len_str

        ; Carriage return and line feed (CRLF) to separate headers and body.
        crlf: db 0x0d, 0x0a
        len_crlf: equ $ - crlf

        ; Error Message
        error_msg: db "An error has occurred X_X Quitting...", 0x0d, 0x0a, "Are you sure the port 8080 isn't being used?"
        len_error_msg: equ $ - error_msg


section .bss

        request_buffer: resb 4096                               ; To store the incoming HTTP request
        file_path_buffer: resb 256                              ; To store the parsed file path
        file_content_buffer: resb 1048576                       ; To hold the content of the file (1MB)
        content_len_buffer: resb 20                             ; To store file size for Content-Length header
        server_socket_fd: resq 1                                ; To hold the file descriptor for server socket
        client_socket_fd: resq 1                                ; To hold the file descriptor for client socket


section .text
        global _start                                           ; This make the entry point visible to linker


_start:
        ; -- Step 1: Create a TCP socket --
        mov rax, 41                                             ; Syscall number for socket()
        mov rdi, 2                                              ; AF_INET (IPv4)
        mov rsi, 1                                              ; SOCKET_STREAM (TCP)
        mov rdx, 0                                              ; Protocol (0 for defalut, which is IP)
        syscall                                                 ; Call kernel

        ; rax now holds the new socket file descriptor (or an error code if failed)

        cmp rax, 0                                              ; Compare rax with 0
        jl .exit_error                                          ; If rax < 0, there's an error 
        mov [server_socket_fd], rax                             ; Store the server socket file descriptor

        ; -- Step 2: Bind the socket to an address and port (0.0.0.0:8080) --

        ; We need to create a sockaddr_in struct in memory.
        ; struct sockaddr_in {
        ;       sa_family_t     sin_family;     /* address family: AF_INET */
        ;       in_port_t       sin_port;       /* port in network byte order */
        ;       struct in_addr  sin_addr;       /* internet address */
        ; };

        ; Start pushing our sockaddr_in struct down in the stack
        push dword 0x00000000                                   ; sin_addr (0.0.0.0 - listen on all interfaces)
        push word 0x901f                                        ; sin_port (port 8080 in network bytes order, 0x1f90)
        push word 2                                             ; sin_family (AF_INET)

        mov rax, 49                                             ; Syscall number for bind()
        mov rdi, [server_socket_fd]                             ; The socket to bind
        mov rsi, rsp                                            ; Pointer to sockaddr_in struct on the stack
        mov rdx, 16                                             ; Size of our struct
        syscall                                                 ; Call kernel

        add rsp, 16                                             ; Clean up the stack
        cmp rax, 0                                              ; Compare rax with 0
        jl .exit_error                                          ; If rax < 0, bind failed


        ; -- Step 3: Listen for incoming connections --
        mov rax, 50                                             ; Syscall number for listen()
        mov rdi, [server_socket_fd]                             ; The socket to listen on
        mov rsi, 10                                             ; Backlog (max number of pending connections)
        syscall                                                 ; Call kernel

        cmp rax, 0                                              ; Compare rax with 0
        jl .exit_error                                          ; If rax < 0, listen failed


.accept_loop:
        ; -- Step 4: Accept a new connection --
        mov rax, 43                                             ; Syscall number for accept()
        mov rdi, [server_socket_fd]                             ; The listening socket
        mov rsi, 0                                              ; NULL(0) We don't need client's address info
        mov rdx, 0                                              ; NULL(0)
        syscall                                                 ; Call kernel

        ; rax now holds the file descriptor for the new client connection

        cmp rax, 0                                              ; Compare rax with 0
        jl .accept_loop                                         ; If accept fails, try again.
        mov [client_socket_fd], rax                             ; Store the client socket fd

        ; -- Step 5: Read the HTTP request from the client --
        mov rax, 0                                              ; Syscall number for read()
        mov rdi, [client_socket_fd]                             ; Read from the client socket
        mov rsi, request_buffer                                 ; Store the request in our buffer
        mov rdx, 4096                                           ; Max bytes to read
        syscall                                                 ; Call kernel

        ; -- Step 6: Parse the request to get the file path --
        ; We're going to make a very simple parse: "GET /path/to/file HTTP/1.1" 
        ; We just want the "path/to/file" part

        mov rsi, request_buffer                                 ; rsi points to the start of the request
        mov rdi, file_path_buffer                               ; rdi points to where we'll store the path
        add rsi, 5                                              ; Skip "GET /" (5 words including space)

        ; If the request is just for "/", server "index.html" by default
        cmp byte [rsi], ' '                                     ; Check if there's nothing after "/"
        je .server_index                                        ; If equal, jump to index handler

.copy_path_loop:
        cmp byte [rsi], ' '                                     ; Stop when we hit the space before "HTTP:
        je .path_copied                                         ; If equal, jump to path handler
        movsb                                                   ; Copy bytes from [rsi] to [rdi] and increment both
        ; movsb instruction moves a single byte of data from a source memory location to a destination memory location.
        ; the movsb instruction moves data byte by byte
        jmp .copy_path_loop                                     ; Loop again to get full file path

.server_index:
        ; Copy "index.html" to the file path buffer
        mov rdi, file_path_buffer                               ; Move buffer to rdi
        mov rsi, .index_filename                                ; mov filename to rsi
        mov rcx, 10                                             ; number of times for rep instruction
        rep movsb
        ; when movsb is used with the rep (repeat) prefix, The rep prefix repeats the string instruction for the number of times specified in the rcx register.

        jmp .path_copied                                        ; After rep, jump to .path_copied
.index_filename: db 'index.html'                                ; Specify file name of index.html

.path_copied:
        mov byte [rdi], 0                                       ; Null-terminate the path string


        ; -- Step 7: Open the requested file --
        mov rax, 2                                              ; Syscall number for open()
        mov rdi, file_path_buffer                               ; The file path to open
        mov rsi, 0                                              ; O_RDONLY (Read only flag)
        mov rdx, 0                                              ; Mode (No need for open existing files)
        syscall                                                 ; Call kernel

        ; rax holds the file descriptor for the opend file, or -1 on error

        cmp rax, 0                                              ; Compare rax with 0
        jl .send_404                                            ; If rax < 0, it's a 404 error

        mov r12, rax                                            ; Save the file's fd in a safe register (r12)

        ; -- Step 8: Read the file's content into a buffer --
        mov rax, 0                                              ; Syscall number for read()
        mov rdi, r12                                            ; File descriptor of the file to read 
        mov rsi, file_content_buffer                            ; To put the contents into the buffer
        mov rdx, 1048576                                        ; Max file size to read (1MB)
        syscall                                                 ; Call kernel

        ; rax now holds the number of bytes read (file size)

        mov r13, rax                                            ; Save the file size in r13

        ; -- Step 9: Close the file --
        mov rax, 3                                              ; Syscall number for close()
        mov rdi, r12                                            ; File descriptor of the file to close
        syscall                                                 ; Call kernel

        ; -- Step 10: Convert file size to a string for the header --
        mov rax, r13                                            ; Move file size into rax for conversion
        mov rdi, content_len_buffer + 19                        ; Start converting from the end of buffer
        mov byte [rdi], 0xa                                     ; Newline character at the end
        dec rdi                                                 ; Decrease rdi by 1
        mov byte [rdi], 0xd                                     ; Carriage return 
        dec rdi                                                 ; Decrease rdi by 1
        mov rbx, 10                                             ; Set the divisor to 10
.itoa_loop:
        xor rdx, rdx                                            ; Clear rdx as we'll store remainder here
        div rbx                                                 ; rax = rax / rbx, remainder is in rdx
        add rdx, '0'                                            ; Convert remainder to ASCII digit
        mov [rdi], dl                                           ; Store the digit (dl is 8 bit register of rdx)
        dec rdi                                                 ; Decrease rdi by 1 for next digit
        test rax, rax                                           ; Is the quotient zero?
        jnz .itoa_loop                                          ; If not, loop again
        inc rdi                                                 ; Point rdi to the start of the number string
        mov r14, rdi                                            ; Save the pointer to the number string in r14

        ; Now r14 points to the start of the number string

        ; -- Step 11: Send the 200 OK response --
        ; Send the main header 
        mov rax, 1                                              ; Syscall number for write()
        mov rdi, [client_socket_fd]                             ; Write to  client socket
        mov rsi, http_200_header                                ; Header
        mov rdx, len_http_200_header                            ; Header Length
        syscall                                                 ; Call kernel

        ; Send "Content-Length: "
        mov rax, 1                                              ; Syscall number for write()
        mov rdi, [client_socket_fd]                             ; File descriptor for client socket
        mov rsi, content_len_str                                ; Content length
        mov rdx, len_content_len_str                            ; Size for Content length 
        syscall                                                 ; Call kernel

        ; Send the actual length string
        mov rax, 1                                              ; Syscall number for write()
        mov rdi, [client_socket_fd]                             ; File descriptor for client socket
        mov rsi, r14                                            ; Pointer to the start of the number string
        mov rdx, content_len_buffer + 20                        ; To get the actual length
        sub rdx, r14                                            ; Calculate the length of the number string
        syscall                                                 ; Call kernel

        ; Send the extra CRLF to separate headers from the body
        mov rax, 1                                              ; Syscall number for write()
        mov rdi, [client_socket_fd]                             ; File descriptor for client socket
        mov rsi, crlf                                           ; CRLF
        mov rdx, len_crlf                                       ; Size for CRLF
        syscall                                                 ; Call kernel

        mov rax, 1                                              ; File descriptor for write() 
        mov rdi, [client_socket_fd]                             ; File descriptor for client socket 
        mov rsi, file_content_buffer                            ; For file contents
        mov rdx, r13                                            ; The file size we saved earlier
        syscall                                                 ; Call kernel

        jmp .close_client                                       ; We're done, close the conection

.send_404:
        mov rax, 1                                              ; Syscall number for write()
        mov rdi, [client_socket_fd]                             ; File descriptor for client socket
        mov rsi, http_404_response                              ; Response for http 404
        mov rdx, len_http_404_response                          ; Size of http 404
        syscall                                                 ; Call kernel

.close_client:
        mov rax, 3                                              ; Syscall number for close()
        mov rdi, [client_socket_fd]                             ; File descriptor for client socket
        syscall                                                 ; Call kernel
        jmp .accept_loop                                        ; Go back and wait for the next connection

.exit_error:
        mov rax, 1                                              ; Syscall number for write()
        mov rdi, 2                                              ; File descriptor for stderr
        mov rsi, error_msg                                      ; Message
        mov rdx, len_error_msg                                  ; Message length
        syscall

        mov rax, 60                                             ; Syscall number for exit()
        mov rdi, 1                                              ; Exit with error code 1
        syscall                                                 ; Call kernel
