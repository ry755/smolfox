# smolfox

smolfox is an incomplete [fox32](https://github.com/fox32-arch) emulator for the Parallax Propeller 2 microcontroller.
It only implements a subset of the platform, just enough to boot a stripped-down fox32os (in this repo as smolos).
The Propeller 2 outputs a 640x480 VGA signal containing an 80x30 character terminal, and uses [usbnew](https://github.com/Wuerfel21/usbnew) to accept keyboard input. This terminal is connected to the fox32 serial port, where smolos is configured to start a shell on boot.

To compile this, you must use [FlexProp](https://github.com/totalspectrum/flexprop) or plain flexspin. Ensure it is compiled to PASM and not Spin bytecode, otherwise you will get *terrible* performance.

Note that smolrom and smolos in this repo are sort of "disconnected" from their original fox32rom/fox32os form, and have modifications made to them that still need to be upstreamed. Similarly, upstream fox32rom and fox32os now have many new features that haven't yet made their way into smolrom/smolos. The plan is to have upstream fox32rom determine the "type" of fox32 system that it's currently running on, and pass that info to fox32os so it can adjust itself as needed (booting headless, less RAM, etc.)

Eventually it might be neat to look into supporting multiple different types and sizes of framebuffers in fox32rom/fox32os, so that this emulator can output a lower resolution and/or lower color-depth graphical screen, probably with less than the standard 32 overlays (maybe just one single framebuffer that fox32rom manually blits multiple "virtual" overlays into?)

Support for external RAM is also on the to-do list. The internal 512 KiB just isn't enough to do much.
