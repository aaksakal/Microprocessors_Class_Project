GPIO_PORTE_DIR   	EQU 0x40024400	;pg.663
GPIO_PORTE_AFSEL 	EQU 0x40024420	;pg.671
GPIO_PORTE_AMSEL 	EQU 0x40024528	;pg.687
	
ADC1_ADCACTSS		EQU 0x40039000	;ADC Active Sample Sequencer Register, pg.821
ADC1_ADCEMUX		EQU	0x40039014	;ADC Event Multiplexer Select Register, pg.833
ADC1_ADCSSMUX3		EQU 0x400390A0	;ADC Sample Sequence Input Multiplexer Select 3 Register , pg.875
ADC1_ADCSSCTL3		EQU 0x400390A4	;ADC Sample Sequence Control Register, pg.876
ADC1_ADCPC			EQU 0x40039FC4	;ADC Peripheral Configuration Register, pg.891

SYSCTL_RCGCADC		EQU	0x400FE638	;ADC clock set, pg.352
SYSCTL_RCGCGPIO		EQU	0x400FE608	;GPIO clock set, pg.340
SYSCTL_PRGPIO		EQU 0x400FEA08	;GPIO Peripheral Ready, pg.406
SYSCTL_PRADC		EQU 0x400FEA38	;ADC Peripheral Ready, pg.418
	
;LABEL		DIRECTIVE		VALUE		COMMENT
			AREA			adcpot, CODE, READONLY
			THUMB
			EXPORT		ADC_POT_Init
				
ADC_POT_Init	PROC
				PUSH{R0,R1,LR}
	;ENABLE GPIO, we will be using PE2 as the input for POT.
				;Enable GPIO_clock
				LDR R1,=SYSCTL_RCGCGPIO
				LDR R0,[R1]
				ORR	R0,R0,#0x10				;Enable clock of Port E
				STR R0,[R1]
				LDR R1,=SYSCTL_PRGPIO
poll_gpio		LDR R0,[R1]					;Wait until the clock settles.
				LSRS R0,#5
				BCC poll_gpio
				;Select Data Direction for PE2
				LDR R1,=GPIO_PORTE_DIR
				LDR R0,[R1]
				BIC	R0,R0,#0x04				;Clear bit2 for PE2 input
				STR R0,[R1]
				;Select AFSEL
				LDR	R1,=GPIO_PORTE_AFSEL
				LDR R0,[R1]
				ORR	R0,R0,#0x04				;Set bit2 for PE2 Alternative Function
				STR R0,[R1]
				;Enable Analog Function
				LDR R1,=GPIO_PORTE_AMSEL
				LDR R0,[R1]
				ORR R0,R0,#0x04				;Set bit2 for PE2 Analog Function
				STR	R0,[R1]
				
	;ENABLE ADC
				;Enable ADC_clock
				LDR R1,=SYSCTL_RCGCADC
				LDR R0,[R1]
				ORR	R0,R0,#0x02				;Enable clock of ADC1
				STR R0,[R1]
				LDR R1,=SYSCTL_PRADC		;Wait until clock settles
poll_adc		LDR R0,[R1]
				LSRS R0,#2
				BCC poll_adc
				;Disable ADC
				LDR R1,=ADC1_ADCACTSS
				LDR R0,[R1]
				BIC R0,R0,#0x08				;Clear bit3 to disable sequencer3
				STR	R0,[R1]
				;Select the event type
				LDR R1,=ADC1_ADCEMUX
				LDR R0,[R1]
				BIC R0,R0,#0xF000			;Clear bits 15:12 for Processor Trigger
				STR R0,[R1]
				;Set sampling number and interrupt
				LDR R1,=ADC1_ADCSSCTL3
				LDR R0,[R1]
				ORR R0,R0,#0x06				;set bit2 for IE0, bit3 for END0
				STR R0,[R1]
				;Set sampling rate
				LDR R1,=ADC1_ADCPC
				LDR R0,[R1]
				BIC R0,R0,#0x0F
				ORR R0,R0,#0x07				;Set final 4 bits to 0111 for 1Msps
				STR R0,[R1]
				;Enable ADC
				LDR R1,=ADC1_ADCACTSS
				LDR R0,[R1]
				ORR R0,R0,#0x08				;Clear bit3 to enable sequencer3
				STR	R0,[R1]
				;Now ADC is ready to sample on the program's trigger!												
				POP{R0,R1,LR}	
				BX	LR
		ENDP
	END