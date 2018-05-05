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
stringBuffer:	.space	152
bytesBuffer:	.space	152
badgeList:	.space	32
ramName:	.asciiz	"Pokemon Red (U) [S][BF].sav"
	.space	101
ramBuffer:	.space	32768
romName:	.asciiz	"Pokemon Red (U) [S][BF].gb"
	.space	101
romBuffer:	.space	1048576

checkSumRamString:	.asciiz	"#Checksum (RAM): "
checkSumRomString:	.asciiz	"#Checksum (ROM): "
fileErrorString:	.asciiz	"#Error reading/writing file\n"
currentName:	.asciiz	"#Current Name:\n"
enterNewName:	.asciiz	"\n#Please enter new name:\n"
currentMoney:	.asciiz	"#Current Money:\n"
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
currentBadges:	.asciiz	"#Current Badges:\n"
enterNewBadges:	.asciiz	"#Please enter the 8-char binary string rep for your new badges:\n"
currentItems:	.asciiz	"#Current Items:\n"
enterNewItems:	.asciiz	"#Please enter new item in format: <#> 0x<ID> <QTY>\n"
titlePokemon:	.asciiz	"#Title Pokemon Displayed:\n"
notFound:	.asciiz	"NOT FOUND"
currentMamaLogue:	.asciiz	"#Current Mom's Dialogue:\n"

enterRomName:	.asciiz	"#Please enter .gb file name:\n"
enterRamName:	.asciiz	"#Please enter .sav file name:\n"
funcTutorial:	.ascii	"#Enter the number of the function you'd like to do\n"
	.ascii	"#1 - Player name edit\n"
	.ascii	"#2 - Money edit\n"
	.ascii	"#3 - Badge edit\n"
	.ascii	"#4 - Item bag edit\n"
	.ascii	"#5 - Title screen Pokemon display\n"
	.ascii	"#6 - Dialogue search\n"
	.asciiz	"#7 - Mom's dialogue edit\n"

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
.macro	print_char(%reg)
	move	$a0, %reg
	li	$v0, 11
	syscall
.end_macro
.macro	print_chari(%c)
	li	$a0, %c
	li	$v0, 11
	syscall
.end_macro
.macro	print_string(%label)
	la	$a0, %label
	li 	$v0, 4
	syscall
.end_macro
.macro	scan_string(%label, %length)
	la	$a0, %label
	li	$a1, %length
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
	jal	FixCheckSumRam
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
.macro	commit_rom_buffer
	jal	FixCheckSumRom
	open_file(romName, $s7, 1)
	write_file(romBuffer, $s7, 1048576)
	close_file($s7)
.end_macro
.macro	change_name
	jal	GetName
	print_string(currentName)
	print_string(stringBuffer)
	
	print_string(enterNewName)
	scan_string(stringBuffer, 8)
	jal	StripNewLine
	jal	SetName
.end_macro
.macro	change_money
	jal	GetMoney
	move	$s2, $v0
	print_string(currentMoney)
	print_chari('P')
	print_chari(' ')
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
	scan_string(stringBuffer, 9)
	jal	StripNewLine
	jal	SetBadges
.end_macro
.macro	change_items
	print_string(currentItems)
	jal	GetItems
	print_string(enterNewItems)	
	scan_string(stringBuffer, 14)
	jal	StripNewLine
	jal	SetItems
.end_macro
.macro	show_title_pokemon
	jal	GetTitlePokemon
.end_macro
.macro	dialogue_search
	scan_string(stringBuffer, 31)
	jal	StripNewLine
	jal	DialogSearch	
	bltz	$v0, Dialogue_None
	move	$a0, $v0	
	jal	PrintPlainHex
	j	Dialogue_Out
Dialogue_None:	print_string(notFound)
Dialogue_Out:
.end_macro
.macro	change_mamalogue
	print_string(currentMamaLogue)
	jal	GetMamaLogue
	print_string(stringBuffer)
	print_chari('\n')
	scan_string(stringBuffer, 150)
	jal	SetMamaLogue
