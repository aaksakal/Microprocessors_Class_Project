SYSCTL_RCC			EQU 0x400FE060  ;Run Mode Clock Configuration, pg.254
SYSCTL_RIS			EQU 0x400FE050	;Raw Interrupt Status, pg.244
	
;LABEL		DIRECTIVE		VALUE		COMMENT
			AREA			pll_init, CODE, READONLY
			THUMB
			EXPORT		PLL_Init
				
PLL_Init		PROC
				PUSH{R0,R1,LR}
				LDR R1,=SYSCTL_RCC
				LDR R0,[R1]
				;PART 1
				BIC R0,R0,#0x400000 	;clear bit22 for USESYSDIV, allow system to run on raw clock while configuring
				ORR R0,R0,#0x800		;set bit11 for BYPASS, same reason above
				STR R0,[R1]
				;PART 2
				LDR R0,[R1]
				BIC R0,R0,#0x7C0
				ORR R0,R0,#0x600		;XTAL, set bit 10:6 to 0x18 for 20MHz
				BIC R0,R0,#0x2000		;OSRC, set bit 5:4 to select PIOSC as the oscillator source, default no need to change
										;and bit13 to clear PWRDN
				STR R0,[R1]
				;PART 3
				LDR R0,[R1]
				BIC R0,R0,#0x7100000
				ORR R0,R0,#0x4C00000	;SYSDIV, set bit 26:23 to 0x9, and bit22 to activate USESYSDIV
				STR R0,[R1]
				;PART 4
				LDR R1,=SYSCTL_RIS		;Poll PLLLRIS, bit6, to ensure PLL lock
poll_plllris	LDR R0,[R1]
				LSRS R0,#7				;Right shift R0 7 times to get PLLLRIS bit in C flag.
				BCC poll_plllris
				;PART 5
				LDR R1,=SYSCTL_RCC
				LDR R0,[R1]
				BIC R0,R0,#0x800		;clear bit11 for BYPASS, to enable MCU to use PLL
				STR R0,[R1]
end_loop		POP{R0,R1,LR}	
				BX	LR
		ENDP
	END