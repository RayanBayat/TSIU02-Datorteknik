	.equ	E = 1
	.equ	RS = 0
	.equ	HOME = 0
	.equ	FN_SET = $28
	.equ	DISP_ON = $0E
	.equ	LCD_CLR = $01
	.equ	E_MODE = $06
	.equ	CURSOR =$0

	sbi     DDRB,2
    sbi     DDRB,E
    sbi     DDRB,RS
    sbi     DDRD,7
    sbi     DDRD,6
    sbi     DDRD,5
    sbi     DDRD,4
	call	LCD_INIT
		
MAIN:	
	call	LINE_PRINT
	jmp		MAIN
	.org	$100
	.dseg
	;Detta ?r bokst?verna
CURPOS:
	.byte	1
	.org	$110
ALPHABET:
	.byte	17
	.cseg
DEDAULT:
	.db		$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00
LCD_INIT:
	call	BACKLIGHT_ON
	call	WAIT
	ldi		r16, $30
	call	LCD_WRITE4
	call	LCD_WRITE4
	call	LCD_WRITE4
	ldi		r16, $20
	call	LCD_WRITE4
	ldi		r16, FN_SET
	call	LCD_COMMAND
	ldi		r16, DISP_ON
	call	LCD_COMMAND
	call	LCD_ERACE
	ldi		r16, E_MODE
	call	LCD_COMMAND	
	call	COPY
	call	UPDATE
	call	COPYCURSOR
	call	LCD_COL
	
	
	ret
BACKLIGHT_ON:
	sbi		PORTB, 2
	call	WAIT
	ret
BACKLIGHT_OFF:
	cbi		PORTB, 2
	call	WAIT
	ret
BACKLIGHT_toggle:
	sbi		pinb, 2
	call	WAIT
	ret
LCD_WRITE4:
	sbi		PORTB, E
	out		PORTD, r16
	cbi		PORTB, E
	call	WAIT	
	ret
LCD_WRITE8:
	sbi		PORTB, E
	out		PORTD, r16
	cbi		PORTB, E
	swap	r16	
	sbi		PORTB, E
	out		PORTD, r16
	cbi		PORTB, E
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
	call	LCD_HOME
	call	EXECUTE
	ret
EXECUTE:
	call	KEY_READ
	call	FUNCTIONS
	ret
LCD_PRINT:
	ldi		r16,$80
	call	LCD_COMMAND
	call	UPDATE
	ret
COPY:
	ldi		ZH,HIGH(DEDAULT << 1)		
	ldi		ZL,LOW(DEDAULT<< 1)
	ldi		XH,HIGH(ALPHABET)		
	ldi		XL,LOW(ALPHABET)
	ldi		YH,HIGH(ALPHABET+CURSOR)
	ldi		YL,LOW(ALPHABET+CURSOR)
RR:
	lpm		r16,Z+	
	st		X+,r16
	cpi		r16,$00
	brne	RR
	ret

UPDATE:

	ldi		XH,HIGH(ALPHABET)
	ldi		XL,LOW(ALPHABET)
LOOP:
	ld		r21,X+
	mov		r16,r21
	ldi		r17,0
	cpse	r21,r17
	call	LCD_ASCII
	cpi     r21,$00
	brne	LOOP
	call	LCD_COL
	ret
PLUSCOUNT:
	
	
	ld		r16,Y
	cpi		r16,$20
	brne	LO
	ldi		r16,$40
LO:
	cpi		r16,$5A
	breq	PLUSRECOUNT
	inc		r16
	st		Y,r16
	jmp		EXITPLUSCOUNT
PLUSRECOUNT:
	ldi 	r16,$41
	st		Y,r16
EXITPLUSCOUNT:
	ret

MINUSCOUNT:
	
	ld		r16,Y
	cpi		r16,$42
	brlo	MINUSRECOUNT
	dec		r16
	st		Y,r16
	jmp		EXITMINUSCOUNT
MINUSRECOUNT:
	ldi		r16,$5A
	st		Y,r16
EXITMINUSCOUNT:
	ret

