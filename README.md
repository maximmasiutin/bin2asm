# BIN2ASM
BIN to ASM Encoder Utility, Version 1.1. 

Written on November 2nd, 1993. Copyright (C) 1993 by MasyutinMax (Maxim Masiutin)

## Usage
```
Usage :  [path]BIN2ASM[.EXE] [switches] source[.com] [,] [dest[.asm]]
 when source       - any binary file,
      dest         - file, that would be created by BIN2ASM.
Switches :
       /d(d|q|t)   - Make 4-;8-;10-bytes data.
       /sNN        - Number of Counts per line, hex (01-80).
       /aNNNN      - Number of bytes to Skip, hex (0000-FFFF).
Example : ~BIN2ASM /dq /s0F /a0026 $cut$_02.COM, PIC~
```
