section .data
	LINESEP		db ': '
	ARGERR		db 'Invalid Argument(s)',10
	ARGERRL		equ $ - ARGERR
	RERRMSG		db 'File messed up', 10
	RERRMSGL	equ $ - RERRMSG
	ARGC:		dq 1			; Number of args
	NL:		db 10			; Newline char
	FILENAME:	db 'todo.txt',0		; Name of todo file
	NULL:		equ 0			; Null char
	FBUFF_LEN:	equ 1024			; Bytes in file buffer
	READ_LEN	dq 0			; How much of the file is read
section .bss
	POPI		resq 1
	FDESC 		resq 1			; File discriptor
	FBUFF		resb 1024		; File buffer
	WBUFF		resb 1			; Write buffer
	LWBUFF		resq 1
	ADESC		resb 1			; Argument discriptor
	ABUFF		resb 1			; Argument buffer

section .text

global _start

_start:
	; Check the flags 
	pop	rax 		; Removes the # of args from the stack
	mov	[ARGC], rax 	; Store it in memory
	cmp	rax, 1		; If there is only one arg
	je	print		; User just wants to print the contents
	pop	r8 		; Otherwise remove the pointer to the args from the stack
	xor	rcx, rcx 	; Zero the char counter

ArgCheck:
	; Iterates through every char in the arg to seperate them 
	mov	r9b, [r8]	; Uses the first byte in r9 to store the relevent char
	inc	r8 		; Increments the arg pointer
	cmp	r9b, byte NULL	; If the char is the null value that is used to seperate the args
	je	NextArg		; Handle it as a new arg
	jne	ArgCheck	; Otherwise restart the loop
NextArg:
	; Checks what the arg is
	mov	r9b, [r8]	; Stores the char
	cmp 	r9b, byte 45	; If the arg starts with a hyphen
	jne	add		; We will continue on
	; Otherwise it must be an item to add, so we jump to that part

	inc	r8 		; Increment the arg pointer
	mov	r9b, [r8]	; Gets the next char of the arg, should be all we need to know what to do 
	cmp	r9b, byte 100	; If it is d, the delete flag
	je	del		; Jump to the delete function
				; Otherwise it is invalid
	; Print a error message
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, ARGERR
	mov	rdx, ARGERRL
	syscall

	call	EXIT		; End the program

print:
	call POUT		; Call the print function
del:
	inc	r8		; move past the null seperator
CalcPopIndex:
	inc	r8		; Get the next char
	mov	r9b, [r8]	; Store the next char
	cmp	r9b, 0		; Check if it is null terminator
	je	POPcall
	sub	r9b, 48		; Subtract 48 from the ascii value to get the decimal value
	mov	rax, [POPI]
	mov	r14, 10
	mul	r14 
	mov	[POPI], rax 
	add	[POPI], r9 	; Store it in the pop index variable
	jmp	CalcPopIndex
POPcall:
	call	POP		; Call the pop function
add:
	call PUT		; Call the put function

global EXIT
EXIT:
	mov	rax, 60		; Exit syscode
	mov	rdi, 0		; Normal exit code
	syscall

global newline
newline:
	; print a newline char
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, NL
	mov	rdx, 1
	syscall
	ret

global lnspace
lnspace:
	mov	rax, 1
	mov	rsi, 1
	mov	rsi, LINESEP
	mov	rdx, 2
	syscall
	ret


global POUT
POUT:
	; Open the file
	mov	rax, 2		; open syscall #
	mov	rdi, FILENAME	;
	mov	rsi, 0		;
	syscall

	cmp	rax, 0
	jle	ReadErr

	mov	[FDESC], rax	; store file pointer

	; Read file
	mov	rax, 0
	mov	rdi, [FDESC]
	mov	rsi, FBUFF
	mov	rdx, FBUFF_LEN
	syscall

	cmp	rax, 0
	jle	ReadErr

	mov	[READ_LEN], rax 
	; Print "0: "
	mov	[LWBUFF], byte 48
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, LWBUFF
	mov	rdx, 8
	syscall
	call lnspace

	xor	r10, r10 
	xor	r8, r8 
PrintItr:
	cmp	r8, [READ_LEN]
	jz	PrintEnd

	cmp	[FBUFF+r8], byte 10
	je	PrintNewline
	jmp	PrintFChar

PrintNewline:
	inc	r8 
	cmp	r8, [READ_LEN]
	jz	PrintEnd
	call	newline
	mov	r10, 0
	mov	al, byte [LWBUFF]
	cmp	al, 57
	je	ShiftDigit
	inc	byte [LWBUFF]
PrintLineCounter:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, LWBUFF
	add	rsi, 7
	sub	rsi, r10 
	mov	rdx, 1
	syscall
	inc	r10 
	cmp	r10, 8
	jge	EndLineCounter
	jl	PrintLineCounter
