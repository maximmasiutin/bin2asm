dosseg

.model MEDIUM

StSize equ 200h

.stack StSize

.data
About   db      7 dup('-'),' *** RS Graphics Utilities *** ',9 dup('-'),' Kishinev, RSsoftware ',6 dup('-'),10,13
        db      'BIN ==> ASM Encoder Utility Version 1.1  Copyright (C) 1993 by MasyutinMax~'
crlf    db      10,13,'$'
Help    db      'Usage :  [path] BIN2ASM [.EXE]  [switches] source[.com] [,] [dest[.asm]]',10,13,10,13
        db      ' when ',27h,'source',27h,' - any binary file,',10,13
        db      '       ',27h,'dest',27h,'  - file, that would be created by BIN2ASM.',10,13,10,13
        db      'Switches :',10,13
        db      '       /d(d|q|t)   - Make 4-;8-;10-bytes data.',10,13
        db      '       /sNN        - Number of Counts per line, hex (01-80).',10,13
        db      '       /aNNNN      - Number of bytes to Skip, hex (0000-FFFF).',10,13,10,13
        db      'Example : ~BIN2ASM /dq /s0F /a0026 $cut$_02.COM, PIC~',10,13,10,13
        db      'Thanks!',10
HelpE   db      13
NoMem   db      'Not enough memory.',10,13,'$'
DosVer  db      'Incorrect DOS version.  This program requires DOS 3.20 or later.',10,13,'$'
FNotFound db    'File NOT found.',10,13,'$'
AccDen  db      'Access denied.',10,13,'$'
TooManyFiles db 'Too many files open.',10,13,'$'
ErrOpFile db    'Error opening file.',10,13,'$'
TooBig  db      'Source file is to large for BIN-file. It must be no bigger than 64Kb.',10,13,'$'
CreaErr db      'Can',27h,'t create destination file.',10,13,'$'
WritErr db      'Error writing destination file.',10,13,'$'
BadT    db      'Unknown numeric type (use ~/dd~ or ~/dq~ or ~/dt~).',10,13,'$'
ParEr   db      'Error in parameter string: duplicate option.',10,13,'$'
KeyDiv  db      'Any option in parameter string.',10,13
        db      'must be devided from file names by space character.',10,13,'$'
NotDigM db      'Invalid number : use a hex value in range (01-80).',10,13,'$'
OutOfR  db      'Value of option /S is out of range (01-80).',10,13,'$'
OutOfA  db      'Value of option /A is out of range (0000-FFFF).',10,13,'$'
NoDiA   db      'Invalid number : use a hex value in range (0000-FFFF).',10,13,'$'
SeekErr db      'Seek error.',10,13,'$'
ParErrorM db    'Unknown option.',10,13,'$'
Encod   db      'Encoding : "$'
Arrow   db      '" ==> "$'
EncEnd  db      '"...',10,13,'$'
FindFir db      'Reading source file : "$'
REnd    db      '"...',10,13,'$'
Writ    db      'Writing destination file : "$'
Complet db      'Encoding process completed successfuly.',10,13,'$'

FName2Loc       equ     52h
FName1Loc       equ     02h
cmCmpDl         equ     0FA80h
cmMovAx         equ     0B8h
cmMovCx         equ     0B9h
cmCmpBp         equ     0FD83h

PspSeg          equ     word ptr ss:[StSize-2]
SouSeg          equ     word ptr ss:[StSize-4]
DstSeg          equ     word ptr ss:[StSize-6]
FnmSeg          equ     word ptr ss:[StSize-8]
DtaSeg          equ     word ptr ss:[StSize-10]
Opt_D           equ     byte ptr ss:[StSize-11]
Opt_S           equ     byte ptr ss:[StSize-12]
Opt_A           equ     byte ptr ss:[StSize-13]
SkipSize        equ     word ptr ss:[StSize-15]
StackDLen       equ     18

.code

;============ Stack Initialization =============
        cld
        mov     sp,StSize-StackDLen
        mov     di,StSize-StackDLen+2
        mov     al,0
        mov     cx,StackDLen-2
        push    es
        push    ss
        pop     es
        rep     stosb
        pop     es
