  ifndef graphics_tile_metadata_z80
  define graphics_tile_metadata_z80

; Mapping from tile number as shown in ZX Graphics Editor to a memory address
; in the .asm file generated from the .udg file. (See GenerateGraphicsAsm rule
; tasks.json.) This memory address can be used with Print_UDG8.
  MACRO TILE name, i
Tile_name: EQU Tiles_1 + (i - 32) * 8
  ENDM

; Like above, but maps to a character number suitable for calling Print_Char.
; This is useful when we choose snake tiles depending on direction and need
; to do the multiplication with 8 anyway.
  MACRO CHAR name, i
Char_name: EQU (i - 32)
  ENDM

; Apperantly, for recursive expansion of macros in macros, you have to indent
; them like this. Not documented in the sjasmplus documentation.
  MACRO FRUIT name, i
  CHAR name_stalk, i
  CHAR name, i + 1
  ENDM

  CHAR snake_tongue, 56

  TILE bricks, 73
  FRUIT apple, 64
  FRUIT cherry, 66
  CHAR snake_head_start, 32
  CHAR snake_tail_start, 36
  CHAR snake_body_start, 40
  CHAR snake_head_x_eyes, 60
  TILE background, 72

  endif ; graphics_tile_metadata_z80