ShiftDigit:
	mov	rax, [LWBUFF]
	sub	rax, 8
	shl	rax, 8
	add	rax, 48
	mov	[LWBUFF], rax 
	jmp PrintLineCounter

EndLineCounter:
	call	lnspace
	jmp 	PrintItr

PrintFChar:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, FBUFF
	add	rsi, r8 
	mov	rdx, 1
	syscall
	inc	r8 
	jmp	PrintItr


PrintEnd:
	call	newline
	call	EXIT

global POP
POP:
; Reads in the file, then writes line by line except for 
; the line specified in the next arg of the program

	; Open file
	mov	rax, 2		; Open call #
	mov	rdi, FILENAME	; Pointer to the name of the file
	mov	rsi, 0		; Read 
	mov	rdx, 0
	syscall

	cmp	rax, 0
	jle	ReadErr		; If rax is negative or 0 print an error and exit
	mov	[FDESC], rax	; Store file descriptor

	; Read file
	mov	rax, 0
	mov	rdi, [FDESC]
	mov	rsi, FBUFF
	mov	rdx, FBUFF_LEN
	syscall

	mov	[READ_LEN], rax	; Store how many bytes were read
	; Close file
	mov	rax, 3
	mov	rdi, [FDESC]
	syscall

	; Delete file
	mov	rax, 87
	mov	rdi, FILENAME
	syscall

	; Open and create anew
	mov	rax, 2
	mov	rdi, FILENAME
	mov	rsi, 101	; Create if not exist and open to read
	mov	rdx, 666q	; read/write perms for all users
	syscall

	mov	rax, 2
	mov	rdi, FILENAME
	mov	rsi, 2
	xor	rdx, rdx 
	syscall

	mov	[FDESC], rax	;

	; Prepare to write
	; Zero counters
	xor 	r10, r10	; line counter
	xor	r8, r8		; char counter

Itr:
	; Goes char by char, using a r10 to store line #
	; if the line # matches the line to be deleted
	; as passed in arg 3, it does not write any chars
	; until the next newline char has been reached
	xor	rsi, rsi	; clear char container 
	mov	sil, byte [FBUFF + r8 ]	; Store the next char in the first 8 bits of rsi
	mov	[WBUFF], sil		; Store the char into the write buffer
	; You can't move directly between memory so 
	; I have to use rsi as an inbetween.
	; For writing rsi must be a pointer to the string
	; to be written so the actual char cannot be stored therein
	cmp	r8b, byte [READ_LEN]	; If we've reached the last char
	jge	ItrEnd		; End the loop
	inc	r8 		; Otherwise go to the next
	cmp	rsi, 10		; If this char is a newline
	je	IncNL
	cmp	r10, [POPI]	; If this line is to be removed
	jne	Write		; Write to file if it is not
	je	Skip		; If it is, skip it
IncNL:
	inc	r10 		; Increment the line counter
	mov	r14, [POPI]
	cmp	r10, [POPI]	; If the line is to be removed
	je	Itr		; Restart the loop
Write:				; Otherwise it continues to this code
	mov	rax, 1		; write syscall #
	mov	rdi, [FDESC]	; File Discriptor
	mov	rsi, WBUFF	; Pointer to char
	mov	rdx, 1		; # of bytes
	syscall
	jmp Itr			; Restart loop
Skip:
	jmp Itr			; Restart loop
ItrEnd:
	call	EXIT		; Just leave

ReadErr:
	; If the file isn't read right it prints an error
	; message to std out
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, RERRMSG
	mov	rdx, RERRMSGL
	syscall

	call	EXIT		; then it exits

global PUT
PUT:
	; Open the file
	mov	rax, 2
	mov	rdi, FILENAME
	mov	rsi, 2
	syscall

	cmp	rax, 0		; If it failed to open
	jle	ReadErr		; Print error message
	mov	[FDESC], rax 	; Otherwise store the file discriptor 

	mov	rax, 8
	mov	rdi, [FDESC]
	mov	rsi, 0
	xor	rdx, 2
	syscall
PIter:
	mov	r9b, [r8]	; Get the next char
	mov	[WBUFF], r9b 	; Store it in the write buffer
	inc	r8 		; Increment the pointer
	cmp	r9b, byte NULL	; If it is the null end char
	je	PEnd		; End the loop
	; Otherwise write char to the file
	mov	rax, 1
	mov	rdi, [FDESC]
	mov	rsi, WBUFF
	mov	rdx, 1
	syscall
	jmp	PIter		; Restart the loop
PEnd:
	; Write a newline to the end of the file
	mov	[WBUFF], byte 10
	mov	rax, 1
	mov	rdi, [FDESC]
	mov	rsi, WBUFF
	mov	rdx, 1
	syscall
	call	EXIT		; Exit the jawn
