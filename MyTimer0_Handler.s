;ADC1 Registers
ADC1_ADCACTSS		EQU 0x40039000	;ADC Active Sample Sequencer Register, pg.821
ADC1_ADCPSSI		EQU 0x40039028	;ADC Processor Sample Sequencer Initiate, pg.845
ADC1_ADCSSFIFO3		EQU 0x400390A8	;ADC Sample Sequence Result FIFO 3, pg.860
ADC1_ADCSSFSTAT3	EQU 0x400390AC	;ADC Sample Sequence FIFO 3 Status, pg.861

;TIMER0 Registers
TIMER0_CTL			EQU 0x4003000C
TIMER0_ICR			EQU 0x40030024 ; Timer Interrupt Clear
TIMER0_TAILR		EQU 0x40030028 ; Timer interval	
	
;I2C0 Registers
I2CMCR					EQU	0x40020020
I2CMTPR					EQU	0x4002000C
I2CMSA					EQU	0x40020000
I2CMDR					EQU	0x40020008
I2CMCS					EQU	0x40020004
	
UPPER				EQU	10000
SRAM_BEGIN			EQU	0x20000000
SRAM_END			EQU	0x20005DC0	;3second recording * 8kB/s = 24kB Memory Space
;---------------------------------------------------
					
			AREA 	routiness, CODE, READONLY
			THUMB
			EXPORT 	MyTimer0_Handler					
;---------------------------------------------------	
MyTimer0_Handler	PROC
					PUSH{R0,R1,R3,LR}
					LDR R1,=TIMER0_CTL
					LDR R0,[R1]
					BIC R0,R0,#0x03				;Disable the timer
					STR R0,[R1]
					LDR R1,=TIMER0_ICR
					LDR R0,[R1]
					ORR R0,R0,#0x01				;Clear the interrupt flag
					STR R0,[R1]
					;Start ADC sampling, get data from the potentiometer
					LDR R1,=ADC1_ADCPSSI
					LDR R0,[R1]
					ORR R0,R0,#0x08				;Set bit3 to activate SS3 sampling
					STR R0,[R1]
					;Wait for the sampling to be completed, poll FIFOFULL Flag
poll_fifo_full		LDR R1,=ADC1_ADCSSFSTAT3	;If it is not pressed check if the sample ready
					LDR R0,[R1]
					ANDS R0,#0x1000
					BEQ poll_fifo_full
					;If FIFO is full then sampling is completed.
					LDR R1,=ADC1_ADCSSFIFO3
					LDR R0,[R1]					;R0 is the sampled value from POT.
					;Each bit in the sample corresponds to 2 value in timer.
					;So for 000 we will load 10000, and for FFF we will load 1810 to the timer value.
					;This way the i2c frequency will vary between 2kHz and 10,18kHz
					LSL R0,#1					;Multiply the value with 2
					LDR R1,=UPPER				;Load R1 <- 10000, this is the corresponding value for 2kHz
					SUB R1,R0					;R1 = 10000 - Sample * 2
					LDR R0,=TIMER0_TAILR		;Store the new value to timer.
					STR R1,[R0]
					
					;Now its time to send the data to DAC
																	;*********** first DATA BYTE *****************
					MOV R3,#0					;Reset R3 just in case.
					LDRB R3,[R2],#1				;Load the next data to be transferred, and increment R2
					LDR R1,=I2CMDR
					MOV R0,R3					;Copy the 8 bit data to R0, the first 4 bit is the most significant 4 bit
					LSR R0,#4					;Shift the data 4 to right, Rest of R1 is 0
					;MOV R0,#0x0T				;For fast mode command c2 and c1 = 0. For normal operation pd1 and pd0 = 0. T will be the 
					STR	R0,[R1]					;most significant 4 bits of data			
					;Set START and RUN bits				
					LDR	R1,=I2CMCS
					LDR	R0,[R1]
					ORR	R0,R0,#0x03			
					STR	R0,[R1]
busbusy1			LDR	R1,=I2CMCS
					LDR	R0,[R1]
					ANDS R0,R0,#0x40			;wait until transmission completed by polling BUSBSY bit
					BNE	busbusy1
									;*********** second DATA BYTE ****************
					BIC R3,R3,#0xF0				;Clear the most significant 4 bits
					LSL R3,#4					;Shift 4 bits to the left, the least significant 4 bits are zeros
					LDR	R1,=I2CMDR				;This way we decompress the data.
					;MOV	R0,#0xTT				;TT will be the least significant 8 bits of data
					STR	R0,[R1]
					;Set RUN bits
					LDR	R1, =I2CMCS
					LDR	R0,[R1]
					ORR	R0,R0,#0x01			
					STR	R0,[R1]			
busbusy2			LDR	R1, =I2CMCS
					LDR	R0, [R1]
					ANDS R0, R0, #0x40			;wait until transmission completed by polling BUSBSY bit
					BNE	busbusy2
					;Clear the START and RUN bits to transmit EOT
					LDR	R1,=I2CMCS
					LDR	R0,[R1]
					BIC	R0,R0,#0x03				
					STR	R0,[R1]
					;Set STOP bit
					LDR	R1,=I2CMCS
					LDR	R0,[R1]
					ORR	R0,R0,#0x04			
					STR	R0,[R1]
									;*********** TRANSMISSION COMPLETED!! ****************		
					LDR R0,=SRAM_END
					CMP R0,R2
					LDREQ R2,=SRAM_BEGIN
					
enable				LDR R1,=TIMER0_CTL
					LDR R0,[R1]
					ORR R0,R0,#0x03			;Enable the timer back again
					STR R0,[R1]
					POP{R0,R1,R3,LR}
					BX 	LR 
				ENDP
			END