section .data

sudoku	dd 0, 6, 0, 1, 0, 4, 0, 5, 0
 		dd 0, 0, 8, 3, 0, 5, 6, 0, 0
       	dd 2, 0, 0, 0, 0, 0, 0, 0, 1
  		dd 8, 0, 0, 4, 0, 7, 0, 0, 6
        dd 0, 0, 6, 0, 0, 0, 3, 0, 0
        dd 7, 0, 0, 9, 0, 1, 0, 0, 4
        dd 5, 0, 0, 0, 0, 0, 0, 0, 2
        dd 0, 0, 7, 2, 0, 6, 9, 0, 0
        dd 0, 4, 0, 5, 0, 8, 0, 7, 0

endl db 0xa

section .bss
buffer resb 4

section .text
global _start

_start:

call printsudoku
call solve
call printsudoku
jmp exit


solve:
sub rsp, 8										;move stack pointer under the return address
;base case: check for empty spot (0)
lea r8, [sudoku]								;load grid address into r8
mov rcx, 1										;reset row counter
loop1:	
mov rbx, 1										;reset col counter
	loop2:
	mov r9d, DWORD[r8]							;load element from grid
	cmp r9, 0
	je found									;if element == 0, go to found (empty spot found)
	add r8, 4									;get location of next element
	inc rbx										;increment col index 
	cmp rbx, 10	
	jne loop2									;if col index == 10, exit loop (go to next row)
inc rcx											;increment row index
cmp rcx, 10
jne loop1										;if row index == 10, no empty places found (return)

;if no empty places found, return
add rsp, 8										;move stack pointer above return address
ret 											;return

found:											;empty place found, col index in rbx and row index in rcx	
;get address of empty spot		
lea r8, [sudoku]								;load grid address into r8
dec rcx											;decrement row index
mov rax, 9										;move 9 in rax for multiplication
mul rcx											;row*9 = index of first element in this row
mov r10, rax									;move index of first element in row into r10
mov rax, 4										;move 4 in rax for multiplication
mul r10 										;index of element*4 = no. of bytes from start of grid to 1st element in this row
mov r10, rax									;move no. of bytes from start of grid to 1st element in row into r10
add r10, r8										;no. of bytes+grid address = address of first element in this row (r10)
dec rbx											;decrement col index
mov rax, 4										;move 4 in rax for multiplication
mul rbx											;col*4 = number of bytes from start of grid to the first element in this col
mov r9, rax										;move no. of bytes from start of grid to the first element in this col into r9
mov rsi, 0										;reset rsi
add rsi, r9 									;move no. of bytes of 1st element in col into rsi
add rsi, r10									;no. of bytes of 1st element in col + addr of 1st element in row = addr of empty place (rsi)
add r9, r8										;no. of bytes of 1st element in col + addr of grid = address of 1st element in column (r9)
			
mov r11, 1										;first option for empty spot (1-9)


												;push values onto the stack without moving stack pointer
mov DWORD[rsp-4], esi							;address of empty spot
mov DWORD[rsp-8], r9d							;address of 1st element in column
mov DWORD[rsp-12], r10d							;address of 1st element in row
mov DWORD[rsp-16], ebx							;column index
mov DWORD[rsp-20], ecx							;row index

assign: 

mov DWORD[rsp-24], r11d							;push value we are trying to place in empty spot onto the stack 
	
												;pop values without moving stack ptr
