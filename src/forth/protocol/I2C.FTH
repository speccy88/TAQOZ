TACHYON [~

FORGET *SDA

#P35	== *SDA
#P60	== *SCL			--- clock shared with SPI

BYTE i2cflg
pub I2CSTART
	*SDA HIGH *SCL HIGH
	*SDA LOW 1 i2cflg C! *SCL LOW			--- 12.6us
	;
pub ?I2CSTART 	BEGIN i2cflg C@ 0= UNTIL I2CSTART ;

{ I2C STOP CONDITION also releases I2C lines
 SCL XX-------==
 SDA XX___----==
}
pub I2CSTOP
	*SCL HIGH BL DROP *SDA FLOAT
 	NOP NOP NOP \ *SCL HIGH					--- free up I2C lines
 	0 i2cflg C!						--- i2c bus free
	;

: ICLK	*SCL HIGH BL DROP *SCL LOW ;
--- Write a byte to the I2C bus and return with the ack flag
--- This routine runs at an I2C speed of 400kHz
--- 38.4us
pub I2C!? ( data -- flg )					--- write a byte to the I2C bus and return with the ack  0=ack	)
	REV #24 SHR							--- put into lsb first format for SHROUT
	*SDA HIGH					--- data masks
 	*SDA SWAP
	8 FOR SHROUT ICLK NEXT
	DROP FLOAT						--- Float SDA
	*SCL HIGH *SDA PIN@ 0<> *SCL LOW					--- ack clock
	;


pub I2C! ( data -- )					--- write a byte to the I2C bus but ignore the ack )
	REV #24 SHR						--- put into lsb first format for SHROUT
	*SDA HIGH					--- data masks
	*SDA SWAP
	8 FOR SHROUT ICLK NEXT
	DROP FLOAT					--- Float SDA
	ICLK				--- dummy ack clock
	;

pub I2C@	( ack -- data \ Fetch a byte from the I2C bus - mirror ack signal 0 in = 0 out ) \ 36.6us
	*SDA DUP FLOAT 0  ( ack pin dat )
	  8 FOR *SCL HIGH SHRINP *SCL LOW NEXT
	ROT 0= IF OVER LOW THEN
 	ICLK SWAP FLOAT
	REV						--- flip 8 msbs of long back into 8 lsbs
 	;
pub ackI2C@ 	0 I2C@ ;

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

( REAL-TIME CLOCK )

LONG	runtime
10 BYTES time

--- DS3231 I2C RTC DRIVER ---

$D0    == @rtc        --- device I2C address

--- selects type of I2C RTC chip used
pub DS3231	$D0 ' @rtc CHANGE ;
pub MCP79410	$DE ' @rtc CHANGE ;
pub NORTC	0 ' @rtc CHANGE ;


pub RTC! ( byte addr -- )
    I2CSTART @rtc I2C! I2C! I2C! I2CSTOP
    ;
pub RTC@ ( addr -- byte )
    I2CSTART @rtc I2C! I2C! I2CSTART @rtc 1+ I2C! 1 I2C@ I2CSTOP
    ;

8 BYTES rtcbuf


\ Read first 8 timekeeping bytes of RTC into rtcbuf
pub RDRTC
    @rtc
    IF
      I2CSTART @rtc I2C! 0 I2C! I2CSTART @rtc 1+ I2C!
      rtcbuf 8 ADO 0 I2C@ I C! LOOP 1 I2C@ DROP
      I2CSTOP
    THEN
;
\ Write first 8 timekeeping bytes of RTC from rtcbuf
pub WRRTC
    @rtc
    IF
      I2CSTART @rtc I2C! 0 I2C!
      rtcbuf 8 ADO I C@ I2C! LOOP
      I2CSTOP
    THEN
    ;


LONG time

pub BCD>DEC ( bcd -- dec )
    DUP >N SWAP 4/ 4/ #10 * +
    ;
pub DEC>BCD ( dec -- bcd )
    #10 U/MOD 4* 4* +
    ;

pub TIME@ ( -- #hhmmss ) \ read time in decimal format
    @rtc
    IF
      RDRTC
      rtcbuf 2+ C@ $3F AND BCD>DEC #10000 *
      rtcbuf 1+ C@ BCD>DEC #100 * +
      rtcbuf C@ $7F AND BCD>DEC +
      DUP time !
    ELSE
      time @ 1000 /
      60 U/MOD ( sec x ) 60 U/MOD ( sec mins hrs ) 24 MOD 10000 * SWAP 100 * + +
    THEN
    ;
pub TIME! ( #hh.mm.ss -- ) \ write time in decimal format
    @rtc
    IF
      DUP time !
      RDRTC
      #100 U/MOD SWAP DEC>BCD $80 OR rtcbuf C!		--- ensure some RTC devices have a 'RUN' bit set otherwised it is ignored.
      #100 U/MOD SWAP DEC>BCD rtcbuf 1+ C!
      DEC>BCD rtcbuf 2+ C!
      WRRTC
    ELSE
      100 U/MOD 100 U/MOD 60 * SWAP + 60 * + 1000 * time !
    THEN
    ;



--- read international date in decimal format
pub DATE@ ( -- #yymmdd )
    @rtc
    IF
      RDRTC
      rtcbuf 6 + C@ BCD>DEC #10000 *
      rtcbuf 5 + C@ $3F AND BCD>DEC #100 * +
      rtcbuf 4 + C@ $3F AND BCD>DEC +
      DUP time 4 + !						--- copy to hub memory
      rtcbuf 3 + C@ 7 AND time 8 + C!
    ELSE
       time 4 + @
    THEN
    ;
--- Usage: #130630 DATE! \ set the date to the 30th June 2013
pub DATE! ( #yy.mm.dd -- )
    @rtc
    IF
    DUP time 4 + !						--- copy date to hub memory
    RDRTC
    #100 U/MOD SWAP DEC>BCD rtcbuf 4 + C!
    #100 U/MOD SWAP DEC>BCD rtcbuf 5 + C!
    DEC>BCD rtcbuf 6 + C!
    WRRTC
    ELSE
       time 4 + !
    THEN
    ;

pub DAY@ ( -- day ) --- read the day of the week as 0-6
    time 8 + C@
     ;
pub DAY! ( day -- )
     DUP time 8 + C!
     @rtc IF rtcbuf 3 + C@ 7 ANDN + rtcbuf 3 + C! WRRTC ELSE DROP THEN
     ;
1 == MON
2 == TUE
3 == WED
4 == THU
5 == FRI
6 == SAT
7 == SUN

pri .DTF ( value sep -- )
     SWAP #10 >RADIX <# # # OVER HOLD # # SWAP HOLD # # #> PRINT$ RADIX>
     ;
pub .TIME     TIME@ ":" .DTF ;

--- Print date in international format YYYY/MM/DD (otherwise 1/12/2013 could be 1st of December or 12th of January)
pub .DATE        PRINT" 20" DATE@ "/" .DTF ;

pub .DAY        DAY@ 1- 3 * " MONTUEWEDTHUFRISATSUN" + 3 CTYPE ;

pub .ASMONTH ( index -- )
    >N 1- 3 * " JanFebMarAprMayJunJulAugSepOctNovDec" + 3 CTYPE
    ;
pub .DT        .DATE SPACE .DAY SPACE .TIME ;

--- read temperature from DS3231
pub 'F ( -- 'F*100 )        $12 RTC@ $11 RTC@ B>W ;
pub 'C ( -- 'C*100 )        'F #3200 - 5 * 9 / ;


]~ END