;===============================================

        call    SetDs
        mov     PspSeg,es
        lea     dx,About
        mov     ah,9
        int     21h
        call    WriteLine
        lea     dx,crlf
        mov     ah,9
        int     21h


        mov     ah,30h
        int     21h
        cmp     al,3
        ja      OkDos
        jnz     WrongDos
        cmp     ah,20
        jnb     OkDos

WrongDos:
        lea     dx,DosVer
        jmp     RunTimeError


OkDos:

        push    ss
        pop     bx
        add     bx,StSize/16
        mov     ax,es
        sub     bx,ax

        mov     ah,4Ah
        int     21h

        push    ds
        push    es
        pop     ds

        mov     si,81h

ClearS: lodsb
        cmp     al,' '
        jz      ClearS
        pop     ds
        cmp     al,0Dh
        jnz     ExParam


DisplayHelp:
        lea     dx,Help
        mov     cx,offset HelpE-offset Help+1
        mov     bx,2
        mov     ah,40h
        int     21h
        call    WriteLine
        jmp     NormExit

ExParam:
        dec     si
        mov     ah,48h
        mov     bx,0FFFFh/16
        int     21h
        jnc     SouAlloc

NoMemor:
        lea     dx,NoMem
        jmp     RunTimeError

SouAlloc:
        mov     SouSeg,ax
        mov     bx,0A000h/16
        mov     ah,48h
        int     21h
        jnc     DstAlloc

DstErr:
        mov     es,SouSeg
        mov     ah,49h
        int     21h
        jmp     short NoMemor

DstAlloc:
        mov     DstSeg,ax
        mov     bx,80h/16+2
        mov     ah,48h
        int     21h
        jnc     FnmAlloc

FnmError:
        mov     es,DstSeg
        mov     ah,49h
        int     21h
        jmp     short DstErr

FnmAlloc:
        mov     FnmSeg,ax
        mov     bx,80h/16+1
        mov     ah,48h
        int     21h
        jnc     NDtaAlloc
        mov     es,FnmSeg
        mov     ah,49h
        int     21h
        jmp     short FNmError

NDtaAlloc:
        mov     DtaSeg,ax

;---------------------- Begin Anal ------------------------------------------
        mov     es,FnmSeg
        mov     ds,PspSeg
        mov     di,FName1Loc
        xor     bx,bx
        mov     dl,80h
        mov     cx,'td'
        mov     bp,10


Next0:
        lodsb
        cmp     al,' '
        jz      Next0
        cmp     al,0Dh
        jnz     Cont0
        jmp     DisplayHelp

OptA:
        cmp     Opt_A,1
        jz      ParError
        mov     Opt_A,1
        call    ALoadByte
        mov     bx,ax
        call    ALoadByte
        mov     ah,bl
        mov     word ptr cs:SkipSize,ax
        jmp     short ToCont0

Cont0:
        cmp     al,'/'
        jnz     ToNotFrac
        lodsb
        cmp     al,'d'
        jz      OptD
        cmp     al,'D'
        jz      OptD
        cmp     al,'s'
        jz      OptS
        cmp     al,'S'
        jz      OptS
        cmp     al,'a'
        jz      OptA
        cmp     al,'A'
        jz      OptA

        lea     dx,ParErrorM
        jmp     RuntimeMem

OptD:
        cmp     Opt_D,1
        jz      ParError
        mov     Opt_D,1
        lodsb
        cmp     al,'d'
        jnz     NotDD
        mov     bp,4
        mov     cx,'dd'

ToCont0:
        lodsb
        cmp     al,' '
        jz      Next0
        lea     dx,KeyDiv
        jmp     RunTimeMem

NotDD:
        cmp     al,'q'
        jnz     NotDQ
        mov     bp,8
        mov     cx,'qd'
        jmp     short ToCont0

NotDQ:
        cmp     al,'t'
        jz      OptDT
        lea     dx,BadT
        jmp     RunTimeMem

OptDT:
        mov     bp,10
        mov     cx,'td'
        jmp     short ToCont0

ParError:
        lea     dx,ParEr
        jmp     RunTimeMem

ToNotFrac:
        jmp     NotFrac
OptS:
        cmp     Opt_S,1
        jz      ParError
        mov     Opt_S,1
        lodsb
        call    CheckDigit
        jnc     Dig1

