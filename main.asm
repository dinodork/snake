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

; Updates the X, Y position of the head according to the direction it's facing.
; H Snake head Y position
; L Snake head X position
; A Snake head direction description, see comment above Snake_segment_queue.
Advance_head:
    AND 0x0F
    CP Facing_right
    JP NZ, Advance_head_2
    INC L
    RET
Advance_head_2:
    CP Facing_left
    JP NZ, Advance_head_3
    DEC L
    RET
Advance_head_3:
    CP Facing_up
    JP NZ, Advance_head_4
    DEC H
    RET
Advance_head_4:
    CP Facing_down
    RET NZ
    INC H
    RET

Game_Over:
    DEFS 1

; H Snake head Y position
; L Snake head X position
Detect_Collision:
    LD A, L
    CP 31
    JR Z, Detect_Collision_Happened
    RET
Detect_Collision_Happened:
    LD IX, Game_Over
    LD (IX), 1
    RET

Update_snake:
    LD HL, (Snake_head_x) ; H := Y position, L := X position
    LD A, (Current_Direction)
    CALL Advance_head

    PUSH AF
    CALL Detect_Collision
    POP AF
    BIT 0, (IX)
    RET NZ

    ; Write new head position
    LD (Snake_head_x), HL

    PUSH HL
    CALL Get_attr_address
    LD (HL), Play_area_attribute | Snake_ink
    POP HL

    ; Draw the head in the new position
    PUSH AF
    CALL Get_Char_Address
    POP AF
    LD DE, Snake_1
    CALL Print_Char

    RET

Delay:  EQU 10 ; TODO - make sure to initialise to 0
Delay_timer:
    DEFS 1

Interrupt:
    DI
    EXX
    EX AF, AF'

    LD A, (Delay_timer)
    INC A
    CP Delay
    JR NZ, Interrupt_done

    CALL Update_snake
    LD A, 0
Interrupt_done:
    LD (Delay_timer), A

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

    CALL Draw_Scene

	CALL Initialise_Sprites

    LD IX, Game_Over
    LD (IX), 0

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
    LD IX, Game_Over
    LD A, (IX)
    CP 1
    JR Z, Handle_Game_Over
    JP Loop

Handle_Game_Over:
    DI
    LD DE, Npm_1 - 0x100
    LD IX, Game_over_text
	LD H, 10
	LD L, 10
	CALL Print_String_At
    HALT

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
