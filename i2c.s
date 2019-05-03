;i2c0 will be used
I2CMCR					EQU	0x40020020
I2CMTPR					EQU	0x4002000C
I2CMSA					EQU	0x40020000
I2CMDR					EQU	0x40020008
I2CMCS					EQU	0x40020004

;pb2(3) will be used for i2cscl and pb3(3) will be used for i2csda
GPIO_PORTB_DIR			EQU	0x40005400
GPIO_PORTB_AFSEL		EQU	0x40005420
GPIO_PORTB_DEN			EQU	0x4000551C
GPIO_PORTB_PDR			EQU	0x40005514
GPIO_PORTB_PUR			EQU	0x40005510
GPIO_PORTB_CR			EQU	0x40005524
GPIO_PORTB_PCTL			EQU	0x4000552C
GPIO_PORTB_AMSL			EQU	0x40005528
GPIO_PORTB_DR			EQU	0x4000550C

SYSCTL_RCGCI2C			EQU	0x400FE620
SYSCTL_RCGCGPIO		 	EQU 0x400FE608
SYSCTL_PRGPIO			EQU 0x400FEA08	;GPIO Peripheral Ready, pg.406
SYSCTL_PRI2C			EQU 0x400FEA20	;I2C Peripheral Ready, pg. 414

	;SYMBOL		DIRECTIVE		VALUE		COMMENT
				AREA    		|.text|, CODE, READONLY
				EXPORT			i2c
				ENTRY
			
i2c				PROC
				
				;Activate the clock for PortB
				LDR	R1,=SYSCTL_RCGCGPIO		
				LDR	R0,[R1]
				ORR	R0,R0,#0x02
				STR	R0,[R1]
				LDR R1,=SYSCTL_PRGPIO
poll_gpio		LDR R0,[R1]					;Wait until the clock settles.
				LSRS R0,#2
				BCC poll_gpio
				;Set directions of the pins
				LDR	R1,=GPIO_PORTB_DIR
				LDR	R0,[R1]					;set PB3 and PB2 as output
				ORR	R0,R0,#0x0C
				STR	R0,[R1]
				;enable alternate function for PB3 and PB2
				LDR	R1,=GPIO_PORTB_AFSEL				
				LDR	R0,[R1]
				ORR	R0,#0x0C
				STR	R0,[R1]
				;enable i2c SDA pin for open-drain operation
				LDR	R1,=GPIO_PORTB_DR
				LDR	R0,[R1]
				ORR	R0,R0,#0x08				;PB3 => SDA, PB2 => SCL
				STR	R0,[R1]
				;Set the alternative function for PB2 and PB3 as i2c
				LDR	R1,=GPIO_PORTB_PCTL
				LDR	R0,[R1]
				BIC R0,R0,#0xFF00
				ORR	R0,R0,#0x3300
				STR	R0,[R1]
				;Set pull-up resistors for PB2 and PB3
				LDR R1,=GPIO_PORTB_PUR
				STR R0,[R1]
				ORR R0,R0,#0x0C
				STR R0,[R1]
				;Enable digital port
				LDR	R1,=GPIO_PORTB_DEN
				LDR	R0,[R1]
				ORR	R0,R0,#0x0C
				STR	R0,[R1]
				
				;Activate i2c clock
				LDR	R1,=SYSCTL_RCGCI2C		
				LDR	R0,[R1]
				ORR	R0,R0,#0x01
				STR	R0,[R1]
				LDR R1,=SYSCTL_PRI2C
poll_i2c		LDR R0,[R1]					;Wait until the clock settles.
				LSRS R0,#1
				BCC poll_i2c
				;Enable Master Mode			
				LDR	R1,=I2CMCR
				LDR	R0,[R1]
				ORR	R0,R0,#0x10
				STR	R0,[R1]
				;SCL clock speed is 100kbps
				LDR	R1,=I2CMTPR
				LDR	R0,[R1]
				ORR	R0,R0,#0x09
				STR	R0,[R1]
				;Set the slave address to 0x60 and transmit mode
				LDR	R1,=I2CMSA				
				LDR	R0,[R1]
				ORR	R0,R0,#0xC0
				STR	R0,[R1]
				BX LR
			ENDP
			ALIGN
		END			
			


