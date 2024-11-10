    ifndef src_messages_z80
    define src_messages_z80

    MACRO DEFINE_MESSAGE name, text
name_string:
    DB text, 0xFE
name_string_end:
    ENDM

; Prints a text centre-justified
;
    MACRO PRINT_CENTRED line, message
.start_pos: \
    EQU (line << 8) + 32 / 2 - (message_string_end - message_string) / 2

    LD HL, .start_pos
    LD DE, Font_1 - 0x100
    LD IX, message_string
    CALL Print_String_At

    LD HL, .start_pos
    CALL Get_Attr_Address
    LD (HL), Ink_White | Bright | Paper_Blue
    LD DE, HL
    INC DE
    LD BC, message_string_end - message_string - 2
    LDIR
    ENDM

    endif ; src_messages_z80
