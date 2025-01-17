.data
	base: .word 33
	MsgInput: .asciiz "Input: "
	MsgInvalid: .asciiz "NaN"
	MsgDivider: .asciiz ","
	userString: .space 1001 #1000 characters
	charCount: .word 0
	# Main #
	stackEnd: .word 0
	# CalculateValues #
	cvMessage: .space 1001 #1000 characters.
	cvResult: .space 1001 # 1000 characters.
	# Process Substring #
	psSubstring: .space 1001 # 1000 characters.
	psTempSubstring: .space 1001 # 1000 characters.
	
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
	jal CalculateValues # Subprogram A.
	
mPrintStrings:
	addiu $t0, $zero, -4 # i = -1.
	addu $t7, $zero, $zero # lastPrint = false.
	addu $t8, $zero, $zero # stackPos = 0.
	addu $t9, $zero, $sp # stackStart.
mPrintStringsLoop:
	lw $t8, stackEnd # stackEnd, aka the top of this list.
	addu $t8, $t8, $t0 # stackPos = stackEnd - i.
	blt $t8, $t9, endProgram # stackPos < stackStart, exit out.
	beq $t8, $t9, mLastPrint # stackPos == stackStart
	j mRegularPrint
mLastPrint:
	addi $t7, $zero, 1 # lastPrint = true (1).
mRegularPrint:
	lw $t1, 0($t8) # result = stack[stackPos].
	blt $t1, -2, endProgram # result <= -3, end of stack. Exit out.
	beq $t1, -2, mPSLEnd # result == -2, null character. Skip it.
	blt $t1, $zero, mPSLPrintError # result == -1, invalid.
mPSLPrint:
	li $v0, 1 # Printing result
	add $a0, $zero, $t1 # Set a0 to the result.
	syscall  # Print number
	
	beq $t7, 1, mPSLEnd
	li $v0, 4 # System call to print a string.
	la $a0, MsgDivider # Load string to be printed.
	syscall # Print string.
	
	j mPSLEnd # Keep looping.
mPSLPrintError:
	li $v0, 4 # System call to print a string.
	la $a0, MsgInvalid # Load string to be printed.
	syscall # Print string.
	
	beq $t7, 1, mPSLEnd
	li $v0, 4 # System call to print a string.
	la $a0, MsgDivider # Load string to be printed.
	syscall # Print string.
mPSLEnd:
	#addiu $sp, $sp, 4 # stackPointer++.
	addiu $t0, $t0, -4 # i -= 1.
	j mPrintStringsLoop
	
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
	add $s1, $zero, $zero # i = 0.
	addiu $sp, $sp, -4 # stackPointer -= 1.
	addiu $t0, $zero, -3 # -3.
	sw $t0, 0($sp) # Save "-3" to the stack. That signifies the end of the stack.
	la $t0, ($sp)
	sw $t0, stackEnd # Save the position of the stack before this operation.
cvProcessSubLoop:
	la $s0, cvMessage # cvMessage address.
	add $s2, $s0, $s1 # cvMessage[i] address.
	lb $s3, 0($s2) # cvMessage[i].
	addiu $sp, $sp, -4 # stackPointer -= 1.
	sb $s3, 0($sp) # stack[stackPointer] = cvMessage[i].
	addi $s1, $s1, 1 # i++.
	beq $s3, 44, cvProcessAndLoop # cvMessage[i] == ','. Process what's on the stack and loop.
	beq $s3, 0, cvProcessAndEnd # cvMessage[i] == null. Process one more time.
	beq $s3, 10, cvProcessAndEnd # cvMessage[i] == \n. Process one more time.
	j cvProcessSubLoop	
cvProcessAndLoop:
	sw $ra, 0($sp) # stack[stackPointer] = $ra. We overrirde the ',' character.
	jal ProcessSubstring # Process substring.
	lw $ra, 0($sp) # $ra = stack[stackPointer].
	sw $v0, 0($sp) # stack[stackPointer] = result.
	addiu $sp, $sp, -4 # stackPointer -= 1.
	addiu $t0, $zero, -2 # -2.
	sw $t0, 0($sp) # Save "-2" to the stack. This will be our null.
	j cvProcessSubLoop
cvProcessAndEnd:
	sw $ra, 0($sp) # stack[stackPointer] = $ra. We overrirde the null character.
	jal ProcessSubstring # Process substring.
	lw $ra, 0($sp) # $ra = stack[stackPointer].
	sw $v0, 0($sp) # stack[stackPointer] = result.
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
	blt $t4, 1, psStringCpyNull # stackCharacter <= null, fill with null.
