IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT



INCLUDE "KEYB.INC"
INCLUDE "FILEH.INC"
INCLUDE "gfx.inc"
INCLUDE "genl.inc"
INCLUDE "cons.inc"
INCLUDE "rand.inc"

; -------------------------------------------------------------------

CODESEG


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                                                        ;;;;;
;;;;;                              Strucs                                    ;;;;;
;;;;;                                                                        ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; strucs to represent the player, enemies and powerups 
STRUC player
	x dd 0
	y dd 0
	; pointer to used sprite
	sprite dd 0 
ENDS player

STRUC enemyobj
	x dd 0
	y dd 0
	;toys move in a direction. 0 is left, 1 is right
	dir dd 0 
	sprite dd 0
	valid dd 0
ENDS enemyobj

struc powerup
	x dd 0
	y dd 0
	sort dd 0
	shown dd 0
	active dd 0
	sprite dd 0
ends powerup


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                                                        ;;;;;
;;;;;                              Move player                               ;;;;;
;;;;;                                                                        ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; when the player goes to the next level, or when a collision has occured, the duck gets back to the bottom of the screen
proc resetPlayerPosition
	
	mov [duck1.x], INIT_X_PLAYER
	mov [duck1.y], INIT_Y_PLAYER
	call drawSprite, [duck1.sprite], [duck1.x], [duck1.y]

	ret
endp resetPlayerPosition

;; a general procedure to move a sprite
;; the procedure takes the address of the x and y coordinates, and updates them according to the direction and speed given as arguments.
proc moveSprite
	arg @@x: dword, @@y: dword, @@speed: dword, @@dir: dword
	uses ebx, ecx, edx, edi, esi
	
	xor eax, eax

	mov ebx, [@@x] ;; the address of x
	mov edx, [@@y] ;; the address of y
	mov ebx, [ebx]	;; the value of x
	mov edx, [edx]	;; the value of y

	mov edi, [@@speed] ;; the unit of which the position is to be incremented
	mov ecx, [@@dir]  ;; the direction to which the sprite is headed

	cmp ecx, LEFT
	je @@moveLeft
	cmp ecx, RIGHT
	je @@moveRight
	cmp ecx, UP
	je @@moveUp
	cmp ecx, DOWN
	je @@moveDown
	jmp @@dont_move

	@@moveLeft:
		mov esi, LEFT_BORDER ;; check the left border
		neg edi				 ;; the x value should be decremented when going to left
		jmp @@moveHoriz
		
	@@moveRight:
		mov esi, RIGHT_BORDER	;; check the right border

	@@moveHoriz:
		call CheckforCollision, ebx, edx, esi, edx	;; check whether the sprite collided with the border so the sprite doesn't move out of screen
		test eax, eax
		jnz @@dont_move
		mov ebx, [@@x]
		jmp @@move

	@@moveUp:
		mov esi, UPPER_BORDER	;; check the upper border
		neg edi					;; to go up you need to decrement the y value
		jmp @@moveVert
	@@moveDown:
		mov esi, DOWN_BORDER	;; check the down border

	@@moveVert:
		call CheckforCollision, ebx, edx, ebx, esi	;; check whether the sprite collided with the border
		test eax, eax
		jnz @@dont_move_vertical
		mov ebx, [@@y]
		jmp @@move

	@@dont_move:		;; if the sprite collided with a horizontal border, 1 will be returned
		mov eax, 1
		jmp @@end

	@@dont_move_vertical:	;; if the sprite collided with a vertical border, 2 will be returned
		mov eax, 2
		jmp @@end

	@@move:
		add [ebx], edi

	@@end:
	ret
endp moveSprite


;--------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                                                        ;;;;;
;;;;;                   Make, draw and move enemies                          ;;;;;
;;;;;                                                                        ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;INITIALIZE TOYS AT START LEVEL;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Determine how many toys are required for this level (level * TOYS_TIMES_LEVEL) and make toys.
;; There is a maximum of 6 toys per row so they can fit in the screen.
proc make_all_toys
	uses eax, ebx, edx
	
	mov ebx, [level]
	mov eax, TOYS_TIMES_LEVEL		
	xor edx, edx
	mul ebx
	cmp eax, MAX_TOYS_PER_ROW*ROWS_WITH_TOYS
	jl @@initialize

	mov eax, MAX_TOYS_PER_ROW*ROWS_WITH_TOYS
	
	@@initialize:
	mov [current_amount_of_toys], eax
	call initialize_toys, eax
	
	ret
