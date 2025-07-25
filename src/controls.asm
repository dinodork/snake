    ifndef src_controls_z80
    define src_controls_z80

    include "lib/keyboard.asm"
Input_Custom:
  DB 0xFB, %00000001  	; Q (Up)
  DB 0xFD, %00000001  	; A (Down)
  DB 0xDF, %00000010  	; O (Left)
  DB 0xDF, %00000001  	; P (Right)


; Reads the keyboard and updates the player sprite's direction;
; Current_Direction
Handle_Controls:
  LD HL, Input_Custom
  CALL Read_Controls

Check_Up:
  BIT 4, A
  JR Z, Check_Down

  DI
  LD HL, (Game_snake_head_x)
  CALL Game_get_address
  CALL Game_get_direction
  CP Game_tile_facing_down
  EI
  RET Z

  LD HL, Game_next_direction
  LD (HL), Game_tile_facing_up

  RET
Check_Down:
  BIT 3, A
  JR Z, Check_Left

  DI
  LD HL, (Game_snake_head_x)
  CALL Game_get_address
  CALL Game_get_direction
  CP Game_tile_facing_up
  EI
  RET Z

  LD HL, Game_next_direction
  LD (HL), Game_tile_facing_down

  RET
Check_Left:
  BIT 2, A
  JR Z, Check_Right

  DI
  LD HL, (Game_snake_head_x)
  CALL Game_get_address
  CALL Game_get_direction
  CP Game_tile_facing_right
  EI
  RET Z

  LD HL, Game_next_direction
  LD (HL), Game_tile_facing_left

  RET

Check_Right:
  BIT 1, A
  JR Z, Keycheck_Done

  DI
  LD HL, (Game_snake_head_x)
  CALL Game_get_address
  CALL Game_get_direction
  CP Game_tile_facing_left
  EI
  RET Z

  LD HL, Game_next_direction
  LD (HL), Game_tile_facing_right

Keycheck_Done:
  RET

All_key_banks:
    BYTE Key_bank_12345, Key_bank_09876
    BYTE Key_bank_QWERT, Key_bank_POIUY
    BYTE Key_bank_ASDFG, Key_bank_EnterLKJH
    BYTE Key_bank_CsZXCV, Key_bank_SpaceSsMNB
All_key_banks_end:

    endif ; src_controls_z80
