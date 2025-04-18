# Video adapter memory test
Tests 32KB memory segment starting from B000:0 or B800:0. The test is recommended for 2 monitor configuration:
- MDA/Hercules + CGA
- MDA/Hercules + VGA
The user can test video memory of some adapter and see the result on another.
The program renders current tested address for byte-by-byte test and address test
In case of an error, the test is stopped, the following information is printed:
- **AAAA** **BB CC**
where **AAAA** is the address, **BB** is the written byte, **CC** is the read byte
Pressing any key continues the test
Pressing **q** key stops the test
## Some details
- The test includes byte-by-byte test and address tests
- Only character part or attribute part may be tested
- Tested memory half-segment can be specified: B000 or B800
- Current memory address is shown at MONO or COLOR adapter (direct video memory wriote is used, video memory segment can be specified)
- The address test may be skipped
## How to run
mdatest1.com ABCDE
where:
- A: 0|8 specifies half-segment for test
- B: 0|8 specifies half-segment for display
- C: 1|2 tested address step: 1 or 2 bytes
- D: 0|1 initial address offset (0000h or 0001h)
- E: 0|1 0 for passing byte-by-byte test
Default values: 08101
## Comments, how to use
mdatest1 **08101** make all tests on mono adapter, display on color\
mdatest1 **80211** make all tests on color adapter, display on mono, step is 2 bytes, offset is 1, so it tests attributes only\
etc
