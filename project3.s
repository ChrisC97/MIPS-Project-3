.data
	base: .word 33
	MsgInput: .asciiz "Input: "
	MsgInvalid: .asciiz "NaN"
	MsgDivider: .asciiz ","
	newLine: .asciiz "\n"
	userString: .space 1001 #1000 characters
	charCount: .word 0
	# CalculateValues #
	cvMessage: .space 1001 #1000 characters.
	
.text # Instructions section, goes in text segment.

main:
	# PROMPT INPUT #
	li $v0, 4 # System call to print a string.
	la $a0, MsgInput # Load string to be printed.
	syscall # Print string.
	
	# READ USER INPUT #
	li $v0, 8 # System call for taking in input.
	la $a0, userString # Where the string is saved.
	li $a1, 1001 # Max number of characters to read.
	syscall
	
	# PASS STRING THROUGH STACK #
	la $t0, userString # message address.
	addi $t1, $t1, 1000 # i.
	addiu $sp, $sp, -1 # expand stack by one byte.
	sb $zero, ($sp) # Save "null" to the stack. That signifies the end of the string.
mStringSaveLoop:
	add $t2, $t0, $t1 # message[i] address.
	lb $t3, 0($t2) # Character at message[i].
	addiu $sp, $sp, -1 # expand stack by one byte.
	sb $t3, 0($sp) # Save the character to the stack.
	addiu $t1, $t1, -1 # i--
	blt, $t1, $zero, mStringSaveLoopEnd # i < 0, exit out.
	j mStringSaveLoop # Loop back.
mStringSaveLoopEnd:
	# CALL FUNCTION #
	jal CalculateValues
	
	# END OF PROGRAM #
endProgram:
	li $v0, 10 # Exit program system call.
	syscall
	
	
# CALCULATE VALUES #
CalculateValues:
	la $t0, cvMessage # cvMessage address.
	addi $t1, $t1, 0 # i.
	jr $ra # return to main.