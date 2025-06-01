; Infra Red remote transmittter
        LIST    p=PIC16C84

;ind0    equ     00h             ; index register
;pcl     equ     02h             ; program counter low byte
;status  equ     03h             ; status register
;fsr     equ     04h             ; file select register
;porta   equ     05h             ; port A
;portb   equ     06h             ; port B
;intcon  equ     0bh             ; interrupt control register
rc      equ     0ch             ; scratch register C
rd      equ     0dh             ; scratch register D
re      equ     0eh             ; scratch register E
rf      equ     0fh             ; scratch register F
rg      equ     10h             ; scratch register 10
rh      equ     11h             ; scratch register 11
romptr  equ     1fh             ; pointer to Eprom location
IRcode  equ     22h             ; location of IR code in RAM
;opt     equ     01h             ; option register
rp0     equ     5
;W       equ     0               ; W is destination
;f       equ     1               ; f is destination

;ROM_DTA equ     07h             ; EPROM data I/O bit
;ROM_CLK equ     02h             ; EPROM clock bit
;ROM_CS  equ     00h             ; EPROM enable bit, active high


IRSlong equ     5ch              ; long sync pulse length
IRSshor equ     2ch              ; short sync pulse
IRDpuls equ     7h               ; light pulse
IRDzero equ     4h               ; no light for "zero"
IRDone  equ     10h              ; no light for "one"


        org     0

        clrf    intcon          ; disable interrupts
        movlw   LCD_MASK        ; setup port B outputs
        movwf   portb
        clrf    porta           ; all outputs low in port A
        bsf     status,rp0      ; open page 1
        clrf    opt             ; clear option register
        bsf     opt,7           ; disable pullup
        movlw   0ch             ; set RA0, RA1 outputs, RA2, RA3 inputs
        movwf   porta
        movlw   001h            ; set port B as output
        movwf   portb             ; except for bit 0
        bcf     status,rp0      ; open page 0
        call    initlcd         ; initialize LCD

        clrf    romptr          ; reset pointer to ROM
        movlw   20h
        movwf   fsr             ; setup RAM address pointer
        movlw   38h             ; initialize message codes to
        movwf   ind0            ; 38 c7 00 ff
        comf    ind0,W
        incf    fsr,f
        movwf   ind0
        incf    fsr,f
        clrf    ind0
        comf    ind0,W
        incf    fsr,f
        movwf   ind0
        call    RomPrt

main    call    rdkbd           ; read keyboard
        movwf   rh
        call    LcdHome
        movf    rh,W
        call    exec            ; execute code for key pressed
        movlw   delay2          ; wait a while...
        call    wait
        call    wait
        goto    main            ; and start over


;
; IR send 4 bytes from RAM location 20h
;
IRSend  movlw   20h
;
; IR send 4 bytes pointed to by W
;
IRSend1 movwf   fsr             ; setup RAM address pointer
IRSync  bsf     porta,1         ; enable IR transmitter
        movlw   IRSlong         ; Sync long pulse
        call    IRwait
        bcf     porta,1         ; disable transmitter
        movlw   IRSshor         ; Sync short pulse
        call    IRwait
IRData  movlw   4               ; number of bytes to be sent
        movwf   rh
IRD2    movlw   8               ; number of bits in a byte
        movwf   rg
        movf    ind0,W
        movwf   rf
IRD1    bsf     porta,1         ; turn on LED
        movlw   IRDpuls         ; load pulse length
        call    IRwait          ; wait
        movlw   IRDzero         ; load delay length for zero
        btfsc   rf,0            ; if bit 0 of byte pointed to by fsr
        movlw   IRDone          ; is set, then use delay for "one"
        bcf     porta,1         ; turn off LED
        call    IRwait
        rrf     rf,f            ; prepare next bit
        decfsz  rg,f            ; decrement counter
        goto    IRD1            ; close inner loop
        incf    fsr,f           ; point to next byte
        decfsz  rh,f            ; check if this was last byte
        goto    IRD2            ; no, continue loop
        bsf     porta,1         ; turn on LED
        movlw   IRDpuls         ; load pulse length
        call    IRwait          ; wait
        bcf     porta,1         ; turn off LED

ret     return                  ; you're done

IRwait  movwf   rd              ; 1                     1 |
IRw1    movlw   23h             ; 1                     1 |
        movwf   re              ; 1                     1 |
