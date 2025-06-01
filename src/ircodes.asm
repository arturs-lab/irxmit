	org 0

	db 083h,04Ah,003h,0FCh	; cd_play
	db 083h,04Ah,00Bh,0F4h	; cd_stop
	db 083h,04Ah,004h,0FBh	; cd_next
	db 083h,04Ah,005h,0FAh	; cd_prev
	db 083h,04Ah,007h,0F8h	; cd_pause
	db 083h,04Ah,013h,0ECh	; cd_disc

	db 0D2h,06Dh,000h,0FFh	; class_up
	db 0D2h,06Dh,001h,0FEh	; class_dn
	db 0D2h,06Dh,002h,0FDh	; vol_up
	db 0D2h,06Dh,003h,0FCh	; vol_dn
	db 0D2h,06Dh,004h,0FBh	; power
	db 0D2h,06Dh,005h,0FAh	; mute
	db 0D2h,06Dh,007h,0F8h	; tape2
	db 0D2h,06Dh,008h,0F7h	; tape1
	db 0D2h,06Dh,009h,0F6h	; cd
	db 0D2h,06Dh,00Ah,0F5h	; phono
	db 0D2h,06Dh,00Bh,0F4h	; tuner
	db 0D2h,06Dh,00Dh,0F2h	; video3
	db 0D2h,06Dh,00Eh,0F1h	; video2
	db 0D2h,06Dh,00Fh,0F0h	; video1

	db 0D2h,06Dh,042h,0BDh	; rear_up
	db 0D2h,06Dh,043h,0BCh	; rear_dn
	db 0D2h,06Dh,04Ah,0B5h	; class
	db 0D2h,06Dh,04Ch,0B3h	; surr_mode
	db 0D2h,06Dh,053h,0ACh	; surr_delay
	db 0D2h,06Dh,059h,0A6h	; main_spkr
	db 0D2h,06Dh,05Ah,0A5h	; rem_spkr
	db 0D2h,06Dh,05Dh,0A2h	; sleep
	db 0D2h,06Dh,080h,07Fh	; cntr_up
	db 0D2h,06Dh,081h,07Eh	; cntr_dn
	db 0D2h,06Dh,09Ah,065h	; surr_test
	db 0D2h,06Dh,0C2h,03Dh	; src_up
	db 0D2h,06Dh,0C3h,03Ch	; src_dn
	db 0D2h,06Dh,0CCh,033h	; multisrc

	db 002h,020h,0a0h,008h,000h,015h	; deck_a_stop
	db 002h,020h,0a0h,008h,000h,015h	; deck_a_fwd
	db 002h,020h,0a0h,008h,000h,015h	; deck_a_rev
	db 002h,020h,0a0h,008h,000h,015h	; deck_a_rec
	db 002h,020h,0a0h,008h,000h,015h	; deck_a_ffwd
	db 002h,020h,0a0h,008h,000h,015h	; deck_a_frev

	db 002h,020h,0a0h,008h,000h,0a8h	; deck_b_stop
	db 002h,020h,0a0h,008h,00ah,0a2h	; deck_b_fwd
	db 002h,020h,0a0h,008h,00bh,0a3h	; deck_b_rev
	db 002h,020h,0a0h,008h,008h,0a0h	; deck_b_rec
	db 002h,020h,0a0h,008h,002h,0aah	; deck_b_ffwd
	db 002h,020h,0a0h,008h,003h,0abh	; deck_b_frev
