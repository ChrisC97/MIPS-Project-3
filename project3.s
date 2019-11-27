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
	addi $t1, $zero, 1000 # i = 1000.
	addiu $sp, $sp, -1 # stackPointer -= 1 (in bytes).
	sb $zero, 0($sp) # Save "null" to the stack. That signifies the end of the string.
mStringSaveLoop:
	add $t2, $t0, $t1 # message[i] address.
	lb $t3, 0($t2) # Character at message[i].
	addiu $sp, $sp, -1 # stackPointer -= 1.
	sb $t3, 0($sp) # stack[stackPointer] = message[i].
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
	add $t1, $zero, $zero # i = 0.
cvStringCpyLoop:
	add $t2, $t0, $t1 # cvMessage[i] address.
	lb $t3, 0($sp) # stackCharacter.
	beq $t3, 0, cvStringCpyEnd # stackCharacter == null, then exit out. 
	sb $t3, 0($t2) # cvMessage[i] = stackCharacter.
	addiu $t1, $t1, 1 # i++
	addiu $sp, $sp, 1 # stackPointer += 1.
	bgt $t1, 1000, cvStringCpyEnd # i > 1000, exit out.
	j cvStringCpyLoop # Loop back.
cvStringCpyEnd:
	jr $ra # return to main.