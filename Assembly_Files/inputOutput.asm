section .data
	prompt db "Enter a message: ",0
	prompt_len equ $ - prompt

	msg db "You entered: ",0
	msg_len equ $ - msg

section .bss
	input resb 128				; Reserve 128 bytes for user input

section .text
	global _start

_start:
	; Print the Prompt
	mov rax, 1				; sys_write
	mov rdi, 1				; STDOUT
	mov rsi, prompt				; Address of the prompt
	mov rdx, prompt_len 			; Length of the prompt
	syscall

	; Read user input
	mov rax, 0				; sys_read
	mov rdi, 0				; STDIN
	mov rsi, input				; Address of the buffer
	mov rdx, 128				; Input size
	syscall
	mov r8, rax				; Save the number of bytes read into r8

	; Print "You entered: "
	mov rax, 1				; sys_write
	mov rdi, 1				; STDOUT
	mov rsi, msg				; Addess of the message
	mov rdx, msg_len			; Length of the message
	syscall

	mov rax, 1				; sys_write
	mov rdi, 1				; STDOUT
	mov rsi, input				; Address of the buffer (user input)
	mov rdx, r8				; Use the saved value in r8
	syscall

	; Exit program
	mov rax, 60				; sys_exit
	xor rdi, rdi				; Exit code 0
	syscall


