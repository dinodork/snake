  SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

NEX:  equ 0   ;  1=Create nex file, 0=create sna file

  IF NEX == 0
    ;DEVICE ZXSPECTRUM128
    DEVICE ZXSPECTRUM48
    ;DEVICE NOSLOT64K
  ELSE
      DEVICE ZXSPECTRUMNEXT
  ENDIF

  ORG 0x4000
  defs 0x6000 - $  ; move after screen area
screen_top: defb  0   ; WPMEMx

  include "lib/attribute.z80"
  include "lib/graphics.z80"
  include "lib/format.z80"
  include "canvas.z80"
  include "controls.z80"
  include "screen.z80"
  include "food.z80"
  include "game_state.z80"
  include "graphics/tile_metadata.z80"
  include "graphics.z80"
  include "src/keyboard.z80"
  include "messages.z80"
  include "message_strings.z80"
  include "lib/sound.z80"

  include "build/graphics/font.asm"
  include "build/graphics/frames.asm"


 defs 0x8000 - $
 ORG $8000

Stack_Top:  	EQU 0xFFF0
  LD SP, Stack_Top

; Updates the X, Y position of the head according to the direction it's facing.
;   H Snake head Y position
;   L Snake head X position
;   A Snake head direction, see comment above Snake_segment_queue.
; Returns:
;   H new Y position
;   L new X position
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

; Draw the snake in its entirety. This is only done in few occasions, mostly
; when drawing the screen at the start of the game.
Draw_Snake:
  CALL Draw_Tail
  LD HL, (Game_snake_tail_x) ; H := Y position, L := X position
  PUSH HL
  CALL Game_get_address
  LD A, (HL)
  POP HL
  CALL Get_Next_Position

Draw_Snake_Loop:
  PUSH HL
  CALL Game_get_address
  LD A, (HL)
  POP HL
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
  LD B, Snake_head_ink
  CALL Draw_Frame_With_Ink

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
  CALL Clear_tongue
  LD HL, (Game_snake_head_x) ; H := Y position, L := X position
  LD A, (Game_next_direction)
  LD DE, HL ; We're going to keep the old position in DE in this routine.
  CALL Get_Next_Position
  LD B, A ; Save A in B instead of the stack so we can do an early return.

  PUSH HL
  PUSH DE
  PUSH BC
  CALL Detect_Collision
  POP BC
  POP DE
  POP HL
  LD A, (IX)
  CP Game_Phase_Game_Over
  RET Z

  LD A, B

  ; Write new head position
  LD (Game_snake_head_x), HL
  PUSH DE
  CALL Game_get_address
  LD (HL), A

  LD HL, (Game_snake_target_length)
  LD DE, (Game_snake_length)
  SBC HL, DE
  JR NZ, Update_Snake_Grow

  ; The snake doesn't need to grow anymore, so move the tail one slot in its
  ; current direction.

  LD HL, (Game_snake_tail_x)
  CALL Game_get_address
  CALL Game_get_direction
  PUSH AF
  LD (HL), Game_tile_empty

  LD HL, (Game_snake_tail_x)
  CALL Get_Attr_Address
  ; Don't bother clearing the graphics, just hide it
  LD A, Invisible_ink
  CALL Set_Ink

  LD HL, (Game_snake_tail_x)
  POP AF
  CALL Get_Next_Position
  LD (Game_snake_tail_x), HL
  CALL Draw_Tail
  JP Update_Snake_Render

Update_Snake_Grow:
  INC DE
  LD (Game_snake_length), DE
Update_Snake_Render:
  POP DE
  LD HL, DE
  PUSH HL
  CALL Draw_snake_body_segment
  POP HL
  CALL Game_get_address
  LD A, (Game_next_direction)
  LD (HL), A
  CALL Draw_Head

  ; Play sound if snake just ate
  LD IX, Game_Phase
  LD A, (IX)
  LD (IX), Game_Phase_Running

  CP A, Game_Phase_Eating
  RET NZ

  LD A, 10
  LD B, 20
  LD C, 0xFF
  LD D, 0xFF
  CALL SoundFX_A_Init
  CALL SoundFX_A_Main

  RET

Initial_interrupt_target_count:  EQU 10

Interrupt_target_count: DEFS 1, Initial_interrupt_target_count
; Incremented for every interrupt. When equal to Interrupt_target_count, the
; interrupt action is performed. In-game, this is Update_Snake; But different
; phases of the game swap out the interrupt action.
Interrupt_count: DEFS 1

; Set to 1 by the Interrupt handler when Interrupt_count reaches
; Interrupt_target_count.
Interupt_target_count_reached: DEFS 1

Interrupt:
  DI
  EXX
  EX AF, AF'

  LD A, (Interrupt_target_count)
  LD B, A
  LD A, (Interrupt_count)

  INC A
  CP B
  JR NZ, Interrupt_done

SM_Interrupt_handler:
  CALL Update_Snake
  LD A, 0
Interrupt_done:
  LD (Interrupt_count), A

  EX AF, AF'
  EXX
  EI
  RET

