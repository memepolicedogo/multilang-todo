section .data
	LINESEP		db ': '
	ARGERR		db 'Invalid Argument(s)',10
	ARGERRL		equ $ - ARGERR
	RERRMSG		db 'File messed up', 10
	RERRMSGL	equ $ - RERRMSG
	ARGC:		dq 1			; Number of args
	NL:		db 10			; Newline char
	TMPFILE:	db 'todotmp.txt',0
	FILENAME:	db 'todo.txt',0		; Name of todo file
	NULL:		equ 0			; Null char
	FBUFF_LEN:	equ 1024		; Bytes in file buffer
	READ_LEN	dq 0			; How much of the file is read
section .bss
	POPI		resq 1
	TMPDESC		resq 1
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

	cmp	rax, 0		; Checks for error
	jle	ReadErr

	mov	[FDESC], rax	; store file pointer

	; Read file
	mov	rax, 0
	mov	rdi, [FDESC]
	mov	rsi, FBUFF
	mov	rdx, FBUFF_LEN
	syscall

	cmp	rax, 0		; Checks for error
	jle	ReadErr

	mov	[READ_LEN], rax ; Store the number of pingus read
	; Print "0: "
	mov	[LWBUFF], byte 48
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, LWBUFF
	mov	rdx, 8
	syscall
	call lnspace

	xor	r10, r10 	; Dont worry about this one
	xor	r8, r8 		; How many chars from the file have been printed
PrintItr:
; Iterates through each byte of the file and prints it out
; along with a line number at each newline
	cmp	r8, [READ_LEN]	; If we've printed all we read
	jz	PrintEnd	; End the jawn

	cmp	[FBUFF+r8], byte 10; If the next char is a newline
	je	PrintNewline	; Handle line numbers
	jmp	PrintFChar	; Otherwise print it normally

PrintNewline:
; Prints a newline charachter and increments the line number
; counter and then prints it out
	inc	r8 		; Increments the char printed counter
	cmp	r8, [READ_LEN]	; If this is the final byte of the file
	jz	PrintEnd	; End the loop
	call	newline		; Otherwise print a newline
	mov	r10, 0		; Zero the counter for printing the chars of the counter
	mov	al, byte [LWBUFF]; Store the lowest byte in the line number counter
	cmp	al, 57		; If it is the ascii for 9
	je	ShiftDigit	; We need to shift the digits 
	inc	byte [LWBUFF]	; Otherwise we can just add 1
PrintLineCounter:
; This prints the counter that stores the ascii value of 
; each digit in reverse order. Normally sys_write prints 
; each byte from left to right, but we need to store
; the bytes from right to left in order to easily be 
; able to shift them every 10 lines
	mov	rax, 1		; System write #
	mov	rdi, 1		; Stdout
	mov	rsi, LWBUFF	; Load counter pointer
	add	rsi, 7		; Go to the highest byte in the counter
	sub	rsi, r10 	; Go down by the number of bytes of the counter that have been printed
	mov	rdx, 1		; The number of bytes to print
	syscall			; Prints
	inc	r10 		; Increments the counter
	cmp	r10, 8		; If there are no more bytes to print
	jge	EndLineCounter	; Go to print ': ' and the next line of chars
	jl	PrintLineCounter; Otherwise print the next byte
ShiftDigit:
	mov	rax, [LWBUFF]	; Store our counter in rax so we can do more to it
	sub	rax, 8		; Subtract 8, turns out '9' to a '1'
	cmp	ah, 0
	jne	AddTen
	shl	rax, 8		; Move everything over to the left 1 byte
	; i.e. if we have '','','1','1' this gives us '','1','1',''
	add	rax, 48		; Adds the ascii for '0', effectivly puts it in the lowest bit
	mov	[LWBUFF], rax 	; Put our updated value into our buffer
	jmp PrintLineCounter	; Print our updated value
AddTen:
	cmp	ah, 57
	je	AddH
	inc	ah
	mov	[LWBUFF], rax
	jmp PrintLineCounter
AddH:
	sub	ah, 8
	shl	rax, 8
	mov	al, ah
	mov	ah, 0
	jmp	PrintLineCounter

EndLineCounter:
	call	lnspace		; Print ': '
	jmp 	PrintItr	; Restart the loop

PrintFChar:
; Print the nth char from the file
	mov	rax, 1		; Read syscall #
	mov	rdi, 1		; Stdout #
	mov	rsi, FBUFF	; Memory address of the data from the file
	add	rsi, r8 	; Changes the memory address to that of the nth char
	mov	rdx, 1		; Print only 1 byte
	syscall			; Let the system take over
	inc	r8 		; Increment our printed chars counter
	jmp	PrintItr	; Restart the loop


