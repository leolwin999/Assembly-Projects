1) How does reversing string work?
	Imagine you have a string like "FRIEND". Now we are going to reverse from both sides.
	F R I E N D
	**D** R I E N **F**
	D **N** I E **R** F
	D N **E** **I** R F
	We got Final Result : DNEIRF
	
	
2) shr rcx, 1 (Shift Right) means divided by 2, But how?
	Let's say rcx is "130", so in binary format it's "1000 0010".
	Now shift the bits to right : "0100 0001"
	Binary "0100 0001" is "65"
	"130 / 2" is also "65", Wow...Pretty cool right?
	

3) How does [input_buffer] has our reversed string? But we don't move the string to "input_buffer"
	It's because in this instruction ``` lea rsi, [input_buffer] ``` rsi now holds the **ADDRESS** of the buffer not it's content. So in this instructions:
	```
	reverse_loop:
    mov al, [rsi]           
    mov bl, [rdi]           

    mov [rsi], bl           
    mov [rdi], al           

    inc rsi                 
    dec rdi                 
    loop reverse_loop
    	```
    	The characters are moved, not the **ADDRESS**, i.e. 'input_buffer' always hold our string throughout the execution.
