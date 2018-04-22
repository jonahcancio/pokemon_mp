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
badgeList:	.space	32
ramName:	.asciiz	"Pokemon Red (U) [S][BF].sav"
ramBuffer:	.space	32768
romName:	.asciiz	"Pokemon Red (U) [S][BF].gb"
romBuffer:	.space	1048576

checkSumString:	.asciiz	"#Checksum: "
fileErrorString:	.asciiz	"#Error reading/writing file"
currentName:	.asciiz	"#Current Name: "
enterNewName:	.asciiz	"\n#Please enter new name:\n"
currentMoney:	.asciiz	"#Current Money: "
enterNewMoney:	.asciiz	"\n#Please enter new money:\n"

boulderBadge:	.asciiz	"BOULDERBADGE"
cascadeBadge:	.asciiz	"CASCADEBADGE"
thunderBadge:	.asciiz	"THUNDERBADGE"
rainbowBadge:	.asciiz	"RAINBOWBADGE"
soulBadge:	.asciiz	"SOULBADGE"
marshBadge:	.asciiz	"MARSHBADGE"
volcanoBadge:	.asciiz	"VOLCANOBADGE"
earthBadge:	.asciiz	"EARTHBADGE"
noneString:	.asciiz	"NONE"
currentBadges:	.asciiz	"#Curren Badges:\n"
enterNewBadges:	.asciiz	"\n#Please enter the 8-char binary string rep for your new badges:\n"
currentItems:	.asciiz	"#Current Items:\n"
enterNewItems:	.asciiz	"\n#Please enter new item in format: <#> 0x<ID> <QTY>\n"
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
.macro	init_ram_buffer
	open_file(ramName, $s6, 0)
	read_file(ramBuffer, $s6, 32768)
	move	$t0, $v0
	close_file($s6)
	move	$v0, $t0
.end_macro
.macro	commit_ram_buffer
	jal	FixCheckSum
	open_file(ramName, $s6, 1)
	write_file(ramBuffer, $s6, 32768)
	close_file($s6)
.end_macro
.macro	init_rom_buffer
	open_file(romName, $s7, 0)
	read_file(romBuffer, $s7, 1048576)
	move	$t0, $v0
	close_file($s7)
	move	$v0, $t0
.end_macro
.macro	change_name
	jal	GetName
	print_string(currentName)
	print_string(stringBuffer)
	
	print_string(enterNewName)
	scan_string(stringBuffer)
	jal	StripNewLine
	jal	SetName
.end_macro
.macro	change_money
	jal	GetMoney
	move	$s2, $v0
	print_string(currentMoney)
	print_int($s2)
	
	print_string(enterNewMoney)
	scan_int($a0)
	jal	SetMoney
.end_macro
.macro	init_badge_list
	li	$t0, 0
	la	$t1, boulderBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, cascadeBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, thunderBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, rainbowBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, soulBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, marshBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, volcanoBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, earthBadge
	sw	$t1, badgeList($t0)	
.end_macro
.macro	change_badges
	print_string(currentBadges)
	jal	GetBadges
	print_string(enterNewBadges)
	scan_string(stringBuffer)
	jal	StripNewLine
	jal	SetBadges
.end_macro
.macro	change_items
	print_string(currentItems)
	jal	GetItems
	print_string(enterNewItems)	
	scan_string(stringBuffer)
	jal	StripNewLine
	jal	SetItems
.end_macro
main:	
	init_ram_buffer
	init_rom_buffer
	init_badge_list
#	change_name
#	change_money
#	change_badges
	change_items
	commit_ram_buffer
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
	
#initialize badgelist	
InitBadgeList:	push($ra)
	li	$t0, 0
	la	$t1, boulderBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, cascadeBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, thunderBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, rainbowBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, soulBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, marshBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, volcanoBadge
	sw	$t1, badgeList($t0)
	addi	$t0, $t0, 4
	la	$t1, earthBadge
	sw	$t1, badgeList($t0)	
	pop($ra)
	jr	$ra


#Get Badges and Print
GetBadges:	push($ra)
	lbu	$s0, ramBuffer+0x2602
	li	$t0, 0		#badgelist index
	li	$t2, 0x00000001		#badgemask
	li	$t3, 0		#badge count
GetBadgeLoop:	bge	$t0, 32, GetBadgeBreak
	and	$t1, $s0, $t2
	bne	$t1, $t2, GetBadgeNoPrint
	lw	$a0, badgeList($t0)
	li	$v0, 4
	syscall
	addi	$t3, $t3, 1
	print_char('\t')
GetBadgeNoPrint:	sll	$t2, $t2, 1
	addi	$t0, $t0, 4
	j	GetBadgeLoop
GetBadgeBreak:	bnez	$t3, GetBadgeMeron
	print_string(noneString)
GetBadgeMeron:	print_char('\n')
	pop($ra)
	jr	$ra


#Set Badges with binary byte input in stringBuffer
SetBadges:	push($ra)
	li	$t0, 0		#index
	li	$t2, 0x00000080		#badge corresponding bit
	li	$t3, 0		#sum total badge output
SetBadgeLoop:	bge	$t0, 8, SetBadgeBreak
	lbu	$t1, stringBuffer($t0)
	bne	$t1, 49, SetBadgeNoAdd
	add	$t3, $t3, $t2
SetBadgeNoAdd:	srl	$t2, $t2, 1
	addi	$t0, $t0, 1
	j	SetBadgeLoop
