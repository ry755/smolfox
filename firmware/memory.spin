CON
    MEMORY_RAM         = $00040000 ' 256 KiB
    MEMORY_ROM         = $00004000 '  16 KiB
    MEMORY_ROM_START   = $F0000000

OBJ
    umath: "umath.spin"

VAR
    byte ram[MEMORY_RAM]

PUB GetRamAddr
    return @ram

PUB ReadByte(address)
    if (umath.ge(address, 0) and umath.lt(address, MEMORY_RAM))
        return ram[address]
    else
        if (umath.ge(address, constant(MEMORY_ROM_START + $40000)) and umath.lt(address, constant(MEMORY_ROM_START + $40FFF)))
            address -= constant($40000 - $3000)
        elseif (umath.ge(address, constant(MEMORY_ROM_START + $45000)) and umath.lt(address, constant(MEMORY_ROM_START + $45FFF)))
            address -= constant($45000 - $3100)
        elseif (umath.ge(address, constant(MEMORY_ROM_START + $46000)) and umath.lt(address, constant(MEMORY_ROM_START + $46FFF)))
            address -= constant($46000 - $3200)
        elseif (umath.ge(address, constant(MEMORY_ROM_START + $47000)) and umath.lt(address, constant(MEMORY_ROM_START + $47FFF)))
            address -= constant($47000 - $3300)

        if (umath.ge(address, MEMORY_ROM_START) and umath.lt(address, constant(MEMORY_ROM_START + MEMORY_ROM)))
            address &= $00007FFF
            return rom[address]
        else
            return 0

PUB ReadHalf(address)
    result := ReadByte(address)
    result |= ReadByte(address + 1) << 8

PUB ReadWord(address)
    result := ReadByte(address)
    result |= ReadByte(address + 1) << 8
    result |= ReadByte(address + 2) << 16
    result |= ReadByte(address + 3) << 24

PUB WriteByte(address, value)
    if (umath.lt(address, MEMORY_RAM))
        ram[address] := value

PUB WriteHalf(address, value)
    WriteByte(address, value & $000000FF)
    WriteByte(address + 1, (value & $0000FF00) >> 8)

PUB WriteWord(address, value)
    WriteByte(address, value & $000000FF)
    WriteByte(address + 1, (value & $0000FF00) >> 8)
    WriteByte(address + 2, (value & $00FF0000) >> 16)
    WriteByte(address + 3, (value & $FF000000) >> 24)

DAT
rom file "../smolrom.bin"
