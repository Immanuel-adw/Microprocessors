  #include <xc.inc>
extrn    hex_dec_conversion, delay, LCD_Setup, LCD_Write_Message, LCD_write_dec, LCD_Send_Byte_I, LCD_delay_ms,LCD_Send_Byte_D
global high_value, low_value, hex_high, hex_low, offset_low, offset_high, full_scale
  global  loadfsr
    global Keypad_output,Keypad_output2,MessageLength1,MessageLength2,Typed_in_vals,Read_out_vals, Decoded_val,keyvalue,keyv

;extrn	UART_Setup, UART_Transmit_Message  ; external uart subroutines
extrn	LCD_Setup, LCD_Write_Hex ; external LCD subroutines
extrn	ADC_Setup, ADC_Read, ADC_Setup_1, ADC_Read_1 ; external ADC subroutines
extrn	DAC_Int_Hi,sawtooth, square, delay,DAC_Setup,LCD_Write_Hex,LCD_ClearScreen
	extrn potentiometer1, potentiometer2, keyvalue, NonDataVals_n_Instructions , ClearMem,Keypad_getKey
	extrn Decoder, Keypad_Setup_1 ,loadfsr, setkey1, wavedis


;***********    Reserve Bytes in Access Memory (for use)     *********	    ;	
	psect	udata_acs   ; reserve data space in access ram
;	******************************************************		    ;
;*****								******	    :	
;____________Reserving Memory Bytes for Storing Useful Variables_____________; 
;**
hex_high: ds 1
hex_low: ds 1
blank:ds 1
delay_count:ds 1    ; reserve one byte for counter in the delay routine
high_value: ds 1
low_value: ds 1
offset_high:ds 1
offset_low:ds 1
full_scale: ds 1
keyv:ds 1
 Decoded_val: ds 1        ; reserve 2nd byte for button pressed on keypad
Keypad_output: ds 1        ; reserve 1 byte for button pressed on keypad
Keypad_output2: ds 1        ; reserve 2nd byte for button pressed on keypad
 max: ds 1  
MessageLength1: ds 1  ; reserve byte address for the number of keys pressed
		    ; to be used in storing& reading characters from memory
MessageLength2: ds 1 ; re
    
  
     ; *********					********* ;
;   ************ Reserve Bytes in Banked Memory (for use) ******************* ;
;********							    *********;
psect	udata_bank6 ; reserve data in bank6 Banked Memory (0x500)
Typed_in_vals: ds 0x50   ; reserve 80 (0x50) bytes for storing values typed in 
psect	udata_bank7 ; reserve data in bank7 Banked Memory (0x600) 
Read_out_vals: ds 0x50   ; reserve 80 (0x50) bytes for creating a copy for storage of Typed_in_vals
			   ; initially stored in Bank6 above
;
;			   **********************			       
;_______________________ Begin Executable Programme ___________________________;  
;	*******
psect	code, abs	
rst: 	org 0x0
 	goto	setup
	;   High Interrupt 
int_hi:	org	0x0008	; high vector, no low vector
	goto	DAC_Int_Hi  ;Calls the Function assigned to the High Interrupt
	
;			     *********************			       ;
;______________________ Setup (product Device-components) _____________________;
;  *********************				***********************
setup:
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	LCD_Setup	; setup UART
	movlw '1'
	movwf keyvalue, A
	call setkey1	    ;	Calls the Keypad Setup Routine, and Enables PORTC as Output 
	;interrupt;;;;;;;;
	call	DAC_Setup   ; Calls the DAC Setup Routine 
;	goto $
	goto	measure_loop
;	```
	
	
;------------------------------------------------------------------------------;
;			 Main Code - Measurement Loop		               ;
;------------------------------------------------------------------------------;	
;      *****************  Settings & Write Commands  ******************;
measure_loop:
	call Keypad_getKey
	nop
	tstfsz keyv, A
	call checkmax
	movf keyvalue, W, A
	call wavedis
	
	movlw	' '
	call LCD_Send_Byte_D
	
	call potentiometer1
	nop
	
	movlw	' '
	call LCD_Send_Byte_D
	
	call potentiometer2
	nop
	nop
	;movlw	3
	call LCD_delay_ms
	nop
	call LCD_delay_ms
	nop
	call LCD_delay_ms
	nop	
	call	LCD_ClearScreen
	
	goto	measure_loop		; goto current line in code
;	

	
add:
    movlw 0x01
    addwf high_value, F, A
    return
    
checkmax:
    cpfseq max, A
    movff keyv, keyvalue, A
    return
end rst