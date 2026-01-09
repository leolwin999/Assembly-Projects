default rel                                     ; Use relative addressing

section .data
        proc_base db "/proc/", 0                ; Base path to scan
        comm_suffix db "/comm", 0               ; File inside PID folder (contains the command name associated with the process)
        file_out db "processes.txt", 0          ; Output filename

        header      db "PID     PROCESS NAME", 10, "---------------------", 10, ; Header line
        space db " "                            ; Space character for padding
        newline db 10                           ; Newline character

        COL_WIDTH equ 8                         ; We reserve 8 chars for the PID column

section .bss
        fd_proc resq 1                          ; To hold File Descriptor 
        fd_out resq 1                           ; To hold File Descriptor
        fd_comm resq 1                          ; To hold File Descriptor

        dir_buffer resb 4096                    ; 4KB buffer for raw directory entries
        path_buffer resb 256                    ; Buffer to build string (e.g. "/proc/1234/comm")
        name_buffer resb 256                    ; Buffer to hold the process name (e.g. "bash")

section .text
        global _start                           ; This make the entry point visible to the linker


_start:
        ; STEP 1 : OPEN THE /PROC DIRECTORY
        mov rax, 2                              ; Syscall number for open
        lea rdi, [proc_base]                    ; Arg1: Path "/proc"
        mov rsi, 0x10000                        ; Arg2: Flags (O_RDONLY | O_DIRECTORY)
                                                ; No need rdx here
        syscall                                 ; Call kernel

        cmp rax, 0                              ; Check if open failed (negative result for error)
        jl .exit_error                          ; If negative, jump to error handler
        mov [fd_proc], rax                      ; Save the file descriptor



        ; STEP 2: OPEN / CREATE OUTPUT FILE
        mov rax, 2                              ; Syscall number for open
        lea rdi, [file_out]                     ; Arg1: "processes.txt"
        mov rsi, 65                             ; Arg2: Flags (O_WRONLY | O_CREAT)
        mov rdx, 0644o                          ; Arg3: Mode (File permissions rw-r--r--)
        syscall                                 ; Call kernel
        mov [fd_out], rax                       ; Save the file descriptor



        ; STEP 3: WRITE THE HEADER
        lea rsi, [header]                       ; Address of header string
        call _strlen                            ; Calculate its length and put into RDX

        mov rax, 1                              ; Syscall number for write
        mov rdi, [fd_out]                       ; Write to output file
                                                ; RSI already loaded
                                                ; RDX already calculated
        syscall                                 ; Call kernel



        ; STEP 4: MAIN LOOP - READ DIRECTORY ENTRIES 
.loop_dir:
        ; getdents64 read the contents (names, inode numbers, types) of an open directory into a buffer, providing access to directory entries for tasks like listing files.
        mov rax, 217                            ; Syscall number for getdents64
        mov rdi, [fd_proc]                      ; Read from /proc
        lea rsi, [dir_buffer]                   ; To store in our buffer
        mov rdx, 4096                           ; Read up to 4KB
        syscall                                 ; Call kernel

        test rax, rax                           ; Check return value
        jz .finished                            ; If 0, we are done (EOF)
        js .finished                            ; If negative, error (exit too)

        mov r12, rax                            ; R12 becomes total bytes read from directory
        xor r13, r13                            ; R13 current offset (cursor) in buffer

        ; STEP 5: PARSE INDIVIDUAL ENTRIES
.parse_buffer:
        lea rbx, [dir_buffer + r13]             ; RBX points to current entry struct
        movzx r14, word [rbx + 16]              ; R14 = d_reclen (Size of this entry)
        lea rsi, [rbx + 19]                     ; RSI points to d_name (The filename/PID)

        ; To check if filename is a PID (starts with digit) 
        mov al, [rsi]                           ; Move into 8 bit register
        cmp al, '0'                             ; Compare with ascii 0 (48 in value)
        jl .next_entry                          ; If char < '0', skip
        cmp al, '9'                             ; Compare with ascii 9 (57 in value)
        jg .next_entry                          ; If char > '9', skip



        ; STEP 6: PRINT THE PID
        ; A. Calculate PID length
        push rsi                                ; Save RSI (PID string pointer)
        call _strlen                            ; Returns length in RDX
        mov r15, rdx                            ; Store PID length n R15 for padding math later
        pop rsi                                 ; Restore RSI

        ; B. Write PID to file
        mov rax, 1                              ; Syscall number for write
        mov rdi, [fd_out]                       ; Write to output file 
                                                ; RSI is already calculated
                                                ; RDX is already calculated with _strlen function
        syscall                                 ; Call kernel

        ; C. Print Padding (Spaces)
        mov rcx, COL_WIDTH                      ; Logic is "Count = COL_WIDTH - PID_Length"
        sub rcx, r15                            ; Subtract actual length from target width
        cmp rcx, 0                              ; Safety check (if PID is huge)
        jle .path_construction                  ; If no padding needed, move on

