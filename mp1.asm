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


.text
.macro	print_int(%reg)
	move	$a0, %reg
	li	$v0, 1
	syscall
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
main:	#READ FILE
	open_file(ramName, $s6, 0)
	read_file(ramBuffer, $s6, 32768)	
	jal	GetName
	print_string(stringBuffer)
	print_char('\n')
	close_file($s6)
	
	print_char('\n')
	#WRITE FILE
	open_file(ramName, $s6, 1)
	scan_string(stringBuffer)
	jal	SetName
	jal	FixCheckSum
	write_file(ramBuffer, $s6, 32768)
	close_file($s6)
	
	li	$v0, 10
	syscall
	
#FUNCTIONS START HERE
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
