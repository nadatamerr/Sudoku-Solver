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

star: .asciiz "*"
space: .asciiz " "
endl: .asciiz "\n"

.text
				
jal printsudoku
jal solve
jal printsudoku
j exit


solve:
sub $sp, $sp, 4				#move stack ptr
sw $ra, ($sp)				#push return address

#base case: check for empty  spot (0)
la $a0, sudoku				#load grid address into a0
li $a3, 1				#reset row counter
loop1:	
li $a2, 1				#reset col counter
	loop2:
	lw $t1, ($a0)			#load element from grid
	beqz $t1, found			#if element == 0, go to found (empty spot found)
	add $a0, $a0, 4			#get location of next element
	add $a2, $a2, 1			#increment col index 
	bne $a2, 10, loop2		#if col index == 10, exit loop (go to next row)
add $a3, $a3, 1				#increment row index
bne $a3, 10, loop1			#if row index == 10, no empty places found (return)

#if no empty places found, return
j return

found:					#empty place found, col index in a2 and row index in a3	
#get address of empty spot
la $a0, sudoku				#load grid address into a0
sub $a3, $a3, 1				#decrement row index
mul $t2, $a3, 9				#row*9 = index of first element in this row
mul $t2, $t2, 4				#index of element*4 = no. of bytes from start of grid to 1st element in this row
add $t2, $t2, $a0			#no. of bytes+grid address = address of first element in this row (t2)
sub $a2, $a2, 1				#decrement col index
mul $t1, $a2, 4				#col*4 = number of bytes from start of grid to the first element in this col
add $s0, $t1, $t2			#no. of bytes of 1st element in col + addr of 1st element in row = addr of empty place(s0)
add $t1, $t1, $a0			#no. of bytes of 1st element in col + addr of grid = address of 1st element in column(t1)	

li $t3, 1				#first option for empty spot (1-9)
						
					#push values onto stack without moving stack ptr
sw $s0, -4($sp)				#address of empty spot
sw $t1, -8($sp)				#addr of first element in column
sw $t2, -12($sp)			#addr of first element in row
sw $a2, -16($sp)			#col index
sw $a3, -20($sp)			#row index

assign:

sw $t3, -24($sp)			#value being placed in grid

jal check				#call check function to see if its okay to place this number here

beqz $a1, next				#wrong number (returned false), check next option
#else (returned true)	
sw $t3, ($s0)				#store number (1-9) into empty spot and try to solve sudoku

sub $sp, $sp, 24			#move stack pointer after values stored (24 bytes)

jal solve				#recursively call the function to continue solving it

add $sp, $sp, 24			#move stack pointer before values stored (24 bytes)
lw $s0, -4($sp)				#address of empty spot
lw $t1, -8($sp)				#addr of first element in column
lw $t2, -12($sp)			#addr of first element in row
lw $a2, -16($sp)			#col index
lw $a3, -20($sp)			#row index
lw $t3, -24($sp)			#value being placed in grid

beqz $a1, next				#if returned false (no solution), backtrack
j return				#else return
	
next:					#loop again//next option
add $t3, $t3, 1				#get next option for this spot (1-9)
bne $t3, 10, assign			#if value not equal 10, loop again

backtrack:
li $a1, 0				#return false
sw $t3, -24($sp)			#get last value tried for this spot from the stack to try next option
sw $zero, ($s0)				#reset empty spot

j return

#-----------end of solve function------------

check:					#check if okay to place this number here
la $a0, sudoku				#load grid address into a0
lw $s0, -4($sp)				#address of empty spot
lw $t1, -8($sp)				#addr of first element in column
lw $t2, -12($sp)			#addr of first element in row
lw $a2, -16($sp)			#col index
lw $a3, -20($sp)			#row index
lw $t3, -24($sp)			#value being placed in grid

