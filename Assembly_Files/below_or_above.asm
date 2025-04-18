;Checking Integer Number is in certain range (x,y)
;In this case (0,30)

section .data
prompt: db "Type your number: ", 0
prompt_len equ $ - prompt
yes: db "Yes, your number is in between.",0xa
yes_len equ $ - yes
no: db "No, it's not between.",0xa
no_len equ $ - no

section .bss
	usr_input resb 128

section .text
global _start

_start:
	
	mov rax, 1
	mov rdi, 1
	mov rsi, prompt
	mov rdx, prompt_len
	syscall

	mov rax, 0
	mov rdi, 0
	mov rsi, usr_input
	mov rdx, 128
	syscall

	mov rsi, usr_input
	call atoi

	mov rbx, rax
	cmp rbx, 0
	jl _no

	cmp rbx, 30
	jg _no

	mov rax, 1
	mov rdi, 1
	mov rsi, yes
	mov rdx, yes_len
	syscall

;You don't need to write "call exit" here for yes, because exit is next to this. Whether you call it or not, exit will be executed anyway. Assembly execute line by line.

exit:
	mov rax, 60
	xor rdi, rdi
	syscall


_no:
	mov rax, 1
	mov rdi, 1
	mov rsi, no
	mov rdx, no_len
	syscall
	call exit

atoi:
	xor rax, rax

atoi_loop:
	movzx rdx, byte[rsi]
	cmp rdx, 0xA
	je atoi_end
	sub rdx, '0'
	imul rax, rax, 10
	add rax, rdx
	inc rsi
	jmp atoi_loop
atoi_end:
	ret


