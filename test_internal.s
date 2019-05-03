GPIO_PORTF_DATA  	EQU 0x400253FC
;LABEL		DIRECTIVE	VALUE		COMMENT
			AREA    	main, READONLY, CODE	
			THUMB
			EXTERN		DELAY100
			EXTERN		PortF_unlock
			EXTERN		ADC_Init
			EXTERN		PLL_Init
			EXTERN		Timer_Init
			EXPORT  	__main				; Make available
			
			ENTRY
			
__main			BL PLL_Init
				BL PortF_unlock
				LDR R1,=GPIO_PORTF_DATA
loop			LDR R0,[R1]
				EOR R0,#0x02
				STR R0,[R1]
				B loop