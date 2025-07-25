    ifndef lib_graphics_z80
    define lib_graphics_z80

    include "attribute.asm"

Attribute_ram_columns: EQU 32
Start_Of_Image_File: EQU 0x4000

Start_Of_Attribute_Ram: EQU 0x4000 + 0x1800

; Clears a box of 8x8 blocks (i.e. sets both paper and ink to black)
; H: Y position of upper left corner.
; L: X position of upper left corner.
; B: Height
; C: Width
Clear_Box:
Clear_Box_Outer_Loop:
  PUSH BC
  PUSH HL
  LD B, C
Clear_Box_Inner_Loop:
  PUSH HL
  PUSH AF
  CALL Get_Attr_Address
  POP AF
  LD (HL), A
  POP HL
  INC L
  DJNZ Clear_Box_Inner_Loop

  POP HL
  POP BC
  INC H
  DJNZ Clear_Box_Outer_Loop

  RET

SWAP_B_C:
  LD A, B
  LD B, C
  LD C, A
  RET

    endif ; lib_graphics_z80
