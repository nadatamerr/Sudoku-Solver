.data
sudoku: .word 0, 6, 0, 1, 0, 4, 0, 5, 0
              0, 0, 8, 3, 0, 5, 6, 0, 0
              2, 0, 0, 0, 0, 0, 0, 0, 1
              8, 0, 0, 4, 0, 7, 0, 0, 6
              0, 0, 6, 0, 0, 0, 3, 0, 0
              7, 0, 0, 9, 0, 1, 0, 0, 4
              5, 0, 0, 0, 0, 0, 0, 0, 2
              0, 0, 7, 2, 0, 6, 9, 0, 0
              0, 4, 0, 5, 0, 8, 0, 7, 0

star: .asciz "*"
space: .asciz " "
endl: .asciz "\n"

.text

jal printsudoku
jal solve
jal printsudoku
j exit

solve:
addi sp, sp, -4				#move stack ptr
sw ra, (sp)				#push return address

#load immediates into registers for multiplication later
li a7, 10
li s9, 4
li s10, 9
#base case: check for empty  spot (0)
la a0, sudoku				#load grid address into a0
li a2, 1				#reset row counter
loop1:	
li a1, 1				#reset col counter
	loop2:
	lw t0, (a0)			#load element from grid
	beqz t0, found			#if element == 0, go to found (empty spot found)
	addi a0, a0, 4			#get location of next element
	addi a1, a1, 1			#increment col index 
	bne a1, a7, loop2		#if col index == 10, exit loop (go to next row)
addi a2, a2, 1				#increment row index
bne a2, a7, loop1			#if row index == 10, no empty places found (return)

#if no empty places found, return
j return 

found:					#empty place found, col index in a1 and row index in a2	
#get address of empty spot
la a0, sudoku				#load grid address into a0
addi a2, a2, -1				#decrement row index
mul t1, a2, s10				#row*9 = index of first element in this row
mul t1, t1, s9				#index of element*4 = no. of bytes from start of grid to 1st element in this row
add t1, t1, a0				#no. of bytes+grid address = address of first element in this row (t1)
addi a1, a1, -1				#decrement col index
mul t0, a1, s9				#col*4 = number of bytes from start of grid to the first element in this col
add s7, t0, t1				#no. of bytes of 1st element in col + addr of 1st element in rows = addr of empty place(s7)
add t0, t0, a0				#no. of bytes of 1st element in col + addr of grid = address of 1st element in column(t0)	

li t2, 1				#first option for empty spot (1-9)

sw s7, -4(sp)				#address of empty spot
sw t0, -8(sp) 				#addr of first element in column
sw t1, -12(sp)				#addr of first element in row
sw a1, -16(sp)				#col index
sw a2, -20(sp)				#row index

assign:

sw t2, -24(sp)				#value being placed in grid

jal check				#call check function to see if its okay to place this number here

beqz a3, next				#wrong number (returned false), check next option
#else (returned true)
sw t2, (s7)				#store number (1-9) into empty spot and try to solve sudoku

addi sp, sp, -24			#move stack pointer after values stored (24 bytes)

jal solve				#recursively call the function to continue solving it

addi sp, sp, 24				#move stack pointer before values stored (24 bytes)
lw s7, -4(sp)				#address of empty spot
lw t0, -8(sp)				#addr of first element in column
lw t1, -12(sp)				#addr of first element in row
lw a1, -16(sp)				#col index
lw a2, -20(sp)				#row index
lw t2, -24(sp)				#value being placed in grid

beqz a3, next				#if returned false (no solution), backtrack
j return				#else return

next:					#loop again//next option
addi t2, t2, 1				#get next option for this spot (1-9)
bne t2, a7, assign			#if value not equal 10, loop again

backtrack:
li a3, 0				#return false
sw t2, -24(sp)				#get last value tried for this spot from the stack to try next option
sw zero, (s7)				#reset empty spot

j return

#-----------end of solve function------------

check:					#check if okay to place this number here
la a0, sudoku				#load grid address into a0
lw s7, -4(sp)				#address of empty spot
lw t0, -8(sp)				#addr of first element in column
lw t1, -12(sp)				#addr of first element in row
lw a1, -16(sp)				#col index
lw a2, -20(sp)				#row index
lw t2, -24(sp)				#value being placed in grid

