.data

bank_array: 	.word 0, 0, 0, 0, 0			# this array holds banking details
query_array: 	.space 104				# space to hold 25 element query plus an end token
# error message for invalid transactions
error_message:	.asciiz "That is an invalid banking transaction. Please enter a valid one.\n" 
.align 2
command_buffer:	.space	36				# space to hold upto 8 characters and a space character
command_array:	.space	24				# space to hold 5 items and an end token

.text
.globl main

main:
	# initializing query_array with the end token
	la	$t0, query_array
	li	$t1, -1
	sw	$t1, 0($t0)
	
restart:# initializing command_array with the end token
	la	$t0, command_array
	sw	$t1, 0($t0)
		
	# receive command until the user presses 'enter'
	# stop to record the command after every 'space'
	la	$s0, command_buffer
	la	$s1, command_array
	
receive:jal	read	
	move	$a0,$v0
	
	beq	$a0, 10, enter		# end with 'enter'
	sw	$v0, 0($s0)		# write to buffer
	beq	$a0, 32, record		# record intruction after each 'space'
					# want space to be in the buffer as an end token but before s0 update since it will be updated in record
	addi	$s0, $s0, 4
	j	receive	
	
enter:	# add -1 as end token at the end of both the array and the buffer
	li	$t0, -1
	sw	$t0, ($s1)
	sw	$t0, ($s0)
	# get the last value
	# if command array length == 0 then QT or error
	la	$a0, command_array
	li	$a1, -1
	jal	length
	bne	$v0, 0, value
	
	# if commnad array==0 but commnand buffer isnt eaxctly 2 length
	la	$a0, command_buffer
	li	$a1, -1
	jal	length
	bne	$v0, 2, error
	
	lw	$s0, command_buffer
	lw	$s1, command_buffer+4
	bne	$s0, 'Q', error
	bne	$s1, 'T', error
	j	quit
	# else; getvalue once and end
value:	
	la	$a0, command_buffer
	li	$a1, -1			# end character
	jal	get_value
	sw	$v0, 0($s1)
	
	li	$t0, -1
	sw	$t0, 4($s1)		# -1 will incidate the end of input array
	lw	$s0, command_array
	lw	$s1, command_array+4	# to be used to determmine command later
	
	j	test1
	
	
record:	lw	$s2, command_buffer	# determining whether its the command letters or numbers
	beq	$s2, 32, receive	# ignore if its repeated spaces
	addi	$s2, $s2, -48
	li	$t1, 0
	li	$t2, 9
	
	slt	$t3, $s2, $t1
	bne	$t3, $0, error
	
	slt	$t3, $t2, $s2
	bne	$t3, $0, letters
	
	# get value
	la	$a0, command_buffer
	li	$a1, 32			# scape character
	jal	get_value
	sw	$v0, 0($s1)
	addi	$s1, $s1, 4		# set command array to next element
	la	$s0, command_buffer	# reset command buffer back to 0
	j	receive
	
	
letters:# if we're considering letters, the buffer should be exactly 2 characters long
	la	$a0, command_buffer
	li	$a1, 32
	jal	length
	bne	$v0, 2, error

	addi	$s2, $s2, 48		# bring the test char back to its ascii value
	li	$t1, 65
	li	$t2, 90
	slt	$t3, $s2, $t1
	bne	$t3, $0, error
	
	slt	$t3, $t2, $s2
	bne	$t3, $0, error
	
	sw	$s2, command_array
	
	lw	$s2, command_buffer+4	# if first went in as a letter so should the second one
	li	$t1, 65
	li	$t2, 90
	slt	$t3, $s2, $t1
	bne	$t3, $0, error
	
	slt	$t3, $t2, $s2
	bne	$t3, $0, error
	
	sw	$s2, command_array+4
	
	la	$s1, command_array+8	# set command array to 3rd element
	la	$s0, command_buffer	# reset command buffer back to 0
	j	receive	
	
test1:	bne	$s1, 'H', test2
	bne	$s0, 'C', sub1
	la	$a0, command_array
	jal	length
	bne	$v0, 4, error
	lw	$a0, command_array+8
	lw	$a1, command_array+12
	jal	open_checking
	j	ending
sub1:	bne	$s0, 'Q', test2
	la	$a0, command_array
	jal	length
	bne	$v0, 3, error
	lw	$a0, command_array+8
	jal	history
	j	no_change_ending

test2:	bne	$s1, 'L', test3
	bne	$s0, 'C', sub2
	la	$a0, command_array
	jal	length
	bne	$v0, 3, error
	lw	$a0, command_array+8
	jal	close_account
	j	ending
