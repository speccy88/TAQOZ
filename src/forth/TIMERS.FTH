
(	*** RTC and TIMERS ***		)




( REAL-TIME CLOCK )

{ HELP TIMER ( <name> -- )
create a timer variable (replaces DOUBLE)
ms(4), alarm/mode(2), link(2), tid(1), nu(1), nu(2)
}
pre TIMER			( 4 ALIGNORG ) DATPTR W@ 16 ERASE 4 [C] LONGS ;


\ Define variables used by the background timer cog
{
PUBLIC
1 cword timers		--- link to timers - set to 1 as last
PRIVATE
byte tid
}
CLKFREQ #1000 / == ttint				\ define the timing constant ( writable constant )

( Background timer API )

{ New timer methods that allow modules to link their timers into the background countdown process
add a timer to the list of timers to countdown,
addr points to 2 longs, first is the timer, second is both the alarm word and the link word
last timer has a link word of 0
link->TIMER3->TIMER2->TIMER1->0
}
{
--- Set the timeout period in ms for this timer - link and init if not already set
pub TIMEOUT ( ms addr --  )
 	SWAP OVER ! --- set it and link it if it has not been linked yet
pri +TIMER ( addr -- )
	--- discard and ignore if already linked
 	DUP 8 + C@ tid C@ = IF DROP EXIT THEN
	--- set tid
 	tid C@ OVER 8 + C!
	--- link in new timer (first one is set to 1 )
   	timers W@ OVER 6 + W!
	--- save latest in timers
 	timers W!
	;

pub COUNTUP ( addr -- \ countup timer mode )
 	1 SWAP
	DUP +TIMER
pub ALARM ( pfa addr -- \ Set an alarm action to perform once timeout occurs )
	4+ W!
	;
pub TIMEOUT? ( addr -- flg \ check if this timer has timed out )
	@ 0=
	;

TIMER wdt
pub WATCHDOG ( ms -- )		wdt TIMEOUT ;




PUBLIC
long	runtime

PRIVATE
8 bytes rtcbuf

4 bytes @time
4 bytes @date
2 bytes @day


pri rtcbuf@	rtcbuf + C@ ;
pri rtcbuf!	rtcbuf + C! ;



--- I2C RTC DRIVERS ---

--- RTC I2C ADDRESS psuedo constant
pub @rtc		0 ;

--- selects type of I2C RTC chip used
--- DS3231 is fairly generic f
pub DS3231		$D0
pri =rtc		' @rtc C! ;
pub MCP79410	$DE =rtc ;
---  EEPROM of MCP79410 - access with RTC@/RTC!
pub RTCEE		$AE =rtc ;
pub NORTC		0 =rtc ;


--- Start and address RTC device
pri <RTC			I2C400 <I2C @rtc I2C! ;
--- restart and read RTC device
pri <RTC>			<I2C> @rtc 1+ I2C! ;

--- Read first 8 timekeeping bytes of RTC into rtcbuf
pub RDRTC
	@rtc 0EXIT <RTC 0 I2C! <RTC>
	  rtcbuf 8 ADO ackI2C@ I C! LOOP nakI2C@ DROP I2C>
	;

--- Write first 8 timekeeping bytes of RTC from rtcbuf
pub WRRTC
	@rtc 0EXIT <RTC 0 I2C!
	  rtcbuf 8 ADO IC@ I2C! LOOP I2C>
	;

pub RTC! ( byte addr -- )	<RTC I2C! I2C! I2C> ;

pub RTC@ ( addr -- byte )	<RTC I2C! <RTC> nakI2C@ I2C> ;
\ pub RTCW@ 					DUP RTC@ 8<< SWAP 1+ RTC@ + ;

--- Select RTC as a DUMP device - byte method only
pub RTC						DUMP: RTC@ RTC@ RTC@ ;

pub BCD>DEC ( bcd -- dec )	DUP >N SWAP 4 >> 10 * + ;

pub DEC>BCD ( dec -- bcd )	10 U/MOD 4 << + ;

--- read HHMMSS time in decimal format
pub TIME@ ( -- #hhmmss )
    @time @ 1000 /
    60 U/MOD ( sec x ) 60 U/MOD ( sec mins hrs ) 24 MOD 10000 * SWAP 100 * + +
    ;

--- split 6 digit decimal number into 3 two digit groups
pri HMS ( #xxyyzz -- zz yy xx )		100 U/MOD 100 U/MOD ;

--- read international date in decimal format
pub DATE@ ( -- #yymmdd )
	@date @ DUP 0= IF DROP 010101 THEN
	;

pub TIME! ( hh.mm.ss -- )
	0
--- write time/date in decimal format where d/t = 4 for date
pub DT! ( hh.mm.ss|yy.mm.dd d/t -- )
	@rtc
	IF
	  RDRTC
	  4 AND 2DUP @time + !
	  OVER HMS ( yymmdd n dd mm yy )
	  DEC>BCD 4TH 2+ rtcbuf!
	  DEC>BCD 3RD 1+ rtcbuf!
	  --- ensure some RTC devices have a 'RUN' bit set otherwised it is ignored.
          DEC>BCD $80 OR OVER rtcbuf!
	  WRRTC
	THEN
--- write soft time/date in decimal format where d/t = 4 for date
pub SDT! ( hh.mm.ss|yy.mm.dd d/t -- )
	4 AND DUP NOT
	  IF DROP HMS 60 * SWAP + 60 * + 1000 * 0 THEN
	@time + !  --- time stored in milliseconds
	;

pub DATE! ( yy.mm.dd -- )	4 DT! ;
{
--- Days of the week constants
PUBLIC
1 == MON
2 == TUE
3 == WED
4 == THU
5 == FRI
6 == SAT
7 == SUN
}
pub DAY@ ( -- day )			@day C@ 1 MAX ;

--- set DAY as in MON DAY etc
pub DAY ( day -- )
     DUP @day C!
     @rtc IF 3 rtcbuf@ 7 ANDN + 3 rtcbuf! WRRTC ELSE DROP THEN
     ;

pub .DAY ( n -- )	1 7 LIMIT 1-  3 * " MonTueWedThuFriSatSun" + 3 CTYPE ;

pub .TIME
     TIME@ ':'

pri .DTF ( value sep -- )
     SWAP #10 >RADIX <# # # OVER HOLD # # SWAP HOLD # # #> PRINT$ RADIX>
     ;

--- Print date in international format YYYY/MM/DD
pub .DATE        20 . DATE@ '/' .DTF ;

pub .ASMONTH ( index -- )
    >N 1- 3 * " JanFebMarAprMayJunJulAugSepOctNovDec" + 3 CTYPE
    ;


\ 8 cbytes tz$
8 bytes tz$

pub TZ ( str -- )	tz$ $! ; \ tz$ DUP 8 ESAVEB ;

" UTC " TZ

pub .DT		TIME@ DATE@ DAY@
( Tue, 03 Dec 2013 04:19:05 GMT )
pri .DTS ( time date day -- )
	.DAY ',' EMIT HMS
	SPACE ROT $420A PRINTNUM
	SPACE SWAP .ASMONTH SPACE
	DUP 100 < IF 2000 + THEN PRINT
	SPACE ':' .DTF SPACE tz$ PRINT$ CR
	;

{

TACHYON
1	== January
2	== February
3	== March
4	== April
5	== May
6	== June
7	== July
8	== August
9	== September
10	== October
11	== November
12	== December

pub am ;
pre pm			1200 + ;

pri SetClock		10000 * SWAP 100 * + + DATE! DAY 100 * TIME! ;
pre Monday, 1		DEFER SetClock ;
pre Tuesday, 2		DEFER SetClock ;
pre Wednesday, 3	DEFER SetClock ;
pre Thursday, 4		DEFER SetClock ;
pre Friday, 5		DEFER SetClock ;
pre Saturday, 6		DEFER SetClock ;
pre Sunday, 7		DEFER SetClock ;
END


5:29 pm
Monday, 23 October 2017



}


--- STAMP@ returns a 32-bit millisecond time + day of month in top 5-bits
pub STAMP@ ( --- dhmsc )	@time @ @day 1+ C@ 27 << + ;


--- read temperature from DS3231
pub 'C ( -- 'C*100 )		@rtc IF $12 RTC@ $11 RTC@ B>W 6 >> 25 * ELSE 0 THEN ;
pub 'F ( -- 'F*100 )		'C 9 5 */ 3200 + ;
pub .TEMP			'C <# # # '.' HOLD #S #> PRINT$ PRINT" 'C " ;

( TIMERS )
--- Maintain chained list of TIMERS
--- by default count down 32-bits to zero every millisecond if set
pri CountDown
	--- next timer
	timers W@
 	BEGIN
	  --- link to another timer?
 	  DUP $FF >
	WHILE
	  --- count up mode? (ALARM=1)
 	  DUP 4+ W@ 1 =
 	  IF
	    --- simple count up mode
 	    DUP ++
 	  ELSE --- count down if non-zero
 	    DUP @ ?DUP
 	    IF
	      --- decrement non-zero timer and udate
 	      1- DUP 3RD !
	        --- if now zero then execute valid alarm if set
 	        0= IF DUP 4+ W@ DUP 4 >>
 	          IF CALL ELSE DROP THEN
 	        THEN
 	    THEN
 	  THEN
	  --- follow link to next timer
 	  6 + W@
 	REPEAT
 	DROP
	;


{ DS3231 REGISTERS  --- typical arrangement of most RTCs with minor differences

	7	6	5	4	3	2	1	0
00	0	----10 seconds---	------ seconds ----------
01	0	----10 minutes---	------ minutes ----------
02	0	12/24	PM --------------- hours ----------------
03	0	0	0	0	0	----- day -------
04	0	0	--date---	---------- date ---------
05	cent	0	0	--------- month -----------------
06	--------- 10 year -------	-------- year -----------
0E	/eosc	bbsqw	conv	-	-	intcn	A2IE	A1IE
11	sign------------------ temperature msb ------------------
12	-- t lsb --

}
pub !RTC
	--- set some defaults in case hardware is not present
	010101 4 SDT! 0 0 SDT! MON @day C!
	--- skip if no hardware RTC has been set
	@rtc 0EXIT
	--- otherwise buffer current RTC readings
	RDRTC
	--- read hours and convert to minutes
	2 rtcbuf@ $3F AND BCD>DEC 60 *
	--- read minutes, acc and convert to seconds
	1 rtcbuf@ BCD>DEC + 60 *
	--- read seconds and acc
	0 rtcbuf@ $7F AND BCD>DEC +
	--- convert to millisec and update soft rtc
	1000 * @time !				--- resynch soft rtc
	--- read year and decimal shift 4 places
	6 rtcbuf@ BCD>DEC #10000 *
	--- read month and decimal shift 2 places and acc
	5 rtcbuf@ $1F AND BCD>DEC 1 12 LIMIT #100 * +
	--- read date and acc
	4 rtcbuf@ $3F AND BCD>DEC 1 31 LIMIT DUP @day 1+ C! +
	--- latch date
	@date !
	--- day
	3 rtcbuf@ 7 AND 1 MAX @day C!
	;



--- --- --- --- TIMERS --- --- --- ---


--- create a timer variable (replaces DOUBLE)
--- ms(4), alarm/mode(2), link(2), tid(1), nu(1), nu(2)
pre TIMER		#12 [C] BYTES ;


\ Define variables used by the background timer cog

\ LONG	runtime
BYTE	_seconds
BYTE	_minutes
BYTE	_hours
BYTE	_days
LONG	_date
\ WORD	timers				--- link to timers
\ BYTE	tid
\ 1 timers W!				--- last link

\ CLKFREQ #1000 / == ttint				\ define the timing constant ( writable constant )

( Background timer API )

{ New timer methods that allow modules to link their timers into the background countdown process
add a timer to the list of timers to countdown,
addr points to 2 longs, first is the timer, second is both the alarm word and the link word
last timer has a link word of 0
link->TIMER3->TIMER2->TIMER1->0
}
pri +TIMER ( addr -- )
 	DUP 8 + C@ tid C@ = IF DROP EXIT THEN --- discard and ignore if already linked
 	tid C@ OVER 8 + C! --- set tid
   	timers W@ OVER 6 + W! --- link in new timer (first one is set to 1 )
 	timers W! --- save latest in timers
	;
pub TIMEOUT ( ms addr -- \ Set the timeout period in ms for this timer - link and init if not already set )
 	SWAP OVER ! --- set it and link it if it has not been linked yet
	+TIMER
	;
pub ALARM ( pfa addr -- \ Set an alarm action to perform once timeout occurs )
	4+ W!
	;

pub COUNTUP ( addr -- \ countup timer mode )
 	1 SWAP ALARM
	;

--- check if this timer has timed out
pub TIMEOUT? ( addr -- flg  )
	@ 0=
	;


pub DAT>NAME ( adr -- nfa \ find the nfa else false )
	@NAMES 1+
	BEGIN
	  DUP NFA>CFA >PFA 4+ @ 3RD = IF NIP EXIT THEN
	  NFA>CFA 3 + DUP C@ 0=
 	UNTIL
	2DROP 0
	;



\ List the timers and their status
pub .TIMERS
      SPACE CLKFREQ ttint / PRINT" ticks = 1/" 0 PRINTDEC 3 SPACES PRINT" runtime = " runtime @ .DEC
 	timers W@
 	BEGIN
 	  DUP $FF >
 	WHILE
 	  CR DUP .W 	  PRINT" : "
	  DUP DAT>NAME DUP PRINT$ LEN$ #17 SWAP - SPACES
 	  DUP @ 6 PRINTDEC ." ms "
 	  ." =" DUP @ .L
 	  ."  L:" DUP 6 + W@ .W
	  SPACE DUP 4+ W@ IF ." ALARM=" DUP 4+ W@ CFA>NFA 1+ PRINT$ THEN
 	  6 + W@								--- fetch the link to the next timer
 	REPEAT
 	DROP
 	;


( WATCHDOG TIMER )
{
Watchdog timer, default action is to reboot, activate from application by specifying a timeout period:
#3000 WATCHDOG --- reload the watchdog timer, if not reloaded within 3 seconds it will reboot
OFF WATCHDOG --- disable watchdog
}

TIMER wdt
pub WATCHDOG ( ms -- )		wdt TIMEOUT ;


( TIMERS )
--- Maintain chained list of TIMERS by counting down 32-bits to zero every millisecond if set
pri CountDown
	timers W@ --- next timer
 	BEGIN
 	  DUP $FF > --- another timer?
	WHILE
 	  DUP 4+ W@ 1 = --- count up mode? (ALARM=1)
 	  IF --- count up mode
 	    DUP ++ --- count up without anything else
 	  ELSE --- count down mode
 	    DUP @ ?DUP --- non-zero?
 	    IF
 	      1- DUP 3RD ! --- decrement non-zero timer and udate
 	        0= IF DUP 4+ W@ DUP 4 >> --- if now zero then execute valid alarm if set
 	          IF CALL ELSE DROP THEN
 	        THEN
 	    THEN
 	  THEN
 	  6 + W@ --- follow link to next timer
 	REPEAT
 	DROP
	;

12 LONGS timerstk		--- allot space for timer data stack (typ. 4 levels)
WORD timerjob
pub TIMERJOB ( cfa -- )		BEGIN timerjob W@ 0= UNTIL timerjob W! ;

{
pub 1SECOND
	_seconds C++ _seconds C@ 60 =>
	  IF _seconds C~ _minutes C++ _minutes C@ 60 =>
	    IF _minutes C~ _hours C++ _hours C@ 24 =>
	      IF _hours C~ _days C++ _days C@ 7 =>
	        IF _days C~
		THEN
	      THEN
	    THEN
	  THEN
	;
pub HHMM@		_hours C@ 100 * _minutes C@ + ;
pub TIME@		HHMM@ 100 * _seconds C@ + ;
pub DATE@		_date @ ;
pub DATE!		_date ! ;
pub DAY@		_days C@ 1+ ;
pub .DAY		DAY@ 1- 3 * " MONTUEWEDTHUFRISATSUN " + 3 CTYPE ;
pub TIME! ( hhmmss -- )		DUP 100 U/MOD 100 U/MOD _hours C! _minutes C! _seconds C! ;

1	== MON
2	== TUE
3	== WED
4	== THU
5	== FRI
6	== SAT
7	== SUN

pub DAY			1- _days C! ;
pub .DT			.DAY SPACE HHMM@ .DEC ;
pub .TIME		_hours C@ 2 PRINTDEC ." :" _minutes C@ 2 PRINTDEC ." :" _seconds C@ 2 PRINTDEC ;
}

pub TIMERTASK ( DESC: Provide background timing functions including alarm actions on timeouts )
	timerjob W~
	--- reset timer chain
	1 timers W!
	--- timer boot id - if timer id is same as this then it has already been added since boot
 	3 tid C+!
	--- clear variables
	runtime ~ _seconds ~
	--- set the WAITCNT DELTA for every millisecond
	ttint DELTA
	--- disable watchdog but link it into the timer list
 	wdt 8 ERASE 0 wdt TIMEOUT
	--- set default watchdog behaviour
	' REBOOT wdt ALARM
	BEGIN
	  --- allow other cogs to get this cog to handle I/O inits etc
 	  timerjob W@ ?DUP IF CALL timerjob W~ THEN
 	  runtime ++
\	  runtime @ 1000 MOD 0= IF 1SECOND THEN
	  --- maintain the linked chain of countdown timers
 	  CountDown
	  --- synch to next heartbeat
	  WAITCNT
	AGAIN
	;

