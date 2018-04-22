ramName = "Pokemon Red (U) [S][BF].sav"
romName = "Pokemon Red (U) [S][BF].gb"

decodeTionary = "^***************" +\
	"****************"	\
	"****************"	\
	"****************"	\
	"***************\\" \
	"&|***_*#$*******"	\
	"****************"	\
	"*************** "	\
	"ABCDEFGHIJKLMNOP"	\
	"QRSTUVWXYZ******"	\
	"abcdefghijklmnop"	\
	"qrstuvwxyz@*****"	\
	"****************"	\
	"****************"	\
	"'**-**?!.*******"	\
	"***/,*0123456789"

ramBytes = 0

def fix_checksum():
	global ramBytes
	fBarr = bytearray(ramBytes)
	sum = 0
	for i in range(0x2598, 0x3523):
	    sum += ramBytes[i]
	    sum %= 256
	sum = (-sum - 1) % 256
	fBarr[0x3523] = sum
	ramBytes = bytes(fBarr)


def change_badge():
    with open(ramName, "rb") as f:
        ramBytes = f.read()
        fBarr = bytearray(ramBytes)
        fBarr[0x2602] = 0b00110000
        ramBytes = bytes(fBarr)
        fix_checksum()

def check_dict():
	zaByte = input("Enter byte: ")
	while zaByte != "bye":
		try:
			zaByte = int(zaByte, 0)
			print(decodeTionary[zaByte])
		except ValueError:
			print("Not a number")
		zaByte = input("Enter byte: ")

def decode_bytes(_bytes):
	_string = []
	for b in _bytes:
		if b == 0x50:
			break
		_string += decodeTionary[b];
	_string = "".join(_string)
	return _string

def get_item_name(id):
	with open(romName, "rb") as f:
		romBytes = f.read()
		offset = 0
		for i,b in enumerate(romBytes[0x472b:0x4a91]):
			if id <= 0:
				offset = 0x472b + i
				break
			if b == 0x50:
				id -= 1;

		itemBytes = []
		for b in romBytes[offset:0x4a91]:
			itemBytes += [b]
			if b == 0x50:
				break
	return decode_bytes(itemBytes)

def check_item_names():
	idString = input("Enter item #: ")
	while idString != "bye":
		try:
			id = int(idString, 0)
			print(get_item_name(id))
		except ValueError:
			print("Not a number")
		idString = input("Enter byte: ")


def add_item(id, qty):
	global ramBytes

	with open(ramName, "rb") as f:
		ramBytes = f.read()

	itemCount = 0
	fBarr = bytearray(ramBytes)
	isAlreadyInBag = False
	offset = 0x25ca

	#check if item is already in bag and find offset
	for i,b in enumerate(fBarr[0x25ca:(0x25ca+40):2]):
		if b == id:
			isAlreadyInBag = True
			offset += i*2
			break
		if b == 0xff:
			offset += i*2
			break
	else:
		print("Bag is full")
		return

	#increment all items count
	if not isAlreadyInBag:
		print("New Item Added at bag offset {:#02x}".format(offset) )
		fBarr[0x25c9] += 1
		itemCount = fBarr[0x25c9]
	else:
		print("Item already in bag offset {:#02x}".format(offset) )

	fBarr[0x25ca + 2*itemCount] = 0xff
	fBarr[offset] = id
	fBarr[offset+1] = qty

	ramBytes = bytes(fBarr)

	fix_checksum()

	with open(ramName, "wb") as f:
		f.write(ramBytes)

#check_dict();



#check item
#check_item_names()
add_item(0x01, 99)
add_item(0x06, 1)
