; 16/32 Timer Registers
TIMER0_CFG			EQU 0x40030000	;pg.727
TIMER0_TAMR			EQU 0x40030004	;pg.729
TIMER0_CTL			EQU 0x4003000C	;pg.737
TIMER0_TAILR		EQU 0x40030028 ; Timer interval, pg.756
	
;System Registers
SYSCTL_RCGCTIMER 	EQU 0x400FE604 ; GPTM Gate Control
SYSCTL_PRTIMER		EQU 0x400FEA04 ; Peripheral Ready Timer, pg.404

;Value for 8kHz Sampling Rate
TIME_VALUE			EQU 2500	;ADC should sample every this count to have 8kHz freq.
;---------------------------------------------------
					
			AREA 	timerinit, CODE, READONLY
			THUMB
			EXPORT	Timer_Init
					

Timer_Init		PROC
				PUSH{R0,R1,LR}
				;Start Timer0 clock
				LDR R1,=SYSCTL_RCGCTIMER
				LDR R0,[R1]
				ORR R0,R0,#0x01
				STR R0,[R1]
				;Poll PR Register, wait for clock to settle
				LDR R1,=SYSCTL_PRTIMER
poll_timer		LDR R0,[R1]
				LSRS R0,#1
				BCC poll_timer
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
				;Enable timer
				LDR R1,=TIMER0_CTL
				LDR R0,[R1]
				ORR R0,R0,#0x23 ; set bit0 to enable
				STR R0,[R1] ; and bit 1 to stall on debug, and bit5 to enable ADC trigger
				POP{R0,R1,LR}
				BX LR ; return
		ENDP
	END