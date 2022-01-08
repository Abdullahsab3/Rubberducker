BLACK EQU 00h
LIGHT_BLUE EQU 20h
GREY EQU 17h
YELLOW EQU 0Eh

VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen width
SCRHEIGHT EQU 200	; screen height
GAME_BGCOLOR EQU LIGHT_BLUE

LEFT_BORDER EQU 0
RIGHT_BORDER EQU SCRWIDTH-MAXSPEED
UPPER_BORDER EQU 0
DOWN_BORDER EQU SCRHEIGHT-1

INCUNIT_VERT EQU 20
INCUNIT_HORIZ EQU 16

SPRITEWIDTH EQU 16
SPRITEHEIGHT EQU 20
SPRITESIZE EQU SPRITEWIDTH*SPRITEHEIGHT
NUMBEROFENEMIES EQU 100
BULLETFREQUENCY EQU 200

INIT_X_PLAYER EQU  SCRWIDTH/2
INIT_Y_PLAYER EQU SCRHEIGHT-SPRITEHEIGHT

TOYS_Y_OFFSET EQU 40
TOYS_TIMES_LEVEL EQU 2
ROWS_WITH_TOYS EQU 4
MAX_TOYS_PER_ROW EQU 6
SPACE_BETWEEN_SPRITES_HORIZONTALLY EQU 3
SPACE_BETWEEN_SPRITES_VERTICALLY EQU 2

LEFT EQU 0
RIGHT EQU 1
DOWN EQU 2
UP EQU 3

INPUT_DELAY EQU 4
NEXTDD EQU 4
INITIAL_DIVIDED_TIMER EQU 4

NUMBER_OF_LIVES EQU 5
INITIAL_LEVEL EQU 1
INITIAL_SPEED EQU 1
INITIAL_TIMER EQU 500

UPPER_LINE_HEIGHT EQU 8
UPPER_LINE_COLOR EQU 00h

INITIAL_TRECT_X EQU 70
TRECT_Y EQU 0
TRECT_H EQU UPPER_LINE_HEIGHT
TRECT_W EQU 30
TRECT_COLOR EQU GREY

STRING_LIVES_ROW EQU 0
STRING_LIVES_COL EQU 32

STRING_LEVEL_ROW EQU 0
STRING_LEVEL_COL EQU 0

LEVELS_ROW EQU 0
LEVELS_COL EQU 7

LIVES_ROW EQU 0
LIVES_COL EQU 39

TIMER_ROW EQU 0
TIMER_COL EQU 20

USAGE_ROW EQU 10
USAGE_COL EQU 16

WELCOME_ROW EQU 2
WELCOME_COL EQU 7

END_ROW EQU 13
END_COL EQU 10

HLEVEL_ROW EQU END_ROW+2
HLEVEL_COL EQU END_COL

CONGRATS_ROW EQU END_ROW+4
CONGRATS_COL EQU END_COL-3

LEVELS_END_ROW EQU END_ROW
LEVELS_END_COL EQU 26

INS_ROW EQU 5
INS_COL EQU 0

ENTER_KEY EQU 1Ch
ESC_KEY EQU 01h
UP_KEY EQU 48H
DOWN_KEY EQU 50H
LEFT_KEY EQU 4Bh
RIGHT_KEY EQU 4Dh

R_RED EQU 63
G_RED EQU 06
B_RED EQU 06

R_BROWN EQU 30
G_BROWN EQU 25
B_BROWN EQU 20

R_GREY EQU 20
G_GREY EQU 20
B_GREY EQU 20

R_YELLOW EQU  63
G_YELLOW EQU 63
B_YELLOW EQU 0

R_BLACK EQU  0
G_BLACK EQU 0
B_BLACK EQU 30

HEARTPUP EQU 1
FREEZINGPUP EQU 2
SHIELD_PUP EQU 3

NUMBER_OF_ADDED_LIVES EQU 1
FREEZING_CTR EQU 3
SHIELD_TIMER EQU 100

DEAD EQU 0
TOP EQU 0

KEYCNT EQU 4

MAXSPEED EQU 5

NUMBEROFSPRITES EQU 7
PATHSIZE EQU 9

POWERUPFERQ EQU 700
LOWEST_POWERUP EQU 1
HIGHEST_POWERUP EQU 3