.pad_loop:
        push rcx                                ; Save loop counter (Syscalls will destroy rcx)
        mov rax, 1                              ; Syscall number for write
        mov rdi, [fd_out]                       ; Write to output file
        lea rsi, [space]                        ; Space character for padding
        mov rdx, 1                              ; Just 1 bit
        syscall                                 ; Call kernel

        pop rcx                                 ; Restore counter
        dec rcx                                 ; Decrease counter by 1
        jnz .pad_loop                           ; Loop again if not 0



        ; STEP 7: CONSTRUCT PATH & READ NAME
        ; Build string: "/proc/" + PID + "/comm"
.path_construction:
        lea rsi, [rbx + 19]                     ; Point RSI back to PID string in directory buffer

        ; A. Copy "/proc/"
        lea rdi, [path_buffer]                  ; Destination 
        lea r8, [proc_base]                     ; Source
        call _strcpy                            ; Copy (Updates RDI to end of string)

        ; B. Append PID
        lea r8, [rsi]                           ; Source is the PID (From directory)
        call _strcpy                            ; Copy

        ; C. Append "/comm"
        lea r8, [comm_suffix]                   ; Source is /comm
        call _strcpy                            ; Copy

        ; D. Open the constructed path
        mov rax, 2                              ; Syscall number for open
        lea rdi, [path_buffer]                  ; To put into buffer
        mov rsi, 0                              ; O_RDONLY
        syscall                                 ; Call kernel

        cmp rax, 0                              ; Compare with 0 for error
        jl .next_entry                          ; If we can't open (permission issues), skip
        mov [fd_comm], rax                      ; Store the file descriptor

        ; E. Read the process name
        mov rax, 0                              ; Syscall number for read
        mov rdi, [fd_comm]                      ; Read from /comm
        lea rsi, [name_buffer]                  ; To put into name buffer
        mov rdx, 256                            ; 256 bytes for size
        syscall                                 ; Call kernel
        mov r15, rax                            ; Save bytes read (Name Length)

        ; F. Close the file
        mov rax, 3                              ; Syscall number for close
        mov rdi, [fd_comm]                      ; To close /comm
        syscall                                 ; Call kernel



        ; STEP 8: WRITE PROCESS NAME
        mov rax, 1                              ; Syscall number for write 
        mov rdi, [fd_out]                       ; Read to output file
        lea rsi, [name_buffer]                  ; To put into name buffer
        mov rdx, r15                            ; Length of name
        syscall                                 ; Call kernel
        ; 'comm' file includes a newline, so we don't need to add one. 



        ; STEP 9: ADVANCE TO NEXT DIRECTORY ENTRY
.next_entry:
        add r13, r14                            ; Current Offset += Record Length
        cmp r13, r12                            ; Have we processed all bytes in buffer? 
        jl .parse_buffer                        ; If not, loop back
        jmp .loop_dir                           ; If yes, go get more directory entries

.finished:
        mov rax, 3                              ; Syscall number for close
        mov rdi, [fd_proc]                      ; To close /proc
        syscall                                 ; Call kernel

        mov rax, 3                              ; Syscall number for close
        mov rdi, [fd_out]                       ; To close a file
        syscall                                 ; Call kernel

.exit_error:
        mov rax, 60                             ; Syscall number for exit
        xor rdi, rdi                            ; Return code 0
        syscall                                 ; Call kernel



        ; HELPER FUNCTIONS
_strcpy:
        mov al, [r8]                            ; Move into 8 bit register
        test al, al                             ; Check for null terminator (0)
        jz .done_copy                           ; If 0, we're done
        mov [rdi], al                           ; Copy byte
        inc rdi                                 ; Move Dest forward
        inc r8                                  ; Move Src forward
        jmp _strcpy                             ; Loop again
.done_copy:
        mov byte [rdi], 0                       ; Ensure null termination
        ret                                     ; Return from the function 



_strlen:                                        ; Calculates string length (Input is RSI (Source String)  and Output is RDX (Length))
        mov rdx, 0                              ; Set RDX to 0
.len_loop:
        cmp byte [rsi + rdx], 0                 ; Check for null terminator 
        je .len_done                            ; Jump to done if 0
        inc rdx                                 ; Increase RDX by 1
        jmp .len_loop                           ; Loop again
.len_done:
        ret                                     ; Return from the function
