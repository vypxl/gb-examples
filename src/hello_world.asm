; Advanced Hello World GB Program

include "hardware.inc"
include "header.inc"
include "ibmpc1.inc"

; Constants

MESSAGE EQUS "\"Hello World!!!\""

section "VBlank", ROM0[$0040]
reti

section "STAT", ROM0[$0048]
reti

section "Timer", ROM0[$0050]
reti

section "Serial", ROM0[$0058]
reti

section "Joypad", ROM0[$0060]
reti

section "start", ROM0[$0100]
nop
jp begin

; ROM Header
    ROM_HEADER "Hello World", CART_COMPATIBLE_DMG, CART_INDICATOR_GB, CART_ROM, CART_ROM_32KB, CART_SRAM_NONE, CART_DEST_NON_JAPANESE

TileData:
    chr_IBMPC1 1, 8
TileDataEnd:

begin:
    di ; Disable interrupts for setup
    ld sp, $ffff ; Set the stack pointer to the top of HRAM
    call turnLCDoff

    ; Load font tile data into vram
    ld hl, _VRAM9000
    ld de, TileData
    ld bc, TileDataEnd - TileData

    .copyFont
        ld a, [de]
        ld [hl+], a
        ld [hl+], a ; We write this a second time, because ibmpc1.inc contains a monochrome font (only 1 bit per pixel)
        inc de
        dec bc
        ld a, b
        or c ; corresponds to `b or c` (see previous instruction), check if both are zero
        jr nz, .copyFont ; if at least one bit is set, z is reset and we still have bytes to copy

    ; Clear Screen by setting all tiles to ASCII Space ($20)
    ld b, " "
    ld de, SCRN_VX_B * SCRN_VY_B * 2 ; Size of Screen Data
    ld hl, _SCRN0
    call memset

    ; Display message
    ld hl, _SCRN0
    ld de, Message
    call strcpy

    ; Init display registers
    ld a, %11100100 ; All shades of gray
    ld [rBGP], a
    xor a ; a = 0
    ld [rSCY], a ; scrollX = 0
    ld [rSCX], a ; scrollY = 0

    ; Disable sound
    ld a, AUDENA_OFF 
    ld [rNR52], a

    ; Turn LCD on
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

    .loop ; loop for eternity
        halt ; go into low power mode until an interrupt occurs
        jr .loop

Message:
    db MESSAGE, 0 ; Zero-terminate the message string

; Functions

; turnLCDoff: Disable LCD to freely write to VRAM and the others
turnLCDoff::
    ; Check if the LCD is already off
    ld a, [rLCDC]
    rlca ; Put bit 7 of a into carry
    ret nc ; Return if LCD is turned off already

    ; Wait for VBlank
    .wait
        ld a, [rLY]
        cp SCRN_Y ; Check if in VBlank
        jr c, .wait

    ld a, [rLCDC]
    res 7, a ; Turn off LCD by resetting bit 7
    ld [rLCDC], a ; Write back to rLCDC

    ret

; memset: Set memory region to value
; For VRAM, only call this function when VRAM is accessible!
; - b: value to set everything to
; - de: byte count
; - hl: destination address
memset::
    ld a, b
    ld [hl+], a
    dec de
    ld a, e
    or d ; d || e
    jr nz, memset
    ret

; strcpy: Copy a null-terminated string to some address
; For VRAM, only call this function when VRAM is accessible
; - de: Source Address
; - hl: Destination address
strcpy::
    ld a, [de]
    and a ; Check if a (the byte to copy) is zero
    ret z ; Stop upon reaching a NULL Byte
    ld [hl+], a
    inc de
    jr strcpy
