;Nested Vector Interrupt Controller registers
NVIC_EN0_INT19		EQU 0x00080000 ; Interrupt 19 enable
NVIC_EN0			EQU 0xE000E100 ; IRQ 0 to 31 Set Enable Register
NVIC_PRI4			EQU 0xE000E410 ; IRQ 16 to 19 Priority Register
	
; 16/32 Timer Registers
TIMER0_CFG			EQU 0x40030000	;pg.727
TIMER0_TAMR			EQU 0x40030004	;pg.729
TIMER0_CTL			EQU 0x4003000C	;pg.737
TIMER0_IMR			EQU 0x40030018	;pg.745
TIMER0_TAILR		EQU 0x40030028 ; Timer interval, pg.756
	
	
;System Registers
SYSCTL_RCGCTIMER 	EQU 0x400FE604 ; GPTM Gate Control
SYSCTL_PRTIMER		EQU 0x400FEA04 ; Peripheral Ready Timer, pg.404

;Value for 8kHz Sampling Rate
TIME_VALUE			EQU 2500	;The Device is initially set to 8kHz frequency
;---------------------------------------------------
					
			AREA 	changetimer, CODE, READONLY
			THUMB
			EXPORT	Change_Timer_Settings
					

Change_Timer_Settings PROC	
				PUSH{R0,R1,LR}
				;Disable Timer During Setup
				LDR R1,=TIMER0_CTL
				LDR R0,[R1]
				BIC R0,R0,#0x01
				STR R0,[R1]
				;Set to 16 bit mode
				LDR R1,=TIMER0_CFG
				MOV R0,#0x04		;0x4 to bit 2:0 selects 16 bit configuration
				STR R0,[R1]
				;Set to periodic count down mode
				LDR R1,=TIMER0_TAMR
				MOV R0,#0x02		;0x2 to bit 1:0 for periodic mode, rest should be 0
				STR R0,[R1]
				;Initialize Clock time
				LDR R1,=TIMER0_TAILR
				LDR R0,=TIME_VALUE
				STR R0,[R1]	
				LDR R1,=TIMER0_IMR ; enable timeout interrupt
				MOV R0,#0x01
				STR R0,[R1]
				;Configure interrupt priorities
				;Timer0A is interrupt #19.
				;Interrupts 16-19 are handled by NVIC register PRI4.
				;Interrupt 19 is controlled by bits 31:29 of PRI4.
				;set NVIC interrupt 19 to priority 2
				LDR R1,=NVIC_PRI4
				LDR R0,[R1]
				AND R0,R0,#0x00FFFFFF ; clear interrupt 19 priority
				ORR R0,R0,#0x40000000 ; set interrupt 19 priority to 2
				STR R0,[R1]
				;NVIC has to be enabled
				;Interrupts 0-31 are handled by NVIC register EN0
				;Interrupt 19 is controlled by bit 19
				;enable interrupt 19 in NVIC
				LDR R1,=NVIC_EN0
				MOVT R0,#0x08 ; set bit 19 to enable interrupt 19
				STR R0,[R1]
				; Enable timer
				LDR R1,=TIMER0_CTL
				LDR R0,[R1]
				ORR R0,R0,#0x03 ; set bit0 to enable
				STR R0,[R1] ; and bit 1 to stall on debug
				POP{R0,R1,LR}
				BX LR ; return
		ENDP
	END