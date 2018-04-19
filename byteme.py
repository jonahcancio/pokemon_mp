ramName = "Pokemon Red (U) [S][BF].sav"

with open(ramName, "rb") as f:
    fBytes = f.read()
    print(hex(fBytes[0x25f3]))
    print(hex(fBytes[0x25f4]))
    print(hex(fBytes[0x25f5]))
