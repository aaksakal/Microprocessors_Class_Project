;i2c0 will be used
I2CMCR				EQU	0x40020020
I2CMTPR				EQU	0x4002000C
I2CMSA				EQU	0x40020000
I2CMDR				EQU	0x40020008
I2CMCS				EQU	0x40020004
	
;PORTF Registers
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
	
TIMER0_CTL			EQU 0x4003000C	;pg.737

;ADC0 Registers
ADC0_ADCACTSS		EQU 0x40038000	;ADC Active Sample Sequencer Register, pg.821
ADC0_ADCSSFIFO3		EQU 0x400380A8	;ADC Sample Sequence Result FIFO 3, pg.860
ADC0_ADCSSFSTAT3	EQU 0x400380AC	;ADC Sample Sequence FIFO 3 Status, pg.861
	
;Memory Start Point
SRAM_BEGIN			EQU	0x20000000
SRAM_END			EQU	0x20005DC0	;3second recording * 8kB/s = 24kB Memory Space
MEMORY_COUNT		EQU	32768		;There are this many spaces
	
;LABEL		DIRECTIVE	VALUE		COMMENT
			AREA    	main, READONLY, CODE	
			THUMB
			EXTERN		DELAY100
			EXTERN		PortF_unlock
			EXTERN		ADC_Init
			EXTERN		PLL_Init
			EXTERN		Timer_Init
			EXTERN 		Change_Timer_Settings
			EXTERN		i2c
			EXTERN 		ADC_POT_Init
			EXPORT  	__main				; Make available
			
			ENTRY
			
__main			BL PLL_Init
				BL Timer_Init
				BL PortF_unlock
				BL ADC_Init
;*************************************************************************
				;INIT STATE
;*************************************************************************
				LDR R1,=GPIO_PORTF_DATA
				MOV R0,#0x04					;Make the LED blue as the indication of HOLD or INIT
				STR R0,[R1]
				;Poll PF4, which is the record button
poll_record 	LDR R0,[R1]						;Poll PF4 until the button is pushed and it becomes 0
				ANDS R0,#0x10
				BNE poll_record
				BL DELAY100	
				LDR R0,[R1]						;Get rid of bouncing effects.
				ANDS R0,#0x10
				BNE poll_record					;It will move to the recording state.
wait_for_release\
				LDR R0,[R1]
				ANDS R0,#0x10
				BEQ wait_for_release
;*************************************************************************
				;RECORD STATE
;*************************************************************************				
recording		LDR R2,=SRAM_BEGIN				;From here till the end of recording R2 is the memory pointer!!!!
				;Enable ADC back again
				LDR R1,=ADC0_ADCACTSS
				LDR R0,[R1]
				ORR R0,R0,#0x08					;Set bit3 to enable sequencer3
				STR	R0,[R1]
				;Now ADC will trigger every time timer counts to 0, poll FSTAT and read from FIFO whenever it is full
				;Set the state, and light the RED LED.
				LDR R1,=GPIO_PORTF_DATA
				MOV R0,#0x02					;Make the LED red as an indication of recording
				STR R0,[R1]
poll_button		LDR R1,=GPIO_PORTF_DATA			;Here we first check the button, if it is not pressed we continue sampling
				LDR R0,[R1]
				ANDS R0,#0x10
				BEQ recording_paused			;If it is pressed pause the recording process and poll the button again to continue
poll_fifo		LDR R1,=ADC0_ADCSSFSTAT3		;If it is not pressed check if the sample ready
				LDR R0,[R1]
				ANDS R0,#0x1000	
				BEQ	poll_button
				LDR R1,=ADC0_ADCSSFIFO3			;If it is ready, Load the sample to R0
				LDR R0,[R1]
				;Compression is done by dividing the value to 16
				LSR R0,#4
				STR R0,[R2],#1					;Store the compressed sample to memory.
				LDR R1,=SRAM_END
				CMP R1,R2						;Is the memory full?
				BEQ	recording_completed			;YES => recording is completed
				B poll_button					;NO => gather more data.
;*************************************************************************
				;RECORD PAUSE STATE
;*************************************************************************					
recording_paused\
				BL DELAY100						;Put a delay in order to get rid of bouncing effects
				LDR R0,[R1]
				ANDS R0,#0x10
				BNE poll_fifo					;If it is not pressed keep polling fifo
wait_for_release1\
				LDR R0,[R1]
				ANDS R0,#0x10
				BEQ wait_for_release1
				MOV R3,#2						;R3=2 => INTERMISSION/PAUSE STATE
				LDR R1,=GPIO_PORTF_DATA
				MOV R0,#0x04					;Make the LED blue as the indication of HOLD or INIT
				STR R0,[R1]
paused_poll		LDR R0,[R1]
				ANDS R0,#0x10
				BNE paused_poll					;If the record button is pressed, keep recording
				BL DELAY100
				LDR R0,[R1]
				ANDS R0,#0x10
				BNE paused_poll
wait_for_release2\
				LDR R0,[R1]
				ANDS R0,#0x10
				BEQ wait_for_release2				
				MOV R3,#1						;Update the status flag
				MOV R0,#0x02					;Make the LED red as an indication of recording
				STR R0,[R1]
				B poll_fifo
;*************************************************************************
				;RECORD COMPLETE (HOLD) STATE
;*************************************************************************	
recording_completed\
				LDR R1,=GPIO_PORTF_DATA
				MOV R0,#0x04					;Make the LED blue as the indication of HOLD or INIT
				STR R0,[R1]
				;Now poll the play button (SW2) to start playing.
completed_poll	LDR R0,[R1]
				ANDS R0,#0x01
				BNE completed_poll				;If the play button is pressed, start playing.
				BL DELAY100
				LDR R0,[R1]
				ANDS R0,#0x01
				BNE completed_poll
wait_for_release3\
				LDR R0,[R1]
				ANDS R0,#0x01
				BEQ wait_for_release3
				MOV R0,#1						;Check the status flag, if we were playing before and paused it will be 1
				CMP R0,R3
				LDREQ R1,=TIMER0_CTL			;If R3=1 then enable timer and go poll the play button
				LDREQ R0,[R1]					;Otherwise it will skip these 5 lines and go to play state, and initilize PLAY.
				ORREQ R0,R0,#0x03 ; set bit0 to enable
				STREQ R0,[R1] ; and bit 1 to stall on debug
				BEQ after_pause
;*************************************************************************
				;PLAY STATE
;*************************************************************************
				MOV R3,#1						;Update the status flag
				LDR R2,=SRAM_BEGIN
				LDR R1,=GPIO_PORTF_DATA
				MOV R0,#0x08					;Make the LED green as the indication of PLAY
				STR R0,[R1]			
				BL i2c
				BL ADC_POT_Init
				BL Change_Timer_Settings
after_pause		LDR R1,=GPIO_PORTF_DATA
playing_poll	LDR R0,[R1]
				ANDS R0,#0x01
				BNE playing_poll				;If the play button is pressed, start playing.
				BL DELAY100
				LDR R0,[R1]
				ANDS R0,#0x01
				BNE playing_poll
wait_for_release4\
				LDR R0,[R1]
				ANDS R0,#0x01
				BEQ wait_for_release4
				;Disable Timer
				LDR R1,=TIMER0_CTL
				LDR R0,[R1]
				BIC R0,R0,#0x01
				STR R0,[R1]
				B recording_completed
last			B last
			END
			