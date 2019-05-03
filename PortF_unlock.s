GPIO_PORTF_DATA  	EQU 0x400253FC
GPIO_PORTF_DIR   	EQU 0x40025400
GPIO_PORTF_IM		EQU 0x40025410
GPIO_PORTF_RIS		EQU 0x40025414
GPIO_PORTF_MIS		EQU 0x40025418
GPIO_PORTF_ICR		EQU 0x4002541C
GPIO_PORTF_AFSEL 	EQU 0x40025420
GPIO_PORTF_PUR   	EQU 0x40025510
GPIO_PORTF_DEN   	EQU 0x4002551C
GPIO_PORTF_LOCK  	EQU 0x40025520
GPIO_PORTF_CR   	EQU 0x40025524
GPIO_PORTF_AMSEL 	EQU 0x40025528
GPIO_PORTF_PCTL  	EQU 0x4002552C
GPIO_PORTF_PDR 		EQU 0x40025514
	
SYSCTL_RCGCGPIO		EQU 0x400FE608
SYSCTL_PRGPIO		EQU 0x400FEA08	;GPIO Peripheral Ready, pg.406

UNLOCK 				EQU	0x4C4F434B
	
;LABEL		DIRECTIVE		VALUE		COMMENT
			AREA			portf_unlock, CODE, READONLY
			THUMB
			EXPORT		PortF_unlock
				
PortF_unlock	PROC
				PUSH{R0,R1,LR}
				;Start the clock
				LDR R1,=SYSCTL_RCGCGPIO
				LDR R0,[R1]
				ORR R0,R0,#0x20
				STR R0,[R1]
				;poll PR register
				LDR R1,=SYSCTL_PRGPIO
poll_gpio		LDR R0,[R1]					;Wait until the clock settles.
				LSRS R0,#6
				BCC poll_gpio
				;Unlock PortF
				LDR R1,=GPIO_PORTF_LOCK
				LDR R0,=UNLOCK
				STR R0,[R1]
				;Make registers writable
				LDR R1,=GPIO_PORTF_CR
				MOV R0,#0xFF
				STR R0,[R1]
				;Select Directions
				LDR R1,=GPIO_PORTF_DIR		;We need to use SW1 and SW2 as inputs, PF4 - SW1, PF0 - SW2
				LDR R0,[R1]					;and RGB led as output, PF1 - RED, PF2 - BLUE, PF3 - GREEN
				ORR R0,R0,#0x0E				; bit1,2,3 are 1
				BIC R0,R0,#0x11				;bit4 and bit0 are 0
				STR R0,[R1]
				;disable analog functions
				LDR R1,=GPIO_PORTF_AMSEL
				LDR R0,[R1]
				BIC R0,R0,#0x1F
				STR R0,[R1]
				;enable digital
				LDR R1,=GPIO_PORTF_DEN
				LDR R0,[R1]
				ORR R0,R0,#0x1F
				STR R0,[R1]
				;pull-up resistors for buttons
				LDR R1,=GPIO_PORTF_PUR
				LDR R0,[R1]
				ORR R0,R0,#0x11
				STR R0,[R1]
				POP{R0,R1,LR}
				BX LR
			ENDP
		END	
				