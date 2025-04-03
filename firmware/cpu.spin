CON
    OP_NOP           = $00
    OP_ADD           = $01
    OP_MUL           = $02
    OP_AND           = $03
    OP_SLA           = $04
    OP_SRA           = $05
    OP_BSE           = $06
    OP_CMP           = $07
    OP_JMP           = $08
    OP_RJMP          = $09
    OP_PUSH          = $0A
    OP_IN            = $0B
    OP_ISE           = $0C
    OP_MSE           = $0D
    OP_HALT          = $10
    OP_INC           = $11
    OP_OR            = $13
    OP_IMUL          = $14
    OP_SRL           = $15
    OP_BCL           = $16
    OP_MOV           = $17
    OP_CALL          = $18
    OP_RCALL         = $19
    OP_POP           = $1A
    OP_OUT           = $1B
    OP_ICL           = $1C
    OP_MCL           = $1D
    OP_BRK           = $20
    OP_SUB           = $21
    OP_DIV           = $22
    OP_XOR           = $23
    OP_ROL           = $24
    OP_ROR           = $25
    OP_BTS           = $26
    OP_MOVZ          = $27
    OP_LOOP          = $28
    OP_RLOOP         = $29
    OP_RET           = $2A
    OP_INT           = $2C
    OP_TLB           = $2D
    OP_DEC           = $31
    OP_REM           = $32
    OP_NOT           = $33
    OP_IDIV          = $34
    OP_IREM          = $35
    OP_ICMP          = $37
    OP_RTA           = $39
    OP_RETI          = $3A
    OP_FLP           = $3D

    CD_ALWAYS        = $00
    CD_IFZ           = $01
    CD_IFNZ          = $02
    CD_IFC           = $03
    CD_IFNC          = $04
    CD_IFGT          = $05
    CD_IFLTEQ        = $06

    SZ_BYTE          = 1
    SZ_HALF          = 2
    SZ_WORD          = 4

    TY_REG           = 0
    TY_REGPTR        = 1
    TY_IMM           = 2
    TY_IMMPTR        = 3

OBJ
    bus: "bus.spin2"

VAR
    long instructionPointer
    long instructionPointerMut
    long stackPointer
    long framePointer
    long registers[32]
    byte flags
    byte debug

    ' in-flight opcode storage
    byte opcode
    byte condition
    byte offset
    byte target
    byte source
    byte size

PUB Initialize
    instructionPointer := $F0000000
    stackPointer := 0
    debug := false
    bus.Initialize
    'bus.DebugStr(string("vm info: fox32 ram at "))
    'bus.DebugHex(bus.GetRamAddr, 8)
    'bus.DebugChar(10)

