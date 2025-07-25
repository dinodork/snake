    ifndef lib_attribute_z80
    define lib_attribute_z80

Ink_Black:     EQU 0x00
Ink_Blue:      EQU 0x01
Ink_Red:       EQU 0x02
Ink_Magenta:   EQU 0x03
Ink_Green:     EQU 0x04
Ink_Cyan:      EQU 0x05
Ink_Yellow:    EQU 0x06
Ink_White:     EQU 0x07
Paper_Black:   EQU 0x00
Paper_Blue:    EQU 0x08
Paper_Red:     EQU 0x10
Paper_Magenta: EQU 0x18
Paper_Green:   EQU 0x20
Paper_Cyan:    EQU 0x28
Paper_Yellow:  EQU 0x30
Paper_White:   EQU 0x38

Bright:        EQU 0x40
Flash:         EQU 0x80

Attribute_box_columns: EQU 32
Attribute_box_rows:    EQU 24

; Returns attribute address
; H = Y character position
; L = X character position
; Returns address in HL

    MACRO ClearCarryFlag
        SCF
        CCF
    ENDM

    MACRO HL_X_32
        ClearCarryFlag
        DUP 5
        RL HL
        EDUP
    ENDM

    MACRO X_32 register
        ClearCarryFlag
        DUP 5
        RL register
        EDUP
    ENDM


; Returns the address in the attribute file.
;   H = Y character position
;   L = X character position
; Clobbers: DE
Get_Attr_Address:
    ; Save the X value in DE
    LD E, L
    LD D, 0

    ; Make HL contain only the Y value
    LD L, H
    LD H, 0

    HL_X_32

    ; Add the X value back
    ADD HL, DE

    ; Add this to the start of attribute RAM
    LD DE, Start_Of_Attribute_Ram
    ADD HL, DE

    RET

; Sets a new ink value, leaving other attributes intact.
;   A  = New ink value
;   HL = Address of attribute byte
; Clobbers: A, C
Set_Ink:
    LD C, A
    LD A, (HL)
    AND A, ~Ink_White
    OR A, C
    LD (HL), A
    RET

    endif ; lib_attribute_z80
