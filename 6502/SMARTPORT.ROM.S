.FEATURE    labels_without_colons
.MACPACK    apple2
.DEFINE ASC scrcode
.DEFINE DFB .byte
.DEFINE ORG .org

LOC0        = $00
LOC1        = $01
KBD         = $C000
KBDSTRB     = $C010
MSLOT       = $7F8
ROMSOFF     = $CFFF
CMD         = $42
UNIT        = $43
ADDRL       = $44
ADDRH       = $45
BLOCKL      = $46
BLOCKH      = $47
SIZEL       = $46
SIZEH       = $47
DATA        = $CFF0
CTRL        = $CFF1
BANKCLR     = $CFFB
BANKSET     = $CFFC
SLOOP       = $FABA
SETSCR      = $FE93
SETKBD      = $FE89
SETTXT      = $FB39
HOME        = $FC58
COUT        = $FDED
BASIC       = $E000
BASCALC     = $FBC1
BASL        = $28

.macro SLOT_ROM SLOTNUM
    .scope
        ORG $C000 + $0100 * SLOTNUM

        CMP #$20
        CMP #$00
        CMP #$03
        CMP #$3C
        CLV
        BVC DENTRY
        .ASSERT .LOBYTE(*) = $0B, error

        DFB $01
        DFB $31
        DFB <PINIT
        DFB <PREAD
        DFB <PWRITE
        DFB <PSTATUS

IENTRY  RTS
OENTRY  RTS

DISK    CLC
        BCC SETUP
        SEC
SETUP   JSR DSETUP
        JMP COMMON

DENTRY  JSR DSETUP
        JMP BOOT

PINIT   LDX #$00
        RTS
PREAD   LDX #$27
        RTS
PWRITE  LDX #$27
        RTS
PSTATUS LDX #$00
        RTS

DSETUP  LDX #$C0 + SLOTNUM
        STX MSLOT
        STA ROMSOFF
        RTS

        .RES $0100 - $10 - <*

CONFIG  JSR DSETUP
        JMP CFG

        ASC "OlSc"
        DFB $00
        DFB $00
        DFB $00, $00
        DFB $D7
        .ASSERT .LOBYTE(*) = $FF, error

        DFB <DISK
    .endscope
.endmacro

SLOT_ROM 0
SLOT_ROM 1
SLOT_ROM 2
SLOT_ROM 3
SLOT_ROM 4
SLOT_ROM 5
SLOT_ROM 6
SLOT_ROM 7

ORG $C800
.RES $CF00 - *

BOOT    LDA #$01
        STA BANKSET
        JMP BOOT1

PDBOOT  JSR PRODOS
        LDA #$01
        STA BANKSET
        JMP BOOT2

COMMON  LDA #$01
        STA BANKSET
        JMP SWITCH

QUIT    STA BANKCLR
        RTS

RDBLOCK LDA #$02
        STA BANKSET
        JSR $C800
        LDA #$03
        STA BANKSET
        JSR $C800
        LDA #$01
        STA BANKSET
        RTS

CFG     LDA #$01
        STA BANKSET
        JSR CFGHDLR
        STA BANKCLR
        RTS

.INCLUDE "SMARTPORT.S"

ORG $CF00
        .RES $D000 - *

ORG $D000
        .RES $0800

ORG $D800
        .RES $0800

ORG $E000
        .RES $0800

ORG $E800
        .RES $0800

        .RES $F800 - *
