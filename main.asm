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
    include "graphics/tile_metadata.z80"

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
    ;
    ; Draw the tail
    ;
    LD HL, (Snake_tail_x) ; H := Y position, L := X position
    CALL Get_Char_Address
    LD DE, Snake_1
    PUSH HL
    PUSH DE

    ; A := tail's direction
    CALL Segment_Queue_get_front
    LD A, (HL)
    ADD A, Tile_snake_tail_start

    POP DE
    POP HL
    CALL Print_Char

    LD HL, (Snake_tail_x) ; H := Y position, L := X position
    CALL Get_attr_address
    LD A, Snake_ink
    CALL Set_Ink

    ;
    ; Draw the body segments loop
    ; IX: The current X, Y position
    ; IY: The current index in the segment queue
    CALL Segment_Queue_get_front
    LD A, (HL) ; A := tail's direction
    LD IY, HL
    INC IY
    LD HL, (Snake_tail_x) ; H := Y position, L := X position
    CALL Advance
    LD IX, HL
Draw_Snake_Loop:
    ; Draw a body segment
    LD HL, IX
    LD A, Tile_snake_body_start
    PUSH IY
    CALL Draw_Snake_Tile
    POP IY

    ; Go to next X, Y position
    LD HL, IX
    LD A, (IY)
    CALL Advance
    LD IX, HL

    ; Advance position in segment queue
    LD HL, IY
    CALL Segment_Queue_get_next
    LD IY, HL

    ; Draw the head
    LD HL, IX
    LD A, (IY)
    CALL Draw_Snake_Tile

    RET

; Draws a tile (bitmap + attribute) of the snake.
;   H: Y position
;   L: X position
;   A: Tile number
Draw_Snake_Tile:
    PUSH HL
    PUSH AF
    CALL Get_Char_Address
    LD DE, Snake_1
    POP AF
    CALL Print_Char

    POP HL
    CALL Get_attr_address
    LD A, Snake_ink
    CALL Set_Ink
    RET

; The heart of the game loop. Updates the state of the snake, checks
; for collisions and updates the game's state accordingly.
Update_Snake:
    CALL Segment_Queue_get_back
    LD A, (HL) ; A := head's direction

    LD HL, (Snake_head_x) ; H := Y position, L := X position
    CALL Advance

    PUSH AF
    CALL Detect_Collision
    POP AF
    BIT 0, (IX)
    RET NZ

    ; Write new head position
    LD (Snake_head_x), HL

    PUSH HL
    CALL Segment_Queue_push_back
    POP HL
    PUSH HL
    CALL Get_attr_address
    PUSH AF
    LD A, Snake_ink
    CALL Set_Ink
    POP AF
    POP HL

    ; Draw the head in the new position
    PUSH AF
    CALL Get_Char_Address
    POP AF
    LD DE, Snake_1
    CALL Print_Char

    CALL Segment_Queue_get_length
    CP (Snake_length), (HL)

    JR Z, Done

Dont_grow:
    ; The snake does not need to grow anymore, so move the tail one slot in its
    ; current direction.
    CALL Segment_Queue_pop_front
    PUSH AF

    LD HL, (Snake_tail_x) ; H := Y position, L := X position
    PUSH HL
    CALL Get_attr_address
    LD A, Background_Ink
    CALL Set_Ink

    ; Write the new tail
    POP HL
    POP AF
    CALL Advance
    LD (Snake_tail_x), HL

    PUSH HL
    CALL Segment_Queue_get_front
    LD A, (HL) ; A := current direction
    POP HL
    ADD A, Tile_snake_tail_start
    CALL Draw_Snake_Tile
Done:
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
	CALL Initialise_Sprites
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
