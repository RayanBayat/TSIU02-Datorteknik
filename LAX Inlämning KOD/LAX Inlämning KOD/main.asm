	.equ	E = 1
	.equ	RS = 0
	.equ	HOME = 0
	.equ	FN_SET = $28
	.equ	DISP_ON = $0C
	.equ	LCD_CLR = $01
	.equ	E_MODE = $06
	.equ	CURSOR =$3

	sbi     DDRB,2
    sbi     DDRB,E
    sbi     DDRB,RS
    sbi     DDRD,7
    sbi     DDRD,6
    sbi     DDRD,5
    sbi     DDRD,4
	call	LCD_INIT	






START:

	clr		r18 
	ldi		r16 , $2A
	call	LCD_ASCII
L0 :
	call	DISP_W
	
L0_KEY :
	
	call	KEY_READ
	cpi		r16 ,1
	breq	LAX

	cpi		r16 ,5
	breq	L0_RIGHT
	cpi		r16 ,2
	breq	L0_LEFT
	jmp		L0_KEY
L0_RIGHT :
	inc		r18
	cpi		r18 ,6
	brne	L0
	ldi		r18 ,5
	jmp		L0
L0_LEFT :
	dec		r18
	cpi		r18,0
	brge	L0
	ldi		r18,0
	jmp		L0
DISP_W :
	call	LCD_HOME
	ldi		r19,-1
DISP_W_NEXT :
	cp		r19 , r18
	brge	DISP_W1
	jmp		DISP_W_SPACE
DISP_W1 :
	cp		r18 , r19
	brge	DISP_W_ASTER
	jmp		DISP_W_EXIT
DISP_W_SPACE :
	ldi		r16 , $2A
	jmp		DISP_W_COMMON
DISP_W_ASTER :
	ldi		r16 , $20
DISP_W_COMMON :
	call	LCD_ASCII
	inc		r19
	jmp		DISP_W_NEXT
DISP_W_EXIT :
	ret

LAX:
	call	LCD_ERACE
	call	LCD_HOME
	jmp		START
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
	call	LCD_COL
	ret
BACKLIGHT_ON:
	sbi		PORTB, 2
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
	call	LCD_HOME
LCD_HOME:
	ldi		r16, HOME
	call	LCD_COL
	sbi		PORTB,RS
	ret
LCD_COL:	
	subi	r16,-$80
	call	LCD_COMMAND
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
	call	ADC_READ8
	cpi		r16,12
	brlo	OUTPUT1V
	cpi		r16,42
	brlo	OUTPUT0V
	cpi		r16,81
	brlo	OUTPUT0V
	cpi		r16,129
	brlo	OUTPUT4V
	cpi		r16,206
	brlo	OUTPUT5V
	cpi		r16,207
	brge	OUTPUT0V
OUTPUT1V:
	ldi		r16,5
	jmp		KEYEXIT


OUTPUT4V:
	ldi		r16,2
	jmp		KEYEXIT
OUTPUT5V:
	ldi		r16,1
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