mov esi, DWORD[rsp-4]							;address of empty spot 
mov r9d, DWORD[rsp-8]							;address of 1st element in column
mov r10d, DWORD[rsp-12]							;address of 1st element in row
mov ebx, DWORD[rsp-16]							;column index
mov ecx, DWORD[rsp-20]							;row index
	
		;check row
		row:
		;r10 = address of first element in row
				mov r13, 1						;loop counter
				.loop:
				mov r12d, DWORD[r10]			;load element
				add r10, 4						;next element in row
				inc r13							;increment loop counter
				mov r14, r12 					;move element loaded from grid into r14
				xor r14, r11 					;xor element with the value we want to place into grid
				cmp r14, 0						;if the xor result is zero then the values are equal
				jne here 						;if theyre not equal, continue checking row
				jmp wrong						;else go to wrong
				here:	
				cmp r13, 10
				jne row.loop 					;if counter == 10 (all row checked) check column, else loop again

		;check col	
		col:
				mov r13, 1						;loop counter
				.loop1:
				mov r12d, DWORD[r9]				;load element
				add r9, 36						;next element address in column
				inc r13							;increment loop counter
				mov r14, r12 					;move element loaded from grid into r14
				xor r14, r11 					;xor element with the value we want to place into grid
				cmp r14, 0						;if the xor result is zero then the values are equal
				jne here2 						;if theyre not equal, continue checking col
				jmp wrong						;else go to wrong
				here2:
				cmp r13, 10
				jne col.loop1					;if counter == 10 (all col checked) check box, else loop again
						
		;check 3x3 box
		box:
				add rsp, 8						;move stack pointer above return address
				push rbx						;push value in rbx to use rbx in division then restore value after
				mov rax, rbx					;dividend in rax (col index)
				mov rbx, 3
				div rbx							;divide col index by 3 (dividend in rax)
												;remainder is in rdx
				pop rbx							;restore value of rbx from stack
				mov r15, rbx
				sub r15, rdx					;subtract remainder from col index = column index starting this 3x3 box
				mov rax, 4
				mul r15							;multiply by 4 = no. of bytes from left of grid to this column
				mov r15, rax
	
				push rbx						;push value in rbx to use rbx in division then restore value after
				mov rbx, 3						;divisor
				mov rax, rcx					;dividend in rax (row index)
				div rbx							;divide row index by 3
												;remainder is in rdx

				mov rbx, rcx
				sub rbx, rdx					;subtract remainder from row index = row index starting this 3x3 box
				mov rax, 36						
				mul rbx 						;multiply by 36 [4*9] = no. of bytes from start of grid to first element in the row starting the 3x3 box

				mov rdi, r15
				add rdi, rax					;add [no. of bytes from left of grid to this column] + [no. of bytes from start of grid to first element in the row]
													;to get no. of bytes from start of grid to first element in the 3x3 box
				add rdi, r8						;add to grid address = address of first element in 3x3 box [rdi]
				pop rbx
				sub rsp, 8						;move stack ptr back below return address again

				mov r13, 1						;loop counter
				jmp inc.loop2					;dont go to "inc" in first iteration
				
				inc:
				add rdi, 24						;skip 6 elements (next row in 3x3 box)	
				.loop2:
				mov r12d, DWORD[rdi]			;load element
				add rdi, 4						;next element address in box
				inc r13							;increment loop counter
				mov r14, r12 					;move element loaded from grid into r14
				xor r14, r11 					;xor element with the value we want to place into grid
				cmp r14, 0						;if the xor result is zero then the values are equal
				jne here3 						;if theyre not equal, continue checking 3x3 box
				jmp wrong						;else go to wrong
				here3:
				cmp r13, 4
				je inc							;if 3 elements done, go to inc (next row in 3x3 box)
				cmp r13, 7
				je inc							;if 6 elements done, go to inc (next row in 3x3 box)
				cmp r13, 10
				jne inc.loop2					;if counter == 10 (all box checked) exit loop
		
		mov rax, 1								;return true
		jmp cont

		wrong:
		mov rax, 0								;return false

cont:
cmp rax, 0										;if false, go to "next" to try next option for the empty spot
je next

mov DWORD[rsi], r11d							;if true, then place the number into the sudoku grid to continue solving

sub rsp, 24										;move stack pointer after the values stored on the stack (24 bytes)

call solve										;recursively call the function to solve the grid

add rsp, 24										;move stack pointer before the values stored on the stack (24 bytes) to load them


												;pop values without moving stack ptr
mov esi, DWORD[rsp-4]							;address of empty spot 
mov r9d, DWORD[rsp-8]							;address of 1st element in column
mov r10d, DWORD[rsp-12]							;address of 1st element in row
mov ebx, DWORD[rsp-16]							;column index
mov ecx, DWORD[rsp-20]							;row index
mov r11d, DWORD[rsp-24]							;value placed in empty spot

cmp rax, 0										;if solve function returned false, go to "next" to try another value for this spot
je next
add rsp, 8										;move stack pointer above return address
ret 											;return

next:
inc r11											;get next option for this spot (1-9)
cmp r11, 10
jne assign										;if value not equal 10, loop again
												;else, backtrack
backtrack:
mov rax, 0										;return false
mov DWORD[rsi], eax								;reset empty spot
mov DWORD[rsp-24], r11d							;get last value tried for this spot from to stack to try next option

add rsp, 8										;move stack pointer above return address
ret 											;return



printsudoku:
lea r9, [sudoku]								;load address of grid into r9
mov r10, 1										;reset col index
.loopa:	
mov r11, 1										;reset row index
	.loopb:					

	push r9 									;push address of grid, row index and col index before interrupts to restore them after interrupts
	push r10
	push r11


	mov ecx, DWORD[r9]							;load element from grid
	add ecx, 48									;add 48 to the number to get ascii equivalent

	cmp ecx, 48									;if loaded element is zero (48 in ascii) replace with *
	jne .prnt 									;else print

	mov ecx, 42									;replace it with ascii equivalent of *

	.prnt:
	mov [buffer], rcx							;move into buffer
	mov rcx, buffer								;move buffer into string
	mov rax, 4									
	mov rbx, 1
	mov rdx, 1
	int 0x80									;print number

	mov rcx, 32									;ascii for space
	mov [buffer], rcx							;move into buffer
	mov rcx, buffer								;move buffer into string
	mov rax, 4									
	mov rbx, 1
	mov rdx, 1
	int 0x80									;print space

	pop r11
	pop r10
	pop r9 										;pop registers after interrupts

	add r9, 4									;next element address
	inc r11										;increment col index
	cmp r11, 10
	jne .loopb 									;if column not all printed yet loop again
inc r10											;increment row index

push r9 										;push registers before interrupt
push r10
push r11

mov rcx, endl									;mov \n into rcx to print
mov rax, 4
mov rbx, 1
mov rdx, 1
int 0x80										;print \n

pop r11
pop r10
pop r9 											;pop registers after interrupt

cmp r10, 10
jne .loopa										;if not all rows printed yet, loop again


mov rcx, endl									;mov \n into rcx to print
mov rax, 4
mov rbx, 1
mov rdx, 1
int 0x80										;print \n


ret 											;return

exit:
mov rbx, 0
mov rax, 1
int 0x80										;exit program