PUB Execute(cycles) | instructionHalf, temp, temp2, savedSize, skip
    repeat cycles
        instructionHalf := bus.ReadHalf(instructionPointer)
        instructionPointerMut := instructionPointer + SZ_HALF

        opcode := (instructionHalf >> 8) & 63
        condition := (instructionHalf >> 4) & 7
        offset := (instructionHalf >> 7) & 1
        target := (instructionHalf >> 2) & 3
        source := instructionHalf & 3
        size := ((instructionHalf >> 14))
        if (size == 0)
            size := 1
        else
            size *= 2
        skip := ShouldSkip

        if (instructionPointer == 0)
            'bus.DebugStr(string("vm warn: called non-existent jump table entry?"))
            'bus.DebugChar(10)
            debug := false

        if (debug)
            bus.DebugHex(instructionPointer, 8)
            bus.DebugHex(instructionHalf, 4)
            bus.DebugHex(opcode, 2)
            bus.DebugHex(condition, 2)
            bus.DebugHex(offset, 2)
            bus.DebugHex(target, 2)
            bus.DebugHex(source, 2)
            bus.DebugHex(size, 2)
            bus.DebugChar(10)

        case opcode
            OP_NOP, OP_HALT, OP_ISE, OP_ICL, OP_MSE, OP_MCL: ' nothing!
            OP_BRK:
                debug := !debug
            OP_ADD:
                temp := ReadSource(false)
                if not (skip)
                    temp2 := ReadTarget
                    SetCarryFlag((temp2 > 0) and (temp +> $FFFFFFFF - temp2))
                    temp += temp2
                    SetZeroFlag(temp == 0)
                WriteTarget(temp, true, skip, false)
            OP_INC:
                temp := ReadSource(true)
                if not (skip)
                    temp2 := (1 << target)
                    SetCarryFlag((temp2 > 0) and (temp +> $FFFFFFFF - temp2))
                    temp += temp2
                    SetZeroFlag(temp == 0)
                target := source
                WriteTarget(temp, true, skip, false)
            OP_SUB:
                temp2 := ReadSource(false)
                if not (skip)
                    temp := ReadTarget
                    SetCarryFlag((temp2 > 0) and (temp +< 0 + temp2))
                    temp -= temp2
                    SetZeroFlag(temp == 0)
                WriteTarget(temp, true, skip, false)
            OP_DEC:
                temp := ReadSource(true)
                if not (skip)
                    temp2 := (1 << target)
                    SetCarryFlag((temp2 > 0) and (temp +< 0 + temp2))
                    temp -= temp2
                    SetZeroFlag(temp == 0)
                target := source
                WriteTarget(temp, true, skip, false)
            OP_MUL:
                temp := ReadSource(false)
                if not (skip)
                    temp2 := ReadTarget
                    SetCarryFlag((temp2 <> 0) and (temp +> $FFFFFFFF / temp2))
                    temp *= temp2
                    SetZeroFlag(temp == 0)
                WriteTarget(temp, true, skip, false)
            OP_IMUL: ' FIXME: is this correct? also need to implement carry flag
                temp := ReadSource(false)
                case size
                    SZ_BYTE: temp := ~temp ' sign extend 7
                    SZ_HALF: temp := ~~temp ' sign extend 15
                if not (skip)
                    temp2 := temp * ReadTarget
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_DIV:
                temp := ReadSource(false)
                WriteTarget(ReadTarget +/ temp, true, skip, false)
            OP_IDIV: ' FIXME: is this correct?
                temp := ReadSource(false)
                case size
                    SZ_BYTE: temp := ~temp ' sign extend 7
                    SZ_HALF: temp := ~~temp ' sign extend 15
                if not (skip)
                    temp2 := ReadTarget / temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_REM:
                temp := ReadSource(false)
                if not (skip)
                    temp2 := ReadTarget +// temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_IREM: ' FIXME: is this correct?
                temp := ReadSource(false)
                if not (skip)
                    case size
                        SZ_BYTE:
                            temp := ~temp ' sign extend 7
                            temp2 := ReadTarget // temp
                            SetZeroFlag(temp2 == 0)
                        SZ_HALF:
                            temp := ~~temp ' sign extend 15
                            temp2 := ReadTarget // temp
                            SetZeroFlag(temp2 == 0)
                        SZ_WORD:
                            temp2 := ReadTarget // temp
                            SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_AND:
                temp := ReadSource(false)
                if not (skip)
                    temp2 := ReadTarget & temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_OR:
                temp := ReadSource(false)
                if not (skip)
                    temp2 := ReadTarget | temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_XOR:
                temp := ReadSource(false)
                if not (skip)
                    temp2 := ReadTarget ^ temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_NOT:
                temp := !ReadSource(true)
                if not (skip)
                    SetZeroFlag(temp == 0)
                target := source
                WriteTarget(temp, true, skip, false)
            OP_SLA: ' shifts & rotates always use an 8-bit source
                savedSize := size
                size := SZ_BYTE
                temp := ReadSource(false)
                size := savedSize
                if not (skip)
                    temp2 := ReadTarget << temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_SRA: ' shifts & rotates always use an 8-bit source
                savedSize := size
                size := SZ_BYTE
                temp := ReadSource(false)
                size := savedSize
                if not (skip)
                    temp2 := ReadTarget ~> temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_SRL: ' shifts & rotates always use an 8-bit source
                savedSize := size
                size := SZ_BYTE
                temp := ReadSource(false)
                size := savedSize
                if not (skip)
                    temp2 := ReadTarget >> temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_ROL: ' shifts & rotates always use an 8-bit source
                savedSize := size
                size := SZ_BYTE
                temp := ReadSource(false)
                size := savedSize
                if not (skip)
                    temp2 := ReadTarget <- temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_ROR: ' shifts & rotates always use an 8-bit source
                savedSize := size
                size := SZ_BYTE
                temp := ReadSource(false)
                size := savedSize
                if not (skip)
                    temp2 := ReadTarget -> temp
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_BSE: ' bit operations always use an 8-bit source
                savedSize := size
                size := SZ_BYTE
                temp := ReadSource(false)
                size := savedSize
                if not (skip)
                    temp2 := ReadTarget | (1 << temp)
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_BCL: ' bit operations always use an 8-bit source
                savedSize := size
                size := SZ_BYTE
                temp := ReadSource(false)
                size := savedSize
                if not (skip)
                    temp2 := ReadTarget & !(1 << temp)
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, skip, false)
            OP_BTS: ' bit operations always use an 8-bit source
                savedSize := size
                size := SZ_BYTE
                temp := ReadSource(false)
                size := savedSize
                if not (skip)
                    temp2 := ReadTarget & (1 << temp)
                    SetZeroFlag(temp2 == 0)
                WriteTarget(temp2, true, true, false) ' dummy write
            OP_CMP:
                temp2 := ReadSource(false)
                if not (skip)
                    temp := ReadTarget
                    SetCarryFlag(temp2 +> temp)
                    temp -= temp2
                    SetZeroFlag(temp == 0)
                WriteTarget(temp, true, true, false) ' dummy write
            OP_ICMP:
                temp2 := ReadSource(false)
                if not (skip)
                    case size
                        SZ_BYTE:
                            temp2 := ~temp2 ' sign extend 7
                            temp := ReadTarget
                            SetCarryFlag(temp < temp2)
                        SZ_HALF:
                            temp2 := ~~temp2 ' sign extend 15
                            temp := ReadTarget
                            SetCarryFlag(temp < temp2)
                        SZ_WORD:
                            temp := ReadTarget
                            SetCarryFlag(temp < temp2)
                    temp -= temp2
                    SetZeroFlag(temp == 0)
                WriteTarget(temp, true, true, false) ' dummy write
            OP_MOV: WriteTarget(ReadSource(false), true, skip, false)
            OP_MOVZ: WriteTarget(ReadSource(false), false, skip, false)
            OP_PUSH:
                temp := ReadSource(false)
                if not (skip)
                    Push(temp)
            OP_POP:
                if not (skip)
                    temp := Pop
                target := source
                WriteTarget(temp, true, skip, false)
            OP_RTA:
                temp := ReadSource(false)
                case size
                    SZ_BYTE:
                        temp := ~temp ' sign extend 7
                    SZ_HALF:
                        temp := ~~temp ' sign extend 15
                savedSize := size
                size := SZ_WORD
                WriteTarget(instructionPointer + temp, false, skip, false)
                size := savedSize
            OP_JMP:
                temp := ReadSource(false)
                if not (skip)
                    instructionPointerMut := temp
            OP_CALL:
                temp := ReadSource(false)
                if not (skip)
                    savedSize := size
                    size := SZ_WORD
                    Push(instructionPointerMut)
                    size := savedSize
                    instructionPointerMut := temp
            OP_LOOP:
                temp := ReadSource(false)
                if not (skip)
                    registers[31]--
                    if (registers[31] <> 0)
                        instructionPointerMut := temp
            OP_RJMP:
                temp := ReadSource(false)
                case size
                    SZ_BYTE:
                        temp := ~temp ' sign extend 7
                    SZ_HALF:
                        temp := ~~temp ' sign extend 15
                if not (skip)
                    instructionPointerMut := instructionPointer + temp
            OP_RCALL:
                temp := ReadSource(false)
                case size
                    SZ_BYTE:
                        temp := ~temp ' sign extend 7
                    SZ_HALF:
                        temp := ~~temp ' sign extend 15
                if not (skip)
                    savedSize := size
                    size := SZ_WORD
                    Push(instructionPointerMut)
                    size := savedSize
                    instructionPointerMut := instructionPointer + temp
            OP_RLOOP:
                temp := ReadSource(false)
                case size
                    SZ_BYTE:
                        temp := ~temp ' sign extend 7
                    SZ_HALF:
                        temp := ~~temp ' sign extend 15
                if not (skip)
                    registers[31]--
                    if (registers[31] <> 0)
                        instructionPointerMut := instructionPointer + temp
            OP_RET:
                if not (skip)
                    savedSize := size
                    size := SZ_WORD
                    instructionPointerMut := Pop
                    size := savedSize
            OP_IN:
                temp := ReadSource(false)
                if not (skip)
                    temp2 := bus.Read(temp)
                WriteTarget(temp2, true, skip, false)
            OP_OUT:
                temp := ReadSource(false)
                temp2 := ReadTarget
                if not (skip)
                    bus.Write(temp2, temp)
                WriteTarget(0, true, true, false)
            other: Panic(string("bad opcode"), opcode)

        instructionPointer := instructionPointerMut

