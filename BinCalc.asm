global _start
_start:
    mov edx, Welcome_msgLen      	; Setup sys_write for the character
    mov ecx, Welcome_msg
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80 
	mov byte [total], 0x00	; Initialize the total.
_input: ; read the input to inBuffer
    mov edx, BUFFERSIZE  	; use sys_read to read a line or buffer full of bytes 
    mov ecx, inBuffer  
    mov ebx, stdin   
    mov eax, sys_read 
    int 0x80            	; trigger a system call interrupt for the sys_read 
    cmp eax, 0x00
    jle _exit            	; check return value of sys_read, 0 or less means error or end of file.
	mov [inputLen], eax		; Store the number of bytes read.
	mov esi, inBuffer 		; Use esi as a pointer to input bytes
	mov bl, [esi]			; Store the operand in ebx				; Point to what should be the first binary digit. (Most significant bit)
	mov ecx, 0x00
	mov byte [numin], 0x00
	add esi, [inputLen]	; Point the the end.
	sub esi, 0x02	; Move back to account for the newline.
_a2b:
	mov eax, 0x00
	cmp byte [esi], bl	; If esi = the operator, we reversed through all bits.
	je _opcheck
	mov al, [esi]	; store the first digit
	and eax, 0x0000000F
	cmp al, 0x00	; Check that it is a 1 or a 0, go to error if not.
	je _valid
	cmp al, 0x01
	je _valid
	jmp _error
	_valid: ; If the bit is valid add it to numin.
	shl al, cl ; the left shift adds 0 equal to the counter to ensure the bit is put in the right location.
	add al, [numin]
	mov [numin], al
	inc cl
	dec esi			; update the pointer
	jmp _a2b
_opcheck:
	mov eax, 0x00; Reset eax for the arithmetic used below and find which operator to use.
	cmp bl, 0x2B ; +
	je _add
	cmp bl, 0x2D ; -
	je _sub
	cmp bl, 0x2A ; *
	je _mul
	cmp bl, 0x2F ; /
	je _div
	cmp bl, 0x25 ; %
	je _mod
_add: ; Find the sum
	mov al, [total]
	add al, [numin]
	mov byte [total], 0x00
	mov [total], al
	jc _overflow
	jmp _output
_sub: ; Find the difference
	mov al, [total]
	sub al, [numin]
	mov byte [total], 0x00
	mov [total], al
	jc _overflow
	jmp _output
_mul: ; Find the product
	mov al, [total]
	mov bl, [numin]
	mul bl
	mov byte [total], 0x00
	mov [total], ax
	jc _overflow
	jmp _output
_div: ; Find the quotient after dvision
	mov al, [total]
	mov bl, [numin]
	cmp bl, 0x00
	je _errordiv
	div bl
	mov byte [total], 0x00
	mov [total], al
	jc _overflow
	jmp _output
_mod: ; Find the remainder after division
	mov al, [total]
	mov bl, [numin]
	div bl
	mov byte [total], 0x00
	mov [total], ah
	jc _overflow
	jmp _output
_output:
    mov edx, 0x01      	; Setup sys_write for the = character
    mov ecx, equals
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80
	mov byte [count], 0x00
	mov edx, outBuffer
_totalLoop:	; Convert the total (in binary) to it's ASCII representation.
	mov al, [total]
	cmp byte [count], 0x07
	jg _outputCont
	mov cl, [count]
	shl al, cl
	add al, 10000000b ; I chose to just shift the bit in question to the top of al and add a 1
	jc _oneOut		  ; If it carried, it was a one. If not, it was a 0.
	jnc _zeroOut
	_oneOut:	; move the ASCII equivalent into the output buffer.
		mov byte [edx], 0x31
		add byte [count], 0x01
		inc edx
		jmp _totalLoop
	_zeroOut:
		mov byte [edx], 0x30
		add byte [count], 0x01
		inc edx
		jmp _totalLoop
_outputCont:
	mov edx, 0x04      	; Setup sys_write for the first four bits of the total.
    mov ecx, outBuffer
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80 
    mov edx, 0x01      	; Setup sys_write for the space between 4 bits.
    mov ecx, space
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80 
	mov esi, outBuffer
	add esi, 0x04
	mov edx, 0x04      	; Setup sys_write for the last four bits of the total.
    mov ecx, esi
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80 
    mov edx, 0x01      	; Setup sys_write for the newline
    mov ecx, new_line
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80 	
	mov ecx, 0x00
	jmp _input
_overflow: ; Output an overflow error if the carry flag is set.
	mov byte [total], 0x00
	mov edx, Overflow_msgLen      	; Setup sys_write for error
    mov ecx, Overflow_msg
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80
	jmp _output
_error:
	mov edx, Error_msgLen      	; Setup sys_write for error
    mov ecx, Error_msg
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80 
	jmp _exit
_errordiv:
	mov edx, Errordiv_msgLen      	; Setup sys_write for error
    mov ecx, Errordiv_msg
    mov ebx, stdout 
    mov eax, sys_write 
    int 0x80 
	jmp _input
_exit:
	mov ebx, 0x00
	mov eax, 0x01
	int 	 0x80

section .data
	Welcome_msg     DB      "Welcome to Chapek 9",0x0A,"We do math in binary.",0x0A
	Welcome_msgLen  equ   	$ - Welcome_msg
	Overflow_msg     DB      "Overflow. I'm all out of bits!",0x0A
	Overflow_msgLen  equ   	$ - Overflow_msg
	Error_msg		DB	  	"Error, does not compute",0x0A
	Error_msgLen	equ	  	$ - Error_msg
	Errordiv_msg		DB	  	"Error, can't divide by 0",0x0A
	Errordiv_msgLen	equ	  	$ - Errordiv_msg
	Exit_msg		DB	  	0x0A,"...returning to your human planet",0x0A
	Exit_msgLen	equ	  	$ - Exit_msg
	new_line  		DB 0x0A
	equals			DB 0x3D
	space			DB 0x20
	numin     DB  00000000b
section .bss
	sys_read   	equ 0x03 
	sys_write  	equ 0x04 
	stdin     	equ 0x00 
	stdout     	equ 0x01 
	stderr     	equ 0x02 
	BUFFERSIZE 	equ 100 
	inputLen   	resd 1
	inBuffer   	resb BUFFERSIZE
	outBuffer	resb BUFFERSIZE
	total		resb 0x01
	count		resb 0x01
