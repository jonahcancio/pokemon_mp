ramName = "Pokemon Red (U) [S][BF].sav"
fBytes = 0

def fix_checksum(fBytes):
    fBarr = bytearray(fBytes)
    sum = 0
    for i in range(0x2598, 0x3523):
        sum += fBytes[i]
        sum %= 256
    sum = (-sum - 1) % 256
    fBarr[0x3523] = sum
    fBytes = bytes(fBarr)
    return fBytes

with open(ramName, "rb") as f:
    fBytes = f.read()
    fBarr = bytearray(fBytes)
    fBarr[0x2602] = 0b00110000
    fBytes = bytes(fBarr)
    fBytes = fix_checksum(fBytes)




with open(ramName, "wb") as f:
    f.write(fBytes)
