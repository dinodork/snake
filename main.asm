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
    include "game_state.z80"
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
Get_Next_Position:
    AND 0x0F
    CP Game_tile_facing_right
    JP NZ, Get_Next_Position_head_2
    INC L
    RET
Get_Next_Position_head_2:
    CP Game_tile_facing_left
    JP NZ, Get_Next_Position_head_3
    DEC L
    RET
Get_Next_Position_head_3:
    CP Game_tile_facing_up
    JP NZ, Get_Next_Position_head_4
    DEC H
    RET
Get_Next_Position_head_4:
    CP Game_tile_facing_down
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
; Returns address of game state in IX

Detect_Collision:
    LD IX, Game_State
    LD A, L
    CP 31
    JR Z, Detect_Collision_Happened

    CALL Game_get_address
    CALL Game_get_direction
    CP A, Game_tile_empty
    JR NZ, Detect_Collision_Happened

    RET
Detect_Collision_Happened:
    LD (IX), Game_State_Game_Over
    RET

; Draw the snake in its entirety. This is only done in few occasions, mostly
; when drawing the screen at the start of the game.
Draw_Snake:
    CALL Draw_Tail
    LD HL, (Game_snake_tail_x) ; H := Y position, L := X position
    LD DE, HL
    CALL Get_Next_Position

Draw_Snake_Loop:
    PUSH HL
    CALL Draw_snake_body_segment
    POP HL

    PUSH HL
    CALL Game_get_address
    CALL Game_get_direction
    POP HL
    CALL Get_Next_Position
    LD BC, (Game_snake_head_x)
    LD DE, HL
    SBC DE, BC

    JR NZ, Draw_Snake_Loop

    ADD A, Tile_snake_head_start
    CALL Draw_Snake_Tile
    RET

; The heart of the game loop. Updates the state of the snake, checks
; for collisions and updates the game's state accordingly.
; Roughly, the procedure is this:
; - Stow away the current position of the head, this will be the new neck
; - Stow away the direction stored in the head position. This is the same as
;   the direction in the tile before it. It may change during this function, if
;   the player requested a turn. The new direction is in this case in
;   `Game_next_direction`.
; - Advance the head in the direction _`Game_next_direction`_. Before writing
;   it back, though, check for collisions and return early.
; - Check if the snake is currently growing. If not, move the tail one step
;   along its direction.

; Throughout this function, you will notice the construction
; `LD HL, (Game_snake_head|tail_x)`. This will actually load the X value into
; L and the Y value into H, courtesy of little-endian, since the Y value
; follows the X value in memory.
Update_Snake:

    LD HL, (Game_snake_head_x) ; H := Y position, L := X position
    PUSH HL

    LD A, (Game_next_direction)
    LD HL, (Game_snake_head_x) ; H := Y position, L := X position
    CALL Get_Next_Position

    PUSH AF
    PUSH HL
    CALL Detect_Collision
    POP HL
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
    JR NZ, Grow_Snake

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
    CALL Get_Next_Position
    LD (Game_snake_tail_x), HL
    JP Render_snake

Grow_Snake:
    INC DE
    LD (Game_snake_length), DE
Render_snake:
    CALL Draw_Tail
    POP HL
    PUSH HL
    CALL Draw_snake_body_segment
    POP HL
    CALL Game_get_address
    LD A, (Game_next_direction)
    LD (HL), A
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
