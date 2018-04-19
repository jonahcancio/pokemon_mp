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
ramName:	.asciiz	""
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


main:	li	$t0, 0x8a8b8c8d
	sw	$t0, bytesBuffer
	li	$t0, 0x50
	sb	$t0, bytesBuffer+4
	jal	PrintBytes
	jal	DecodeBytes
	print_string(stringBuffer)
	scan_string(stringBuffer)
	jal	StripNewLine
	jal	EncodeString
	jal	PrintBytes
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