PRI Panic(message, arg)
    bus.DebugStr(string("vm panic: "))
    bus.DebugStr(message)
    bus.DebugStr(string(" "))
    bus.DebugHex(arg, 8)
    bus.DebugChar(10)
    bus.DebugHex(instructionPointer, 8)
    bus.DebugHex(opcode, 2)
    bus.DebugHex(condition, 2)
    bus.DebugHex(offset, 2)
    bus.DebugHex(target, 2)
    bus.DebugHex(source, 2)
    bus.DebugHex(size, 2)
    bus.DebugChar(10)
    repeat

PRI Push(value)
    stackPointer -= size
    if (stackPointer & $80000000)
        Panic(string("stack pointer has high bit set???"), stackPointer)
    case size
        SZ_BYTE: bus.WriteByte(stackPointer, value)
        SZ_HALF: bus.WriteHalf(stackPointer, value)
        SZ_WORD: bus.WriteWord(stackPointer, value)
        other: Panic(string("bad size"), size)

PRI Pop
    case size
        SZ_BYTE: result := bus.ReadByte(stackPointer)
        SZ_HALF: result := bus.ReadHalf(stackPointer)
        SZ_WORD: result := bus.ReadWord(stackPointer)
        other: Panic(string("bad size"), size)
    stackPointer += size
    if (stackPointer & $80000000)
        Panic(string("stack pointer has high bit set"), stackPointer)