sub2:	bne	$s0, 'B', test3
	la	$a0, command_array
	jal	length
	bne	$v0, 3, error
	lw	$a0, command_array+8
	jal	get_balance
	j	no_change_ending

test3:	bne	$s1, 'T', test4	
	bne	$s0, 'W', sub3
	la	$a0, command_array
	jal	length
	bne	$v0, 4, error
	lw	$a0, command_array+8
	lw	$a1, command_array+12
	jal	withdraw
	j	ending
sub3:	bne	$s0, 'Q', test4
	jal	quit			

test4:	bne	$s0, 'D', test5
	bne	$s1, 'E', test5
	la	$a0, command_array
	jal	length
	bne	$v0, 4, error
	lw	$a0, command_array+8
	lw	$a1, command_array+12
	jal	deposit
	j	ending
	
test5:	bne	$s0, 'L', test6
	bne	$s1, 'N', test6
	la	$a0, command_array
	jal	length
	bne	$v0, 3, error
	lw	$a0, command_array+8
	jal	get_loan
	j	ending
	
test6:	bne	$s0, 'T', test7
	bne	$s1, 'R', test7
	la	$a0, command_array
	jal	length
	bne	$v0, 5, loan
	lw	$a0, command_array+8
	lw	$a1, command_array+12
	lw	$a2, command_array+16
	jal	transfer
	j	ending
	
loan:	bne	$v0, 4, error
	lw	$a0, command_array+8
	lw	$a1, command_array+12
	jal	transfer_loan
	j	ending
	
test7:	bne	$s0, 'S', error
	bne	$s1, 'V', error
	la	$a0, command_array
	jal	length
	bne	$v0, 4, error
	lw	$a0, command_array+8
	lw	$a1, command_array+12
	jal	open_savings	
	j	ending		

error:	li	$v0, 4
	la	$a0, error_message
	syscall
	j	restart
	
ending:	
	la	$a0, query_array
	li	$a1, -1
	jal	length
	move	$a0, $v0
	jal	update_query
	la	$a0, bank_array
	jal	print_array
	#la	$a0, query_array
	#li	$a1, -1
	#jal	length
	#move	$a0, $v0
	#li	$a1, 5
	#jal	print_query
	#li	 $v0, 11
	#li	$a0, 10
	#syscall

no_change_ending:
	j	restart	
###########################
####### END OF MAIN #######
###########################	

## read
read:  	
	lui	$t0, 0xffff 		#ffff0000
read_loop:
	lw	$t1, 0($t0) 		#control
	andi	$t1,$t1,0x0001
	beq	$t1,$zero,read_loop
	lw	$v0, 4($t0) 		#data	
	jr	$ra

## get value
get_value:
	# a0 <- start of value
	# a1 <- end token
	li	$v0, 0
	li	$t2, 0
	li	$t3, 9
value_loop:	
	lw	$t0, 0($a0)
	beq	$t0, $a1, value_done	# when end token is reached we're at the end
	addi	$t0, $t0, -48		# convert t0 from ascii to int
	
	slt	$t1, $t0, $t2		# digit can't be < 0
	bne	$t1, $0, error
	
	slt	$t1, $t3, $t0		# digit can't be > 9
	bne	$t1, $0, error
	
	mul	$v0, $v0, 10
	add	$v0, $v0, $t0
	
	addi	$a0, $a0, 4
	j	value_loop
	
value_done:
	jr	$ra		
	
## length
length:
	# a0 <- beginning of array
	# a1 <- end token
	add	$v0, $zero, $zero
	
length_loop:	
	lw	$t0, 0($a0)
	beq	$t0, $a1, length_done
	addi	$v0, $v0, 1
	addi	$a0, $a0, 4
	j	length_loop
	
length_done:	
	jr	$ra
	
## update query
update_query:	
	la	$a0, query_array
	li	$a1, -1
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	jal	length		# returns number of elements in query
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	li	$t0, 25		# 25 length means 5 bank array already resigtered
	slt	$t2, $v0, $t0
	beq	$t2, $0, pop	# if it has 5 arrays already get rid of first // shift // add
	
	# just contatinate
	mul	$t0, $v0, 4	# amount we need to move by to find the end of query array
	la	$a0, query_array($t0)
	la	$a1, bank_array
	
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	jal	copy_array	# from bank to end of query
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	
pop:	# 5 total copies
	# 4 copies shifting arrays up
	# one last copy from bank array
	la	$a0, query_array
	la	$a1, 20($a0)
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	jal	copy_array
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	move	$a0, $a1
	la	$a1, 20($a0)
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	jal	copy_array
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	move	$a0, $a1
	la	$a1, 20($a0)
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	jal	copy_array
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	move	$a0, $a1
	la	$a1, 20($a0)
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	jal	copy_array
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	move	$a0, $a1
	la	$a1, bank_array
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	jal	copy_array
	lw	$ra, ($sp)
	addi	$sp, $sp, 4