ErrDig:
        lea     dx,NotDigM
        jmp     RunTimeMem
Dig1:
        call    ShlAl4
        mov     ah,al
        lodsb
        call    CheckDigit
        jc      ErrDig
        or      al,ah
        cmp     al,0
        jnz     NotOOR

OutOfRange:
        lea     dx,OutOfR
        jmp     RunTimeMem

NotOOR:
        cmp     al,80h
        ja      OutOfRange

        mov     dl,al
        jmp     short ToCont0

NotFrac:
        call    Correction
        stosb
Next1:  lodsb
        cmp     al,' '
        jz      FormFName2
        cmp     al,0Dh
        jz      FormFName2
        cmp     al,','
        jz      FormFname2
        cmp     al,'.'
        jnz     NotPoint0
        mov     bx,di
NotPoint0:
        stosb
        jmp     short Next1

FormFName2:
        push    ax

        jmp     short Next10
Next11:
        lodsb
Next10:
        cmp     al,' '
        jz      Next11
        cmp     al,','
        jz      Next11


        push    di
        dec     di
        cmp     bx,di
        pop     di
        jnz     NotBxDi
        dec     di

NotBxDi:
        or      bx,bx
        jnz     ExistExt0
        mov     bx,di
        mov     ax,'c.'
        stosw
        mov     ax,'mo'
        stosw

ExistExt0:
        mov     ax,di
        dec     ax
        dec     ax
        mov     word ptr es:[Fname1Loc-2],ax
        mov     al,0
        stosb
        pop     ax

        jmp     short Next7
Next12:
        lodsb
Next7:
        cmp     al,' '
        jz      Next12
        cmp     al,','
        jz      Next12

        cmp     al,0Dh
        jz      EmptyFName2

        dec     si
        dec     si

        mov     di,Fname2Loc
        mov     ah,0

Next2:
        lodsb
        cmp     al,' '
        jz      Next2
        cmp     al,0Dh
        jz      EmptyFname2
        stosb
Next3:
        lodsb
        cmp     al,0Dh
        jz      FName2Formed
        cmp     al,' '
        jz      Next3
        cmp     al,'.'
        jnz     NotPoint1
        mov     ah,1

NotPoint1:
        stosb
        jmp     short Next3

FName2Formed:
        cmp     ah,1
        jz      ExistExt1
        mov     ax,'a.'
        stosw
        mov     ax,'ms'
        stosw

ExistExt1:
        mov     ax,di
        sub     ax,Fname2Loc
        mov     word ptr es:[Fname2Loc-2],ax
        mov     al,0
        stosb
        jmp     short FormedBoth

EmptyFName2:
        push    es
        pop     ds
        mov     si,Fname1Loc
        mov     di,Fname2Loc

Next4:  lodsb
        stosb
        cmp     bx,si
        jnz     Next4
        mov     ax,'a.'
        stosw
        mov     ax,'ms'
        stosw

        jmp     short ExistExt1

FormedBoth:

;---------------------- End Anal --------------------------------------------

        lea     dx,Encod
        call    Prnt
        call    PrintFName1
        lea     dx,Arrow
        call    Prnt
        call    PrintFName2
        lea     dx,EncEnd
        call    Prnt

        mov     ds,cs:DtaSeg
        xor     dx,dx
        mov     ah,1Ah
        int     21h

        mov     ds,cs:FnmSeg
        mov     dx,Fname1Loc
        mov     cx,0FFFFh
        mov     ah,4Eh
        int     21h
        jnc     Found1
        lea     dx,FNotFound
        jmp     short ToRT

Found1:
        mov     ds,cs:DtaSeg
        mov     ax,word ptr ds:[1Ch]
        or      ax,ax
        jz      NorSize
        lea     dx,TooBig
        jmp     short ToRT

NorSize:
        lea     dx,FindFir
        call    Prnt
        call    PrintFName1
        lea     dx,REnd
        call    Prnt

        mov     bp,word ptr ds:[1Ah]
        sub     bp,word ptr cs:SkipSize
        mov     ds,cs:FnmSeg
        mov     dx,Fname1Loc
        mov     ax,3D00h
        int     21h
        jnc     ReadSuc

ErrorReadOc:
        cmp     al,2
        jnz     NotErr2
        lea     dx,FNotFOund
