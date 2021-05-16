; header.inc
; Defines and a macro to create a valid ROM header
; By vypxl

; Include hardware.inc for all the constants
INCLUDE "hardware.inc"
    rev_Check_hardware_inc 3.0

; If all of these are already defined, don't do it again.

    IF !DEF(HEADER_INC)
HEADER_INC SET 1

rev_Check_header_inc : MACRO
;NOTE: REVISION NUMBER CHANGES MUST BE ADDED
;TO SECOND PARAMETER IN FOLLOWING LINE.
    IF  \1 > 1.0 ;PUT REVISION NUMBER HERE
        WARN    "Version \1 or later of 'header.inc' is required."
    ENDC
ENDM

; Insert a ROM header containing the specified data
; For a valid ROM, put this at $0104 in ROM0
; Arguments:
; - Title: String (max. 11 Characters for GBC compatibility, otherwise up to 15 characters. 16 characters are not allowed in this macro to be able to include the CGB flag)
; - CGB Flag: Either CART_COMPATIBLE_DMG, CART_COMPATIBLE_DMG_GBC or CART_COMPATIBLE_GBC
; - SGB Flag: Either CART_INDICATOR_SGB or CART_INDICATOR_GB
; - Cartridge Type: See Pandocs or hardware.inc for possible values, e.g. CART_ROM, CART_MBC1_RAM
; - ROM Size: See Pandocs or hardware.inc for possible values, e.g CART_ROM_32KB, CART_ROM_1024KB
; - SRAM Size: See Pandocs or hardware.inc for possible values, e.g CART_SRAM_NONE, CART_SRAM_128KB
; - Destination Code: Either CART_DEST_JAPANESE or CART_DEST_NON_JAPANESE
; Example Usage: ROM_HEADER "Example", CART_COMPATIBLE_DMG, CART_INDICATOR_GB, CART_ROM, CART_ROM_32KB, CART_SRAM_NONE, CART_DEST_NON_JAPANESE
ROM_HEADER : MACRO
_ROM_Header_Start:
    ; $0104: Nintendo Logo
    NINTENDO_LOGO
    IF STRLEN(\1) > 15
        FAIL "Fail (header.inc): Game title cannot be longer than 15 characters"
    ENDC
    IF STRLEN(\1) > 11
        WARN "Warning (header.inc): Game title has more than 11 characters."
    ENDC
    ; $0134: Game Title
    DB \1
    ; Fill the rest of the title and manufacturer code area with zeroes
    REPT 15 - STRLEN(\1)
        db 0
    ENDR
    ; $0143: CGB Flag
    DB \2
    ; $0144: Empty new licensee code (Publisher: None)
    DW $0000
    ; $0146: SGB Flag
    DB \3
    ; $0147: Cartridge Type
    DB \4
    ; $0148: ROM Size
    DB \5
    ; $0149: SRAM Size
    DB \6
    ; $014A: Destination Code
    DB \7
    ; $014B: Old License Code (Should be $33 to use new licensee code)
    DB $33
    ; $014C: Mask ROM Version number (handled by rgbfix)
    DB 0
    ; $014D: Header Checksum (handled by rgbfix)
    DB 0
    ; $014E: Global Checksum (handled by rgbfix)
    DW $0000
_ROM_Header_End:
    ; Check if the header has the correct size
    IF _ROM_Header_End - _ROM_Header_Start != $4c
        FAIL "Fail (header.inc) ROM Header is not 4Ch bytes long."
    ENDC
ENDM

    ENDC ; HEADER_INC