PRI ReadRegister(register)
    case register
        0..31: return registers[register]
        32: return stackPointer
        '33: return 0 ' resp, not used here
        34: return framePointer
        other: Panic(string("bad register"), register)

PRI WriteRegister(register, value)
    case register
        0..31: registers[register] := value
        32: stackPointer := value
        '33: return
        34: framePointer := value
        other: Panic(string("bad register"), register)

' affects global state!
PRI ReadSource(stay) | register, pointer, value
    case source
        TY_REG:
            register := bus.ReadByte(instructionPointerMut)
            if not (stay)
                instructionPointerMut += SZ_BYTE
            value := ReadRegister(register)
            case size
                SZ_BYTE: value &= $000000FF
                SZ_HALF: value &= $0000FFFF
            return value
        TY_REGPTR:
            register := bus.ReadByte(instructionPointerMut)
            pointer := ReadRegister(register)
            instructionPointerMut += SZ_BYTE
            if (offset <> 0)
                pointer += bus.ReadByte(instructionPointerMut)
                instructionPointerMut += SZ_BYTE
            value := ReadWithSize(pointer)
            if (stay)
                instructionPointerMut -= SZ_BYTE
                if (offset <> 0)
                    instructionPointerMut -= SZ_BYTE
            return value
        TY_IMM:
            value := ReadWithSize(instructionPointerMut)
            if not (stay)
                instructionPointerMut += size
            return value
        TY_IMMPTR:
            pointer := bus.ReadWord(instructionPointerMut)
            if not (stay)
                instructionPointerMut += SZ_WORD
            return ReadWithSize(pointer)
        other: Panic(string("bad source"), source)

' read target without affecting global state. must read source first before calling this
PRI ReadTarget | register, pointer, value
    case target
        TY_REG:
            register := bus.ReadByte(instructionPointerMut)
            value := ReadRegister(register)
            case size
                SZ_BYTE: value &= $000000FF
                SZ_HALF: value &= $0000FFFF
            return value
        TY_REGPTR:
            pointer := ReadRegister(bus.ReadByte(instructionPointerMut))
            if (offset <> 0)
                pointer += bus.ReadByte(instructionPointerMut + SZ_BYTE)
            return ReadWithSize(pointer)
        TY_IMM:
            return ReadWithSize(instructionPointerMut)
        TY_IMMPTR:
            return ReadWithSize(bus.ReadWord(instructionPointerMut))
        other: Panic(string("bad target"), target)

