IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "gfx.inc"
INCLUDE "cons.inc"
INCLUDE "genl.inc"


CODESEG


; Fill the background (for mode 13h) ;; from the WPOs
PROC fillBackground
	ARG 	@@fillcolor:byte
	USES 	eax, ecx, edi

	; Initialize video memory address.
	mov	edi, VMEMADR
	
	; copy color value across all bytes of eax
	mov al, [@@fillcolor]	; ???B
	mov ah, al				; ??BB
	mov cx, ax			
	shl eax, 16				; BB00
	mov ax, cx				; BBBB

	; Scan the whole video memory and assign the background colour.
	mov	ecx, SCRWIDTH*SCRHEIGHT/4
	rep	stosd

	ret
ENDP fillBackground


; performs a busy wait for the start of this interval
; and updates the frame buffer during this interval
proc wait_VBLANK
	USES eax, edx
	mov dx, 03dah
	
	@@VBlank_phase1:
	in al, dx 
	and al, 8
	jnz @@VBlank_phase1
	@@VBlank_phase2:
	in al, dx 
	and al, 8
	jz @@VBlank_phase2
	
	ret 
endp wait_VBLANK


; a macro to reduce code duplication in the drawing procedures
macro horizontal_draw_loop inc_or_dec
	 @@horizontalloop:
            mov al, [ebx]    		;; move the pixel
            mov [edi], al    		;; to the graphic memory
            inc_or_dec ebx          ;; next/previous pixel that needs to be moved
            inc edi			 		;; go to next graphic memory address
            dec edx			 		;; reduce the counter
            jg @@horizontalloop
	 ;; go to the next row
     ;;  i = 320row + column
        add edi, SCRWIDTH
        sub edi, SPRITEWIDTH ;; return breadth times pixels back
endm horizontal_draw_loop

;; a macro te reduce code duplication
macro initialize_drawing_proc height
 ;; index of the first pixel (topleft of the element) i = 320x + y
    mov eax, [@@y]
    mov edx, SCRWIDTH
    mul edx
    add eax, [@@x]

    mov edi, VMEMADR
    add edi, eax  
	mov ecx, height
endm initialize_drawing_proc

;; draw a sprite (20x16)
proc drawSprite
    ARG @@sprite: dword, @@x: dword, @@y:dword 
    USES eax, ebx, ecx, edx, edi
	initialize_drawing_proc SPRITEHEIGHT
    mov ebx, [@@sprite]                   	 ; index of the pixel in the row
    @@vertloop:
	    mov edx, SPRITEWIDTH 
        horizontal_draw_loop inc
        loop @@vertloop
    ret
endp drawSprite

;; based on the the compendium
proc change_color_palette
	ARG @@color: word, @@R: word, @@G: word, @@B: word

	MOV DX, 03C8H ; port to signal index for modification
	MOV AX, [@@color] ; change the colour at index 0
	OUT DX, AL ; write AL to the appropriate port
	MOV DX, 03C9H ; port to communicate the new colour
	MOV AX, [@@R] ; move red value into AL
	OUT DX, AL ; write AL to the appropriate port
	MOV AX, [@@G] ; repeat for green
	OUT DX, AL ;
	MOV AX, [@@B] ; repeat for blue
	OUT DX, AL ;
	
	ret
endp change_color_palette

;; draw a filled rectangle
;; based on the WPO's
proc drawRectangle
	ARG @@x: dword, @@y: dword, @@h: dword, @@w: dword, @@color: byte
    USES eax, ecx, edx, edi
	initialize_drawing_proc [@@h]
	mov edx, [@@w]
    @@vertloop:
        @@horizontalloop:
			mov al, [@@color]
            mov [edi], al
            inc edi
            dec edx
            jg @@horizontalloop
        add edi, SCRWIDTH
		sub edi, [@@w]
		mov edx, [@@w]
        loop @@vertloop
    ret
endp drawRectangle


;; draws the sprite but mirrored around the y-axis
proc drawFlippedSprite
    ARG @@sprite: dword, @@x: dword, @@y:dword 
    USES eax, ebx, ecx, edx, edi, esi
	initialize_drawing_proc SPRITEHEIGHT
	xor esi, esi 			;; esi is being used as the row counter
	add esi, SPRITEWIDTH
    @@vertloop:	
		mov ebx, [@@sprite]
		add ebx, esi
		dec ebx
	 	mov edx, SPRITEWIDTH      	;; the counter of the horizontal loop
        horizontal_draw_loop dec  
		add esi, SPRITEWIDTH 
        loop @@vertloop
    ret
endp drawFlippedSprite

;; from the compendium
proc displaystring
	arg @@row:dword, @@column:dword, @@offset:dword
	uses eax, ebx, edx


	mov edx, [@@row] 	; row in edx
	mov ebx, [@@column] ; column in ebx
	mov ah, 02h 		; set cursor position
	shl edx, 08h 		; row in dh (00h is top)
	mov dl, bl 			; column in dl (00h is left) 
	mov bh, 0			; page number in bh
	int 10h 			; raise interrupt
	mov ah, 09h 		; write string to standard output         
	mov edx, [@@offset] ; offset of ’$’-terminated string in edx
	int 21h 			; raise interrupt

	ret
endp displaystring

