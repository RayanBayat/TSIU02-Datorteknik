	
	
	;H�r kan man �ndra l�ngden p� ljudet
	.equ	M = 20	
	;------------------------------------
	;s�tter stacken
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16

	
	;g�r DDRB 4 till en utg�ngs pin
	sbi     DDRB,4
	
	andi	r24,0
;-------------------------------------------------------
MORSE:
	call	LOOKUP
	call	ISITSPACE
	call	FINDINBTAB
	call	MAKESOUND
	jmp		MORSE
;---------------------------------------------------------
	; Detta �r data och inte instruktioner
 MESSAGE:
	; Ordet som ska k�ra med hj�lp av arduinot
	.db		"RAYBA RAYBA RAYBA",0      
	; Lista �ver bokst�ver fr�n A-Z
 Btab:
    .db $60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$d8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8

	;H�r pekar z p� message som sedan skickas til r16
LOOKUP:
	
    ldi     ZH,HIGH(MESSAGE<<1)
    ldi     ZL,LOW(MESSAGE<<1)
	add		ZL,r24
	

	; vi �kar r24 med 1 f�r att n�sta g�ng kunna peka p� n�sta fr�n bokstav fr�n message
	adiw	r24, 1
    lpm     r16,Z
	; H�r kollar man r16 �r lika med noll och i s�fall betyder detta att allt i message �r l�st
	cpi		r16,0
	breq	end
	ret
ISITSPACE:
	/* vi kollar om byten har v�rdet $20 i asci vilket �r lika med mellanslag, 
	i s�fall pausas ljudet 5*M +2*M sen innan bli 7M och sedan h�mtas ny tecken och programmet forts�tter som det ska
	*/
	ldi		r17,$20
	CPSE	r16,r17
	ret
	push	r20
	clr		r20
	ldi		r20, 5*M
	call	DELAYT
	pop		r20
	call	LOOKUP
	ret
	
FINDINBTAB:	

	; H�r minskar vi r16 med 41 f�r att kunna anv�nda det och l�sa Btab som sedan sparas i r23

	SUBI	r16,$41
  
	CLR		ZH
	CLR		ZL
	
	ldi     ZH,HIGH(Btab<<1)
    ldi     ZL,LOW(Btab<<1)
	add		ZL,r16
	lpm		r16,Z
	
	ret

	; Con har i uppgift att flytta koden till v�nster ett steg och l�sa av vad carry som skickas ut �r
MAKESOUND:
	
	cpi     r16,0
   
    LSL     r16
	
	
	
	
	
	;Om carryn �r lika med nol ska signalen vara dot allts� liten beep annars en dash allts� en l�ngre beep
	ldi		r20, M
	brcc    beep
	ldi		r20, 3*M
	brcs    beep					  ;  
				  ; 
  
beep:
	




	; H�r skickar vi en signalen 1 i I/O registern 4 men en liten delay

	sbi		PORTB,4
	
	
	
	call	DELAYT
	cbi		PORTB,4
	; H�r clearar vi den, allts� sickar signalen 0 i I/O med lite extra delay
	clr		r20
	ldi		r20, M
	call	DELAYT
	
   
    CLR		r25
	MOV		r25,r16
	LSL     r25
	BRNE	MAKESOUND
	clr		r20
	ldi		r20, 2*M
	call	DELAYT
	ret



; H�r kommer delay som vi anv�nda p� f�rra labbar, l�ngen delay skickas som en argument
DELAYT:
	push	r16
	push	r25
	push	r24
	MOV	r16,r20
DELAYT_1:
	adiw	r24,1		
	brne	DELAYT_1
	dec		r16
	brne	DELAYT_1
	pop		r24
	pop		r25
	pop		r16
	ret

; SLutligen kommer man hit och det blir en o�ndligt loop och programmet komemr ingenstans efter denh�r steget
end:
	jmp		end