Update_Delay_Target_Reached:
  LD A, 1
  LD (Interupt_target_count_reached), A
  RET

main:
Main_Menu:
; Modify the code indside the interrupt handler!
; The call to Update_Snake now gets replaced with a different routine
; that simply writes a 1 to Delay_target_reached after `Delay_target`
; interrupts have occured.
  DI

  LD SP, Stack_Top
  LD A, Paper_Black | Ink_White | Bright
  CALL Clear_Screen

  PRINT_CENTRED 5, Title_Message
  PRINT_CENTRED 7, Keys_Message
  PRINT_CENTRED 10, Press_Key_To_Play_Message

  LD HL, 21 << 8
  LD IX, Copyright_String1
  LD DE, Font_1 - 0x100
  CALL Print_String_At

  LD HL, 22 << 8
  LD IX, Copyright_String2
  CALL Print_String_At

  LD HL, 23 << 8
  LD IX, Copyright_String3
  CALL Print_String_At

  LD A, 50
  LD (Interrupt_target_count), A
  LD HL, Update_Delay_Target_Reached
  LD IX, SM_Interrupt_handler
  LD (IX + 1), L
  LD (IX + 2), H
  EI

; Wait for key press, then restart the game
  CALL Wait_For_Any_Key

; Restore the interrupt action
  DI
  LD A, 0
  LD (Interrupt_count), A
  LD A, Initial_interrupt_target_count
  LD (Interrupt_target_count), A
  LD HL, Update_Snake
  LD IX, SM_Interrupt_handler
  LD (IX + 1), L
  LD (IX + 2), H
  EI

  JP game
game:
  DI
  LD SP, Stack_Top
  LD A, Paper_Black | Ink_White | Bright
  CALL Clear_Screen

  LD HL, 0
  LD (Game_Score), HL

  CALL Draw_Score
  CALL Draw_Scene
  CALL Game_initialise
  CALL Draw_Snake
  CALL Place_Food

  LD IX, Game_Phase
  LD (IX), Game_Phase_Running

  LD HL, Interrupt
  LD IX, 0xFFF0
  LD (IX + 04h), 0xC3	   ; Opcode for JP
  LD (IX + 05h), L
  LD (IX + 06h), H
  LD (IX + 0Fh), 0x18	  ; Opcode for JR; this will do JR to FFF4h
  LD A, 0x39
  LD I, A
  IM 2
  EI

Loop:
  HALT
  CALL Handle_Controls
  LD IX, Game_Phase
  LD A, (IX)
  CP Game_Phase_Game_Over
  JR Z, Handle_Game_Over
  JP Loop

Handle_Game_Over:

; X eyes
  LD HL, (Game_snake_head_x) ; H := Y position, L := X position
  CALL Game_get_address
  CALL Game_get_direction
  ADD 64 - 32
  CALL Draw_Head_Frame

; Modify the code indside the interrupt handler!
; The call to Update_Snake now gets replaced with a different routine
; that simply writes a 1 to Delay_target_reached after `Delay_target`
; interrupts have occured.
  DI
  LD A, 50
  LD (Interrupt_target_count), A
  LD HL, Update_Delay_Target_Reached
  LD IX, SM_Interrupt_handler
  LD (IX + 1), L
  LD (IX + 2), H
  EI

  CALL Pause_One_Second

  PRINT_CENTRED 10, Game_Over_Message

  CALL Pause_One_Second

  PRINT_CENTRED 12, Press_Key_To_Play_Again_Message

; Wait for key press, then restart the game
  CALL Wait_For_Any_Key

; Restore the interrupt action
  DI
  LD A, 0
  LD (Interrupt_count), A
  LD A, Initial_interrupt_target_count
  LD (Interrupt_target_count), A
  LD HL, Update_Snake
  LD IX, SM_Interrupt_handler
  LD (IX + 1), L
  LD (IX + 2), H
  EI

  JP game

  LD B, 3
Death_sequence_flash_loop:
  PUSH BC

  ; Clear snake
  LD A, Ink_Red
  LD (Canvas_current_snake_ink), A
  CALL Draw_Snake

  CALL Pause_One_Second

  ; Draw snake
  LD A, Snake_body_ink
  LD (Canvas_current_snake_ink), A
  CALL Draw_Snake

  CALL Pause_One_Second

  POP BC

  DJNZ Death_sequence_flash_loop

  LD H, 9   ; Y
  LD L, 9   ; X
  LD B, 3   ; Height
  LD C, 11  ; Width
  CALL Clear_Box

  LD DE, Font_1 - 0x100
;  LD IX, Game_over_text
  LD H, 10  ; Y
  LD L, 10  ; X
  CALL Print_String_With_Attribute_At

  ; Hang the machine
  DI
  HALT

Pause_One_Second:
  HALT
  LD A, (Interupt_target_count_reached)
  CP 1
  JP NZ, Pause_One_Second

  LD A, 0
  LD (Interupt_target_count_reached), A

  RET

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