IRw2    decfsz  re,f            ; 1/2   |              92 |
        goto    IRw2            ; 2     | 30*3=90+2=92    |100*W
        decfsz  rd,f            ; 1/2                 1/2 |
        goto    IRw1            ; 2                     2 |
        return                  ; 2                     2 |

;
; **************************************************************************
; read word from serial EEPROM and place in location pointed to by fsr
; at EpromRD entry data address is stored there
; at EpromRD1 entry data address is in W
; **************************************************************************
EpromRD1
        movwf   ind0            ; store W in ind0
EpromRD clrf    portb             ; set all outputs low
        bsf     status,rp0      ; open page 1
        bcf     portb,0           ; set RB0 to output
        bcf     status,rp0      ; open page 0
        bsf     portb,ROM_DTA     ; set DI high
        bsf     portb,ROM_CS      ; set CS high
        call    tick1
        call    tick1
        bcf     portb,ROM_DTA     ; clear data bit
        call    tick1           ; READ opcode clocked in, now address
        movlw   006h            ; number of bits in address
        movwf   rc              ; setup counter
erd1    bcf     portb,ROM_DTA     ; begin with address bit = 0
        btfsc   ind0,5          ; check if address bit is high
        bsf     portb,ROM_DTA     ; set data line high if so
        rlf     ind0,f          ; prepare next bit in address
        call    tick1           ; clock in data bit
        decfsz  rc,f            ; decrement counter
        goto    erd1            ; continue loop
        bcf     portb,ROM_DTA     ; address clocked in, now read data
        bsf     portb,ROM_CLK
        bsf     status,rp0      ; open page 1
        bsf     portb,ROM_DTA     ; set RB7 to input
        bcf     status,rp0      ; open page 0
        incf    fsr,f           ; read high byte first
        movlw   008h            ; count data read
        movwf   rc
erd2    rlf     ind0,f          ; prepare ind0 for next bit
        bcf     ind0,0          ; let's clear data bit for starters
        btfsc   portb,ROM_DTA     ; and skip next line if data =0
        bsf     ind0,0          ; but if it is 1, let's correct ind0
        bcf     portb,ROM_CLK     ; send clock pulse
        bsf     portb,ROM_CLK
        decfsz  rc,f            ; decrement counter and see if we're done
        goto    erd2            ; no, continue
        decf    fsr,f           ; now read low byte
        movlw   008h            ; count data read
        movwf   rc
erd3    rlf     ind0,f          ; prepare ind0 for next bit
        bcf     ind0,0          ; let's clear data bit for starters
        btfsc   portb,ROM_DTA     ; and skip next line if data =0
        bsf     ind0,0          ; but if it is 1, let's correct ind0
        bcf     portb,ROM_CLK     ; send clock pulse
        bsf     portb,ROM_CLK
        decfsz  rc,f            ; decrement counter and see if we're done
        goto    erd3            ; no, continue
        clrf    portb             ; clear all lines
        bsf     status,rp0      ; open page 1
        movlw   001h            ; set port B as output
        movwf   portb             ; except for bit 0
        bcf     status,rp0      ; open page 0
        return                  ; done


;
; **************************************************************************
; send clock pulse
; **************************************************************************
tick1   bsf     portb,ROM_CLK     ; set clock high
        bcf     portb,ROM_CLK     ; and reset
        return



RomDec  decf    IRcode,f        ; decrement code to be sent
        comf    IRcode,W
        movwf   IRcode+1
        goto    RomPrt

RomInc  incf    IRcode,f        ; increment code to be sent
        comf    IRcode,W
        movwf   IRcode+1
RomPrt  movlw   20h
        movwf   fsr             ; setup RAM address pointer
        call    hexpr           ; print first byte
        incf    fsr,f
        call    hexpr           ; print second byte
        incf    fsr,f
        call    hexpr           ; print third byte
        incf    fsr,f
        call    hexpr           ; print fourth byte
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
        movlw   0f1h            ; enable keyboard input
        movwf   portb
        bcf     status,rp0      ; open page 0
        swapf   portb,w           ; read keyboard
        movwf   rc              ; store result for a while
        bsf     status,rp0      ; open page 1
        movlw   001h            ; set port B as output
        movwf   portb             ; except for bit 0
        bcf     status,rp0      ; open page 0
        comf    rc,w            ; store result in W
        andlw   0fh             ; clear high nybble
        return
