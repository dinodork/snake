    include "src/snake.asm"

Play_Intro:
snake1 Snake Ink_Yellow, 2, 13, 2, 13, Game_tile_facing_right, 3

  ; Draw the head
  LD IX, snake1
  LD HL, (IX + Snake.head_x)
  LD A, Char_snake_head_start
  ADD A, (IX + Snake.head_direction)
  LD B, Ink_White
  CALL Print_Char_With_Ink

Effects_Update_Snake:
  ; to do: clear tongue

  LD IX, snake1

  ; Write which way the head is going in the game state
  LD HL, (IX + Snake.head_x)
  LD A, (IX + Snake.head_direction)
  CALL Game_get_address
  LD (HL), A

  ; Draw body where the head is
  LD HL, (IX + Snake.head_x)
  CALL Effects_draw_snake_body_segment

  ; Advance the head
  LD HL, (IX + Snake.head_x)
  LD A, (IX + Snake.head_direction)
  CALL Get_Next_Head_Position
  LD (IX + Snake.head_x), HL

  ; Draw the head
  LD A, Char_snake_head_start
  ADD A, (IX + Snake.head_direction)
  LD B, Ink_White
  CALL Print_Char_With_Ink

  ; Draw the tongue
  LD A, (IX + Snake.head_direction)
  LD HL, (IX + Snake.head_x)
  PUSH AF
  CALL Get_Next_Head_Position
  PUSH HL
  CALL Game_get_address
  LD A, (HL)
  CP A, Game_tile_empty
  POP HL
  JR NZ, .dont_draw_tongue
  POP AF
  ADD A, Char_snake_tongue
  LD B, Ink_Red
  CALL Print_Char_With_Ink

.dont_draw_tongue

  ; Handle growth
  LD A, (IX + Snake.growth)

  CP A, 0
  JR Z, .advance_tail ; The snake doesn't need to grow; advance and draw the tail

  CP A, 1
  DEC A
  LD (IX + Snake.growth), A
  JR Z, .draw_tail ; The snake doesn't just finished growing; draw the tail but
                   ; don't advance it

  ; The snake is growing, we're done
  RET

.advance_tail
  ; Clear the old tile in the game state
  LD HL, (IX + Snake.tail_x)
  CALL Game_get_address
  LD A, (HL) ; Get the exit direction in the old tile
  LD (HL), Game_tile_empty
  LD HL, (IX + Snake.tail_x)

  ; Remove the old tail graphics
  PUSH HL
  PUSH AF
  CALL Graphics_Clear_Box
  POP AF
  POP HL

  CALL Get_Next_Head_Position
  LD (IX + Snake.tail_x), HL

.draw_tail:
  CALL Effects_Draw_Tail

  RET

; Draws a body segment (i.e. not tail, tongue or head)
; IX: Address of Snake struct
; H: Current body segment Y position
; L: Current body segment X position
Effects_draw_snake_body_segment:
  PUSH HL
  CALL Game_get_address
  LD A, (HL)
  LD B, A

    ; A := B * 4
  LD A, 0
.loop:
  ADD A, 4
  DJNZ .loop
  LD C, A

  LD A, (Game_next_direction)
  ADD A, C

  ; Index into the lookup table, it's one-dimensional at this point.
  LD D, 0
  LD E, A
  LD HL, Body_segments
  ADD HL, DE

  LD A, (HL)

  POP HL

  PUSH AF
  LD A, H
  XOR L
  AND A, 1
  LD B, A
  POP AF
  ADD A, B
  LD B, (IX + Snake.colour)
  CALL Print_Char_With_Ink

  RET

; Draws the snake's tail. Takes no arguments.
; The snake wags its tail as it slithers across the screen, alternating between
; left and right. The frames are organised so that even frames point left and odd
; frames right. We bake the wagging into the formula for indexing into the
; frames, arriving at:
;
;     index := direction * 2 + ((Y_pos xor X_pos) mod 2)
;
; We choose xor because it changes every time either operand changes.
;
; IX: Address of Snake struct
Effects_Draw_Tail:
  ; Get the current tile's direction and push it on the stack.
  LD HL, (IX + Snake.tail_x)
  LD A, H
  XOR L
  AND A, 1
  LD B, A

  CALL Game_get_address
  CALL Game_get_direction

  PUSH AF
  LD HL, (IX + Snake.tail_x)
  CALL Get_Char_Address
  POP AF

  RLA ; A := A * 2
  ADD A, B
  ADD A, Char_snake_tail_start

  LD HL, (IX + Snake.tail_x) ; As above
  LD B, (IX + Snake.colour)
  CALL Print_Char_With_Ink

  RET
