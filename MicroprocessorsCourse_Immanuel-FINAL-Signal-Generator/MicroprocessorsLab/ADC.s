 #include <xc.inc>
extrn	LCD_Setup, LCD_Write_Hex ; external LCD subroutines

extrn	DAC_Int_Hi,sawtooth, square, delay,DAC_Setup,LCD_Write_Hex,LCD_ClearScreen
extrn	high_value, low_value, hex_high, hex_low, offset_low, offset_high, keyvalue
extrn	 hex_dec_conversion, delay, LCD_Setup, LCD_Write_Message, LCD_write_dec, LCD_Send_Byte_I, LCD_delay_ms,LCD_Send_Byte_D, full_scale
global  ADC_Setup, ADC_Read ,ADC_Setup_1,ADC_Read_1, potentiometer1, potentiometer2

psect	udata_acs
;counter:    ds 1  
high_value_comp: ds 1 
low_value_comp:ds 1
   
psect	adc_code, class=CODE
ADC_Setup:
	bsf	TRISA, PORTA_RA0_POSN, A  ; pin RA0==AN0 input
	bsf	ANSEL0	    ; set RA0=AN0 to analog
	movlw   0x01	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Read:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	return
	

ADC_Setup_1:
	bsf	TRISF, PORTF_RF1_POSN, A  ; pin RF1==AN6 input
	bsf	ANSEL6	    ; set RF1=AN6 to analog
	movlw   00011001B   ; select AN6 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   00110000B	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   11110110B	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	bsf AN5
	return

ADC_Read_1:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop_1:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	return

;------------------------------------------------------------------------------;
;			 Amplitude - Potentiometer	               ;
;------------------------------------------------------------------------------;	
	
;   -   This Potentiometer sets the Amplitude of the Waveform
potentiometer1:
	call	ADC_Setup	; setup ADC
	call	ADC_Read
	movf	ADRESH, W, A
	movwf	hex_high, A
	movwf	high_value, A	;;
	movlw 0x10
	mulwf high_value, A
	movff PRODL,high_value, A
	movf	ADRESL, W, A
	movwf	hex_low, A
	movwf low_value, A
	
	movff low_value, low_value_comp, A  ;change to the scale 
	movff high_value, high_value_comp, A
	call high_value_scale
	movff low_value_comp, low_value, A
	movff high_value_comp, high_value, A
	nop

	;call	hex_dec_conversion ;takes lower value from fsr1, higher value from fsr2
	;nop			    ;the result of conversion is stored at 0x40 to 0x43, A
	;call	LCD_write_dec; write dec stored at 0x40 to 0x43 on LCD.
	
	;movlw	' '
	;call LCD_Send_Byte_D;write blank in between
	
	
	movlw 0x00;show discrete levels
	movwf	hex_high, A
	movf	high_value, W, A
	movwf	hex_low, A
	call	hex_dec_conversion ;takes lower value from fsr1, higher value from fsr2
	nop			    ;the result of conversion is stored at 0x40 to 0x43, A
	call	LCD_write_dec; write dec stored at 0x40 to 0x43 on LCD.
	return

;------------------------------------------------------------------------------;
;			 Offset - Potentiometer				       ;
;------------------------------------------------------------------------------;
potentiometer2:
	call	ADC_Setup_1	; setup ADC
	call	ADC_Read_1	; Call ADC Read Function
	movf	ADRESH, W, A	; 
	movwf	hex_high, A	; Move value from ADRESH to hex_high & offset_high
	movwf	offset_high, A	;
	movlw 0x10		; Multiply by Decimal 16 to shift digits left
	mulwf offset_high, A	; Multiplication
	movff PRODL,offset_high, A  ; Move Product low byte into Offset_high
	
	movf	ADRESL, W, A	; Move ADRESL into hex-&-offset_low
	movwf	hex_low, A	; hex_low
	movwf offset_low, A	; offset_low
	movff offset_low, low_value_comp, A  ;Move offset_low to low_comp 
	movff offset_high, high_value_comp, A	;Move offset_high to high_comp... 
	call high_value_scale		; ...in order to change scale
	movff low_value_comp, offset_low, A ;.... 
	movff high_value_comp, offset_high, A
	nop
	
	
    ; Code below, checks if the programme is currently running a Sine-wave,
    ; then skips the setting of full-scale boundaries since Sine-waves use,
    ; lookup tables and are predefined.
	
	movlw	'3'	
	cpfseq keyvalue, A
	call   Full_Scale_Saw_N_Suare
	
	movlw 0x00;show discrete levels
	movwf	hex_high, A
	movf	offset_high, W, A
	movwf	hex_low, A
	call	hex_dec_conversion ;takes lower value from hex_low, higher value from hex_high
	nop			    ;the result of conversion is stored at 0x40 to 0x43, A
	call	LCD_write_dec; write dec stored at 0x40 to 0x43 on LCD.
	return 
	
	
	Full_Scale_Saw_N_Suare:
	; This is to set a maximum peak-point boundary of the generated Saw
	; and Square wave signals specifically 
		; at 0xff
	    movlw	0xff
	    movwf	full_scale, A
	    movf high_value, W, A  ; Subtracts amplitude(high_value) from maximum
				    ;set the offset range from 0 to max 
	    subwf full_scale, F, A
	    movf	full_scale, W, A
	    cpfslt	offset_high, A
	    movff full_scale, offset_high, A 
	    return
	  
		
	
;------------------------------------------------------------------------------;
;	High-Value - ADRESH Scale x10 (16 Decimal)			       ;
;------------------------------------------------------------------------------;	
high_value_scale:
    ;	This piece of code iteratively adds a number which is equivalent to the
    ; most significant bit of the low_value to the least significant of the high_value
    ; This is equivalent to shifting the bits up (to the left) by one (a multiplication by 0x10)
    ; and then neglecting the lower byte.
    ; The significance of this is to permit us to use the single new high_value byte 
    ; in further computations & calculations
    
    movlw   0x10
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0x20
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0x30
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0x40
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0x50
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0x60
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0x70
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0x80
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0x90
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0xA0
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0xB0
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0xC0
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0xD0
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0xE0
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp, A
    
    movlw   0xF0
    cpfsgt  low_value_comp, A
    return
    movf    high_value_comp, W, A
    addlw   0x01
    movwf   high_value_comp,A
    return

end
