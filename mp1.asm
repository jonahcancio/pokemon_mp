.data
decodeTionary:	.ascii	"^***************"	#0
	.ascii	"****************"	#1
	.ascii	"****************"	#2
	.ascii	"****************"	#3
	.ascii	"***************\\"
	.ascii	"&|***_*#$*******"	#5
	.ascii	"****************"	#6
	.ascii	"*************** "	#7
	.ascii	"ABCDEFGHIJKLMNOP"	#8
	.ascii	"QRSTUVWXYZ******"	#9
	.ascii	"abcdefghijklmnop"	#a
	.ascii	"qrstuvwxyz@*****"	#b
	.ascii	"****************"	#c
	.ascii	"****************"	#d
	.ascii	"'**-**?!.*******"	#e
	.ascii	"***/,*0123456789"	#f
stringBuffer:	.space	128
bytesBuffer:	.space	128
ramName:	.asciiz	"Pokemon Red (U) [S][BF].sav"
ramBuffer:	.space	32768

checkSumString:	.asciiz	"Checksum: "
fileErrorString:	.asciiz	"Error reading/writing file"
currentName:	.asciiz	"Current Name: "
enterNewName:	.asciiz	"\nPlease enter new name:\n"
currentMoney:	.asciiz	"Current Money: "
enterNewMoney:	.asciiz	"\nPlease enter new money:\n"

.text
.macro	print_int(%reg)
	move	$a0, %reg
	li	$v0, 1
	syscall
.end_macro
.macro	scan_int(%reg)
	li	$v0, 5
	syscall
	move	%reg, $v0
.end_macro
.macro	print_hex(%reg)
	move	$a0, %reg
	li	$v0, 34
	syscall
.end_macro
.macro	print_char(%c)
	li	$a0, %c
	li	$v0, 11
	syscall
.end_macro
.macro	print_string(%label)
	la	$a0, %label
	li 	$v0, 4
	syscall
.end_macro
.macro	scan_string(%label)
	la	$a0, %label
	li	$a1, 128
	li 	$v0, 8
	syscall
.end_macro
.macro	push(%reg)
	add	$sp, $sp, -4
	sw	%reg, 0($sp)
.end_macro
.macro	pop(%reg)
	lw	%reg, 0($sp)
	add	$sp, $sp, 4
.end_macro
.macro	open_file(%name, %desc, %flag)
	la	$a0, %name
	li	$a1, %flag
	li	$a2, 0
	li	$v0, 13
	syscall
	move	%desc, $v0
.end_macro
.macro	read_file(%buffer, %desc, %max)
	move	$a0, %desc
	la	$a1, %buffer
	li	$a2, %max
	li	$v0, 14
	syscall
.end_macro
.macro	write_file(%buffer, %desc, %max)
	move	$a0, %desc
	la	$a1, %buffer
	li	$a2, %max
	li	$v0, 15
	syscall
.end_macro
.macro	close_file(%desc)
	move	$a0, %desc
	li	$v0, 16
	syscall
.end_macro
main:	
	jal	InitRamBuffer
	jal	ChangeName
#	jal	ChangeMoney
	li	$v0, 10
	syscall
	
#FUNCTIONS START HERE
#initialize ramBuffer
InitRamBuffer:	push($ra)
	open_file(ramName, $s6, 0)
	read_file(ramBuffer, $s6, 32768)
	move	$t0, $v0
	close_file($s6)
	move	$v0, $t0
	pop($ra)
	jr	$ra

#print bytes in bytesBuffer
PrintBytes:	push($ra)
	li	$t0, 0
PrintBytesLoop:	bge	$t0, 128, PrintBytesBreak
	lbu	$t1, bytesBuffer($t0)
	beq	$t1, 0x50, PrintBytesBreak
	print_char('\\')
	print_hex($t1)
	addi	$t0, $t0, 1
	j	PrintBytesLoop
PrintBytesBreak:	print_char('\n')
	pop($ra)
	jr	$ra
	
#removes trailing \n in stringBuffer
StripNewLine:	push($ra)
	li	$t0, 0
StripLoop:	bge	$t0, 128, StripBreak
	lbu	$t1, stringBuffer($t0)
	beq	$t1, '\n', StripFound
	beq	$t1, 0, StripBreak
	addi	$t0, $t0, 1
	j	StripLoop