.end_macro
.macro	init_ram_rom_names
	#intialize rom name
	print_string(enterRomName)
	scan_string(stringBuffer, 152)
	jal	StripNewLine
	la	$a0, romName
	la	$a1, stringBuffer
	jal	StringCopy

	#initialize ram name
	print_string(enterRamName)
	scan_string(stringBuffer, 152)
	jal	StripNewLine
	la	$a0, ramName
	la	$a1, stringBuffer
	jal	StringCopy

.end_macro
main:
#	init_ram_rom_names
	init_ram_buffer
	blez	$v0, FileErrors 
	init_rom_buffer
	blez	$v0, FileErrors 
	init_badge_list
	print_string(funcTutorial)
	scan_int($s5)
	beq	$s5, 1, Func1
	beq	$s5, 2, Func2
	beq	$s5, 3, Func3
	beq	$s5, 4, Func4
	beq	$s5, 5, Func5
	beq	$s5, 6, Func6
	beq	$s5, 7, Func7
	j	Commitment
Func1:	change_name
	j	Commitment
Func2:	change_money
	j	Commitment
Func3:	change_badges
	j	Commitment
Func4:	change_items
	j	Commitment
Func5:	show_title_pokemon
	j	Commitment
Func6:	dialogue_search
	j	Commitment
Func7:	change_mamalogue
	j	Commitment

Commitment:
	commit_ram_buffer
#	commit_rom_buffer
	j	EndGame
FileErrors:	print_string(fileErrorString)
EndGame:	li	$v0, 10
	syscall
	
#FUNCTIONS START HERE

#print bytes in bytesBuffer
PrintBytes:	push($ra)
	li	$t0, 0
PrintBytesLoop:	bge	$t0, 152, PrintBytesBreak
	lbu	$t1, bytesBuffer($t0)
	beq	$t1, 0x50, PrintBytesBreak
	print_chari('\\')
	print_hex($t1)
	addi	$t0, $t0, 1
	j	PrintBytesLoop
PrintBytesBreak:	print_chari('\n')
	pop($ra)
	jr	$ra
	
#removes trailing \n in stringBuffer
StripNewLine:	push($ra)
	li	$t0, 0
StripLoop:	bge	$t0, 152, StripBreak
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
	
#computes checksum of RAM and assigns it to address 0x3523
FixCheckSumRam:	push($ra)
	li	$t0, 0x2598
	li	$t2, 0
CheckSumRamLoop:	bge	$t0, 0x3523, CheckSumRamBreak
	lbu	$t1, ramBuffer($t0)
	add	$t2, $t2, $t1
	andi	$t2, $t2, 0x000000FF
	addi	$t0, $t0, 1
	j	CheckSumRamLoop
CheckSumRamBreak:	nor	$t2, $t2, $t2
	andi	$t2, $t2, 0x000000FF
	lbu	$t1, ramBuffer+0x3523
	print_string(checkSumRamString)
	print_int($t1)
	print_chari('=')
	print_chari('>')
	print_int($t2)
	print_chari('\n')
	sb	$t2, ramBuffer+0x3523
	pop($ra)
	jr	$ra
	
#computes checksum of RoM and assigns it to address 0x3523
FixCheckSumRom:	push($ra)
	li	$t0, 0
	li	$t2, 0
CheckSumRomLoop:	bge	$t0, 1048576, CheckSumRomBreak
	beq	$t0, 0x14e, CheckSumRomUpdate
	beq	$t0, 0x14f, CheckSumRomUpdate
	lbu	$t1, romBuffer($t0)
	add	$t2, $t2, $t1
	andi	$t2, $t2, 0x0000FFFF
CheckSumRomUpdate:	addi	$t0, $t0, 1
	j	CheckSumRomLoop
