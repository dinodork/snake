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
    include "game.z80"
    include "graphics/tile_metadata.z80"
    include "graphics.z80"

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
Advance:
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

Game_State_Pregame: EQU 0
Game_State_Ongoing: EQU 1
Game_State_Game_Over: EQU 1
Game_State:
    DEFS 1

; Checks for collision and updates game state accordingly.
;   H Snake head Y position
;   L Snake head X position
; Returns game state in IX

Detect_Collision:
    LD A, L
    CP 31
    JR Z, Detect_Collision_Happened
    LD IX, Game_State
    RET
Detect_Collision_Happened:
    LD (IX), Game_State_Game_Over
    RET

; Draw the snake in its entirety. This is only done in few occasions, mostly
; when drawing the screen at the start of the game.
Draw_Snake:
    CALL Draw_Tail
    LD HL, (Game_snake_tail_x) ; H := Y position, L := X position
    CALL Advance

Draw_Snake_Loop:
    LD A, Tile_snake_body_start
    PUSH HL
    CALL Draw_Snake_Tile
    POP HL

    PUSH HL
    CALL Game_get_address
    CALL Game_get_direction
    POP HL
    CALL Advance
    LD BC, (Game_snake_head_x)
    LD DE, HL
    SBC DE, BC

    JR NZ, Draw_Snake_Loop

    ADD A, Tile_snake_head_start
    CALL Draw_Snake_Tile

; The heart of the game loop. Updates the state of the snake, checks
; for collisions and updates the game's state accordingly.
Update_Snake:

    LD HL, (Game_snake_head_x) ; H := Y position, L := X position
    CALL Game_get_address
    CALL Game_get_direction ; A := head's direction
    LD HL, (Game_snake_head_x) ; H := Y position, L := X position
    CALL Advance

    PUSH AF
    CALL Detect_Collision
    POP AF
    BIT 0, (IX)
    RET NZ

    ; Write new head position
    LD (Game_snake_head_x), HL
    CALL Game_get_address
    LD (HL), A

    LD HL, (Game_snake_target_length)
    LD DE, (Game_snake_length)
    SBC HL, DE
    JR NZ, Render_snake

    ; The snake doesn't need to grow anymore, so move the tail one slot in its
    ; current direction.

    LD HL, (Game_snake_tail_x)
    CALL Game_get_address
    CALL Game_get_direction
    PUSH AF
    LD (HL), Game_tile_empty

    LD HL, (Game_snake_tail_x)
    CALL Get_attr_address
    LD A, 0
    CALL Set_Ink

    LD HL, (Game_snake_tail_x)
    POP AF
    CALL Advance
    LD (Game_snake_tail_x), HL



Render_snake:
    CALL Draw_Tail
    CALL Draw_Head


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

    CALL Update_Snake
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
	CALL Game_initialise
    CALL Draw_Snake


    LD IX, Game_State
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
    LD IX, Game_State
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
