; Advanced Hello World GB Program

include "hardware.inc"
include "header.inc"
include "ibmpc1.inc"

; Constants

MESSAGE EQUS "\"Hello World!!!\""

; Global Variables

section "Variables", WRAM0
wScrollDirectionX:: ds 1
wScrollDirectionY:: ds 1

section "VBlank", ROM0[$0040]
call advanceScroll
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

    ; Init sound
    ld a, AUDENA_ON 
    ld [rNR52], a ; turn on sound

    ; Turn LCD on
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

    ; Enable VBlank interrupt and set scroll direction to down right
    ld a, IEF_VBLANK
    ld [rIE], a
    xor a ; a = 0
    ld [wScrollDirectionX], a
    ld [wScrollDirectionY], a
    ei

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

; advanceScroll: Scrolls the screen continously
advanceScroll:
    ld a, [wScrollDirectionX]
    and a ; a == 0 ?
    ld a, [rSCX]
    jr nz, .scrollXLeft ; Scroll left if wScrollDirectionX is not 0

    ; otherwise, scroll right
    .scrollXRight
    dec a ; a = rSCX - 1 (Scroll to the right)
    cp (SCRN_VX - SCRN_X + 8 * (STRLEN(MESSAGE)))
    jr nc, .continueX ; Scroll only if the text did not reach the edge of the screen
    ; otherwise, switch scroll direction and beep
    ld a, 1
    ld [wScrollDirectionX], a
    call beep
    jr .scrollY

    ; Same as above, but scrolling to the left
    .scrollXLeft
    inc a
    jr nz, .continueX
    ld a, 0
    ld [wScrollDirectionX], a
    call beep
    jr .scrollY

    .continueX
    ld [rSCX], a ; Write the in/decremented value into the register

    .scrollY
    ld a, [wScrollDirectionY]
    and a
    ld a, [rSCY]
    jr nz, .scrollYUp

    ; Same as above, but scrolling in Y direction
    .scrollYDown
    sub 1
    cp (SCRN_VY - SCRN_Y + 8)
    jr nc, .continueY
    ld a, 1
    ld [wScrollDirectionY], a
    call beep
    ret

    .scrollYUp
    inc a
    jr nz, .continueY
    ld a, 0
    ld [wScrollDirectionY], a
    call beep
    ret

    .continueY
    ld [rSCY], a

    ret

; beep: Play a beep sound
beep::
    ld a, AUDLEN_DUTY_50 | 46 ; Pattern Duty & Length
    ld [rNR21], a
    ld a, $70 | AUDENV_DOWN | 7 ; Initial volume, envelope direction and envelope sweep number
    ld [rNR22], a
    ld a, $7f ; Frequency low
    ld [rNR23], a
    ld a, AUDHIGH_RESTART | AUDHIGH_LENGTH_ON | $06 ; Audio restart, enable sound length, frequency high
    ld [rNR24], a

    ret