copy_array:
	# a0 <- destination
	# a1 <- source	
	# wont disturb a0 and a1 so we can reuse them in pop
	move	$t0, $a0
	move	$t1, $a1
	
	li	$t2, 0		# counter upto 5
	li	$t3, 5		# limit for counter
	
copy:	lw	$t4, ($t1)
	sw	$t4, ($t0)
	
	addi	$t0, $t0, 4
	addi	$t1, $t1, 4
	addi	$t2, $t2, 1
	
	slt	$t4, $t2, $t3
	bne	$t4, $0, copy
	
	li	$t4, -1
	sw	$t4, ($t0)
	jr	$ra	
	
## print query
print_query:
	# a0 <- length of query history
	# a1 <- munber of query items in question (how many do we want to print)
	li	$t0, 0
	move	$t1, $a0
	addi	$t2, $a0, -1
	mul	$t2, $t2, 20
	la	$t2, query_array($t2)
	li	$t3, 0		# counter to keep track how many query items are printed
query_print_loop:
	li	$t4, 0
	slt	$t5, $t4, $a1
	beq	$t5, $0, error

	slt	$t5, $a0, $a1
	bne	$t5 $0, error
	
	li	$t4, 5
	slt	$t5, $t4, $a1
	bne	$t5 $0, error

	slt	$t5, $t0, $t1
	beq	$t5, $0, query_print_done
	
	slt	$t5, $t3, $a1
	beq	$t5, $0, query_print_done	
	# save t0, t1, t3, ra
	addi	$sp, $sp, -16
	sw	$ra, 12($sp)
	sw	$t0, 8($sp)
	sw	$t1, 4($sp)
	sw	$t3, 0($sp)
	la	$a0, 0($t2)
	jal	print_array
	lw	$ra, 12($sp)
	lw	$t0, 8($sp)
	lw	$t1, 4($sp)
	lw	$t3, 0($sp)
	addi	$sp, $sp, 16
		
	addi	$t0, $t0, 1
	addi	$t2, $t2, -20
	addi	$t3, $t3, 1
	j	query_print_loop		
	
query_print_done:
	jr	$ra	

print_array:
	# since loeading 0s need to be accounted for, we wont have a loop anymore, since it was running only 3 times at that point
	# a0 <- address
	add	$t0, $0, $a0

	li	$v0, 11
	li	$a0, 91		# [
	syscall
	
	# CHECKING ACCOUNT NUMBER
	li	$v0, 1
	
	lw	$a0, 0($t0)
	li	$t4, 9999
	slt	$t3, $t4, $a0
	bne	$t3, $0, digit5
	
	li	$t4, 999
	slt	$t3, $t4, $a0
	bne	$t3, $0, digit4
	
	li	$t4, 99
	slt	$t3, $t4, $a0
	bne	$t3, $0, digit3
	
	li	$t4, 9
	slt	$t3, $t4, $a0
	bne	$t3, $0, digit2
	
	
	li	$a0, 0
	syscall
	
digit2:	li	$a0, 0
	syscall

digit3:	li	$a0, 0
	syscall
	
digit4:	li	$a0, 0
	syscall
	
digit5:	lw	$a0, 0($t0)
	li	$v0, 1		
	syscall
	
	li	$v0, 11
	li	$a0, 44		# comma
	syscall
	li	$a0, 9		# tab
	syscall
	
	addi	$t0, $t0, 4
	#SAVINGS ACCOUNT NUMBER
	li	$v0, 1
	
	lw	$a0, 0($t0)
	li	$t4, 9999
	slt	$t3, $t4, $a0
	bne	$t3, $0, d5
	
	li	$t4, 999
	slt	$t3, $t4, $a0
	bne	$t3, $0, d4
	
	li	$t4, 99
	slt	$t3, $t4, $a0
	bne	$t3, $0, d3
	
	li	$t4, 9
	slt	$t3, $t4, $a0
	bne	$t3, $0, d2
	
	li	$a0, 0
	syscall
	
d2:	li	$a0, 0
	syscall

d3:	li	$a0, 0
	syscall
	
d4:	li	$a0, 0
	syscall
	
