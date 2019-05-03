;LABEL		DIRECTIVE		VALUE		COMMENT
			AREA			convert, CODE, READONLY
			THUMB
			EXPORT		CONVRT
				
CONVRT			PROC
					PUSH {R0-R6,LR}
					MOV 	R1,#0					;m value (digit value)
					MOV 	R2,#10
					MOV 	R3,R4					;Copy the number
					MOV 	R6,#0					;Number zero for comparision
number_loop			UDIV 	R3,R2					;Integer/10
					ADD 	R1,#1					;Increase digit number
					CMP 	R3,R6					;If division is zero end the loop
					BEQ		cont_1
					B 		number_loop
cont_1				MOV 	R0,R1					;Copy the digit number to R0
					SUBS 	R0,#1			
					BEQ		misone
					MOV 	R6,#1					;Start from 1 and loop if m is not 1
power_loop			MUL 	R6,R2					;R6 <-- R6*10
					SUBS 	R0,#1
					BEQ 	digit_loop
					B		power_loop
misone				ADD		R4,#48
					STR		R4,[R5],#1
					B		cont_2
digit_loop			UDIV 	R0,R4,R6				;number/10^m, R0 is the left most digit
					MOV		R3,R0					;Copy R0
					ADD  	R0,#48					;convert the digit to ASCII
					STR		R0,[R5],#1				;Store the first digit to the memory and increment the pointer
					MUL		R3,R6					;R0 <-- digit*10^m
					SUB		R4,R3					;R4 <-- R4 - digit*10^m
					UDIV	 R6,R2					;R6 <-- 10^(m-1)
					SUBS 	R1,#1					;Decrease the digit number
					BEQ		cont_2
					B 		digit_loop
cont_2				LDR 	R0,=0x04				;Load the terminator character to R0
					STR 	R0,[R5]					;Terminate the String
					POP{R0-R6,LR}
					BX		LR
					ENDP
					END