; display a string with its given coordinates
proc displaystring_with_coords
	arg @@str: dword
	uses ebx, ecx, edx, edi

	mov edx, [@@str] ;; row
	mov ebx, edx
	mov edx, [edx]
	inc ebx			 ;; col
	mov ecx, ebx
	mov ebx, [ebx]
	inc ecx			 ;; string
	call displaystring, edx, ebx, ecx

	;; eax will have the total length of the 'array'
	call strlen, ecx
	;; total size of the 'array':
	;; sizeof row (1byte) + sizeof col(1byte) + sizeof string (length of the string)
	add eax, 2

	ret
endp displaystring_with_coords

;; from the WPO's
PROC printUnsignedInteger
		ARG	 @@row:dword, @@column:dword, @@printval:dword    ; input argument
		USES eax, ebx, ecx, edx

		mov edx, [@@row] 	; row in edx
		mov ebx, [@@column] ; column in ebx
		mov ah, 02h 		; set cursor position
		shl edx, 08h 		; row in dh (00h is top)
		mov dl, bl 			; column in dl (00h is left) 
		mov bh, 0			; page number in bh
		int 10h 			; raise interrupt
		mov eax, [@@printval]
		mov	ebx, 10		; divider
		xor ecx, ecx	; counter for digits to be printed

		; Store digits on stack
	@@getNextDigit:
		inc	ecx         ; increase digit counter
		xor edx, edx
		div	ebx   		; divide by 10
		push dx			; store remainder on stack
		test eax, eax	; check whether zero?
		jnz	@@getNextDigit

		; Write all digits to the standard output
		mov	ah, 2h 		; Function for printing single characters.
	@@printDigits:		
		pop dx
		add	dl,'0'      	; Add 30h => code for a digit in the ASCII table, ...
		int	21h            	; Print the digit to the screen, ...
		loop @@printDigits	; Until digit counter = 0.
		
		ret
ENDP printUnsignedInteger

;; used to print the number of levels and the number of lives
proc draw_game_values
	arg @@level:dword, @@lives: dword, @@timer: dword
	USES eax, ebx, ecx
	mov eax, [@@level]
	mov ebx, [@@lives]
	mov ecx, [@@timer]
	CALL printUnsignedInteger, LEVELS_ROW, LEVELS_COL, [dword ptr eax]
	CALL printUnsignedInteger, LIVES_ROW, LIVES_COL, [dword ptr ebx]
	call printUnsignedInteger, TIMER_ROW, TIMER_COL, [dword ptr ecx]
	ret
endp draw_game_values


;; print the string level (Level: ) and the lives string (Lives: )
proc draw_level_and_lives_string
	mov ecx, 2 ;; two strings are going to be printed
	mov edx, offset string_Lives

	@@display_strings:
		call displaystring_with_coords, edx
		add edx, eax
		loop @@display_strings

	ret
endp draw_level_and_lives_string

proc display_start_screen
	uses eax, ebx, ecx, edx

	call fillBackground, BLACK

	lea ebx, [welcome]
	mov ecx, 3
	@@start_screen:
		call displaystring_with_coords, ebx
		add ebx, eax
	loop @@start_screen

	ret
endp display_start_screen

proc display_congrats
	uses edx
	mov edx, offset congrats
	call displaystring_with_coords, edx

	ret
endp display_congrats

proc dispay_end_screen
	arg @@level: dword, @@highest_level: dword
	uses eax, ebx, ecx, edx, edi

	call fillBackground, BLACK

	mov ebx, [@@level]
	mov edi, [@@highest_level]
	call printUnsignedInteger, LEVELS_END_ROW, LEVELS_END_COL, ebx
	call printUnsignedInteger, LEVELS_END_ROW+2, LEVELS_END_COL, edi
	mov edx, offset starting_ins
	mov ecx, 3
	@@end_screen_loop:
		call displaystring_with_coords, edx
		add edx, eax
	loop @@end_screen_loop
	
	ret
endp dispay_end_screen


DATASEG

	string_Lives 	db STRING_LIVES_ROW, STRING_LIVES_COL, "Lives: ", 13, 10, '$'
	string_Level 	db STRING_LEVEL_ROW, STRING_LEVEL_COL, "Level: ", 13, 10, '$'

	welcome 		db WELCOME_ROW, WELCOME_COL
					db "Welcome to Rubberducker!", 13, 10, 10, '$'

	usage			db USAGE_ROW, USAGE_COL
					db "Usage: ", 13, 10, 10
					db "Use the arrows to move around.", 13, 10, 10
					db "Try to reach the top of the screen", 13, 10, 10
					db "without touching any toys", 13, 10, 10
					db "or being hit by a bullet", 13, 10, 10
					db "before your time is up!", 13, 10, 10
					db "Collect power-ups to get extra powers!", 13, 10, '$'

	starting_ins	db INS_ROW, INS_COL
					db "Press Enter to start a new game", 13, 10, 10
					db "Press Esc to leave the game :-(", 13, 10, '$'

	endscreen		db END_ROW, END_COL
					db "Your score was: ", 13, 10, '$'
	
	highest_level 	db HLEVEL_ROW, HLEVEL_COL
					db " Highest score: ", 13, 10, '$'

	congrats 		db CONGRATS_ROW, CONGRATS_COL
					db "Congrats, new high score!", 13, 10, '$'

	stack 100h
END