ToRT:
        jmp     RunTimeMem

NotErr2:
        cmp     al,4
        jnz     NotErr4
        lea     dx,TooManyFiles
        jmp     short ToRT

NotErr4:
        cmp     al,5
        jnz     NotErr5
        lea     dx,AccDen
        jmp     short ToRT

NotErr5:
        lea     dx,ErrOpFile
        jmp     short ToRT

ReadSuc:
        mov     bx,ax
        mov     ax,4200h
        xor     cx,cx
        mov     dx,word ptr cs:SkipSize
        int     21h
        jnc     SeekOk
        lea     dx,SeekErr
        jmp     short ToRT

SeekOk:
        mov     ds,cs:SouSeg
        mov     cx,bp
        xor     dx,dx
        mov     ah,3Fh
        int     21h
        jnc     BlrSuc

Troub:
        call    Close1
        jmp     short ErrorReadOc


BlrSuc:
        cmp     ax,bp
        jz      ReEquSi
        call    Close1
        jmp     short NotErr5

ReEquSi:
        call    Close1

        lea     dx,Writ
        call    Prnt
        call    PrintFName2
        lea     dx,REnd
        call    Prnt

        mov     ds,cs:FnmSeg
        mov     dx,FName2Loc
        xor     cx,cx
        mov     ah,3Ch
        int     21h
        jnc     CreatSuc
        lea     dx,CreaErr
        jmp     RunTimeMem

CreatSuc:
        mov     bx,ax
        mov     ds,cs:SouSeg
        mov     es,cs:DstSeg
        xor     si,si
        xor     di,di

NextString:
        mov     al,9
        stosb

        dw      cmCmpBp
BpSize  db      0       ;9
        jnb     FormDD

        mov     cx,bp

        jcxz    ToOk

        mov     ax,'bd'
        stosw
        mov     al,9
        stosb

StoLstLop:
        lodsb
        call    LeadZero
        call    TrnsByte
        cmp     al,9
        jb      NotHr
        mov     al,'h'
        stosb
NotHr:
        cmp     cx,1
        jz      NotZp
        mov     al,','
        stosb
NotZp:
        loop    StoLstLop
        mov     ax,0A0Dh
        stosw
ToOk:
        jmp     short EncodOk

FormDD:
        db      cmMovAx
Desc    dw      0       ;td
        stosw
        mov     al,9
        stosb

        mov     dl,0

NextDWord:

        db      cmMovCx
CxLoad  dw      0       ;4

LodsLoop:
        lodsw
        push    ax
        loop    LodsLoop

        lodsw

        xchg    al,ah

        call    LeadZero
        call    TrnsByte

        mov     al,ah
        call    TrnsByte


        db      cmMovCx
CxStore dw      0       ;bytes=(cx+1)*2

StoreDW:
        pop     ax
        xchg    al,ah
        call    TrnsByte
        mov     al,ah
        call    TrnsByte
        loop    StoreDW

        mov     al,'h'
        stosb

        db      cmMovAx
NBytes  dw      0       ;10

        sub     bp,ax
        cmp     bp,ax

        jb      ExitDwordStr

        inc     dl

        dw      cmCmpDl
BlPStr  db      0

        jz      ExitDWordStr

        mov     al,','
        stosb
        jmp     short NextDWord


ExitDWordStr:
        mov     ax,0A0Dh
        stosw

        mov     ax,8000h
        cmp     di,ax
        jb      NotDiO

        call    WriteBlck

        xor     di,di
NotDiO:
        jmp     NextString


EncodOk:
        call    WriteBlck

        mov     ah,3Eh
        int     21h

        lea     dx,Complet
        call    Prnt
        call    WriteLine

        call    FreMem

NormExit:
        mov     ax,4C00h
        int     21h

WriteBlck proc  near
        mov     cx,di
        jcxz    WriteBlckRet
        push    ds
        push    es
        pop     ds
        xor     dx,dx
        mov     ah,40h
        int     21h
        pop     ds
        jnc     WriteBlckRet
        pop     bx
        mov     ah,3Eh
        int     21h
        lea     dx,WritErr
        jmp     RunTimeMem
WriteBlckRet:
        ret
WriteBlck       endp