d5:	lw	$a0, 0($t0)
	li	$v0, 1		
	syscall
	
	li	$v0, 11
	li	$a0, 44		# comma
	syscall
	li	$a0, 9		# tab
	syscall
	addi	$t0, $t0, 4
	#CHECKING BALANCE
	li	$v0, 1
	lw	$a0, ($t0)
	syscall
	
	li	$v0, 11
	li	$a0, 44		# comma
	syscall
	li	$a0, 9		# tab
	syscall
	addi	$t0, $t0, 4
	#SAVING BALANCE
	li	$v0, 1
	lw	$a0, ($t0)
	syscall
	
	li	$v0, 11
	li	$a0, 44		# comma
	syscall
	li	$a0, 9		# tab
	syscall
	addi	$t0, $t0, 4
	#LOAN
	li	$v0, 1
	lw	$a0, ($t0)
	syscall
	
	li	$v0, 11
	li	$a0, 93		# ]
	syscall
	li	$a0, 10		# newline
	syscall
	jr	$ra	
	
	
######################
##### OPERATIONS #####
######################

open_checking:
	li	$t0, 99999
	slt	$t1, $t0, $a0
	bne	$t1, $0, error
	
	slt	$t0, $0, $a1
	beq	$t0, $0, error
	
	li	$t0, 0
	slt	$t1, $t0, $a0
	beq	$t1, $0, error
	
	lw	$t0, bank_array
	bne	$t0, $0, error
	lw	$t0, bank_array+4
	beq	$t0, $a0, error
	sw	$a0, bank_array
	sw	$a1, bank_array+8
	jr	$ra

open_savings:	
	li	$t0, 99999
	slt	$t1, $t0, $a0
	bne	$t1, $0, error
	
	slt	$t0, $0, $a1
	beq	$t0, $0, error
	
	li	$t0, 0
	slt	$t1, $t0, $a0
	beq	$t1, $0, error
	
	lw	$t0, bank_array
	beq	$t0, $a0, error
	lw	$t0, bank_array+4
	bne	$t0, $0, error
	sw	$a0, bank_array+4
	sw	$a1, bank_array+12
	jr	$ra

	
deposit:
	la	$t0, bank_array	# will be +4 if savings account to accout for the shift in the array
	lw	$t1, 0($t0)
	beq	$t1, $a0, deposit_okay
	addi	$t0, $t0, 4
	lw	$t1, 0($t0)
	bne	$t1, $a0, error
		
deposit_okay:
	lw	$t2, 8($t0)	# +8 from t0 will give balance for that account
	add	$t2, $t2, $a1
	sw	$t2, 8($t0)
	jr	$ra

withdraw:
	mul	$a1, $a1, -1	# negative amount for withdrawing
	la	$t0, bank_array	# will be +4 if savings account to accout for the shift in the array
	lw	$t1, 0($t0)
	beq	$t1, $a0, withdraw_okay
	addi	$t0, $t0, 4
	mul	$a1, $a1, 105	# 5% fee added to amount to be taken out
	div	$a1, $a1, 100
	lw	$t1, 0($t0)
	bne	$t1, $a0, error
		
withdraw_okay:
	lw	$t2, 8($t0)	# +8 from t0 will give balance for that account
	add	$t2, $t2, $a1
	
	# if balance becomes negative we cannot withdraw
	slt	$t3, $t2, $0
	bne	$t3, $0, error
	
	sw	$t2, 8($t0)
	jr	$ra
	
get_loan:
	lw	$t0, bank_array+8
	lw	$t1, bank_array+12
	add	$t1, $t0, $t1
	
	li	$t2, 10000		# threshold for taking a loan	
	slt	$t0, $t1, $t2
	bne	$t0, $0, error
	
	lw	$t3, bank_array+16	# existing loans
	add	$t3, $t3, $a0		# total loans if new one is taken
	
	div	$t1, $t1, 2		# maximum loan can be taken
	slt	$t0, $t1, $t3
	bne	$t0, $0, error
	
	sw	$t3, bank_array+16
	
	jr	$ra
	
transfer:
	# a0 <- acc no FROM
	# a1 <- acc no TO
	# a2 <- amount transferred
	
	lw	$t0, bank_array
	bne	$t0, $a0, save2check
check2save:
	lw	$t1, bank_array+4
	bne	$t1, $a1, error
	lw	$t2, bank_array+8
	slt	$t3, $t2, $a2
	bne	$t3, $0, error	# insufficient funds
	
	lw	$t4, bank_array+12
	add	$t4, $t4, $a2
	mul	$a2, $a2, -1
	add	$t2, $t2, $a2
	
	sw	$t2, bank_array+8
	sw	$t4, bank_array+12
	jr	$ra

