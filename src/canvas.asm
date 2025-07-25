  include "graphics/tile_metadata.asm"
  include "lib/attribute.asm"
  include "lib/graphics.asm"

  MACRO SLOW_DOWN_VISUALS
;    HALT
  ENDM

Canvas_current_snake_ink: DEFS 1, Snake_body_ink

Snake_body_ink: EQU Ink_Green
Snake_head_ink: EQU Ink_White
Snake_tongue_ink: EQU Ink_Red

Apple_stalk_ink: EQU Ink_Green
Apple_ink: EQU Ink_Red

Background_Paper: EQU Paper_Blue
Background_Ink: EQU Ink_Black
Invisible_ink: EQU Ink_Blue ; Same ink as Background_Paper
Play_area_attribute: EQU Paper_Blue | Background_Ink | Bright
Play_area_drop_shadow_attribute: EQU Play_area_attribute & ~Bright

Brick_attribute: EQU Ink_Yellow | Paper_Red

Draw_Game_Screen:

  LD A, Play_area_attribute
  CALL Draw_Game_Backdrop

  CALL Draw_Game_Floor
  CALL Draw_Fence

  RET

Draw_Game_Floor:

  LD B, 23
Draw_Game_Floor_loop:

  LD H, B ; (Y B)
  PUSH BC
  LD B, 31
Draw_Game_Floor_row_loop:
  LD L, B
  PUSH HL
  CALL Get_Char_Address
  LD IY, Tile_background
  CALL Print_UDG8
  POP HL

  DJNZ Draw_Game_Floor_row_loop

  POP BC

  DJNZ Draw_Game_Floor_loop

  RET

; A Attribute
Draw_Game_Backdrop:
  LD HL, Start_Of_Attribute_Ram + 32
  LD DE, Start_Of_Attribute_Ram + 33
  LD BC, 31
  LD (HL), A
  LDIR

  DUP 22
  SLOW_DOWN_VISUALS
  LD BC, 32
  LDIR
  EDUP

  RET

Draw_Fence:
  LD HL, 0x0100 ; (X 0, Y 1)
Draw_Fence_top_loop:
  PUSH HL
  CALL Get_Char_Address
  LD IY, Tile_bricks
  CALL Print_UDG8
  POP HL

  LD DE, Start_Of_Attribute_Ram + 32
  PUSH HL
  LD H, 0
  ADD HL, DE
  LD (HL), Brick_attribute
  POP HL

  ; Draw drop shadow
  LD DE, Start_Of_Attribute_Ram + 64
  PUSH HL
  LD H, 0
  ADD HL, DE
  LD (HL), Play_area_drop_shadow_attribute
  POP HL

  LD DE, Start_Of_Attribute_Ram + 96
  PUSH HL
  LD H, 0
  ADD HL, DE
  LD (HL), Play_area_drop_shadow_attribute
  POP HL


  INC L
  LD A, L
  CP 32

  SLOW_DOWN_VISUALS

  JP NZ, Draw_Fence_top_loop

  LD HL, 0x021F ; (X 31, Y 2)
Draw_Fence_right_loop:
  PUSH HL
  CALL Get_Char_Address
  LD IY, Tile_bricks
  CALL Print_UDG8
  POP HL

  PUSH HL
  CALL Get_Attr_Address
  LD (HL), Brick_attribute
  POP HL

  INC H
  LD A, H
  CP 23

  SLOW_DOWN_VISUALS

  JP NZ, Draw_Fence_right_loop

  LD HL, 0x171F ; (X 31, Y 23)
Draw_Fence_bottom_loop:
  PUSH HL
  CALL Get_Char_Address
  LD IY, Tile_bricks
  CALL Print_UDG8
  POP HL

  PUSH HL
  CALL Get_Attr_Address
  LD (HL), Brick_attribute
  POP HL

  SLOW_DOWN_VISUALS

  DEC L
  LD A, L
  CP -1
  JP NZ, Draw_Fence_bottom_loop

  LD L, 0
  LD B, 22
Draw_Fence_left_loop:
  LD H, B
  PUSH HL
  CALL Get_Char_Address
  LD IY, Tile_bricks
  CALL Print_UDG8
  POP HL

  PUSH HL
  CALL Get_Attr_Address
  LD (HL), Brick_attribute
  POP HL

  ; Draw drop shadow
  PUSH HL
  LD L, 1
  CALL Get_Attr_Address
  LD (HL), Play_area_drop_shadow_attribute
  POP HL

  PUSH HL
  LD L, 2
  CALL Get_Attr_Address
  LD (HL), Play_area_drop_shadow_attribute
  POP HL

  SLOW_DOWN_VISUALS

  DEC B
  LD A, B
  CP 1
  JP NZ, Draw_Fence_left_loop

Set_Score_Attr:
  LD B, 31
Set_Score_Attr_loop:
  LD H, 0
  LD L, B
  CALL Get_Attr_Address
  LD (HL), Ink_White | Paper_Black | Bright
  DJNZ Set_Score_Attr_loop
Draw_Score:
  LD HL, (Game_Score)
  LD DE, Score_String + 6
  CALL Num2Dec

  LD IX, Score_String
  LD HL, 10
  LD DE, Font_1 - 0x100
  CALL Print_String_At
