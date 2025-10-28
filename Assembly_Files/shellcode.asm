section .data
        shell_str: db "/bin/bash", 0                            ; Define the string "/bin/bash"

section .text
        global _start                                           ; This make the entry point visible to the linker

_start:
        mov rax, 59                                             ; Syscall number for execve, which executes a new program
        ; Now we set up the arguments for execve.
        ; The 'man 2 execve' page shows the C signature:
        ; int execve(const char *pathname, char *const argv[], char *const envp[]);



        ; 1st argument (pathname) goes in 'rdi'
        lea rdi, [rel shell_str]                                ; 'lea' (Load Effective Address) gets the memory address of our string
        ; The 'rel' keyword specifies RIP-relative addressing. 
        ; The RIP register holds the address of the next instruction to be executed.
        ; When you use [rel shell_str], the assembler calculates the difference (or offset) between the current RIP and the address of shell_str



        ; 2nd argument (argv) goes in 'rsi'
        mov rsi, 0                                              ; We don't have any arguments so pass NULL (0)



        ; 3rd argument (envp) goes in 'rdx'
        mov rdx, 0                                              ; We don't have any environment variables so pass NULL (0)
        syscall                                                 ; Call kernel

        ; In case, the system fails, i.e., /bin/bash doesn't exist, the kernel will return control to us.
        ; We should then exit gracefully.
        mov rax, 60                                             ; Syscall for exit
        mov rdi, 1                                              ; Exit with code 1 to signal an error
        syscall                                                 ; Call kernel