LeadZero proc   near
        cmp     al,0A0h
        jb      NotLeadZ
        push    ax
        mov     al,'0'
        stosb
        pop     ax
NotLeadZ:
        ret
LeadZero endp

TrnsByte proc   near
        push    ax
        mov     ah,al

        push    cx
        mov     cl,4
        shr     al,cl
        pop     cx

        call    TransHex

        stosb

        mov     al,ah

        and     al,1111b
        call    TransHex
        stosb
        pop     ax
        ret
TrnsByte endp

TransHex proc   near
        cmp     al,9
        jna     TrsHDigit
        add     al,7
TrsHDigit:
        add     al,'0'
        ret
TransHex endp

Prnt    proc    near
        push    ds
        call    SetDs
        mov     ah,9
        int     21h
        pop     ds
        ret
Prnt    endp


Close1  proc near
        push    ax
        mov     bx,si
        mov     ah,3Eh
        int     21h
        pop     ax
        ret
Close1  endp


PrintFName1     proc near
        push    ds
        mov     ds,cs:FnmSeg
        mov     dx,FName1Loc
        mov     cx,word ptr [ds:FName1Loc-2]
        mov     bx,2
        mov     ah,40h
        int     21h
        pop     ds
        ret
PrintFName1     endp

PrintFName2     proc near
        push    ds
        mov     ds,cs:FnmSeg
        mov     dx,FName2Loc
        mov     cx,word ptr [ds:FName2Loc-2]
        mov     bx,2
        mov     ah,40h
        int     21h
        pop     ds
        ret
PrintFName2     endp

Fre     proc    near
        mov     es,cx
        mov     ah,49h
        int     21h
        ret
Fre     endp

FreMem  proc    near
        call    SetDs
        mov     cx,SouSeg
        jcxz    SouEmpt
        call    Fre
SouEmpt:
        mov     cx,DstSeg
        jcxz    DstEmpt
        call    Fre
DstEmpt:
        mov     cx,FnmSeg
        jcxz    FnmEmpt
        call    Fre
FnmEmpt:
        mov     cx,DtaSeg
        jcxz    DtaEmpt
        call    Fre
DtaEmpt:
        ret

FreMem  endp

CloseF  proc    near
        ret
CloseF  endp

RunTimeFil      proc near
        call    CloseF
RunTimeMem      proc    near
        call    FreMem
RunTimeError    proc near
        call    SetDs
        mov     ah,9
        int     21h
        call    WriteLine
        mov     ax,4C01h
        int     21h
RunTimeError    endp
RunTimeMem      endp
RunTimeFil      endp

WriteLine proc  near
        mov     cx,75
WriteLineLop:
        mov     ah,2
        mov     dl,'-'
        int     21h
        loop    WriteLineLop
        ret
WriteLine       endp

SetDs   proc    near
        mov     ax,@Data
        mov     ds,ax
        ret
SetDs   endp

Correction      proc near
        push    ds
        push    cs
        pop     ds
        push    ax
        mov     ax,bp
        mov     NBytes,ax
        mov     BpSize,al
        shr     ax,1
        dec     ax
        mov     CxLoad,ax
        mov     CxStore,ax
        mov     Desc,cx
        mov     BlPStr,dl
        pop     ax
        pop     ds
        ret
Correction      endp

CheckDigit proc near
        cmp     al,'0'
        jb      NotDigit
        cmp     al,'9'
        ja      CmpLetter
        jmp     short ItsDigit
ItsLetterDigit:
        sub     al,7
ItsDigit:
        sub     al,'0'
        clc
        ret
CmpLetter:
        cmp     al,'F'
        ja      NotDigit
        cmp     al,'A'
        jnb     ItsLetterDigit
NotDigit:
        stc
        ret
CheckDigit endp

ShlAl4  proc    near
        push    cx
        mov     cl,4
        shl     al,cl
        pop     cx
        ret
ShlAl4  endp

ALoadByte proc  near
        lodsb
        call    CheckDigit
        jc      OptAOfr
        call    ShlAl4
        mov     ah,al
        lodsb
        call    CheckDigit
        jc      OptAOfr
        or      al,ah
        ret
OptAOfr:
        pop     dx
        lea     dx,NoDiA
        jmp     RunTimeMem
ALoadByte endp

end