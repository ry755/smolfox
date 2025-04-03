OBJ
    c: "libc.spin2"
    ser: "spin/SmartSerial"
    fs: "fs9p.cc"

VAR
    long myfd[4]
    long image
    byte buf[1024]

PUB GetDiskFromHost | r
    ser.start(63, 62, 0, 921_600)
    ser.printf("Updating disk0.img from host...")
    r := fs.fs_init(@sendrecv)
    if r < 0
        ser.printf(" fs_init returned error %d\n", r)
        return
    r := fs.fs_open(@myfd, @"disk0.img", 0)
    if r < 0
        ser.printf(" fs_open returned error %d\n", r)
        return
    image := c.fopen(@"/sd/disk0.img", @"wb")
    repeat
        r := fs.fs_read(@myfd, @buf, 1024)
        c.fwrite(@buf, 1, 1024, image)
        ser.printf(".")
    until r =< 0
    fs.fs_close(@myfd)
    c.fclose(image)
    ser.printf(" done!\n")

    r := fs.fs_open(@myfd, @"disk1.img", 0)
    if r < 0
        return
    ser.printf("Updating disk1.img from host...")
    image := c.fopen(@"/sd/disk1.img", @"wb")
    repeat
        r := fs.fs_read(@myfd, @buf, 1024)
        c.fwrite(@buf, 1, 1024, image)
        ser.printf(".")
    until r =< 0
    fs.fs_close(@myfd)
    c.fclose(image)
    ser.printf(" done!\n")

'' routine for transmitting and receiving 9P protocol buffers

PUB sendrecv(startbuf, endbuf, maxlen) | len, buf, i, left
    len := endbuf - startbuf
    buf := startbuf
    long[startbuf] := len

    '' transmit magic sequence for loadp2
    ser.tx($FF)
    ser.tx($01)
    repeat while len > 0
        ser.tx(byte[buf++])
        len--

    ' now get response
    buf := startbuf
    byte[buf++] := ser.rx
    byte[buf++] := ser.rx
    byte[buf++] := ser.rx
    byte[buf++] := ser.rx
    len := long[startbuf]
    left := len - 4
    repeat while left > 0
        byte[buf++] := ser.rx
        --left
    return len