#check row	
row:
#t2 = address of first element in row
	li $t6, 1			#loop counter
	.loop:
	lw $t5, ($t2)			#load element
	add $t2, $t2, 4			#next element in row
	add $t6, $t6, 1			#increment loop counter
	xor $t0, $t3, $t5		#xor vlue from grid with value being placed in empty spot
	bnez $t0, here			#if xor result is not zero then they are not equal, continue
	j wrong				#else, element found, return false
	here:
	bne $t6, 10, .loop		#if counter == 10 (all row checked) check column, else loop again

#check col	
col:
	li $t6, 1			#loop counter
	.loop1:
	lw $t5, ($t1)			#load element
	add $t1, $t1, 36		#next element address in column
	add $t6, $t6, 1			#increment loop counter
	xor $t0, $t3, $t5		#xor vlue from grid with value being placed in empty spot
	bnez $t0, here2			#if xor result is not zero then they are not equal, continue
	j wrong				#else, element found, return false
	here2:
	bne $t6, 10, .loop1		#if counter == 10 (all col checked) check box, else loop again
	
#check 3x3 box
box:
	li $s2, 3			#load immediate into register for division
	div $a2, $s2			#divide col index by 3
	mfhi $t8			#move remainder into t8
	sub $s3, $a2, $t8		#subtract remainder from col index = column index starting this 3x3 box
	mul $s3, $s3, 4			#multiply by 4 = no. of bytes from left of grid to this column
	div $a3, $s2			#divide row index by 3
	mfhi $t9			#move remainder into t9
	sub $s4, $a3, $t9		#subtract remainder from row index = row index starting this 3x3 box
	mul $s4, $s4, 36		#multiply by 36 (4*9) = no. of bytes from start of grid to first element in the row starting the 3x3 box
	add $s1, $s3, $s4		#add (no. of bytes from left of grid to this column) + (no. of bytes from start of grid to first element in the row)
					#to get no. of bytes from start of grid to first element in the 3x3 box
	add $s1, $s1, $a0		#add to grid address = address of first element in 3x3 box (s1)
	
	li $t6, 1			#loop counter
	j .loop2			#dont go to "inc" in first iteration
	
	inc:
	add $s1, $s1, 24		#skip 6 elements(next row in 3x3 box)	
	.loop2:
	lw $t5, ($s1)			#load element
	add $s1, $s1, 4			#next element address in box
	add $t6, $t6, 1			#increment loop counter
	xor $t0, $t3, $t5		#xor vlue from grid with value being placed in empty spot
	bnez $t0, here3			#if xor result is not zero then they are not equal, continue
	j wrong				#else, element found, return false
	here3:
	beq $t6, 4, inc			#if 3 elements done, go to inc (next row in 3x3 box)
	beq $t6, 7, inc			#if 6 elements done, go to inc (next row in 3x3 box)
	bne $t6, 10, .loop2		#if counter == 10 (all box checked) exit loop

li $a1, 1				#return true
j ret
wrong:

li $a1, 0				#return false
ret:
jr $ra

#--------------- end of check function--------------

return:
lw $ra, ($sp)				#pop return address
add $sp, $sp, 4				#move stack ptr
jr $ra

printsudoku:
la $t1, sudoku				#load address of grid into t1
li $a3, 1				#reset col index
.loopa:	
li $a2, 1				#reset row index
	.loopb:	
	li $v0, 1			#system code for print integer
	lw $a0, ($t1)			#load element into a0 to print
	bnez $a0, .prnt			#if element is not zero, print it
	li $v0, 4			
	la $a0, star			#else, print *
	.prnt:
	syscall				#print element
	li $v0, 4			#system code for print string
	la $a0, space			#load space character address into a0
	syscall				#print space
	add $t1, $t1, 4			#next element address
	add $a2, $a2, 1			#increment col index
	bne $a2, 10, .loopb		#if column not all printed yet loop again
add $a3, $a3, 1				#increment row index
la $a0, endl				#load address of \n character into a0
syscall					#print \n
bne $a3, 10, .loopa			#if not all rows printed yet, loop again

li $v0, 4				#system code for print string
la $a0, endl				#load address of \n character into a0

syscall					#print \n twice when done
syscall

jr $ra					#return

exit:
li $v0, 10				#system code for exit program
syscall					#exit