save2check:
	lw	$t0, bank_array+4
	bne	$t0, $a0, error
	lw	$t1, bank_array
	bne	$t1, $a1, error
	
	lw	$t2, bank_array+12
	slt	$t3, $t2, $a2
	bne	$t3, $0, error	# insf funds
	
	lw	$t4, bank_array+8
	add	$t4, $t4, $a2
	mul	$a2, $a2, -1
	add	$t2, $t2, $a2
	
	sw	$t2, bank_array+12
	sw	$t4, bank_array+8
	jr	$ra
		
	
transfer_loan:
	# a0 <- acc no
	# a1 <- amount to pay
	la	$t0, bank_array	# will be +4 if savings account to accout for the shift in the array
	lw	$t1, 0($t0)
	beq	$t1, $a0, tr_loan_okay
	addi	$t0, $t0, 4
	lw	$t1, 0($t0)
	bne	$t1, $a0, error
		
tr_loan_okay:
	lw	$t2, 8($t0)		# +8 from t0 will give balance for that account
	lw	$t3, bank_array+16	# loan amount
	slt	$t4, $t2, $a1
	bne	$t4, $0, error		# insf fund
	slt	$t4, $t3, $a1
	bne	$t4, $0, error		# dont have that much loan to pay
	
	mul	$a1, $a1, -1
	add	$t2, $t2, $a1
	add	$t3, $t3, $a1
	
	sw	$t2, 8($t0)		# where it was taken from
	sw	$t3, bank_array+16
	jr	$ra

close_account:
	# usage of t registers:
	#
	#          | account closing    |  other account
	# -----------------------------------------------
	# address  |	t0		|	t3
	# acc no   |	t1		|	t4
	# balance  |	t2		|	-
	#
	# t6: loan amount
	la	$t0, bank_array		# will be +4 if savings account to accout for the shift in the array
	la	$t3, bank_array+4	# where money would go
	lw	$t1, 0($t0)
	beq	$t1, $a0, close_okay
	addi	$t0, $t0, 4
	addi	$t3, $t3, -4
	lw	$t1, 0($t0)
	bne	$t1, $a0, error		# account not found
close_okay:
	lw	$t2, 8($t0)
	lw	$t4, 0($t3)		# all table t's set
	
	lw	$t6, bank_array+16	# all of my t's are set
	
	# all scenarios actually boil down to 2
	# if the other account it open we transfer all our money to that one
	# if this is the only open account we try to pay all the loan we have, if we cant do that we shouldnt be closing the account anyways

	beq	$t4, $0, pay_loan
	
	# transfer the money to other account
	addi	$sp, $sp, -16
	sw	$ra, ($sp)
	sw	$t0, 4($sp)
	sw	$t1, 8($sp)
	sw	$t2, 12($sp)
	move	$a0, $t1
	move	$a1, $t4
	move	$a2, $t2
	jal	transfer
	lw	$ra, ($sp)
	lw	$t0, 4($sp)
	lw	$t1, 8($sp)
	lw	$t2, 12($sp)
	addi	$sp, $sp, 16
	j	close
	
pay_loan:
	addi	$sp, $sp, -16
	sw	$ra, ($sp)
	sw	$t0, 4($sp)
	sw	$t1, 8($sp)
	sw	$t2, 12($sp)
	move	$a0, $t1
	move	$a1, $t6
	jal	transfer_loan
	lw	$ra, ($sp)
	lw	$t0, 4($sp)
	lw	$t1, 8($sp)
	lw	$t2, 12($sp)
	addi	$sp, $sp, 16
	# this will either pay all loans or give error

close:	li	$t1, 0
	li	$t2, 0
	sw	$t1, 0($t0)
	sw	$t2, 8($t0)	
	jr	$ra
	
get_balance:	
	la	$t0, bank_array
	lw	$t1, 0($t0)
	beq	$t1, $a0, balance_okay
	addi	$t0, $t0, 4
	lw	$t1, 0($t0)
	bne	$t1, $a0, error

balance_okay:
	lw	$t1, 8($t0)
	li	$v0, 11
	li	$a0, '$'
	syscall
	li	$v0, 1
	move	$a0, $t1
	syscall
	li	$v0, 11
	li	$a0, 10
	syscall
	jr	$ra
	
history:
	move	$t7, $a0	# to many recursive calls, trying to be safe :)
	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	la	$a0, query_array
	li	$a1, -1
	jal	length
	move	$a0, $v0
	div	$a0, $a0, 5	# every 5 elements is one query line
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	
	move	$a1, $t7
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	print_query
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

quit:	li	$v0,10
	syscall