StripFound:	sb	$zero, stringBuffer($t0)
StripBreak:	pop($ra)
	jr	$ra

#decode bytes from bytesBuffer into string in stringBuffer
DecodeBytes:	push($ra)
	li	$t0, 0
DecodeLoop:	bge	$t0, 127, DecodeBreak
	lbu	$t1, bytesBuffer($t0)
	lbu	$t2, decodeTionary($t1)
	beq	$t2, '&', DecodeBreak
	sb	$t2, stringBuffer($t0)
	addi	$t0, $t0, 1
	j	DecodeLoop
DecodeBreak:	sb	$zero, stringBuffer($t0)
	pop($ra)
	jr	$ra
	

#encode string in stringBuffer
EncodeString: 	push($ra)
	li	$t0, 0
EncodeLoop:	bge	$t0, 127, EncodeBreak
	lbu	$t1, stringBuffer($t0)
	beq	$t1, 0, EncodeBreak
	li	$t2, 0
EncodeTionaryLoop:	bge	$t2, 256, EncodeTionaryElse
	lbu	$t3, decodeTionary($t2)
	beq	$t3, $t1, EncodeTionaryBreak
	addi	$t2, $t2, 1
	j	EncodeTionaryLoop
EncodeTionaryElse:	li	$t2, 0xc4
EncodeTionaryBreak:	sb	$t2, bytesBuffer($t0)
	addi	$t0, $t0, 1
	j	EncodeLoop
EncodeBreak:	li	$t2, 0x50
	sb	$t2, bytesBuffer($t0)	
	pop($ra)
	jr	$ra
	
#computes checksum and assigns it to address 0x3523
FixCheckSum:	push($ra)
	li	$t0, 0x2598
	li	$t2, 0
CheckSumLoop:	bge	$t0, 0x3523, CheckSumBreak
	lbu	$t1, ramBuffer($t0)
	add	$t2, $t2, $t1
	andi	$t2, $t2, 0x000000FF
	addi	$t0, $t0, 1
	j	CheckSumLoop
CheckSumBreak:	nor	$t2, $t2, $t2
	andi	$t2, $t2, 0x000000FF
	lbu	$t1, ramBuffer+0x3523
	print_string(checkSumString)
	print_int($t1)
	print_char('=')
	print_char('>')
	print_int($t2)
	print_char('\n')
	sb	$t2, ramBuffer+0x3523
	pop($ra)
	jr	$ra
	
#reads name from ramBuffer into bytesBuffer, decodes into stringBuffer, 
GetName:	push($ra)
	li	$t0, 0
GetNameLoop:	bge	$t0, 7, GetNameElse
	lbu	$t1, ramBuffer+0x2598($t0)
	sb	$t1, bytesBuffer($t0)
	beq	$t1, 0x50, GetNameBreak
	addi	$t0, $t0, 1
	j	GetNameLoop
GetNameElse:	li	$t1, 0x50
	sb	$t1, bytesBuffer($t0)
GetNameBreak:	jal	DecodeBytes
	pop($ra)
	jr	$ra
	
#encodes name in stringBuffer into bytesBuffer and writes it into ramBuffer
SetName:	push($ra)
	jal	EncodeString
	li	$t0, 0
SetNameLoop:	bge	$t0, 7, SetNameElse
	lbu	$t1, bytesBuffer($t0)
	sb	$t1, ramBuffer+0x2598($t0)
	beq	$t1, 0x50, SetNameBreak
	addi	$t0, $t0, 1
	j	SetNameLoop
SetNameElse:	li	$t1, 0x50
	sb	$t1, ramBuffer+0x2598($t0)
SetNameBreak:	pop($ra)
	jr	$ra

#output current name, get input for new name, and change current name
ChangeName:	push($ra)
	jal	GetName
	print_string(currentName)
	print_string(stringBuffer)
	
	print_string(enterNewName)
	scan_string(stringBuffer)
	jal	StripNewLine
	jal	SetName
	jal	FixCheckSum

	open_file(ramName, $s6, 1)
	write_file(ramBuffer, $s6, 32768)
	close_file($s6)
	pop($ra)
	jr	$ra
	