SetBadgeBreak:	sb	$t3, ramBuffer+0x2602
	pop($ra)
	jr	$ra
	
	
#decodes item id in a0 and stores item name in stringBuffer
DecodeItem:	push($ra)
	push($s0)
	push($t0)
	push($t1)
	push($t2)
	subi	$s0, $a0, 1		#s0 = item id
	li	$t0, 0x472b
DecodeItemLoopF:	bge	$t0, 0x4a91, DecodeItemBreakF
	blez	$s0, DecodeItemBreakF
	lbu	$t1, romBuffer($t0)		#t1 = romByte at index t0
	addi	$t0, $t0, 1
	bne	$t1, 0x50, DecodeItemLoopF
	subi	$s0, $s0, 1	
	j	DecodeItemLoopF
DecodeItemBreakF:	move	$s0, $t0		#s0 = ROM offset to read from
	li	$t0, 0
DecodeItemLoopR:	bge 	$t0, 0x4a91, DecodeItemBreakR
	lbu	$t1, romBuffer($s0)
	sb	$t1, bytesBuffer($t0)
	beq	$t1, 0x50, DecodeItemBreakR
	addi	$s0, $s0, 1
	addi	$t0, $t0, 1
	j	DecodeItemLoopR
DecodeItemBreakR:	jal	DecodeBytes
	pop($t2)
	pop($t1)
	pop($t0)
	pop($s0)
	pop($ra)
	jr	$ra
	
#read items and prints a list of them in format: <#> <ITEM_NAME> x<QTY>
GetItems:	push($ra)
	li	$t0, 1		#t1 = item #
	li	$t2, 0x25ca		#t2 = ram offset
	lbu	$t8, ramBuffer+0x25c9	#t8 = distinct item count
GetItemsLoop:	bgt	$t0, $t8, GetItemsBreak
	print_int($t0)
	print_char(' ')
	lbu	$a0, ramBuffer($t2)		#a0 = item id	
	jal	DecodeItem
	print_string(stringBuffer)
	print_char(' ')
	print_char('x')
	addi	$t2, $t2, 1

	lbu	$a0, ramBuffer($t2)		#a0 = item qty
	print_int($a0)
	print_char('\n')
	addi	$t2, $t2, 1
	addi	$t0, $t0, 1
	j	GetItemsLoop
GetItemsBreak:	pop($ra)
	jr	$ra


#hex char to number
HexToNumber:	push($ra)
	push($t0)
	move	$t0, $a0
	bge	$t0, 'a', HexLetter	
HexDigit:	subi	$v0, $t0, '0'
	j	HexReturn
HexLetter:	subi	$v0, $t0, 'a'
	addi	$v0, $v0, 10
HexReturn:	pop($t0)
	pop($ra)
	jr	$ra

#set items based on <#> 0x<ID> <QTY> in stringBuffer	
SetItems:	push($ra)
	push($s0)
	push($s1)
	push($s2)
	li	$t4, 0		#t4 = itemcount is 2-digit number
	li	$s0, 0		#s0 = item order in bag
	lbu	$t1, stringBuffer
	subi	$t1, $t1, '0'	
	add	$s0, $s0, $t1
	lbu	$t1, stringBuffer+1
	beq	$t1, ' ', SetItemId		#skip digit shifting if item order is only 1-digit
	subi	$t1, $t1, '0'
	mul	$s0, $s0, 10
	add	$s0, $s0, $t1
	li	$t4, 1	
SetItemId:	li	$s1, 0		#s1 = item id
	lbu	$a0, stringBuffer+4($t4)	#beq
	jal	HexToNumber
	move	$t1, $v0	
	sll	$t1, $t1, 4
	add	$s1, $s1, $t1		#add first byte hex
	lbu	$a0, stringBuffer+5($t4)
	jal	HexToNumber
	move	$t1, $v0
	add	$s1, $s1, $t1	 	#add second byte hex
	
	li	$s2, 0		#s2 = item qty
	addi	$t2, $t4, 7		#t2 = string offset
	li	$t3, 1000		#t3 = multiplier/divider
SetItemQtyLoop:	bge	$t2, 10, SetItemQtyBreak
	lbu	$t1, stringBuffer($t2)
	blt	$t1, '0', SetItemQtyBreak
	bgt	$t1, '9', SetItemQtyBreak
	subi	$t1, $t1, '0'
	div	$t3, $t3, 10
	mul	$t1, $t1, $t3
	add	$s2, $s2, $t1
	addi	$t2, $t2, 1
	j	SetItemQtyLoop
SetItemQtyBreak:	div	$s2, $s2, $t3		
	lbu	$t1, ramBuffer+0x25c9	#t1 = total number of items count
	ble	$s0, $t1, SetItemsReturn	# no need for appending if item # < max_item count
AdjustItemK:	add	$s0, $t1, 1		#adjust s0 = max_items + 1
	sb	$s0, ramBuffer+0x25c9
	li	$t1, 0xff
	mul	$t2, $s0, 2
	sb	$t1, ramBuffer+0x25ca($t2)
SetItemsReturn:	mul	$t0, $s0, 2		
	addi	$t0, $t0, 0x25c8		#t0 = offset in ram = 0x25c8 + 2k
	sb	$s1, ramBuffer($t0)
	sb	$s2, ramBuffer+1($t0)
	pop($s2)
	pop($s1)
	pop($s0)
	pop($ra)
	jr	$ra
	
