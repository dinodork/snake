    ifndef game_state_z80
    define game_state_z80

; The Game consists of a grid, where each cell corresponds to an 8x8 pixel box on the
; visible screen. Each tile in this grid contains information about what goes on. It is
; either:
;
; - A direction, the direction that the snake exited this square.
; - Whether the square is occupied by a wall.
; - Whether the square contains food.
;
; There is also some additional information, such as the position of the head and the tail.
Game_height: EQU 24
Game_width: EQU 32
Game_scores_height: EQU 1
Game_size: EQU Game_height * Game_width
Game:
    DEFS Game_size
Game_tile_facing_up: EQU 0x00
Game_tile_facing_down: EQU 0x01
Game_tile_facing_left: EQU 0x02
Game_tile_facing_right: EQU 0x03
Game_tile_wall: EQU 0x04

; Unlike food, we don't have different representations of the stalk in the game
; state, it's all represented by this value.
Game_tile_food_stalk: EQU 0x05
Game_tile_food_bit: EQU 0x3
Game_tile_food_mask: EQU 1 << Game_tile_food_bit
Game_tile_apple: EQU 0x08 | Food_apple
Game_tile_cherry: EQU 0x08 | Food_cherry
Game_tile_empty: EQU 0xFF

; The theoretical position of the tongue. We say theoretical because the tongue
; might not be visible in case some other visual element occupies the same
; space. For the same reason, we need to keep it in a special variable rather
; than in the game state.
Game_snake_tounge_x:
    DEFS 0x1
Game_snake_tongue_y:
    DEFS 0x1
Game_snake_head_x:
    DEFS 0x1
Game_snake_head_y:
    DEFS 0x1
Game_snake_tail_x:
    DEFS 0x1
Game_snake_tail_y:
    DEFS 0x1

; The direction that the player has selected to go next, (by keyboard,
; joystick, etc)
Game_next_direction:
    DEFS 0x1

; The target length of the snake. The tail will not advance until this length
; is met.
Game_snake_target_length:
    DEFS 0x2
Game_snake_length:
    DEFS 0x2

Game_snake_start_length: EQU 3
Game_head_start_x:  EQU Game_width / 2 + Game_snake_start_length / 2
Game_head_start_y:  EQU Game_height / 2
Game_tongue_start_x:  EQU Game_head_start_x + 1
Game_tongue_start_y:  EQU Game_head_start_y
Game_tail_start_x: EQU Game_head_start_x - Game_snake_start_length
Game_tail_start_y: EQU Game_height / 2

Game_Phase:
    DEFS 1
Game_Phase_Running: EQU 0
Game_Phase_Game_Over: EQU 1
Game_Phase_Eating: EQU 2

Game_Score:
    DEFS 2, 0
Game_initialise:
    ; Clear the whole game
  LD HL, Game
  LD DE, Game + 1
  LD BC, Game_size
  LD (HL), Game_tile_empty
  LDIR		; Copy this byte to the second, and so on

    ; Draw top wall
  LD HL, Game + Game_width ; Second row, top row is score etc.
  LD DE, Game + Game_width + 1
  LD BC, Game_width
  LD (HL), Game_tile_wall	; Set the first byte
  LDIR		; Copy this byte to the second, and so on

    ; Draw bottom wall
  LD HL, Game + Game_width * (Game_height + Game_scores_height - 2)
  LD DE, Game + Game_width * (Game_height + Game_scores_height - 2) + 1
  LD BC, Game_width
  LD (HL), Game_tile_wall	; Set the first byte
  LDIR		; Copy this byte to the second, and so on

    ; Draw side walls
  LD IY, Game + Game_width * (Game_scores_height + 1)
  LD B, Game_height - 2 - Game_scores_height
Draw_side_walls_loop:
  LD (IY), Game_tile_wall
  LD (IY + Game_width - 1), Game_tile_wall
  LD D, 0
  LD E, Game_width
  ADD IY, DE
  DJNZ Draw_side_walls_loop

  ; Place snake
  LD IX, Game_snake_tongue_y
  LD (IX), Game_tongue_start_x

  LD IX, Game_snake_head_x
  LD (IX), Game_head_start_x

  LD IX, Game_snake_head_y
  LD (IX), Game_head_start_y

  LD IX, Game_snake_tail_x
  LD (IX), Game_tail_start_x

  LD IX, Game_snake_tail_y
  LD (IX), Game_tail_start_y

  LD IX, Game + Game_tail_start_y * Game_width + Game_tail_start_x
  LD (IX), Game_tile_facing_right
  LD (IX + 1), Game_tile_facing_right
  LD (IX + 2), Game_tile_facing_right
  LD (IX + 3), Game_tile_facing_right

  LD HL, Game_snake_target_length
  LD (HL), 3
  LD HL, Game_snake_length
  LD (HL), 3

  LD IX, Game_next_direction
  LD (IX), Game_tile_facing_right
  RET

; HL: address of game tile in HL
; Returns the direction that the snake exited the tile in A.
Game_get_direction:
  LD A, (HL)
  RET

; Returns address of game tile in HL
;   H: Y position
;   L: X position
; Clobbers: DE
Game_get_address:
    ; Save the X value in DE
  LD E, L
  LD D, 0

    ; Make HL contain only the Y value
  LD L, H
  LD H, 0

  HL_X_32

    ; Add the X value back
  ADD HL, DE

    ; Add this to the start of Game
  LD DE, Game
  ADD HL, DE

  RET

; Returns address of game tile in IX
;   H: Y position
;   L: X position
; Clobbers: BC
Game_get_address_IX:
  ; IX = H * 32
  LD B, 0
  LD C, H
  X_32 BC
  LD IX, BC

  ; IX += L
  LD B, 0
  LD C, L
  ADD IX, BC

  ; IX += L Game
  LD BC, Game
  ADD IX, BC

  RET


; Checks for collision and updates game state accordingly.
;   H Snake head Y position
;   L Snake head X position
; Returns:
;   IX Address of game state
; Clobbers:
;   A
Detect_And_Handle_Collision:
  LD IY, Game_Phase
  LD A, L

  CALL Game_get_address_IX
  LD A, (IX)

  CP A, Game_tile_empty
  RET Z

  CP A, Game_tile_food_stalk
  RET Z

  BIT Game_tile_food_bit, A
  JP NZ, Handle_Collision_With_Food

  ; Collision with wall
  LD (IY), Game_Phase_Game_Over
  RET

; Assumes that the snake's head is in the same location as the food.
;   H Food Y position
;   L Food X position
Handle_Collision_With_Food:
  LD IX, Game_Phase
  LD (IX), Game_Phase_Eating
  LD IX, Game_snake_target_length
  INC (IX)
  INC (IX)
  INC (IX)

  CALL Remove_Food

; Award points
  LD HL, (Game_Score)
  INC HL
  LD (Game_Score), HL
  CALL Draw_Score

  CALL Place_Food

  RET

    endif ; game_state_z80
