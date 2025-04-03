CON
    _clkfreq = 160_000_000

OBJ
    c: "libc.spin2"
    cpu: "cpu.spin"
    hostfs: "hostfs.spin"

PUB Main
    _mount(@"/sd", c._vfs_open_sdcard())
    hostfs.GetDiskFromHost
    cpu.Initialize

    repeat
        cpu.Execute($FFFFFFFF)
