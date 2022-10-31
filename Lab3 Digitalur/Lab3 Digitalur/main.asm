	
	.equ	E = 1
	.equ	RS = 0
	.equ	HOME = 0
	.equ	FN_SET = $28
	.equ	DISP_ON = $0C
	.equ	LCD_CLR = $01
	.equ	E_MODE = $06
	.equ	COOLAN = 0
	.org	0
	jmp		COLD
	.org	OC1Aaddr
	jmp		MAIN
	.equ	SEKUND = 62500 - 1
TMR_INIT:
	ldi		r16,(1<<WGM12)|(1<<CS12)
	sts		TCCR1B,r16
	ldi		r16,HIGH(SEKUND)
	sts		OCR1AH,r16
	ldi		r16,LOW(SEKUND)
	sts		OCR1AL,r16
	ldi		r16,(1<<OCIE1A)
	sts		TIMSK1,r16
	ret
MAIN:
	
	call	COUNT
	call	LCD_ERACE
	call	COPYLINE
	call	UPDATE
	reti
COLD:
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16
	sbi     DDRB,2
    sbi     DDRB,E
    sbi     DDRB,RS
    sbi     DDRD,7
    sbi     DDRD,6
    sbi     DDRD,5
    sbi     DDRD,4
	call	LCD_INIT

	call	TMR_INIT
	sei		
AGAIN:
	jmp		AGAIN	
	.dseg
    .org	$110
TIME: 
	.byte	7
	.org	$120
LINE: 
	.byte	9
	.org	$130
MIDNIGHTT:
	.byte	7
	.cseg
	.org	$115
Default:
	.db		5,4,9,5,3,2,-1
MAXIMUM:
	.db		10,6,10,6,10,6,-1 ; H?r styr gr?nserna
COPY:
	clr		r16
	lpm		r16,Z+	
	st		X+,r16
	cpi		r16,-1
	brne	COPY
	ret
COUNT:
	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)
	ldi		YH,HIGH(MIDNIGHTT)
	ldi		YL,LOW(MIDNIGHTT)
	ldi		r18,0
OC:
	ld		r16,X+
	ld		r20,X
	ld		r19,-X
	inc		r18
	inc		r16
	ld		r17,Y+
	cpi		r17,-1
	breq	AB
	mov		r19,r16
	st		X,r16
	clr		r16
	cpi		r18,5
	breq	MIDNIGH
NO:
	cpse	r19,r17
	ret
	st		X+,r16
	cpi		r16,0
	breq	OC
AB:
	ret
MIDNIGH:	
	cpi		r20,2
	brlo	NO	
	ldi		r17,4	
	st		X,r19	
	cpse	r19,r17
	ret
	clr		r19
	st		X+,r19
	st		X,r19	
	RET
LCD_INIT:
	call	BACKLIGHT_ON
	call	WAIT
	ldi		r16, $30
	call	LCD_WRITE4
	call	WAIT
	call	LCD_WRITE4
	call	WAIT
	call	LCD_WRITE4
	call	WAIT
	ldi		r16, $20
	call	LCD_WRITE4
	call	WAIT
	ldi		r16, FN_SET
	call	LCD_COMMAND
	ldi		r16, DISP_ON
	call	LCD_COMMAND
	call	LCD_ERACE
	ldi		r16, E_MODE
	call	LCD_COMMAND
	call	LINE_PRINT
	ret
BACKLIGHT_ON:
	sbi		PORTB, 2
	ret
BACKLIGHT_OFF:
	cbi		PORTB, 2
	ret
LCD_WRITE4:
	sbi		PORTB, E
	out		PORTD, r16
	cbi		PORTB, E	
	ret
LCD_WRITE8:
	call	LCD_WRITE4
	swap	r16	
	call	LCD_WRITE4
	call	WAIT
	ret
LCD_ASCII:
	sbi		PORTB,RS
	call	LCD_WRITE8
	ret
LCD_COMMAND:
	cbi		PORTB,RS
	call	LCD_WRITE8
	ret
LCD_ERACE:
	ldi		r16, LCD_CLR
	call	LCD_COMMAND
LCD_HOME:
	ldi		r16, HOME
	sbi		PORTB,RS
	ret
LINE_PRINT:
	clr		r16
	call	LCD_HOME
	call	LCD_PRINT
	ret
LCD_PRINT:
	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)
	ldi		ZH,HIGH(Default << 1)
	ldi		ZL,LOW(Default << 1)
	call	COPY
	ldi		XH,HIGH(MIDNIGHTT)
	ldi		XL,LOW(MIDNIGHTT)	
	ldi		ZH,HIGH(MAXIMUM << 1)
	ldi		ZL,LOW(MAXIMUM << 1)
	call	COPY
	call	LCD_ERACE
	call	COPYLINE
	call	UPDATE
	ret
COPYLINE:
	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)
	ldi		YH,HIGH(LINE+9)
	ldi		YL,LOW(LINE+9)
	ldi		r24,0
	ldi		r21,-1
	st		-Y,r21	
STILLCOPIYING:		
	cpi		r24,2
	brne	CL
	ldi		r21,$A
	st		-Y,r21
	clr		r24
CL:
	ld		r21,X+
	cpi		r21,-1
	breq	DONE
	st		-Y,r21
	inc		r24
	cpi		r21,-1
	brne	STILLCOPIYING	
DONE:	
	ret
UPDATE:
	ldi		YH,HIGH(LINE)
	ldi		YL,LOW(LINE)
LOOP:
	ld		r21,Y+
	mov		r16,r21
	ldi		r17,$30
	add		r16,r17
	ldi		r17,-1
	cpse	r21,r17
	call	LCD_WRITE8
	cpi     r21,-1
	brne	LOOP
	ret
WAIT:
	adiw	r24,1
	brne	WAIT
	ret