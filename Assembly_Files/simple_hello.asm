section .data
	message: db "Hello, Friend", 10
	message_len: equ $ - message

section .text
	global _start
_start:
	; Print Message
	mov rax, 1		; system call write
	mov rdi, 1		; file descriptor stdout
	mov rsi, message	; pointer to Hello, Friend
	mov rdx, message_len 	; length of message
	syscall	

	; Exit the Program
	mov rax, 60		; syscall exit
	xor rdi, rdi		; exit code 0
	syscall
		
	
	
	
