    ifndef screen_z80
    define screen_z80

Menu_attribute: EQU Paper_Black | Ink_White | Bright
Menu_border: EQU 0 ; Black
Game_border: EQU Menu_border

; Simple clear-screen routine
; Uses LDIR to block clear memory
; A:  Colour to clear attribute block of memory with
;
Clear_Screen:
  LD HL, 16384	; Start address of screen bitmap
  LD DE, 16385	; Address + 1
  LD BC, 6144	; Length of bitmap memory to clear
  LD (HL), 0	; Set the first byte to 0
  LDIR		; Copy this byte to the second, and so on
  LD BC, 767	; Length of attribute memory, less one to clear
  LD (HL), A	; Set the first byte to A
  LDIR		; Copy this byte to the second, and so on
  RET

; Get screen address
;   H = Y character position
;   L = X character position
; Returns address in graphics file in HL
; Clobbers: A
Get_Char_Address:
  LD A, H
  AND %00000111
  RRA
  RRA
  RRA
  RRA
  OR L
  LD L, A
  LD A, H
  AND %00011000
  OR %01000000
  LD H, A

  RET		; Returns screen address in HL

Get_Char_Address_in_IY:
  LD A, H
  AND %00000111
  RRA
  RRA
  RRA
  RRA
  OR L
  LD IYH, A
  LD A, H
  AND %00011000
  OR %01000000
  LD H, A
  RET		; Returns screen address in HL

; Prints a UDG (Single Height)
; IY - UDG data to print
; HL - Screen address
; Clobbers
;   IY, HL
Print_UDG8:
  DUP 8

  LD A, (IY)
  LD (HL), A
  INC IY
  INC H		; Goto next line on screen

  EDUP

  RET

; Prints a single character to a screen address.
;   A:  Character to print.
;   HL: Screen address to print character at.
;   DE: Address of character set (if entering at Print_Char_UDG.)
; No SM code here - needs to be reentrant if called on interrupt.
;
; Clobbers: BC, IY
Print_Char:
  PUSH HL

  ; Get index into character set, by multiplying ascii value by 8.
  LD B, 0
  LD C, A

  ; Multiply BC by 8
  DUP 3
  SLA C
  RL B
  EDUP

  LD IY, DE
  ADD IY, BC

  CALL Print_UDG8
  POP HL

  RET

; Prints a string with attribute information at a given position.
;   IX: Address of string
;   H:  Row
;   L:  Column
;   DE: Address of character set
Print_String_With_Attribute_At:
  CALL Print_String_At
  PUSH HL
  PUSH IX
  PUSH DE
  LD B, 1
  LD C, 5
  LD A, Ink_White
  CALL Clear_Box
  POP DE
  POP IX
  POP HL
  CALL Print_String_At
  RET


; First two bytes of string contain X and Y char position, then the string
; Individual strings are terminated with 0xFE
; End of data is terminated with 0xFF

Print_Strings:
  CALL Print_String
  CP 0xFF
  RET Z
  INC IX
  JP Print_Strings

Print_String:
  LD L, (IX + 0)  ; Fetch the X coordinate
  INC IX			    ; Increase HL to the next memory location
  LD H, (IX + 0)  ; Fetch the Y coordinate
  INC IX			    ; Increase HL to the next memory location


; Prints a string
;   IX: Address of string
;   H:  Row
;   L:  Column
;   DE: Address of character set
Print_String_At:
  CALL Get_Char_Address	; Calculate the screen address (in HL)
  LD A, (IX)				; Fetch the character to print
  CP 0xFE					; Compare with 0xFE
  RET NC
  CALL Print_Char			; Print the character
  INC IX					; Next character
  INC L					; Go to the next screen address
  JR Print_String_At
Print_String_Done:
  RET

; Clears a single characters block.
;   HL: Screen address to clear at.
Clear_Char:
  DUP 8
  LD (HL), 255
  INC H		; Goto next line on screen
  EDUP

  RET

    endif ; screen_z80
