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
	cvResult: .space 1001 # 1000 characters.
	# Process Substring #
	psSubstring: .space 1001 # 1000 characters.
	
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
	addiu $sp, $sp, -4 # stackPointer -= 1 (in words).
	sb $zero, 0($sp) # Save "null" to the stack. That signifies the end of the string.
mStringSaveLoop:
	add $t2, $t0, $t1 # message[i] address.
	lb $t3, 0($t2) # Character at message[i].
	addiu $sp, $sp, -4 # stackPointer -= 1.
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
	# COPY STRING -> CVMESSAGE #
cvStringCpyLoop:
	add $t2, $t0, $t1 # cvMessage[i] address.
	lb $t3, 0($sp) # stackCharacter.
	beq $t3, 0, cvStringCpyEnd # stackCharacter == null, then exit out. 
	sb $t3, 0($t2) # cvMessage[i] = stackCharacter.
	addiu $t1, $t1, 1 # i++
	addiu $sp, $sp, 4 # stackPointer += 1.
	bgt $t1, 1000, cvStringCpyEnd # i > 1000, exit out.
	j cvStringCpyLoop # Loop back.
cvStringCpyEnd:
	# SPLIT SUBSTRINGS #
	la $s0, cvMessage # cvMessage address.
	add $s1, $zero, $zero # i = 0.
	addiu $sp, $sp, -4 # stackPointer -= 1.
	sb $zero, 0($sp) # Save "null" to the stack. That signifies the end of the string.
cvProcessSubLoop:
	add $s2, $s0, $s1 # cvMessage[i] address.
	lb $s3, 0($s2) # cvMessage[i].
	addiu $sp, $sp, -4 # stackPointer -= 1.
	sb $s3, 0($sp) # stack[stackPointer] = cvMessage[i].
	addi $s1, $s1, 1 # i++.
	beq $s3, 44, cvProcessAndLoop # cvMessage[i] == ','. Process what's on the stack and loop.
	beq $s3, 0, cvProcessAndEnd # cvMessage[i] == null. Process one more time.
	j cvProcessSubLoop
cvProcessAndLoop:
	sw $ra, 0($sp) # stack[stackPointer] = $ra. We overrirde the ',' character.
	jal ProcessSubstring # Process substring.
	lw $ra, 0($sp) # $ra = stack[stackPointer].
	addiu $sp, $sp, 4 # Pop $ra off the stack.
	j cvProcessSubLoop
cvProcessAndEnd:
	sw $ra, 0($sp) # stack[stackPointer] = $ra. We overrirde the null character.
	jal ProcessSubstring # Process substring.
	lw $ra, 0($sp) # $ra = stack[stackPointer].
	addiu $sp, $sp, 4 # Pop $ra off the stack.
cvEnd:
	jr $ra # return to main.
	
# PROCESS SUBSTRING #
ProcessSubstring:
	la $t0, psSubstring # psSubstring address.
	add $t1, $zero, $zero # i = 0.
	addi $t2, $zero, 4 # sPos = 1.
	# COPY STRING -> PSSUBSTRING #
psStringCpyLoop:
	add $t3, $t0, $t1 # psSubstring[i] address.
	add $t5, $sp, $t2 # stackCharacter address.
	lb $t4, 0($t5) # stackCharacter.
	beq $t4, 0, psStringCpyNull # stackCharacter == null, fill with null.
psStringCpyChar:
	sb $t4, 0($t3) # psSubstring[i] = stackCharacter.
	addiu $t1, $t1, 1 # i++
	addiu $t2, $t2, 4 # sPos++
	bgt $t1, 1000, psStringCpyEnd # i > 1000, exit out.
	j psStringCpyLoop # Loop back.
psStringCpyNull:
	sb $t4, 0($t3) # psSubstring[i] = stackCharacter.
	addiu $t1, $t1, 1 # i++
	bgt $t1, 1000, psStringCpyEnd # i > 1000, exit out.
	j psStringCpyLoop # Loop back.
psStringCpyEnd:
	lw $t8, 0($sp) # Get ra off the stack.
	add $sp, $sp, $t2 # stackPointer + sPos.
	addiu $sp, $sp, -4 # create space in the stack.
	sw $t8, 0($sp) # Put ra on the stack.
	jr $ra # return to CalculateValues.