PrintEnd:
	cmp	[READ_LEN], dword 1024; If the entire buffer was read from the file
	je	ContinueRead	; Moves on to the next part of the file
	call	newline		; print a newline for looks
	call	EXIT		; End the program
ContinueRead:

	mov	rax, 0
	mov	rdi, [FDESC]
	mov	rsi, FBUFF
	mov	rdx, FBUFF_LEN
	syscall

	cmp	rax, 0
	jle	ReadErr		; Error message

	xor	r8, r8 		; Zeros char counter
	mov	[READ_LEN], rax ; Stores # of bytes read
	jmp	PrintItr	; Returns to the loop to print this new data


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

	; Open and create temp file
	mov	rax, 2
	mov	rdi, TMPFILE
	mov	rsi, 101	; Create if not exist and open to read
	mov	rdx, 666q	; read/write perms for all users
	syscall

	mov	[TMPDESC], rax	;

	; Prepare to write
	; Zero counters
	xor 	r10, r10	; line counter
	xor	r8, r8		; char counter
	
	cmp	r10, [POPI]	; Check if the line to be removed is zero
	jne	Itr		; If not treat it normally

ZeroItr:
	; Iterates through chars until the end of the first line 
	; giving us the number of bytes we want to skip
	xor	rsi, rsi	; clear char container 
	mov	sil, byte [FBUFF + r8 ]	; Store the next char in the first 8 bits of rsi
	mov	[WBUFF], sil		; Store the char into the write buffer
	inc	r8

	cmp	rsi, 10		; Checks if this is a newline char
	jne	ZeroItr		; If not go to the next char
	; Time to write
	mov	rax, 8		; The lseek syscall, puts us at a specific part of a file
	mov	rdi, [FDESC]	; Where to seek
	mov	rsi, r8		; How much offset
	mov	rdx, 0		; From where do you offset (0 = start of file)
	syscall
ZPlusWrite:
	; It's been months since I worked on this
	; I don't remember what names I've already used
	; this seems safe tho
	
	; Read file
	mov	rax, 0
	mov	rdi, [FDESC]
	mov	rsi, FBUFF
	mov	rdx, 1024
	syscall
	mov	[READ_LEN], rax
	
	; Write what was read in to tmp file
	mov	rax, 1
	mov	rdi, [TMPDESC]
	mov	rsi, FBUFF
	mov	rdx, [READ_LEN]
	syscall

	cmp	rax, 0
	jl	ReadErr		; Not a read error but whatever man

	cmp	rax, 1024	; Check if write buffer was full
	je	ZPlusWrite	; If so, there's probably more to write
	jmp ItrEnd		; Otherwise we can end this


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
	inc	r8
	cmp	r8, [READ_LEN]	; If we've reached the last char
	jle	ContItr	
	
	; Read in again
	mov	rax, 0
	mov	rdi, [FDESC]
	mov	rsi, FBUFF
	mov	rdx, 1024
	syscall
	mov	[READ_LEN], rax
	cmp	rax, 0
	je	ItrEnd
	mov	r8, 0
ContItr:
	cmp	rsi, 10		; If this char is a newline
	je	IncNL
	cmp	r10, [POPI]	; If this line is to be removed
	jne	Write		; Write to file if it is not
	je	Skip		; If it is, skip it
IncNL:
	inc	r10 		; Increment the line counter
	cmp	r10, [POPI]
	je	Itr
Write:				; Otherwise it continues to this code
	mov	rax, 1		; write syscall #
	mov	rdi, [TMPDESC]	; File Discriptor
	mov	rsi, WBUFF	; Pointer to char
	mov	rdx, 1		; # of bytes
	syscall
	jmp Itr			; Restart loop
Skip:
	jmp Itr			; Restart loop
ItrEnd:

	mov	rax, 3
	mov	rdi, [FDESC]
	syscall

	mov	rax, 87
	mov	rdi, FILENAME
	syscall

	mov	rax, 86
	mov	rdi, TMPFILE
	mov	rsi, FILENAME
	syscall

	mov	rax, 87
	mov	rdi, TMPFILE
	syscall

	call	EXIT		; Just leave

ReReadFile:
	mov	rax, 0
	mov	rdi, [FDESC]
	mov	rsi, FBUFF
	mov	rdx, FBUFF_LEN
	syscall
	mov	[READ_LEN], rax 
	cmp	rax, 0
	je	ItrEnd
	xor	r8, r8 
	jmp	Itr

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
