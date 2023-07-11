#include <xc.inc> 
global hex_dec_conversion, LCD_Write_Hex
extrn  hex_low, hex_high, LCD_hex_tmp, LCD_tmp, LCD_Send_Byte_D

psect	udata_acs   ; named variables spaces(bytes) reserved in access ram
deci_digit_1: ds 1
deci_digit_2: ds 1
deci_digit_3: ds 1
deci_digit_4: ds 1
f1: ds 1
f2: ds 1
f3: ds 1
f4: ds 1
    
psect	hex_dec_code,class=CODE
;______________________________________________________________________________;
;______________________________________________________________________________;	
;------------------------------------------------------------------------------;
;			 HEX to Decimal Digit Conversion	               ;
;------------------------------------------------------------------------------;	
;      *****************  Settings & Write Commands  ******************;		
		
hex_dec_conversion:	
	call	hex_dec_digit1 
	nop;convert to first digit of decimal, stored at deci_digit_1
	movff	f1, 0x40, A
	nop
	call	hex_dec_digit234
	nop
	movff	f1, 0x41, A
	call	hex_dec_digit234
	nop
	movff	f1, 0x42, A
	call hex_dec_digit234
	nop
	movff f1, 0x43, A
	return
	
    ; Convert first bit to decimal digit 
	; ----  by multicplication by appropriate scale factor  ---   ;;;;;;;
	hex_dec_digit1:
		movlw	0x8A
		mulwf	hex_low, A
		movff	PRODL, f4, A
		movff	PRODH, 0x13, A

		movlw	0x8A
		mulwf	hex_high, A
		movf	PRODL, W, A
		addwf	0x13, W, A
		movwf	0x23, A

		movlw	0x00
		addwfc	PRODH, W, A
		movwf	0x22, A

		movlw	0x41
		mulwf	hex_low, A
		movf	PRODL, W, A
		addwf	0x23, W, A
		movwf	f3, A
		movf	PRODH, W, A
		addwfc	0x22, W, A
		movwf	0x32, A

		movlw	0x41
		mulwf	hex_high, A
		movf	PRODL, W, A
		addwf	0x32, W, A
		movwf	f2, A
		movlw	0x00
		addwfc	PRODH, W, A
		movwf	f1, A
	    return

	;Conversion of remaining three bits      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;______________________________________________________________________________;
	hex_dec_digit234:
		movf	f4, W, A
		mullw	0x0A
		movff	PRODL, f4, A
		movff	PRODH, 0x18, A
		movf	f3, W, A
		mullw	0x0A
		movf	PRODL, W, A
		addwf	0x18, W, A
		movwf	f3, A
		movff	PRODH, 0x27, A
		movf	f2, W, A
		mullw	0x0A
		movf	PRODL, W, A
		addwfc	0x27, W, A
		movwf	f2, A
		movff	PRODH, 0x36, A
		movlw	0x00
		addwfc	0x36, W, A
		movwf	f1, A
	    return
;______________________________________________________________________________;
;______________________________________________________________________________;	
;------------------------------------------------------------------------------;
;		    Hex digits to ASCII Hex Vals Conterter                     ;
;------------------------------------------------------------------------------;
LCD_Write_Hex:		    ; Writes byte stored in W as hex
	movwf	LCD_hex_tmp, A
	swapf	LCD_hex_tmp, W, A	; high nibble first
	call	LCD_Hex_Nib
	movf	LCD_hex_tmp, W, A	; then low nibble
LCD_Hex_Nib:			; writes low nibble as hex character
	andlw	0x0F
	movwf	LCD_tmp, A
	movlw	0x0A
	cpfslt	LCD_tmp, A
	addlw	0x07		; number is greater than 9 
	addlw	0x26
	addwf	LCD_tmp, W, A
	call	LCD_Send_Byte_D ; write out ascii
	return
	
	
end 


