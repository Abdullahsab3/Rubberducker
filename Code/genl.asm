IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "genl.inc"
include "gfx.inc"


CODESEG

; Set the video mode (from Dancer)
PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
	int 10h

	ret
ENDP setVideoMode


; Terminate the program.
PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

;; determines the length of a $ terminated string
;; based on http://www.int80h.org/strlen/
proc strlen 
	ARG @@str: dword
	uses ebx, ecx, edi
    
	mov edi, [@@str]
	sub ecx, ecx
    not  ecx
    sub  al, al
	mov al, '$'
    repne scasb
	not	ecx
	pop	edi
	lea	eax, [ecx-1]
	inc eax ;; $ should also be counted
	ret
endp strlen

DATASEG

END
