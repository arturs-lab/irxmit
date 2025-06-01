        LIST    p=PIC16C84

ind0    equ     00h             ; index register
pcl     equ     02h             ; program counter low byte
status  equ     03h             ; status register
fsr     equ     04h             ; file select register
porta   equ     05h             ; port A
portb   equ     06h             ; port B
lcd     equ     06h             ; port to which LCD is connected
IRport	equ	06h		; port to which IR LED is connected
intcon  equ     0bh             ; interrupt control register
rc      equ     0ch             ; scratch register C
rd      equ     0dh             ; scratch register D
re      equ     0eh             ; scratch register E
rf      equ     0fh             ; scratch register F
count   equ     10h             ; scratch register 10
buf      equ     11h             ; scratch register 11
romptr  equ     1fh             ; pointer to Eprom location
opt     equ     01h             ; option register
;rp0     equ     5
W       equ     0               ; W is destination
f       equ     1               ; f is destination

PORT_A_MASK	equ	00h	; initial status of port A, all bits are outputs

ROMport	equ	05h		; port to which 
ROM_DTA	equ     00h             ; EEPROM data I/O bit
ROM_CLK	equ     01h             ; EEPROM clock bit
ROM_CS	equ	02h		; EEPROM chip select
PWR	equ	03h		; EEPROM power pin


IRSlong equ     0b8h             ; long sync pulse decimal length 9ms
IRSshor equ     58h              ; short sync pulse 4 ms
IRDpuls equ     0ch              ; light pulse 700 us
IRDzero equ     0ah              ; "zero" 400 us
IRDone  equ     20h              ; "one" 1500 us
IRBit	equ	0		; bit 3 of port IRport that controls IR transmitter


        org     0

        clrf    intcon          ; disable interrupts
        movlw   LCD_MASK        ; setup port B outputs
        movwf   portb
        movlw   PORT_A_MASK
        movwf   porta           ; setup port A outputs
        bsf     status,rp0      ; open page 1
        clrf    opt             ; clear option register
        bsf     opt,7           ; disable pullup
        clrw                    ; set port A as output
        movwf   porta
        clrw                    ; set port B as output
        movwf   portb           ;
        bcf     status,rp0      ; open page 0
        call    initlcd         ; initialize LCD

        clrf    romptr          ; reset pointer to ROM
        call    RomPrt

main    call    rdkbd           ; read keyboard
        movwf   buf
        call    LcdHome
        movf    buf,W
        call    exec            ; execute code for key pressed
        movlw   delay2          ; wait a while...
        call    wait
        call    wait
        goto    main            ; and start over

;
; **************************************************************************
; call code pointed to by W
; **************************************************************************
exec    andlw   0fh     ; strip high nybble
        addwf   pcl,f   ; jump to table entry
        goto    ret     ; 0
        goto    ret     ; 1
        goto    IRSend  ; 2 send IR command
        goto    ret     ; 3
        goto    RomDec  ; 4 decrement rom address
        goto    ret     ; 5
        goto    ret     ; 6
        goto    ret     ; 7
        goto    RomInc  ; 8 incerment ROM address
        goto    ret     ; 9
        goto    ret     ; a
        goto    ret     ; b
        goto    ret     ; c
        goto    ret     ; d
        goto    ret     ; e
        goto    ret     ; f

IRSend  movlw   20h
        movwf   fsr             ; setup RAM address pointer
IRSync  bsf     IRport,IRBit     ; enable IR transmitter
        movlw   IRSlong         ; Sync long pulse
        call    IRwait
        bcf     IRport,IRBit     ; disable transmitter
        movlw   IRSshor         ; Sync short pulse
        call    IRwait
IRData  movlw   4               ; number of bytes to be sent
        movwf   buf
IRD2    movlw   8               ; number of bits in a byte
        movwf   count
        movf    ind0,W
        movwf   rf
IRD1    bsf     IRport,IRBit     ; turn on LED
        movlw   IRDpuls         ; load pulse length
        call    IRwait          ; wait
        movlw   IRDzero         ; load delay length for zero
        btfsc   rf,0            ; if bit 0 of byte pointed to by fsr
        movlw   IRDone          ; is set, then use delay for "one"
        bcf     IRport,IRBit     ; turn off LED
        call    IRwait
        rrf     rf,f            ; prepare next bit
        decfsz  count,f            ; decrement counter
        goto    IRD1            ; close inner loop
        incf    fsr,f           ; point to next byte
        decfsz  buf,f            ; check if this was last byte
        goto    IRD2            ; no, continue loop
        bsf     IRport,IRBit     ; turn on LED
        movlw   IRDpuls         ; load pulse length
        call    IRwait          ; wait
        bcf     IRport,IRBit     ; turn off LED