FUNCTIONS:
	cpi		r16,$31
	breq	FUNCTION_TOGGLE
	cpi		r16,$32
	breq	FUNCTION_LEFT
	cpi		r16,$33
	breq	FUNCTION_UP
	cpi		r16,$34
	breq	FUNCTION_DOWN
	cpi		r16,$35
	breq	FUNCTION_RIGHT

FUNCTION_TOGGLE:
	call	BACKLIGHT_TOGGLE
	jmp		FUNCTIONSEXIT
FUNCTION_LEFT:
	call	CURSORLEFT
	jmp		FUNCTIONSEXIT

FUNCTION_UP:
	call	MINUSCOUNT
	call	LCD_PRINT
	call	LCD_COL
	jmp		FUNCTIONSEXIT
FUNCTION_DOWN:
	call	PLUSCOUNT
	call	LCD_PRINT
	call	LCD_COL
	jmp		FUNCTIONSEXIT
FUNCTION_RIGHT:
	call	CORSURRIGHT
	jmp		FUNCTIONSEXIT
FUNCTIONSEXIT:
	ret
ADC_READ8:
    ldi     r16,(1<<REFS0)|(1<<ADLAR)|0
    sts     ADMUX,r16
    ldi     r16,(1<<ADEN)|7
    sts     ADCSRA,r16
CONVERT:
    lds     r16,ADCSRA
    ori     r16,(1<<ADSC)
    sts     ADCSRA,r16
ADC_BUSY:
    lds     r16,ADCSRA
	sbrc    r16,ADSC
    jmp     ADC_BUSY
    lds     r16,ADCH
	ret
KEY:
	call	ADC_READ8
	cpi		r16,12
	brlo	OUTPUT1V
	cpi		r16,42
	brlo	OUTPUT2V
	cpi		r16,81
	brlo	OUTPUT3V
	cpi		r16,129
	brlo	OUTPUT4V
	cpi		r16,206
	brlo	OUTPUT5V
	cpi		r16,207
	brge	OUTPUT0V
OUTPUT1V:
	ldi		r16,$35
	jmp		KEYEXIT
OUTPUT2V:
	ldi		r16,$34
	jmp		KEYEXIT
OUTPUT3V:
	ldi		r16,$33
	jmp		KEYEXIT
OUTPUT4V:
	ldi		r16,$32
	jmp		KEYEXIT
OUTPUT5V:
	ldi		r16,$31
	jmp		KEYEXIT
OUTPUT0V:
	ldi		r16,0
KEYEXIT:
	ret
KEY_READ :
	call	KEY
	tst		r16
	brne	KEY_READ 
KEY_WAIT_FOR_PRESS :
	call	WAIT
	call	KEY
	tst		r16
	breq	KEY_WAIT_FOR_PRESS
	ret
WAIT:
	adiw	r24,1
	brne	WAIT
	ret
LCD_COL:
	ldi		XH,HIGH(CURPOS)
	ldi		XL,LOW(CURPOS)
	ld		r17,X
	ldi		r16,$80
	add		r16,r17
	call	LCD_COMMAND
	ret
COPYCURSOR:
	ldi		XH,HIGH(CURPOS)
	ldi		XL,LOW(CURPOS)
	ldi		r16,CURSOR
	st		X,r16
	
	ret
CORSURRIGHT:
	ldi		XH,HIGH(CURPOS)
	ldi		XL,LOW(CURPOS)
	ld		r16,X
	cpi		r16,15
	breq	EXITCURSORLEFT
	inc		r16
	st		X,r16
	ldi		r16,$14
	call	LCD_COMMAND
	ld		r20,Y+
EXITCURSORRIGHT:	
	ret
CURSORLEFT:
	ldi		XH,HIGH(CURPOS)
	ldi		XL,LOW(CURPOS)
	ld		r16,X
	cpi		r16,0
	breq	EXITCURSORLEFT
	dec		r16
	st		X,r16
	ldi		r16,$10
	call	LCD_COMMAND
	ld		r20,-Y
EXITCURSORLEFT:
	ret





	