psStringCpyChar:
	sb $t4, 0($t3) # psSubstring[i] = stackCharacter.
	addiu $t1, $t1, 1 # i++
	addiu $t2, $t2, 4 # sPos++
	bgt $t1, 1000, psStringCpyEnd # i > 1000, exit out.
	j psStringCpyLoop # Loop back.
psStringCpyNull:
	sb $zero, 0($t3) # psSubstring[i] = null.
	addiu $t1, $t1, 1 # i++
	bgt $t1, 1000, psStringCpyEnd # i > 1000, exit out.
	j psStringCpyLoop # Loop back.
psStringCpyEnd:
	lw $t8, 0($sp) # Get ra off the stack.
	add $sp, $sp, $t2 # stackPointer + sPos.
	addiu $sp, $sp, -4 # create space in the stack.
	sw $t8, 0($sp) # Put ra on the stack.
	
	# MAIN FUNCTION #
psMain:
	addiu $sp, $sp, -4 # create space in the stack.
	sw $ra, 0($sp) # Push our ra on the stack.
	
	jal removeLeading
	jal replaceString
	jal findCharCount
	sw $v0, charCount # set charCount.
	lw $t5, charCount # load charCount.
	
	jal removeTrailing
	
	slt $t0, $t5, 5 # characterCount < 5?
	beq $t0, 0, psInvalid # characterCount >= 5, invalid.
	
	slt $t0, $t5, 1 # characterCount < 1?
	beq $t0, 1, psInvalid # characterCount < 1, invalid.

psCalc:
	add $s0, $zero, $zero # i = 0.
	lw $s7, charCount # charCount.
	lw $t8, base # base.
	add $s2, $zero, $zero # power.
	add $s3, $zero, $zero # finalResult = 0.
	la $s4, psSubstring # psSubstring address.
psCalcLoop:
	beq $s0, $s7, psValid # i == charCount, exit out.
	bgt $s0, $s7, psValid # i > charCount, exit out.
	
	# Variables
	add $s5, $s4, $s0 # psSubstring[i] address.
	lb $s6, 0($s5) # psSubstring[i].
	
	# Logic
	beq $s6, 0, psValid # psSubstring[i] == null, end of string. exit out.
	
	add $a0, $zero, $s6 # Pass the character.
	jal toUppercase # Convert the character to uppercase. 
	add $s6, $zero, $v0 # psSubstring[i] = result.
	
	add $a0, $zero, $s6 # Pass the character.
	jal isCharInRange # Is the character in our range? (0-9 and A-Z)
	add $s6, $zero, $v0 # psSubstring[i] = result.
	
	bgt $s6, $t8, psInvalid # If the number is larger than our base, it's NaN.
	beq $s6, $t8, psInvalid # If the number equals our base, it's NaN.
	
	# Calculation
	add $a0, $zero, $t8 # Base.
	add $a1, $zero, $s2 # Power.
	jal powerFunct
	mult $s6, $v0 # char * (base^(power))
	mflo $v0 # powerResult = char * (base^(power))
	add $s3, $s3, $v0 # finalResult += powerResult.
psCalcLoopEnd:
	addi $s0, $s0, 1 # i++
	addi $s2, $s2, 1 # power++
	j psCalcLoop # Check the next character.
	
psInvalid:
	addi $v0, $zero, -1 # return -1.
	j psReturn
psValid:
	add $v0, $zero, $s3 # return finalResult.
psReturn:		
	lw $ra, 0($sp) # Pop ra off the stack.
	addi $sp, $sp, 4 # Return the stack pointer.
	jr $ra # return to CalculateValues.
	
	
## CHARACTER CONVERSION ##

# POWER #
powerFunct: # a0 = base, a1 = power, v0 = Result.
	add $t0, $zero, $zero # i.
	addi $t0, $t0, 1 # add 1 to i once.
	add $v0, $zero, $a0 # powerResult = base.
	blt $a1, 1, pFEndOne # power <= 0, just set result to 1.
	blt $a1, 2, pFEnd # power == 1, just return the number.
pFLoop:
	mult $v0, $a0 # powerResult * base
	mflo $v0 # powerResult = powerResult * base.
	addi, $t0, $t0, 1 # i++.
	blt $t0, $a1, pFLoop # i < power, keep looping.
	j pFEnd
pFEndOne:
	addi $v0, $zero, 1 # powerResult = 1.
pFEnd:
	jr $ra
	
# CONVERT TO UPPERCASE #
toUppercase: # a0 = character, v0 = resultCharacter.
	blt $a0, 'a', toUppercaseEnd  # If less than a, return. No change needed.
	bgt $a0, 'z', toUppercaseEnd  # If more than z, return. No change needed.
	sub $a0, $a0, 32  # Lowercase characters are offset from uppercase by 32.