ret     return                  ; you're done

IRwait  movwf   rd              ; 1                     1 |
IRw1    
        movlw   10h             ; 1                     1 |
        movwf   re              ; 1                     1 |
IRw2    decfsz  re,f            ; 1/2   |              50 |
        goto    IRw2            ; 2     | 16*3=48+2=50    |60*W
        decfsz  rd,f            ; 1/2                 1/2 |
        goto    IRw1            ; 2                     2 |
        return                  ; 2                     2 |

RomDec  decf    romptr,f        ; decrement rom address pointer
	decf	romptr,f
        goto    RomPrt

RomInc  incf    romptr,f        ; increment code to be sent
	incf	romptr,f
RomPrt  swapf    romptr,W
        call    tohex           ; convert data to hex
        call    WrLcdData       ; print result
        movf    romptr,W
        call    tohex           ; convert data to hex
        call    WrLcdData       ; print result
        movlw   20h
        call    WrLcdData       ; print space
        movlw   20h
        movwf   fsr             ; setup RAM address pointer
        movf    romptr,W        ; get ROM address
        call    EpromRD1        ; read data from eprom
        call    hexpr           ; print first byte
        incf    fsr,f
        call    hexpr           ; print second byte
        incf    fsr,f           ; point to next RAM location (22h)
        incf    romptr,W        ; fetch incremented eprom address
        call    EpromRD1        ; read second half of data
        call    hexpr           ; print third byte
        incf    fsr,f
        call    hexpr           ; print fourth byte
        return

;
; **************************************************************************
; read word from serial EEPROM and place in location pointed to by fsr
; at EpromRD entry data address is stored there
; at EpromRD1 entry data address is in W
; **************************************************************************
EpromRD1
        movwf   ind0            ; store W in ind0
EpromRD clrf    ROMport		; set all outputs low
        bsf     ROMport,ROM_DTA	; set DI high
        bsf     ROMport,ROM_CS	; set CS high
        call    tick1
        call    tick1
        bcf     ROMport,ROM_DTA	; clear data bit
        call    tick1           ; READ opcode clocked in, now address
        movlw   006h            ; number of bits in address
        movwf   count		; setup counter
erd1    bcf     ROMport,ROM_DTA	; begin with address bit = 0
        btfsc   ind0,5          ; check if address bit is high
        bsf     ROMport,ROM_DTA	; set data line high if so
        rlf     ind0,f          ; prepare next bit in address
        call    tick1           ; clock in data bit
        decfsz  count,f		; decrement counter
        goto    erd1            ; continue loop
        bcf     ROMport,ROM_DTA	; address clocked in, now read data
        bsf     ROMport,ROM_CLK
        bsf     status,rp0      ; open page 1
        bsf     ROMport,ROM_DTA	; set ROM_DTA to input
        bcf     status,rp0      ; open page 0
        incf    fsr,f           ; read high byte first
        movlw   008h            ; count data read
        movwf   count
erd2    rlf     ind0,f          ; prepare ind0 for next bit
        bcf     ind0,0          ; let's clear data bit for starters
        btfsc   ROMport,ROM_DTA	; and skip next line if data =0
        bsf     ind0,0          ; but if it is 1, let's correct ind0
        bcf     ROMport,ROM_CLK	; send clock pulse
        bsf     ROMport,ROM_CLK
        decfsz  count,f		; decrement counter and see if we're done
        goto    erd2            ; no, continue
        decf    fsr,f           ; now read low byte
        movlw   008h            ; count data read
        movwf   count
erd3    rlf     ind0,f          ; prepare ind0 for next bit
        bcf     ind0,0          ; let's clear data bit for starters
        btfsc   ROMport,ROM_DTA	; and skip next line if data =0
        bsf     ind0,0          ; but if it is 1, let's correct ind0
        bcf     ROMport,ROM_CLK	; send clock pulse
        bsf     ROMport,ROM_CLK
        decfsz  count,f		; decrement counter and see if we're done
        goto    erd3            ; no, continue
        clrf    ROMport		; clear all lines
        bsf     status,rp0      ; open page 1
        movlw   00h		; set ROMport as output
        movwf   ROMport
        bcf     status,rp0      ; open page 0
        return                  ; done


;
; **************************************************************************
; send clock pulse
; **************************************************************************
tick1   bsf     ROMport,ROM_CLK     ; set clock high
        bcf     ROMport,ROM_CLK     ; and reset
        return

