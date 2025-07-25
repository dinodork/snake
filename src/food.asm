    ifndef src_food_z80
    define src_food_z80

    include "game_state.asm"
    include "graphics.asm"
    include "lib/attribute.asm"
    include "lib/math.asm"
    include "screen.asm"

Food_apple: EQU 1
Food_cherry: EQU 2

Food_inks:
  ;    Apple    Cherry       Pineapple   Pear
  BYTE Ink_Red, Ink_Magenta, Ink_Yellow, Ink_Green

; Removes food from games state and screen
; H: Y position
; L: X position
Remove_Food:
  DEC H ; The stalk is above the food
  PUSH HL
  CALL Game_get_address
  LD A, (HL)

  CP A, Game_tile_food_stalk
  POP HL

  RET NZ ; The stalk was replaced by something (snake), or was
        ; never drawn (wall, snake), exit.

  ; Remove the food tile from the game state
  PUSH HL
  CALL Game_get_address
  LD A, Game_tile_empty
  LD (HL), A
  POP HL

  ; Remove the food from the screen
  CALL Graphics_Clear_Box

  RET

; Food placement: find a place where food fits, i.e. that is
;  - on the screen, and
;  - vacant
; - Choose a fruit
; - Draw fruit
; - Check if there is room to draw the stalk
; Finds a random X, Y position that is within the screen.
; Once found, places the food there, both in the game state and on-screen.
Place_Food:
  CALL RND16 ; H is Y position, L is X position from now on.

  ; The X value can be 0-31, so it will suffices to mask it.
  LD A, L
  AND 32 - 1
  LD L, A

  ; The Y value can be 0-22 (1 row of score). We mask it first, so it's
  ; in the interval 0-31.
  LD A, H
  AND 32 - 1
  CP 23 - Game_scores_height
  JP S, Place_Food_y_ok:
  RR A ;  It's greater than 22, divide in half. Now we know it's o.k.
Place_Food_y_ok:
  ADD A, Game_scores_height
  LD H, A

  LD BC, HL

  ; Check if the position is free.
  CALL Game_get_address_IX
  LD A, (IX)
  CP A, Game_tile_empty
  JR NZ, Place_Food ; Space occupied, regenerate

  ;
  ; We found a free space, place the food
  ;

  ; Choose fruit: generate a random index. There are four fruits, so use bottom
  ; two bits of only.
  LD A, R
  AND A, 3

  PUSH AF
  OR A, Game_tile_food_mask
  LD (IX), A
  POP AF

  ;
  ; Draw the food on screen
  ;

  PUSH HL
  CALL Draw_Food
  POP HL

 ; Try to place and draw the stalk
  DEC H
  CALL Game_get_address_IX
  LD A, (IX)
  CP A, Game_tile_empty

  RET NZ

  ; There's a free slot to place the stalk
  ; Now go back and check what the food was
  INC H
  CALL Game_get_address_IX
  LD A, (IX)
  AND A, ~Game_tile_food_mask
  DEC H

  PUSH HL
  CALL Draw_Stalk
  POP HL

  CALL Game_get_address_IX
  LD A, Game_tile_food_stalk
  LD (IX), A

  RET

    endif ; src_food_z80
