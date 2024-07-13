    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

NEX:    equ 0   ;  1=Create nex file, 0=create sna file

    IF NEX == 0
        ;DEVICE ZXSPECTRUM128
        DEVICE ZXSPECTRUM48
        ;DEVICE NOSLOT64K
    ELSE
        DEVICE ZXSPECTRUMNEXT
    ENDIF

    ORG 0x4000
    defs 0x6000 - $    ; move after screen area
screen_top: defb    0   ; WPMEMx

    include "lib/attribute.z80"
    include "canvas.z80"
    include "controls.z80"
    include "screen.z80"
    include "sprite.z80"

    include "build/graphics/font_npm.asm"
    include "build/graphics/graphics_snake.asm"

 defs 0x8000 - $
 ORG $8000

Stack_Top:		EQU 0xFFF0
			LD SP, Stack_Top

Scene_Draw:
    RET

; H Snake head Y position
; L Snake head X position
; A Snake head direction description, see comment above Snake_segment_queue.
Move_snake:
    AND 0x0F
    CP Facing_right
    JP NZ, Move_snake_2
    INC L
    RET
Move_snake_2:
    RET

Update_snake:
    LD HL, (Snake_head_x) ; H := Y position, L := X position
    LD A, (Current_Direction)
    CALL Move_snake

    ; Write new head position
    LD (Snake_head_x), HL

    ; Draw the head in the new position
    PUSH AF
    CALL Get_Char_Address
    POP AF
    LD DE, Snake_1
    CALL Print_Char

    RET

Interrupt:
    DI
    EXX
    EX AF, AF'

    CALL Update_snake

    EX AF, AF'
    EXX
    EI
    RET

main:
	DI
	LD SP, Stack_Top
	LD A, Paper_Black | Ink_White | Bright
	CALL Clear_Screen

	LD IX, Text_Scores
    LD DE, Npm_1 - 0x100
	CALL Print_Strings

    CALL Scene_Draw

	CALL Initialise_Sprites
	LD HL, Interrupt
	LD IX, 0xFFF0
	LD (IX + 04h), 0xC3	   ; Opcode for JP
	LD (IX + 05h), L
	LD (IX + 06h), H
	LD (IX + 0Fh), 0x18	    ; Opcode for JR; this will do JR to FFF4h
	LD A, 0x39
	LD I, A
	IM 2
	EI

Loop:
	HALT
	CALL Handle_Controls
	JP Loop

stack_top:
    defw 0  ; WPMEM, 2

    IF NEX == 0
        SAVESNA "snake.sna", main
    ELSE
        SAVENEX OPEN "snake.nex", main, stack_top
        SAVENEX CORE 3, 1, 5
        SAVENEX CFG 7   ; Border colour
        SAVENEX AUTO
        SAVENEX CLOSE
    ENDIF
