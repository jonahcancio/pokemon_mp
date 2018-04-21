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

#check_dict();

#check item
check_item_names()
