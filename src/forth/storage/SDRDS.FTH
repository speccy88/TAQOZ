
512	:= BLKSIZ

: STAT@		0 13 CMD SDRES 8<< OR ;
: SDWAIT	1000 BEGIN 1- SDRES $FE = OVER 0= OR UNTIL DROP  ;

--- Read multiblock sectors from SD into dst
pub SDRDS    ( sector dst bytes -- crc | false )
	BLKSIZ ALIGN 9>> -ROT
	SWAP #18 CMD ( data cmd -- res )			--- read block command
	IF
	  --- didn't like that command - discard dst & return false
	  2DROP FALSE
	ELSE
	  --- process read token and read block if available
	  SDRES $FE = IF SWAP FOR DUP SDRDBK DROP SDWAIT BLKSIZ + NEXT DROP
	   ELSE 2DROP 16 CLKS STAT@ DROP SPICE FALSE THEN
	THEN
	--- release the SD card
	8 CLKS SPICE
	---  save crc/flg
\	DUP _sdrd !
	1000 BEGIN 1- 0 12 CMD 0= OVER 0= OR UNTIL DROP
	SPICE
	;