#check row
row:
#t1 = address of first element in row
	li t4, 1			#loop counter
	.loop:
	lw t3, (t1)			#load element
	addi t1, t1, 4			#next element in row
	addi t4, t4, 1			#increment loop counter
	xor s5, t3, t2			#xor vlue from grid with value being placed in empty spot
	bnez s5, here			#if xor result is not zero then they are not equal, continue
	j wrong				#else, element found, return false
	here:
	bne t4, a7, .loop		#if counter == 10 (all row checked) check column, else loop again

#check col	
col:
	li t4, 1			#loop counter
	.loop1:
	lw t3, (t0)			#load element
	addi t0, t0, 36			#next element address in column
	addi t4, t4, 1			#increment loop counter
	xor s5, t3, t2			#xor vlue from grid with value being placed in empty spot
	bnez s5, here2			#if xor result is not zero then they are not equal, continue
	j wrong				#else, element found, return false
	here2:
	bne t4, a7, .loop1		#if counter == 10 (all col checked) check box, else loop again
	
	#check 3x3 box
	box:
	li s2, 3			#load immediate into register for division
	rem t5, a1, s2			#divide col index by 3 and move remainder into t5
	sub s3, a1, t5			#subtract remainder from col index = column index starting this 3x3 box
	mul s3, s3, s9			#multiply by 4 = no. of bytes from left of grid to this column
	rem t6, a2, s2			#divide row index by 3 and move remainder into t6
	sub s4, a2, t6			#subtract remainder from row index = row index starting this 3x3 box
	mul s4, s4, s9			#multiply by 36 (4*9) = no. of bytes from start of grid to first
	mul s4, s4, s10				# element in the row starting the 3x3 box
	add s8, s3, s4			#add (no. of bytes from left of grid to this column) + (no. of bytes from start of grid to first element in the row)
						#to get no. of bytes from start of grid to first element in the 3x3 box
	add s8, s8, a0			#add to grid address = address of first element in 3x3 box (s8)
	
	li t4, 1			#loop counter
	j .loop2			#dont go to "inc" in first iteration
	
	inc:
	addi s8, s8, 24			#skip 6 elements(next row in 3x3 box)	
	.loop2:
	lw t3, (s8)			#load element
	addi s8, s8, 4			#next element address in box
	addi t4, t4, 1			#increment loop counter
	xor s5, t3, t2			#xor vlue from grid with value being placed in empty spot
	bnez s5, here3			#if xor result is not zero then they are not equal, continue
	j wrong				#else, element found, return false	
	here3:
	beq t4, s9, inc			#if 3 elements done, go to inc (next row in 3x3 box)
	li s11, 7			#load immediate into register for branch instruction
	beq t4, s11, inc		#if 6 elements done, go to inc (next row in 3x3 box)
	bne t4, a7, .loop2		#if counter == 10 (all col checked) check box, else loop again

li a3, 1
jr ra					#return true

wrong:
li a3, 0
jr ra					#return false

#--------------- end of check function--------------

return:
lw ra, (sp)				#pop return address
addi sp, sp, 4				#move stack ptr
jr ra					#return

printsudoku:
li s11, 10				#load immediate into register for branch instruction
la t0, sudoku				#load address of grid into t0
li a2, 1				#reset col index
.loopa:	
li a1, 1				#reset row index
	.loopb:
	li a7, 1			#system code for print integer
	lw a0, (t0)			#load element into a0 to print
	bnez a0, .prnt			#if element is not zero, print it
	li a7, 4
	la a0, star			#else, print *
	.prnt:
	ecall				#print element
	li a7, 4			#system code for print string
	la a0, space			#load space character address into a0
	ecall				#print space
	addi t0, t0, 4			#next element address
	addi a1, a1, 1			#increment col index
	bne a1, s11, .loopb		#if column not all printed yet loop again
addi a2, a2, 1				#increment row index
la a0, endl				#load address of \n character into a0
ecall					#print \n
bne a2, s11, .loopa			#if not all rows printed yet, loop again
	
li a7, 4				#system code for print string
la a0, endl				#load address of \n character into a0
ecall					#print \n twice when done
ecall

jr ra					#return

exit:
li a7, 10				#system code for exit program
ecall					#exit