;
; **************************************************************************
; wait for a period specified in W
; **************************************************************************
wait    movwf   rd      ; initialize delay counter
wait1   clrf    re      ; reset register E, ? cycle
wait2   decfsz  re,f    ; 1+1 cycle
        goto    wait2   ; 1 cycles
                        ; total of 2 cycles executed 256 times + 1=513 cycles
        decfsz  rd,f    ; 1+1 cycle
        goto    wait1   ; 1 cycles
                        ; 516 cycles each pass * 1us(@ 4.00MHz)=0.516ms
        return

;
; **************************************************************************
; Read keyboard, return result in W
; **************************************************************************
rdkbd   bsf     status,rp0      ; open page 1
        movlw   0f0h            ; enable keyboard input
        movwf   portb
        bcf     status,rp0      ; open page 0
        swapf   portb,w         ; read keyboard
        movwf   rc              ; store result for a while
        bsf     status,rp0      ; open page 1
        movlw   00h            ; set port B as output
        movwf   portb
        bcf     status,rp0      ; open page 0
        comf    rc,w            ; store result in W
        andlw   0fh             ; clear high nybble
        return

hexpr   swapf   ind0,W          ; fetch data from fsr->
        call    tohex
        call    WrLcdData       ; print result
        movf    ind0,W
        call    tohex
        call    WrLcdData       ; print result
        movlw   20h             ; print space
        goto    WrLcdData       ; print result

;
; **************************************************************************
; convert contents of low nybble in W to HEX, return ASCII code
; **************************************************************************
tohex   andlw   0fh     ; strip high nybble
        addwf   pcl,f   ; jump to table entry
        retlw   '0'
        retlw   '1'
        retlw   '2'
        retlw   '3'
        retlw   '4'
        retlw   '5'
        retlw   '6'
        retlw   '7'
        retlw   '8'
        retlw   '9'
        retlw   'a'
        retlw   'b'
        retlw   'c'
        retlw   'd'
        retlw   'e'
        retlw   'f'


