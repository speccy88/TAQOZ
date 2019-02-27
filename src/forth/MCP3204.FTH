TAQOZ

--- define SPI pins
   8   := *SCLK    9   := *MISO    10   := *MOSI    11   := *CS
( cmdbits and inbits are fixed and only used inside single word )

&11.9.10.8 := PINS3204

: PIN! ( dat0 pin -- )	SWAP 1 AND IF HIGH ELSE LOW THEN ;
: MOSI! ( state -- )	*MOSI PIN! ( ALSO CLOCKS BIT )
: clockbit   		*SCLK HIGH *SCLK LOW ;

---       sendcmd    Send 1 startbit (high), 4 command bits, 1 don't care bit
: CMD3204 		( channel  --  )

	*CS HIGH *SCLK LOW *CS LOW
	%11000 OR   	(  command )
	27 << REV ( flipped command<<32-CM )
	--- clock command bits plus dummy don't care bit
	6 FOR DUP MOSI! 2/ NEXT DROP
	;

---   END 3204 sendcmd

--- Receive 13 bits from 3204 but first bit is null anyway
: GET3204 ( -- 12bit_raw )
	0 13 FOR 2* *MISO pin@ 1 MOSI! 1 AND or *MOSI LOW NEXT
	$FFF AND ( optional mask - mainly for dummy testing )
	*CS HIGH
	;

--- Calculate volts from 12bit raw
: volts ( 12bit raw -- volts x 10 )  500 4095  */ ;

--- main word
: RAW3204 ( chan -- data  )			CMD3204 GET3204 ;

--- Get data from all 4 channels and display it
: go3204    4 0 do CRLF i .AS" ch#| # " i RAW3204 DUP .AS" raw=####  " volts .AS" #.## volts "  loop CRLF ;

--- **** Type go3204 to run program  ****
END