#take BCD in a0 and outputs decimal equivalent in v0
BcdToDecimal:	push($ra)
	push($s0)
	push($t0)
	push($t1)
	push($t2)
	push($t3)
	move	$s0, $a0
	li	$t0, 0		#t3 = digit index
	li	$t2, 0		#t2 = sum = decimal
BcdToDecimalLoop:	beqz	$s0, BcdToDecimalBreak
	div	$s0, $s0, 16		#t0 = t0/16 = quotient
	mfhi	$t1		#t1 = t0%16 = remainder
	li	$t3, 0		#t4 = power10 index
Power10Loop:	bge	$t3, $t0, Power10Break	#while not yet fullpowere10'ed
	mul	$t1, $t1, 10		#power up t1 by one 10
	addi	$t3, $t3, 1		
	j	Power10Loop
Power10Break:	add	$t2, $t2, $t1		#sum += 10powered remainder
	addi	$t0, $t0, 1		
	j	BcdToDecimalLoop
BcdToDecimalBreak:	move	$v0, $t2		#return decimal sum
	pop($t3)
	pop($t2)
	pop($t1)
	pop($t0)
	pop($s0)
	pop($ra)
	jr	$ra

#take decimal input a0 and output BCD equivalent in v0
DecimalToBcd:	push($ra)
	push($s0)
	push($t0)
	push($t1)
	push($t2)
	push($t3)
	move	$s0, $a0
	li	$t0, 0		#t3 = digit index
	li	$t2, 0		#t2 = sum = bcd
DecimalToBcdLoop:	beqz	$s0, DecimalToBcdBreak
	div	$s0, $s0, 10		#t0 = t0/10 = quotient
	mfhi	$t1		#t1 = t0%10 = remainder
	li	$t3, 0		#t4 = power16 index
Power16Loop:	bge	$t3, $t0, Power16Break	#while not yet fullpowere16'ed
	mul	$t1, $t1, 16		#power up t1 by one 16
	addi	$t3, $t3, 1		
	j	Power16Loop
Power16Break:	add	$t2, $t2, $t1		#sum += 16-powered remainder
	addi	$t0, $t0, 1		
	j	DecimalToBcdLoop
DecimalToBcdBreak:	move	$v0, $t2		#return decimal sum
	pop($t3)
	pop($t2)
	pop($t1)
	pop($t0)
	pop($s0)
	pop($ra)
	jr	$ra

#get movey and store value in v0
GetMoney:	push($ra)
	li	$t0, 0		#t0 = index
	li	$t2, 2 		#t2 = max_index
	li	$t4, 0		#t4 = total bcd value
GetMoneyLoop:	bge	$t0, 3, GetMoneyBreak	#while index < 3
	lbu	$t1, ramBuffer+0x25f3($t0)	#t1 = current_byte	
	sub	$t3, $t2, $t0		
	mul	$t3, $t3, 8		#t3 = shift_left_value
	sllv	$t1, $t1, $t3		#t1 = shift_left(current_byte)
	add	$t4, $t4, $t1		#t4 += left shifted current byte
	addi	$t0, $t0, 1		#loop incrementer
	j	GetMoneyLoop
GetMoneyBreak:	move	$a0, $t4
	jal	BcdToDecimal
	pop($ra)
	jr	$ra

#input decimal money in a0 and store value in ramBuffer
SetMoney:	push($ra)
	jal	DecimalToBcd
	move	$s0, $v0
	andi	$t1, $s0, 0x00FF0000
	srl	$t1, $t1, 16
	sb	$t1, ramBuffer+0x25f3
	andi	$t1, $s0, 0x0000FF00
	srl	$t1, $t1, 8
	sb	$t1, ramBuffer+0x25f4
	andi	$t1, $s0, 0x000000FF
	srl	$t1, $t1, 0
	sb	$t1, ramBuffer+0x25f5
SetMoneyBreak:	pop($ra)
	jr	$ra
	
#output current money, get input new money, change current money
ChangeMoney:	push($ra)
	push($s2)
	jal	GetMoney
	move	$s2, $v0
	print_string(currentMoney)
	print_int($s2)
	
	print_string(enterNewMoney)
	scan_int($a0)
	jal	SetMoney
	jal	FixCheckSum
	
	open_file(ramName, $s6, 1)
	write_file(ramBuffer, $s6, 32768)
	close_file($s6)
	pop($s2)
	pop($ra)
	jr	$ra