; **************************************************************************
; init the lcd (this function is called once at startup to initialize the
; LCD to the proper mode.  Be careful making any changes to the code in this
; routine as the lcd is very fussy about it's initialization.
; **************************************************************************
initlcd movlw   LCD_MASK
        movwf   lcd             ; init the lcd latch, all control
                                ; bits are set to 0
        movlw   delay1
        call    wait        ;wait in case the lcd is in power up
;
; the first 4 commands are nibbles only in the msn of the immediate bytes
; first the lcd is put in 8 bit mode, and then into 4 bit mode
; during the sending of the first 4 nibbles, a delay is placed after each one.
; (you can't check the busy flag during this initial startup.)
       movlw   MODE_8_BIT       ;init 8 bit mode, for starters
       call    WrLcdNibble
       movlw   delay1
       call    wait
       movlw   MODE_8_BIT       ;init 8 bit mode, again
       call    WrLcdNibble
       movlw   delay1
       call    wait
       movlw   MODE_4_BIT       ;now init 4 bit mode
       call    WrLcdNibble
       movlw   delay1
       call    wait
;
       movlw   FUNCTION_MODE    ;setup 4bit mode, 5x7 char, 2 lines
       call    WrLcdStatus
       movlw   DISP_MODE        ;set display mode
       call    WrLcdStatus
       movlw   LCD_CLR          ;clear the lcd
       call    WrLcdStatus
       movlw   LCD_SH_CRSR      ;set entry mode to shift cursor
       call    WrLcdStatus
       return
;
; **************************************************************************
; print null terminated string pointed to by fsr
; **************************************************************************
LcdOut1 movf    ind0,W          ; fetch data to be printed
        incf    fsr,f           ; point to next char
        call    WrLcdData       ; output char in W
LcdOut  incf    ind0,f          ; test if this is NULL
        decfsz  ind0,f
        goto    LcdOut1         ; jump to output procedure if not
        return                  ; exit if it is

; **************************************************************************
; send cursor home
; **************************************************************************
LcdHome
        movlw   LCD_HOME        ; send cursor home
        goto    WrLcdStatus

; **************************************************************************
; clear the lcd
; **************************************************************************
LcdClear
       movlw   LCD_CLR          ;clear lcd
       goto    WrLcdStatus


; **************************************************************************
; move cursor as specified in W:
; D3 D2
; 0  0  shift cursor left
; 0  1  shift cursor right
; 1  0  shift display left
; 1  1  shift display right
; **************************************************************************
MoveCurs
        iorlw   LCD_MOVE_CURS


; **************************************************************************
; write lcd status byte, (first wait to see if lcd is ready for a command).
; **************************************************************************
WrLcdStatus
        movwf   rc              ; store data for later
        call    WaitLcdRdy      ; wait until lcd is ready
        movf    rc,W            ; get data from scratch reg
        andlw   LCD_DATA1       ; setup to write a command to the lcd
        call    WrLcdNibble     ; write the nibble
                                ; now do lsn
        swapf   rc,W            ; get char back and swap nybbles
        andlw   LCD_DATA1       ; setup to write a command to the lcd
        call    WrLcdNibble     ; write the nibble
        return

;
; **************************************************************************
; write lcd data byte, put ascii data to be written in the W register
; **************************************************************************
WrLcdData:
        movwf   rc              ; save char in scratch register
        call    WaitLcdRdy      ; check if lcd is ready
        movf    rc,W            ; restore data from scratch register
        iorlw   LCD_DATA        ; set write data bit
        call    WrLcdNibble     ; write the nibble
                                ; now do lsn
        swapf   rc,W            ; get char back and swap nybbles
        iorlw   LCD_DATA        ; set write data bit
;        call    WrLcdNibble     ; write the nibble
;        return

;
; **************************************************************************
; write a nibble to the lcd, namely the msn
; you must setup LCD_DATA, for either data(1) or command(0) before calling
; also need the dptr set up to lcd_write before calling.
; the nibble is in the msn of the accumulator, the lsn is for lcd control bits
; **************************************************************************
WrLcdNibble
        andlw   LCD_READ1       ; Set WRITE (W/R low)
        andlw   LCD_ENAB1       ; make sure that ENABLE is off
        movwf   lcd             ; output data to lcd
        iorlw   LCD_ENAB        ; enable lcd
        movwf   lcd             ; output data to lcd
        andlw   LCD_ENAB1       ; disable lcd
        movwf   lcd
        return

; **************************************************************************
; wait for the lcd to be ready. check the busy flag, and loop if busy
; needs the dptr set to lcd_write before calling
; **************************************************************************
WaitLcdRdy
        movlw   LCD_MASK        ; make sure that data lines are high
        iorwf   lcd,f
        bsf     status,rp0      ; open page 1
        iorwf   lcd,f           ; switch high nybble to inputs
        bcf     status,rp0      ; open page 0
        movlw   LCD_READ        ; set LCD_READ bit
        movwf   lcd             ; write it to the lcd latch
        iorlw   LCD_ENAB        ; enable lcd
        movwf   lcd             ; output data to lcd
wlcd    btfsc   lcd,7           ; wait here till lcd not busy
        goto    wlcd
wlcd1   andlw   LCD_ENAB1       ; disable lcd
        movwf   lcd
        bsf     status,rp0      ; open page 1
        movlw   00h            ; set port B as output
        movwf   lcd
        bcf     status,rp0      ; open page 0
        return

; Constants for LCD
LCD_MOVE_CURS  equ     0E7h  ; set acc.7 to send move command.
LCD_MASK       equ     0f0h  ; set high nybble to be inputs
LCD_ENAB       equ     002h  ; lcd enable bit
LCD_ENAB1      equ     0fdh
LCD_READ       equ     0f4h  ; lcd read/write bit
LCD_READ1      equ     0fbh
LCD_DATA       equ     008h  ; lcd data/status bit
LCD_DATA1      equ     0f7h
MODE_8_BIT     equ     030h  ; set lcd for 8 bit mode
MODE_4_BIT     equ     020h  ; set lcd for 4 bit mode
FUNCTION_MODE  equ     020h  ; set lcd for 4 bit, 5x7, 1 line
DISP_MODE      equ     00Fh  ; set lcd for disp on, cursor on
SHIFT_DISP_R   equ     01ch  ; shift display right
SHIFT_DISP_L   equ     018h  ; shift display left
SHIFT_CRSR_R   equ     014h  ; shift cursor right
SHIFT_CRSR_L   equ     010h  ; shift cursor left
LCD_SH_DISP    equ     007h  ; display entry mode shift display
LCD_SH_CRSR    equ     006h  ; display entry mode shift cursor
LCD_HOME       equ     002h  ; move cursor home
LCD_CLR        equ     001h  ; clear lcd
delay1         equ     010h  ; LCD write delay
delay2         equ     0ffh  ; display delay

;
; Port B bit assignment:
;
; 7 - DB7, LCD status
; 6 - DB6
; 5 - DB5
; 4 - DB4
; 3 - RS register select
; 2 - R/W read / write
; 1 - E enable
; 0 - IR output
;

        end