toUppercaseEnd:
	add $v0, $zero, $a0
	jr $ra
	
# CHECK IF CHAR IN RANGE #
isCharInRange: # a0 = character.
	blt $a0, 48, psInvalid # Value is less that '0', print an error.
	bgt $a0, 90, psInvalid # Value is more than 'Z', print an error.
	bgt $a0, 57, checkIfIgnore # Value is more than '9', but it could still be a character.
	sub $a0, $a0, 48 # The value is between '0' and '9', make it values 0-9.
	j endCharCheck
checkIfIgnore:
	blt $a0, 65, psInvalid # Value is between '9' and 'A', print an error.
	sub $a0, $a0, 55 # The value is between 'A' and 'Z', make it values 10-35.
endCharCheck:
	add $v0, $zero, $a0
	jr $ra

	
## STRING CLEANUP ##

# REMOVE LEADING SPACES #
removeLeading:
	la $t0, psSubstring # message address.
	la $t1, psTempSubstring # newMessage address.
	add $t2, $zero, $zero # i.
	add $t3, $zero, $zero # h.
	add $t4, $zero, $zero # hitCharacter. Defaults to false (0).
rLLoop:
	add $t5, $t0, $t2 # message[i] address.
	add $t6, $t1, $t3 # newMessage[h].
	lb $t7, 0($t5) # message[i].
	beq $t7, 0, rLLoopEnd # message[i] = null, end of string.
	beq $t4, 1, rLLoopOther # hitCharacter == true, ignore our space logic.
	bne $t7, 32, rLLoopOther # message[i] != ' ', ignore our space logic.
rLLoopSpace:
	addi $t2, $t2, 1 # i++.
	j rLLoop
rLLoopOther:
	addi $t4, $zero, 1 # hitCharacter = true (1).
	sb $t7, 0($t6) # newMessage[h] = message[i]
	addi $t3, $t3, 1 # h++.
	addi $t2, $t2, 1 # i++.
	j rLLoop
rLLoopEnd:
	jr $ra # Return to where we were in the main loop.

# REMOVE TRAILING SPACES #
removeTrailing:
	la $t0, psSubstring # message address.
	add $t1, $zero, $zero # 0 = null.
	lw $t7, charCount # lastCharacterIndex.
	bgt $t7, 1001, rTEnd # lastCharacterIndex > 1001, end of string.
rTLoop:
	add $t2, $t0, $t7 # message[lastCharacterIndex] address.
	sb $t1, 0($t2) # message[lastCharacterIndex] = null.
	addi $t7, $t7, 1 # lastCharacterIndex++.
	bgt $t7, 1001, rTEnd # lastCharacterIndex > 1001, end of string.
	j rTLoop
rTEnd:
	jr $ra
	
# REPLACE STRING #
replaceString:
	la $t0, psSubstring # message address.
	la $t1, psTempSubstring # tempMessage address.
	add $t2, $zero, $zero # i.
rSLoop:
	add $t5, $t0, $t2 # message[i] address.
	add $t6, $t1, $t2 # tempMessage[i] address.
	lb $t7, 0($t6) # tempMessage[i].
	sb $t7, 0($t5) # message[i] = tempMessage[i].
	sb $zero, 0($t6) # tempMessage[i] = null
 	addi $t2, $t2, 1 # i++.
	bgt $t2, 1001, rSLoopEnd # i > 1001, end of string.
	j rSLoop
rSLoopEnd:
	jr $ra # Return to where we were in the main loop.
	
# FIND LAST CHARACTER INDEX #
findCharCount:
	la $t0, psSubstring # message address.
	add $t1, $zero, $zero # i.
	add $v0, $zero, $zero # charCount = 0.
	add $t2, $t0, $t1 # message[0] address.
	lb $t3, 0($t2) # message[0].
	beq $t3, 0, fCEndEmpty # message[0] == null, empty string.
fCLoop:
	add $t2, $t0, $t1 # message[i] address.
	lb $t3, 0($t2) # message[i].
	beq $t3, 0, fCEnd # message[i] == null, exit.
	bgt $t1, 1000, fCEnd # i > 1000, end of string.
	slt $t4, $t3, 33 # message[i] < '!'?
	beq $t4, 1, fCLoopEnd # message[i] <= ' ', loop again.
	add $v0, $zero, $t1 # charCount = i.
fCLoopEnd:
	addi $t1, $t1, 1 # i++.
	j fCLoop
fCEndEmpty:
	addiu $v0, $zero, -1 # Empty, count = -1.
	jr $ra
fCEnd:
	addi $v0, $v0, 1 # the number of characters is i+1.
	jr $ra