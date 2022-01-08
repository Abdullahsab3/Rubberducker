IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT


INCLUDE "FILEH.INC"
INCLUDE "genl.inc"
INCLUDE "cons.inc"


CODESEG

;-----------------------------------------------------------
; opens file, returns file handle in ax

;; HOE GEBRUIKEN: 
; 1- open het bestand met openfile (het argument is het pad naar bestand, zie gameloop voor voobeeld)
; 2- readchunk gaat de inhoud van het bestand kopieren naar het adres dat je als arg meegeeft.
; 3- nu kan je dat adres gebruiken.
PROC openFile
	ARG @@filename: dword
	USES eax, ebx, ecx, edx
	mov al, 0 ; read only
	mov edx, [@@filename]
	mov ah, 3dh
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset openErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	mov [filehandle], ax
	ret
ENDP openFile

PROC readChunk
	ARG @@destadr: dword
	USES eax, ebx, ecx, edx
	mov bx, [filehandle]
	mov cx, SPRITESIZE
	mov edx, [@@destadr]
	mov ah, 3fh
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset readErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	ret
ENDP readChunk

; closes file
PROC closeFile
	USES eax, ebx, ecx, edx
	mov bx, [filehandle]
	mov ah, 3Eh
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset closeErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	ret
ENDP closeFile

DATASEG
    openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'

UDATASEG
	filehandle dw ?

END