CheckSumRomBreak:	lbu	$t3, romBuffer+0x14e
	lbu	$t4, romBuffer+0x14f
	sll	$t3, $t3, 8
	add	$t1, $t3, $t4
	print_string(checkSumRomString)
	print_int($t1)
	print_chari('=')
	print_chari('>')
	print_int($t2)
	print_chari('\n')
	srl	$t3, $t2, 8
	sb	$t3, romBuffer+0x14e
	andi	$t4, $t2, 0x000000FF
	sb	$t4, romBuffer+0x14f 
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
	beqz	$t3	GetFirstBadge
	print_chari(' ')
GetFirstBadge:	lw	$a0, badgeList($t0)		#print badge if it passes the test
	li	$v0, 4
	syscall
	addi	$t3, $t3, 1
GetBadgeNoPrint:	sll	$t2, $t2, 1
	addi	$t0, $t0, 4
	j	GetBadgeLoop
GetBadgeBreak:	bnez	$t3, GetBadgeMeron
	print_string(noneString)
GetBadgeMeron:	print_chari('\n')
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
	li	$t0, 1		#t1 = item # in bag
	li	$t2, 0x25ca		#t2 = ram offset
	lbu	$t8, ramBuffer+0x25c9	#t8 = distinct item count
GetItemsLoop:	bgt	$t0, $t8, GetItemsBreak
	print_int($t0)
	print_chari(' ')
	lbu	$a0, ramBuffer($t2)		#a0 = item id	
	jal	DecodeItem		#DecodeItem will return item string in stringBuffer
	print_string(stringBuffer)
	print_chari(' ')
	print_chari('x')
	addi	$t2, $t2, 1		#t2 = ram offset qty

	lbu	$a0, ramBuffer($t2)		#a0 = item qty
	print_int($a0)
	print_chari('\n')
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
	li	$t4, 0		#t4 = bool(is itemcount a 2-digit number?)
	li	$t5, 1		#t5 = 1 if to add item count, 0 if stays, -1 if delete item 
SetItemNumber:	li	$s0, 0		#s0 = item order in bag
	lbu	$t1, stringBuffer+0
	subi	$t1, $t1, '0'	
	add	$s0, $s0, $t1
	lbu	$t1, stringBuffer+1
	beq	$t1, ' ', SetItemId		#skip digit shifting if item order is only 1-digit
	subi	$t1, $t1, '0'		
	mul	$s0, $s0, 10		#digit shifting phase
	add	$s0, $s0, $t1
	li	$t4, 1	
	#s0 is not the exact item number
SetItemId:	li	$s1, 0		#s1 = item id
	lbu	$a0, stringBuffer+4($t4)	#a0 = 1st hex digit
	jal	HexToNumber
	move	$t1, $v0		#t1 = 1st hex number
	sll	$t1, $t1, 4		#shift to make it MSB
	add	$s1, $s1, $t1		#add first byte hex as upper bits
	lbu	$a0, stringBuffer+5($t4)	#a0 = 2nd hex digit
	jal	HexToNumber
	move	$t1, $v0
	add	$s1, $s1, $t1	 	#add second byte hex
	#s1 is now the full item id
	beqz	$s1, DeleteLastItem
	
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
	beqz	$s2, DeleteLastItem
	lbu	$t1, ramBuffer+0x25c9	#t1 = total number of items count
	ble	$s0, $t1, SetItemsReturn	# no need for appending if item # < max_item count
	j	AdjustItemK
DeleteLastItem:	li	$t5, -1
	lbu	$t1, ramBuffer+0x25c9	#t1 = total number of items count	
AdjustItemK:	add	$s0, $t1, $t5		#adjust s0 = max_items + to add or not to add
	sb	$s0, ramBuffer+0x25c9	#ram[item count] = new item count
	li	$t1, 0xff
	mul	$t2, $s0, 2		#t2 = item end offset
	sb	$t1, ramBuffer+0x25ca($t2)	#ram[item end offset] = 0xff
	
