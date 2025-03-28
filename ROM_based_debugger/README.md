# ROM-based debugger "Dovbyk"

- Based on old DEBUGX real/protected debugger - highly stripped version
- Is loaded before DOS load, so the possible use is for checking bare-metal problems
- Fits in 20KB ROM
- video: https://youtu.be/yeVA9WgrlBg?si=EEFhynffOx-4NdnZ
- The binary file (20KB BIOS extension image + 12KB free data) can be flashed into IDE XT ROM or can be used in standalone ISA ROM extender
- Executable is placed in RAM at 3000:0000 address
- Files:
* demrom.32k - debugger ROM
* DEBUGX.zip - the great father of this version
