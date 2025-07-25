    ifndef graphics_z80
    define graphics_z80

    include "graphics/tile_metadata.asm"
    include "src/food.asm"

; The game's graphics is all in this file

Graphics_play_area_size: EQU (32 - 2) * (24 - 3)

; Lookup table for body segments. The tile to choose for a body segment depends
; upon:
; 1) The previous tile's direction
; 2) The current tile's direction
; To get the correct tile index, take the previous tile's direction and use
; that value as the row, then use the current tile's direction and use that
; as the column. Some combinations make no sense, e.g. Up+Down, and these
; slots contain a -1.
Body_segments:
; Turning -> Up Down Left Right   While going
    BYTE     12,  -1,  16,   20 ; Up
    BYTE     -1,  12,  22,   18 ; Down
    BYTE     18,  20,  14,   -1 ; Left
    BYTE     22,  16,  -1,   14 ; Right

; Prints a single character and sets the ink value.
;   H: Y position
;   L: X position
;   A: Character number
;   B: Ink
Print_Char_With_Ink:
  PUSH AF
  PUSH HL

    ; We set the attribute of the tile first, as this is passed in B, which gets
    ; clobbered by Get_Char_Address
  CALL Get_Attr_Address
  LD A, B
  CALL Set_Ink
  POP HL

  CALL Get_Char_Address
  LD DE, Tiles_1
  POP AF
  CALL Print_Char

  RET

; Draws food's stalk at the position.
;   A: Food index
;   H: Y character position
;   L: X character position
; Clobbers:
;   DE, HL, IY
Draw_Stalk:
  PUSH HL

  PUSH AF
  CALL Get_Char_Address
  POP AF

  RL A ; x2
  ADD A, Char_apple_stalk
  LD DE, Tiles_1
  CALL Print_Char

  POP HL

  CALL Get_Attr_Address
  LD A, Apple_stalk_ink
  CALL Set_Ink

  RET

; Draws food
;   A: Food index
;   H: Y character position
;   L: X character position
; Clobbers:
;   A, B, DE, HL, IY
Draw_Food:
  PUSH HL

  PUSH AF
  CALL Get_Char_Address
  POP AF

  PUSH AF
  RL A ; x2
  ADD A, Char_apple
  LD DE, Tiles_1
  CALL Print_Char
  POP AF

  POP HL

  CALL Get_Attr_Address
  LD IY, Food_inks
  LD (SM_Food_ink_offset + 2), A
SM_Food_ink_offset:
  LD A, (IY + 2)
  CALL Set_Ink

  RET

; Draws the head
Draw_Head:
  LD HL, (Game_snake_head_x) ; H := Y position, L := X position
  CALL Game_get_address
  CALL Game_get_direction

; Draws a frame in the head's ink.
;   A: Character of the head.
Print_Head_Char:
  PUSH AF
  LD HL, (Game_snake_head_x)
  CALL Get_Char_Address
  POP AF

  PUSH AF
    ; We would normally add an offset to the first head frame here, but since
    ; it starts on position 0, we don't need to.

  LD HL, (Game_snake_head_x) ; H := Y position, L := X position

  LD B, Snake_head_ink
  CALL Print_Char_With_Ink

  POP AF

Update_And_Draw_Tongue:
  ; Advance the tongue position
  LD HL, (Game_snake_head_x) ; H := Y position, L := X position
  CALL Game_get_address
  LD A, (HL)
  LD HL, (Game_snake_head_x)
  CALL Get_Next_Head_Position ; HL is now the position in front of the head.
  LD (Game_snake_tounge_x), HL

  LD BC, HL

  ; Return if there is anything in this game tile.
  CALL Game_get_address
  LD B, A
  LD A, (HL)

  ; Exit if there's something in the way of the tongue.
  CP A, Game_tile_empty
  RET NZ

  ; Actually draw the tongue

  LD A, B
  LD HL, (Game_snake_head_x) ; H := Y position, L := X position


  ; Draw the tongue
  LD HL, (Game_snake_tounge_x)
  PUSH HL
  CALL Get_Char_Address
  LD DE, Tiles_1
  LD A, B
  ADD A, Char_snake_tongue
  CALL Print_Char
  POP HL

  CALL Get_Attr_Address
  LD A, Snake_tongue_ink
  CALL Set_Ink

  RET

Clear_Tongue:
  LD HL, (Game_snake_tounge_x)
  CALL Game_get_address
  LD A, (HL)
  CP A, Game_tile_empty
  RET NZ ; Something occupies this position (fruit, wall), hence the tongue was
         ; never drawn. So we're done.

  LD HL, (Game_snake_tounge_x)
  CALL Graphics_Clear_Box

  RET

; Draws a body segment (i.e. not tail, tongue or head)
; H: Current body segment Y position
; L: Current body segment X position
Draw_snake_body_segment:
  PUSH HL
  CALL Game_get_address
  LD A, (HL)
  LD B, A

    ; A := B * 4
  LD A, 0
Draw_snake_body_segment_loop:
  ADD A, 4
  DJNZ Draw_snake_body_segment_loop
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
  LD B, Snake_body_ink
  CALL Print_Char_With_Ink

  RET

; Draws the snake's tail. Takes no arguments.
; The snake wags its tail as it slithers across the screen, alternating between
; left and right. The frames are organised to that even frames point left and odd
; frames right. We bake the wagging into the formula for indexing into the
; frames, arriving at:
;
;     index := direction + ((Y_pos xor X_pos) mod 2)
;
; We choose xor because it changes every time either operand changes.
Draw_Tail:

    ; Get the current tile's direction and push it on the stack.
  LD HL, (Game_snake_tail_x) ; H := Y position, L := X position
  LD A, H
  XOR L
  AND A, 1
  LD B, A

  CALL Game_get_address
  CALL Game_get_direction

  PUSH AF
  LD HL, (Game_snake_tail_x) ; As above
  CALL Get_Char_Address
  POP AF

  RLA ; A := A * 2
  ADD A, B
  ADD A, Char_snake_tail_start

  LD HL, (Game_snake_tail_x) ; As above
  LD B, Snake_body_ink
  CALL Print_Char_With_Ink

  RET

; Clears an 8x8 box (draws the background on it)
;   H: Y position
;   L: X position
Graphics_Clear_Box:
  PUSH HL
  CALL Get_Char_Address
  LD IY, Tile_background
  CALL Print_UDG8
  POP HL

  CALL Get_Attr_Address
  LD A, (HL)
  AND A, Bright
  OR A, Play_area_drop_shadow_attribute
  LD (HL), A

  RET

        endif ; graphics_z80
