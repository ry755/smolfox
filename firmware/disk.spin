OBJ
    c: "libc.spin2"

VAR
    long image[4]
    byte buffer[512]

PUB Initialize
    image[0] := c.fopen(@"/sd/disk0.img", @"r+b")
    image[1] := c.fopen(@"/sd/disk1.img", @"r+b")
    image[2] := c.fopen(@"/sd/disk2.img", @"r+b")
    image[3] := c.fopen(@"/sd/disk3.img", @"r+b")

PUB Seek(id, sector)
    c.fseek(image[id], sector * 512, c#SEEK_SET)

PUB Size(id)
    if image[id] == 0
        return 0
    c.fseek(image[id], 0, c#SEEK_END)
    result := c.ftell(image[id])
    c.fseek(image[id], 0, c#SEEK_SET)

PUB Read(id)
    c.fread(@buffer, 1, 512, image[id])
    return @buffer

PUB WriteBuffer(offset, value)
    byte[@buffer][offset] := value

PUB Write(id)
    c.fwrite(@buffer, 1, 512, image[id])

PUB Sync(id)
    c.fflush(image[id])