endp make_all_toys

;--------------------------------------------------------

;;Make the requested amount of toys (=the argument number)
proc initialize_toys
	arg @@number:dword
	uses eax, ebx, ecx, edx, edi, esi
	
	mov edi, offset enemyArray
	mov ecx, [@@number]
	mov ebx, size enemyobj
	
	@@make_toys:
		; row = (ROWS_WITH_TOYS/(ecx-1)) + 1. (+1 so the most upper line has no toys)
		mov esi, ROWS_WITH_TOYS
		xor edx, edx
		mov eax, ecx
		dec eax					
		div esi 
		inc edx
		;; modulo = which row in the game grid
		;; result of division = which element in the row.
		call make_toy, edi, edx, eax
		;; go to next struc in array
		add edi, ebx
	loop @@make_toys
	
	ret
endp initialize_toys

;--------------------------------------------------------

; make one toy
proc make_toy
	;line = the line on which the element has to be
	;times_x: prevents toys on the same line from having the same position.
	arg @@struc:dword, @@line:dword, @@times_x:dword 
	uses eax, ebx, ecx, edx, edi, esi
		
	mov ebx, [@@struc]

	; All toys are valid (have to move and be drawn on the screen)
	mov [ebx + enemyobj.valid], 1

	;y =(SPACE_BETWEEN_SPRITES_VERTICALLY*SPRITEHEIGHT * line) - SPRITEHEIGHT
	mov eax, [@@line]
	mov edx, SPACE_BETWEEN_SPRITES_VERTICALLY*SPRITEHEIGHT			;;Leave room between rows with toys
	mul edx
	sub eax, SPRITEHEIGHT			;;Let toys start one row below gamevariables (level, timer, lives)
	mov [ebx + enemyobj.y], eax
	
	; x = border + (SPRITEWIDTH*SPACE_BETWEEN_SPRITES_HORIZONTALLY * the i'th element on the line)
	; Even or odd line determines direction and sprites. 
	mov eax, [@@times_x]
	mov edx, SPACE_BETWEEN_SPRITES_HORIZONTALLY*SPRITEWIDTH
	mul edx

	; Check least significant bit -> 1 = odd, 0 = even.
	mov ecx, [@@line]
	test ecx, 1
	jnz @@odd

	;;even line: enemy is a seahorse that moves to the left and is drawn on the right side of the screen
	mov [ebx + enemyobj.dir], LEFT
	mov [ebx + enemyobj.sprite], offset seahorse

	mov ecx, SCRWIDTH-SPRITEWIDTH
	sub ecx, eax
	mov eax, ecx
	
	jmp @@put_x
	
	@@odd: 
	; odd line: enemy is a dolphin that moves to the right and is drawn on the left side of the screen
	mov [ebx + enemyobj.dir], RIGHT
	mov [ebx + enemyobj.sprite], offset dolphin

	@@put_x:
	mov [ebx + enemyobj.x], eax

	@@done:
	ret
endp make_toy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; MOVE ENEMIES ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; moving an enemy (works for enemy toy as well enemy bullet)
PROC moveEnemy
	ARG @@enemy: dword
	USES eax, ebx, ecx, edx, edi, esi
	
	; check if toy is valid (invalid toys don't have to be moved)
	mov edi, [@@enemy]
	cmp [edi + enemyobj.valid], 0
	je @@done

	mov ebx, [edi + enemyobj.dir]
	lea eax, [edi + enemyobj.x]
	lea edx, [edi + enemyobj.y]
	mov ecx, [speed]
	call moveSprite, eax, edx, ecx, ebx
	cmp eax, 1				;; if the sprite hit a horizontal border, it means it is an enemy and its direction will change
	je @@changeDirection
	cmp eax, 2				;; if the sprite hit a vertical border, it means it is a bullet and it needs to be disabled.
	je @@make_invalid
	jmp @@done

	@@make_invalid:
		mov [edi + enemyobj.valid], 0
		jmp @@done

	@@changeDirection:
		cmp [edi + enemyobj.dir], LEFT
		jne @@turnLeft
		mov [edi + enemyobj.dir], RIGHT
		mov [edi + enemyobj.x], 0 		; fixes sprite movement with certain speeds
		jmp @@done
		@@turnLeft:
			mov [edi + enemyobj.dir], LEFT
			mov [edi + enemyobj.x], SCRWIDTH-SPRITEWIDTH ; fixes sprite movement with certain speeds
			jmp @@done


	@@done:
	ret
ENDP moveEnemy

;---------------------------------------------------------------
proc shoot_bullet
	; toy = struc of toy which counter has to be decreased and has to shoot
	ARG @@toy: dword
	USES eax, ebx, ecx, edx, edi
	
	mov edi, [@@toy]

	;;enemy has to be valid and a toy. Toys move left or right (= 0 or 1)
	cmp  [edi + enemyobj.valid], 0
	je @@dont_shoot
	cmp  [edi + enemyobj.dir], 1
	jg @@dont_shoot

	;;When counter = 0, fire bullet and reset counter
	;find invalid bullet (valid = 0) in array of bullets
	mov ebx, offset enemyArray
	mov ecx, NUMBEROFENEMIES 
	
	@@find_bulletstruc:
		cmp [ebx + enemyobj.valid], 0
		je @@make_bullet
		add ebx, size enemyobj
		loop @@find_bulletstruc
	jmp @@no_bullet_made ;If no invalid enemy is found, no new bullet is made
	
	@@make_bullet:
	; x and y are the same als the toy who shoots
	mov eax, [edi + enemyobj.x]
	mov [ebx + enemyobj.x], eax
	mov eax, [edi + enemyobj.y]
	add eax, SPRITEHEIGHT
	mov [ebx + enemyobj.y], eax

	;sprite is bullet, direction is down
	mov [ebx + enemyobj.sprite], offset bullet
	mov [ebx + enemyobj.dir], DOWN
	mov [ebx + enemyobj.valid], 1
	
	@@no_bullet_made:

	@@dont_shoot:
	
	ret
endp shoot_bullet

;--------------------------------------------------------
proc drawEnemy
	ARG @@enemy: dword
	USES eax, ebx, ecx, edx, edi, esi

	; check if toy is valid (invalid toys don't have to be drawn)
	mov edi, [@@enemy]
	cmp [edi + enemyobj.valid], 0
	je @@done

	mov ebx, [edi + enemyobj.dir]

	; If dir is right, the sprite is flipped. Otherwise it is normal
	cmp ebx, RIGHT						
	je @@drawFlippedSprite
	jmp @@drawSprite                  
	
	@@drawSprite:
		call drawSprite, [edi + enemyobj.sprite], [edi + enemyobj.x], [edi + enemyobj.y]
		jmp SHORT @@done
	
	@@drawFlippedSprite:
		call drawFlippedSprite, [edi + enemyobj.sprite], [edi + enemyobj.x], [edi + enemyobj.y]

	@@done:
	ret
endp drawEnemy

; loop to move and draw all enemies
proc moveEnemies
	ARG @@arr: dword
	USES eax, ebx, ecx, edx

	mov eax, [@@arr]
	mov ecx, NUMBEROFENEMIES
	mov ebx, size enemyobj 

	@@loop_over_array:
		call moveEnemy, eax
		call drawEnemy, eax
		add eax, ebx
		loop @@loop_over_array
	ret
endp moveEnemies

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                                                        ;;;;;
;;;;;                               Powerups                                 ;;;;;
;;;;;                                                                        ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; a prcocedure to make a powerup wannabe
proc make_powerup
	uses eax, ebx, ecx

	;; the x position of the powerup is randomly generated (according to the game logic)
	call generate_random_x
	mov [powerup1.x], eax
	;; the y position of the powerup is randomly generated (should be on one of the free rows)
	call generate_powerup_y
	mov [powerup1.y], eax
	
	;; generate a random powerup sort
	call rand_in_range, LOWEST_POWERUP, HIGHEST_POWERUP
	mov [powerup1.sort], eax
	;; show the powerup icon on the screen
	mov [powerup1.shown], 1
    
	;; determine which sprite is the correct one
	;; the sprite = (eax*SPRITESIZE) + heart_powerup
	;; because heart_powerup is the very sprite of the powerups in the dataseg
	dec eax
	mov ebx, offset heart_powerup
	mov ecx, SPRITESIZE
	mul ecx
	add ebx, eax
	mov [powerup1.sprite], ebx

	@@end:
	ret
endp make_powerup

;; draw the powerup icon that the player needs to catch (the powerup wannabe)
proc draw_powerup
	ARG @@pup: dword
	USES eax

	mov eax, [@@pup]
	cmp [eax + powerup.shown], 0
	je @@dont_draw
	call drawSprite, [eax + powerup.sprite], [eax + powerup.x], [eax + powerup.y]

	@@dont_draw:
	ret
endp draw_powerup

;; check whether the player "hit", e.g. caught the powerup icon
;; if so, activate the powerup 
proc player_caught_powerup
	uses eax

	;; if powerup is not shown, the player cannot catch it (the powerup is not (yet) activated)
	cmp [powerup1.shown], 0
	je @@end
	call CheckforCollision, [duck1.x], [duck1.y], [powerup1.x], [powerup1.y]
	test eax, eax
	jz @@end
	;; collision has occured
	call deactivate_powerup_wannabe
	call activate_powerup


	@@end:
	ret
endp player_caught_powerup


proc activate_powerup
	uses eax, ebx, ecx

	;; retrieve the powerup information (its timer/counter) from the array that has these informations
	mov eax, [powerup1.sort]
	dec eax
	mov ebx, NEXTDD
	mul ebx
	add eax, offset active_powerups 
	mov ecx, [eax]
	;; activate the powerup
	mov [powerup1.active], ecx

	;; indicate the powerup is on
	cmp [powerup1.sort], FREEZINGPUP
	je @@change_grey
	cmp [powerup1.sort], SHIELD_PUP
	je @@change_yellow
	jmp @@end

	@@change_grey:
		call change_color_palette, GREY, R_RED, G_RED, B_RED
		jmp @@end

	@@change_yellow:
		call change_color_palette, YELLOW, R_BROWN, G_BROWN, B_BROWN

	@@end:

	ret
endp activate_powerup

;; dont show the powerup icon any more
proc deactivate_powerup_wannabe
	uses eax

	cmp [powerup1.shown], 0
	je @@end
	mov eax, 0
	mov [powerup1.shown], eax

	@@end:
	ret
endp deactivate_powerup_wannabe

;; check whether the powerup is timer based or level based
;; powerups represented with even numbers are level based
;; powerusp represented with odd numbers are time based
proc is_powerup_timer_based
	ARG @@powerup: dword
	USES ebx
	mov ebx, [@@powerup]
	test ebx, 1
	jz @@is_levelbased
	jmp @@is_timerbased

	@@is_levelbased: ;; even
		mov eax, 1
		jmp @@end
		
	@@is_timerbased: ;; odd
		mov eax, 0

	@@end:
	ret
endp is_powerup_timer_based

macro test_and_reduce which_powerup

	mov eax, offset powerup1
	cmp [eax + powerup.shown], 1
	je @@end
	cmp [eax + powerup.sort], which_powerup
	jne @@end
	cmp [eax + powerup.active], 0
	je @@deactivate
	dec [eax + powerup.active]
	jz @@deactivate
	jmp @@end

endm test_and_reduce

;; reduce the counter of the currently active level based powerup/deactivate
proc update_level_based_powerup
	uses eax, ebx

	mov ebx, [powerup1.sort]
	call is_powerup_timer_based, ebx
	test eax, eax
	jz @@end
	test_and_reduce ebx

	@@deactivate:
	mov [eax + powerup.sort], 0
	call change_color_palette, GREY, R_GREY, G_GREY, B_GREY

	@@end:
	ret
endp update_level_based_powerup

;; reduce the timer of the current active time based powerup/deactivate 
proc update_timer_based_powerup
	uses eax, ebx

	mov ebx, [powerup1.sort]
	call is_powerup_timer_based, ebx
	test eax, eax
	jnz @@end
	test_and_reduce ebx

	@@deactivate:
	mov [eax + powerup.sort], 0
	call change_color_palette, YELLOW, R_YELLOW, G_YELLOW, B_YELLOW

	@@end:
	ret
endp update_timer_based_powerup

;; activate the powerup icon that the player needs to catch
proc activate_powerup_wannabe
	USES eax
	cmp [powerup1.shown], 0
	jne @@end
	cmp [powerup1.active], 0
	jne @@end
	mov eax, [powerup_timer]
	cmp [timer], eax
	je @@activate_powerup
	jmp @@end

	@@activate_powerup:
		call make_powerup

	@@end:
	ret
endp activate_powerup_wannabe
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                                                        ;;;;;
;;;;;                               Collision                                ;;;;;
;;;;;                                                                        ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

macro test_collision inc_value
	; Prepare_coords
	mov ecx, edi
	add ecx, inc_value			;objOneRight (x + SPRITEWIDTH) and objOneBottom (y + SPRITEHEIGHT)
	mov edx, ebx
	add edx, inc_value			;objTwoRight and objTwoBottom

	;; First test: objOneRight >objTwoLeft and third test: objOneBottom > objTwoTop
	cmp ecx, ebx
	jle @@no_collision

	;; Second test: objOneLeft < objTwoRight and fourth test: objOneTop < objTwoBottom
	cmp edi, edx
	jge @@no_collision
endm test_collision

;; Checks for collision between two objects. This procedure takes the x and y coordinates of the 
;; objects as argument.
;; Collision detection algorithm: https://happycoding.io/tutorials/processing/collision-detection
;; There is a collision between obj1 and ob2 when the four following conditions are true:
;;    * x1 + SPRITEWIDTH > x2
;;    * x1 < x2 + SPRITEWIDTH
;;    * y1 + SPRITEHEIGHT > y2
;;    * y1 < y2 + SPRITEHEIGHT
proc CheckforCollision
    ARG @@obj_x: dword, @@obj_y: dword, @@antiobj_x: dword, @@antiobj_y:dword
    USES ebx, ecx, edx, edi
	
	; Prepare x
    mov edi, [@@obj_x]			;objOneLeft
    mov ebx, [@@antiobj_x]		;objTwoLeft
		
	test_collision SPRITEWIDTH

	; Prepare y
    mov edi, [@@obj_y]			; objOneTop
    mov ebx, [@@antiobj_y]		; objTwoTop

	test_collision SPRITEHEIGHT

	jmp @@collision

    @@no_collision:			;; no collision has occured, so eax is 0 (the ret value)
		xor eax, eax
        jmp @@end

    @@collision:			;; a collision has occured, so eax is 1
        mov eax, 1
        
    @@end:
        ret
endp CheckforCollision

;; check whether a collision has occured between a player and an enemy
proc playerHitEnemy
    ARG @@player: dword, @@enemy: dword
    USES eax, ebx, ecx, edx, edi, esi

    mov ebx, [@@player]
    mov edi, [ebx + player.x]         
    mov ebx, [ebx + player.y]       

    mov edx, [@@enemy]               
    mov ecx, NUMBEROFENEMIES 
	
    @@check_all_enemies:
		cmp [edx + enemyobj.valid], 0	;; if the current object is not valid, check the next object
		je @@checknext
        mov eax, [edx + enemyobj.x]
        mov esi, [edx + enemyobj.y]
        call CheckforCollision, edi, ebx, eax, esi
        test eax, eax
        jnz @@collision
		@@checknext:
        add edx, size enemyobj		;; go to the next object in the array
        loop @@check_all_enemies
		jmp @@end
    
    @@collision:
		cmp [edx + enemyobj.dir], 1	;; if object is moving horizontally (Right = 1, left = 0), it means it is an enemy toy
		jle @@skip_deleting
		mov [edx + enemyobj.valid], 0	;; delete the bullet when a collision has occured
		@@skip_deleting:
        dec [lives] 
		call deactivate_powerup_wannabe
        call resetPlayerPosition
        call resetTimer
		

	@@end:
    
    ret
endp playerHitEnemy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                                                        ;;;;;
;;;;;                                  Timer                                 ;;;;;
;;;;;                                                                        ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; when a collision has occured, or when the player goes to the next level, the timer is reset
proc resetTimer
	mov [timer], INITIAL_TIMER
	ret
endp resetTimer


;; the bar at the top of the screen that represents the timer
proc draw_timer_rects
	uses eax, ecx

	mov ecx, [timer_divided]
	cmp ecx, 0
	je @@skip

	@@rects_drawing_loop:
		;; x of a rectangle = the position of the very first rectangle of the bar + ecx* width of a rectangle
		mov eax, TRECT_W
		mul ecx
		
		add eax, INITIAL_TRECT_X
		call drawRectangle, eax, TRECT_Y, TRECT_H, TRECT_W, TRECT_COLOR

	loop @@rects_drawing_loop

	@@skip:

	ret
endp draw_timer_rects

;; when the timer decreases, a rectangle from the bar is removed
proc reduce_divided_timer
	uses eax, ebx, edx, ecx
	
	mov ecx, [timer_divided]
	mov eax, [timer]
	xor edx, edx
	;; timer is x00, to get x we have to divide by 100
	mov ebx, 100
	div ebx
	cmp eax, ecx
	;; if x is equal to the divided timer, it means that the timer is still in the divided_timer*100
	;; in other words, the timer didnt "decrease"
	je @@nothing_changed
	;; remove the last rectangle from the bar when the timer decreases

	mov [timer_divided], eax
	
	@@nothing_changed:

	ret
endp reduce_divided_timer

;; reduce the timer in each game loop
;; returns in edx 1 if timer is up, otherwise 0
proc reduce_timer
	arg returns edx
	uses eax
	;; if timer is up, the game gets harder
	;; (the player goes to the next level, but without increasing his score)
	cmp [timer], 0
	je @@time_is_up
	dec [timer]
	call reduce_divided_timer
	jmp @@timer_running

	@@time_is_up:
		mov edx, 1
		jmp @@end

	@@timer_running:
		xor edx, edx
	
	@@end:

ret
endp reduce_timer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;                                                                        ;;;;;
;;;;;                             Other procs                                ;;;;;
;;;;;                                                                        ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; load all sprites to memory
proc loadAllSprites
	uses eax, ebx, ecx

	mov eax, offset spritepaths
	mov ebx, offset duck
	mov ecx, NUMBEROFSPRITES

	@@open_and_load:
		call openFile, eax
		call readChunk, ebx
		call closeFile
		add eax, PATHSIZE	;; next path
		add ebx, SPRITESIZE	;; next memory chunk for the next sprite
		loop @@open_and_load

	ret
endp loadAllSprites


proc draw_player
	call drawSprite, [duck1.sprite], [duck1.x], [duck1.y]
	ret
endp draw_player


;; drawing the game
PROC drawGame
	call fillBackground, GAME_BGCOLOR
	;; this rectangle is the background of the upper line where the game values are displayed
	call drawRectangle, 0, 0, UPPER_LINE_HEIGHT, SCRWIDTH, UPPER_LINE_COLOR
	call draw_level_and_lives_string
	call draw_player
	call draw_timer_rects
	call draw_game_values, offset level, offset lives, offset timer_divided
	call draw_powerup, offset powerup1

	ret
ENDP drawGame


proc process_input
	ARG @@input: dword
	uses eax, ebx, ecx, edx

	mov eax, [@@input]
	cmp eax, 1	;; if the input is 1 or less, it means the duck is moving horizontally
	jg @@vert
	mov edx, INCUNIT_HORIZ
	jmp @@after

	@@vert:
	mov edx, INCUNIT_VERT

	@@after:
	lea ebx, [duck1.x]
	lea ecx, [duck1.y]
	call moveSprite, ebx, ecx, edx, eax


    ret
endp process_input

;; check whether one or more relevant key is pressed
proc listen_to_input
	uses ebx, edx, ecx

	mov ecx, KEYCNT

	@@loopkeys:
		mov edx, ecx
		dec edx
		movzx ebx, [byte ptr relevant_keys + edx]
		mov bl, [offset __keyb_keyboardState + ebx]
		xor ax, ax
		sub ax, bx	; if key is pressed, AX = FFFF, otherwise AX = 0000
		test ax, ax
        jz @@no_key_pressed
		call process_input, edx
        @@no_key_pressed:
		loop  @@loopkeys


	ret
endp listen_to_input

;; handling all the input during the game, and updating the timer responsible for the delay
proc handleInput
	ARG RETURNS esi
	uses ebx

	test esi, esi
	jg @@skip_input
	call listen_to_input
	mov esi, INPUT_DELAY
	@@skip_input:
	mov bl, [__keyb_rawScanCode]
	cmp bl, ESC_KEY
	jne @@end

	@@closeGame:
		call closeGame

	@@end:

	ret
endp handleInput

;; increment the speed of the enemy toys each new level
PROC incr_speed 
	uses eax

	mov eax, [level]
	test eax, 1
	jnz @@dont_inc_speed
	cmp [speed], MAXSPEED
	jg @@dont_inc_speed
	inc [speed]

	@@dont_inc_speed:
	ret

ENDP incr_speed


;; initialize the game values each level
proc init_game_logic_vars

	mov [lives], NUMBER_OF_LIVES
	mov [level], INITIAL_LEVEL
	mov [speed], INITIAL_SPEED
	mov [timer], offset timer

	ret
endp init_game_logic_vars


;; generates a random x position (according to the game logic)
proc generate_random_x
	uses ebx, edx

	call rand_in_range, 0, (SCRWIDTH - SPRITEWIDTH)/SPRITEWIDTH 
	mov ebx, SPRITEWIDTH
	mul ebx
	xor edx, edx

	ret
endp generate_random_x

;; generates a random y position (according to the game logic)
proc generate_random_y
	uses ebx, edx

	call rand_in_range, 0, (SCRHEIGHT-SPRITEHEIGHT)/SPRITEHEIGHT
	mov ebx, SPRITEHEIGHT
	mul ebx
	xor edx, edx

	ret
endp generate_random_y

;; generates a random y position for the powerup icon
;; powerups only appear on rows where there are no toys
proc generate_powerup_y
	;returns in eax
	USES ebx, ecx, edx  
	
	;row 0 holds the gamevariables (level, timer, lives), so there are no powerups on this row
	call rand_in_range, 1, ROWS_WITH_TOYS 	

	;y = TOYS_Y_OFFSET * line
	mov edx, TOYS_Y_OFFSET
	mul edx

	ret
endp generate_powerup_y


;; determines when the powerup will show up during the level
proc rand_powerup_show_time

	call rand_in_range, 0, POWERUPFERQ
	mov [powerup_timer], eax

	ret
endp rand_powerup_show_time

;; A random toy shoots a bullet at a random time
proc rand_bullet
	USES eax, ebx
	call rand_in_range, 0, BULLETFREQUENCY
	cmp eax, 0
	jne @@done
	; let random toy shoot bullet
	call rand_in_range, 1, [current_amount_of_toys]
	mov ebx, size enemyobj
	mul ebx
	mov ebx, offset enemyArray
	add ebx, eax
	call shoot_bullet, ebx

	@@done:
	ret
endp rand_bullet

proc make_all_enemies_invalid
	USES eax, ebx, ecx
	
	mov ebx, offset enemyArray
	mov ecx, NUMBEROFENEMIES
	mov eax, size enemyobj
	
	@@put_enemies_in_array:
		mov [ebx + enemyobj.valid], 0
		add ebx, eax
		loop @@put_enemies_in_array
	ret
endp make_all_enemies_invalid

;; updating the positions of the game elements
;; updating the different game values, taking care of the interactions between the game elements
;; e.g. collision detection, powerup (de)activation, etc. 
proc updateGameStatus
	uses eax

	call activate_powerup_wannabe
	call player_caught_powerup
	call update_timer_based_powerup

	call moveEnemies, offset enemyArray

	cmp [powerup1.active], 0
	je @@powerup_not_active
	mov eax, [powerup1.sort]
	cmp eax, HEARTPUP
	jne @@skip_incr
	@@increment_lives:
		inc [lives]
	@@skip_incr:
	cmp eax, FREEZINGPUP
	je @@skip_timer
	;; if timer is up, the game gets harder
	;; (the player goes to the next level, but without increasing his score)
	@@powerup_not_active:
	call reduce_timer
	test edx, edx 
	jz @@skip_timer ;; if timer is up, edx = 1
	@@time_is_up:
	call time_is_up
	@@skip_timer:
	cmp eax, SHIELD_PUP
	je @@skip_collision
	call playerHitEnemy, offset duck1, offset enemyArray
	@@skip_collision:

	call rand_bullet
	dec esi

	ret
endp updateGameStatus


;; initializing a new level
proc make_level

	call deactivate_powerup_wannabe
	call update_level_based_powerup
	call make_all_enemies_invalid
	call incr_speed
	call make_all_toys
	call resetTimer
	call rand_powerup_show_time

	ret
endp make_level

;; the actions when timer is up
proc time_is_up

	dec [lives] 
	call resetPlayerPosition
	call make_level

	ret
endp time_is_up

;; disabling the powerup
proc terminate_powerup
	mov [powerup1.active], 0

	ret
endp terminate_powerup

proc initialize_game

	;; the delay input counter
	;; used to delay the input whenever an input is given
	;; to avoid the duck moves 10 times after each other
	xor esi, esi
	call init_game_logic_vars
	call terminate_powerup

	ret
endp initialize_game

;; close the game and terminate the program
proc closeGame
	call __keyb_uninstallKeyboardHandler
	call terminateProcess
	
	ret
endp closeGame

proc new_highest_level
	uses eax, ebx
	mov eax, [level]
	mov ebx, [highest_level]
	cmp eax, ebx
	jle @@end

	@@new_highest:
		mov [highest_level], eax

	@@end:

	ret
endp new_highest_level

;; listen to input in the start and end screen
proc listen_to_input_in_menus
	xor eax, eax
	mov bl, [__keyb_rawScanCode]
	cmp bl, ENTER_KEY
	je @@startgame
	cmp bl, ESC_KEY
	je @@exit
	jmp @@end

	@@startgame:
		mov eax, 1
		jmp @@end
	
	@@exit:
		call closeGame

	@@end:

	ret
endp listen_to_input_in_menus

;;------------ The game ----------;;
PROC main
	sti
	cld
	
	push ds
	pop	es

	call    rand_init
	call setVideoMode, 13h
	;; listen to keyboard input
	call __keyb_installKeyboardHandler
	call change_color_palette, BLACK, R_BLACK, G_BLACK, B_BLACK
	call loadAllSprites

	@@start_menu_loop:
		CALL wait_VBLANK
		CALL display_start_screen
		call listen_to_input_in_menus
		test eax, eax
		jnz @@Initializegameloop
		jmp @@start_menu_loop

	@@Initializegameloop:
		call initialize_game
		
	@@makelevel:
		call make_level
		
	@@gameloop:
		call wait_VBLANK
		call drawGame
		call handleInput
		call updateGameStatus
		;; game is done when player has no more lives left
		cmp [lives], DEAD
		je @@end
		cmp [duck1.y], TOP ; level ends when duck reaches top
		jle @@nextlevel
		jmp @@gameloop

	@@nextlevel:
	;; increase level, reset player to bottom of screen and start next level
		inc [level] 
		call resetPlayerPosition 
		jmp @@makelevel
	
	@@end:
		mov ecx, [level]
		mov edx, [highest_level]
		xor esi, esi
		cmp ecx, edx	;; check whether the achieved level a new high level is
		jle @@end_menu_loop

	@@new_highest:					;; new high level
		mov [highest_level], ecx	;; set the high level to the achieved level
		mov edx, ecx
		mov esi, 1

	@@end_menu_loop:
		CALL wait_VBLANK
		CALL dispay_end_screen, ecx, edx
		test esi, esi
		jz @@no_congrats
		;; display a congrats message if a new high level is achieved
		call display_congrats	
		@@no_congrats:
		call listen_to_input_in_menus
		test eax, eax
		jnz @@Initializegameloop
		jmp @@end_menu_loop

ENDP main

DATASEG
	spritepaths db "duck.bin", 0
			   	db "seah.bin", 0
			   	db "dolp.bin", 0
			  	db "hpup.bin", 0
			   	db "fpup.bin", 0
			   	db "spup.bin", 0
			   	db "bull.bin", 0
	
	duck1 player <INIT_X_PLAYER, INIT_Y_PLAYER, offset duck>
	powerup1 powerup <0, 0, 0, 0, 0, 0>
	
	lives dd NUMBER_OF_LIVES
	level dd INITIAL_LEVEL
	highest_level dd 0

	enemyArray enemyobj NUMBEROFENEMIES dup (<0,0,0,0>)	
	current_amount_of_toys dd 0
	speed dd INITIAL_SPEED
	timer dd INITIAL_TIMER
	timer_divided dd INITIAL_DIVIDED_TIMER

	powerup_timer dd 0

	active_powerups dd NUMBER_OF_ADDED_LIVES+1, FREEZING_CTR, SHIELD_TIMER

	relevant_keys db LEFT_KEY, RIGHT_KEY, DOWN_KEY, UP_KEY
	
	STACK 200h


UDATASEG
	duck db SPRITESIZE dup (?)
	seahorse db SPRITESIZE dup (?)
	dolphin db SPRITESIZE dup (?)

	heart_powerup db SPRITESIZE dup (?)
	freezing_powerup db SPRITESIZE dup (?)
	shield_powerup db SPRITESIZE dup(?)

	bullet db SPRITESIZE dup (?)
		
END main