SetItemsReturn:	mul	$t0, $s0, 2		
	addi	$t0, $t0, 0x25c8		#t0 = offset in ram = 0x25c8 + 2k
	sb	$s1, ramBuffer($t0)		#ramBuffer[2k] = item id
	sb	$s2, ramBuffer+1($t0)	#ramBuffer[2k+1] = item qty
	pop($s2)
	pop($s1)
	pop($s0)
	pop($ra)
	jr	$ra


#Decodes pokemon at address in $a0
DecodePokemon:	push($ra)
	push($s0)
	push($t0)
	push($t1)
	push($t2)
	subi	$s0, $a0, 1		#s0 = pokemon id
	mul	$t2, $s0, 10
	add	$t2, $t2, 0x1c21e		#t2 = ROM offset to read from					
	li	$t0, 0
DecodePokeLoopR:	bge 	$t0, 10, DecodePokeBreakR	#loop copies romBuffer to byteBuffer
	lbu	$t1, romBuffer($t2)		#t1 = romByte at index t0
	sb	$t1, bytesBuffer($t0)
	beq	$t1, 0x50, DecodePokeBreakR
	addi	$t2, $t2, 1
	addi	$t0, $t0, 1
	j	DecodePokeLoopR
DecodePokeBreakR:	li	$t1, 0x50
	sb	$t1, bytesBuffer($t0)
	jal	DecodeBytes
	pop($t2)
	pop($t1)
	pop($t0)
	pop($s0)
	pop($ra)
	jr	$ra

#prints out every title pokemon in order of ROM placement
GetTitlePokemon:	push($ra)
	print_string(titlePokemon)
	lbu	$a0, romBuffer+0x4399
	jal	DecodePokemon
	print_string(stringBuffer)
	print_chari('\n')
	li	$t0, 0x4588
GetTitlePokeLoop:	bge	$t0, 0x4598, GetTitlePokeBreak
	lbu	$a0, romBuffer($t0)
	jal	DecodePokemon
	print_string(stringBuffer)
	print_chari('\n')
	addi	$t0, $t0, 1
	j	GetTitlePokeLoop
GetTitlePokeBreak:	pop($ra)
	jr	$ra


#print decimal in a0 as hex without its leading zeros
PrintPlainHex:	push($ra)
	push($s0)
	push($t0)
	push($t1)
	push($t2)
	push($t3)
	move	$s0, $a0		#s0 = original number
	print_chari('0')
	print_chari('x')
	li	$t0, 28		#t0 = shift right amount
	li	$t3, 1		#t3 = isDigitLeadingZero
	li	$t2, 0xF0000000		#t2 = digit mask
PlainHexLoop:	bltz	$t0, PlainHexBreak
	and	$t1, $s0, $t2	
	srlv	$t1, $t1, $t0		#t1 = hex digit
	beqz	$t3, PlainHexPrint		#if digit no longer leading zero
	slti	$t3, $t1, 1
	bnez	$t3, PlainHexUpdate	
PlainHexPrint:	bge	$t1, 10, PlainHexLetter
PlainHexNumber:	print_int($t1)
	j	PlainHexUpdate
PlainHexLetter:	add	$t1, $t1, 'a'
	subi	$t1, $t1, 10
	print_char($t1)
PlainHexUpdate:	subi	$t0, $t0, 4
	srl	$t2, $t2, 4
	j	PlainHexLoop
PlainHexBreak:	pop($t3)
	pop($t2)
	pop($t1)
	pop($t0)
	pop($s0)
	pop($ra)
	jr	$ra

#search dialog of stringBuffer inside romBuffer
DialogSearch:	push($ra)
	push($s0)
	push($t0)
	push($t1)
	push($t2)
	push($t3)
	push($t4)
	jal	EncodeString
	li	$t0, 0		#t0 = romBuffer offset 