' affects global state!
PRI WriteTarget(value, keepUpperBits, skip, stay) | register, pointer, temp
    case target
        TY_REG:
            register := bus.ReadByte(instructionPointerMut)
            if not (stay)
                instructionPointerMut += SZ_BYTE
            if (keepUpperBits)
                temp := ReadRegister(register)
                case size
                    SZ_BYTE: value := (temp & $FFFFFF00) | (value & $000000FF)
                    SZ_HALF: value := (temp & $FFFF0000) | (value & $0000FFFF)
                    SZ_WORD:
                    other: Panic(string("bad size"), size)
            if not (skip)
                WriteRegister(register, value)
        TY_REGPTR:
            register := bus.ReadByte(instructionPointerMut)
            pointer := ReadRegister(register)
            instructionPointerMut += SZ_BYTE
            if (offset <> 0)
                pointer += bus.ReadByte(instructionPointerMut)
                instructionPointerMut += SZ_BYTE
            if (keepUpperBits)
                temp := bus.ReadWord(pointer)
                case size
                    SZ_BYTE: value := (temp & $FFFFFF00) | (value & $000000FF)
                    SZ_HALF: value := (temp & $FFFF0000) | (value & $0000FFFF)
                    SZ_WORD:
                    other: Panic(string("bad size"), size)
            else
                size := SZ_WORD ' we need to write a full word to clear the upper bits
            if not (skip)
                WriteWithSize(pointer, value)
            if (stay)
                instructionPointerMut -= SZ_BYTE
                if (offset <> 0)
                    instructionPointerMut -= SZ_BYTE
        TY_IMM:
            if not (stay)
                instructionPointerMut += size
        TY_IMMPTR:
            pointer := bus.ReadWord(instructionPointerMut)
            if (keepUpperBits)
                temp := bus.ReadWord(pointer)
                case size
                    SZ_BYTE: value := (temp & $FFFFFF00) | (value & $000000FF)
                    SZ_HALF: value := (temp & $FFFF0000) | (value & $0000FFFF)
                    SZ_WORD:
                    other: Panic(string("bad size"), size)
            else
                size := SZ_WORD ' we need to write a full word to clear the upper bits
            if not (stay)
                instructionPointerMut += SZ_WORD
            if not (skip)
                WriteWithSize(pointer, value)
        other: Panic(string("bad target"), target)

PRI ReadWithSize(address)
    case size
        SZ_BYTE: return bus.ReadByte(address)
        SZ_HALF: return bus.ReadHalf(address)
        SZ_WORD: return bus.ReadWord(address)
        other: Panic(string("bad size"), size)

PRI WriteWithSize(address, value)
    case size
        SZ_BYTE: bus.WriteByte(address, value)
        SZ_HALF: bus.WriteHalf(address, value)
        SZ_WORD: bus.WriteWord(address, value)
        other: Panic(string("bad size"), size)

PRI ShouldSkip
    case condition
        CD_ALWAYS:
            return false
        CD_IFZ:
            return ZeroFlag == false
        CD_IFNZ:
            return ZeroFlag == true
        CD_IFC:
            return CarryFlag == false
        CD_IFNC:
            return CarryFlag == true
        CD_IFGT:
            return (ZeroFlag == true) or (CarryFlag == true)
        CD_IFLTEQ:
            return (ZeroFlag == false) and (CarryFlag == false)

PRI ZeroFlag
    return ((flags & 1) <> 0)
PRI CarryFlag
    return ((flags & 2) <> 0)
PRI InterruptFlag
    return ((flags & 4) <> 0)
PRI SwapSpFlag
    return ((flags & 8) <> 0)

PRI SetZeroFlag(set)
    if (set)
        flags |= 1
    else
        flags &= !1
PRI SetCarryFlag(set)
    if (set)
        flags |= 2
    else
        flags &= !2
