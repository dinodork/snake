    ifndef src_message_strings_z80
    define src_message_strings_z80

    include "messages.asm"

Text_Scores:
  DB 0, 0, "Snake", 0xFE
  DB 9, 0, "Score 12345", 0xFF

;
; Main menu texts
;
    DEFINE_MESSAGE Title_Message, "ZX Snake"
    DEFINE_MESSAGE Keys_Message, "Keys are Q, A, O, P"
    DEFINE_MESSAGE Press_Key_To_Play_Message, "Press any key to play"
Copyright_String1:
    DB "2024 B.C.G.", 0xFE
Copyright_String2:
    DB "(Berryby Computer Graphics)", 0xFE
Copyright_String3:
    DB "No rights whatsoever reserved", 0xFE

;
; In-game texts
;
Score_String:
    ; The numbers are overwritten with actual score during game
    DB "Score 123456", 0xFE
;
; Game over texts
;
    DEFINE_MESSAGE Game_Over_Message, "Game Over"
    DEFINE_MESSAGE Press_Key_To_Play_Again_Message, "Press any key to play again"

    endif ; src_message_strings_z80