DialogSearchLoopS:	bge	$t0, 1048576, DialogSearchNone
	li	$t2, 0		#t2 = stringBuffer offset
DialogSearchLoopV:	bge	$t2, 30, DialogSearchFound
	lbu	$t1, bytesBuffer($t2)	#t1 = byteBuffer byte
	add	$t4, $t0, $t2		#t4 = total romBuffer offset
	lbu	$t3, romBuffer($t4)		#t3 = romBuffer byte
	beq	$t1, 0x50, DialogSearchFound	#if end of string reached, dialog found
	bne	$t1, $t3, DialogSearchWrong	#if not mismatch, continue loop in DialogSearchWrong
	addi	$t2, $t2, 1
	j	DialogSearchLoopV
DialogSearchWrong:	addi	$t0, $t0, 1
	j	DialogSearchLoopS
DialogSearchFound:	move	$v0, $t0		#return address offset if found
	j	DialogSearchReturn
DialogSearchNone:	li	$v0, -1		#return -1 if none found
DialogSearchReturn:	pop($t4)
	pop($t3)
	pop($t2)
	pop($t1)
	pop($t0)
	pop($s0)
	pop($ra)
	jr	$ra

#0x94b0d = mom dialogue puts mamalogue inside stringBuffer
GetMamaLogue:	push($ra)
	push($t0)
	push($t1)
	li	$t0, 0
GetMamaLogueLoop:	bge	$t0, 150, GetMamaLogueBreak
	lbu	$t1, romBuffer+0x94b0d($t0)
	sb	$t1, bytesBuffer($t0)
	addi	$t0, $t0, 1
	beq	$t1, 0x57, GetMamaLogueBreak
	beq	$t1, 0x58, GetMamaLogueBreak
	j	GetMamaLogueLoop
GetMamaLogueBreak:	li	$t1, 0x50
	sb	$t1, bytesBuffer($t0)
	jal	DecodeBytes
	pop($t1)
	pop($t0)
	pop($ra)
	jr	$ra

#set dialogue in string buffer as new mom dialogue; max length is 96
SetMamaLogue:	push($ra)
	push($t0)
	push($t1)
	jal	EncodeString
	li	$t0, 0
SetMamaLogueLoop:	bge	$t0, 150, SetMamaLogueElse
	lbu	$t1, bytesBuffer($t0)
	sb	$t1, romBuffer+0x94b0d($t0)
	addi	$t0, $t0, 1
	beq	$t1, 0x57, SetMamaLogueBreak
	beq	$t1, 0x58, SetMamaLogueBreak	
	j	SetMamaLogueLoop
SetMamaLogueElse:	li	$t1, 0x57
	sb	$t1, romBuffer+0x94b0d
SetMamaLogueBreak:	pop($t1)
	pop($t0)
	pop($ra)
	jr	$ra
	
#format for dialogue: \ = new line, _ = await input, | = clear text box

#copy string from a1 to a0
StringCopy:	push($ra)
	push($s0)
	push($s1)
	push($t0)
	push($t1)
	push($t2)
	move	$s0, $a0
	move	$s1, $a1
	li	$t0, 0
StringCopyLoop:	bge	$t0, 151, StringCopyElse
	add	$t2, $s1, $t0		#t2 = src offset
	lbu	$t1, ($t2)		#t1 = src char
	add	$t2, $s0, $t0		#t2 = dest offset
	sb	$t1, ($t2) 		#dest char = t1
	beq	$t1, 0, StringCopyBreak
	addi	$t0, $t0, 1
	j	StringCopyLoop
StringCopyElse:	add	$t2, $s0, $t0
	li	$t1, 0
	sb	$t1, ($t2)	
StringCopyBreak:
	pop($t2)
	pop($t1)
	pop($t0)
	pop($s1)
	pop($s0)
	pop($ra)
	jr	$ra