TAQOZ
{
use this version to extend TAQOZ V1.0 in ROM

P2-ES uses 20MHz crystal
}


$1FA := DIRA
$1FB := DIRB
$1FC := OUTA
$1FD := OUTB
$1FE := INA
$1FF := INB

61	:= SDCK
60	:= SDCS
59	:= SDDI
58	:= SDDO


long _baud 115200 _baud !

: CONBAUD	DUP _baud ! 63 PIN DUP RXD 62 PIN TXD ;

( CLOCK MODES )
---	 1098_7654_321098_7654321098_7654_32_10
---	 0000_000E_DDDDDD_MMMMMMMMMM_PPPP_CC_SS
long _clk

: RCSLOW	1 HUBSET _clk ~ ;
: RCFAST	0 HUBSET _clk ~ ;

--- set the clock mode
: CLKSET 	_clk @ HUBSET ;
( PLL should run between 100 to 200MHz )
: CLK! ( data mask -- )	_clk @ SWAP ANDN OR _clk ! ;
: PLLEN		24 |< _clk SET ;
: PLLOFF	24 |< _clk CLR ;

: XIDIV ( 1..64 -- ) 	1- $3F AND 18 << $00FC0000 CLK! ;

( ends up as multiply)
: VCOMUL ( 1..1024 -- ) 1- $3FF AND 8 << $3FF00 CLK! ;

--- Divide the PLL by 1 2 4 6 ... 30 for the system clock when SS = %11
: PLLDIV ( 2..30 -- ) 	2/ 1- $0F AND 4 << $0F0 CLK! ;

: CLKSRC	CLKSET DUP 1 > IF 200,000 WAITX THEN 3 AND 3 CLK! CLKSET ;

: USEPLL 	3 CLKSRC ;
: USEXTAL	2 CLKSRC ;

: CC		3 AND 2 << $0C CLK! ;
: 15PF		2 CC ;
: 30PF		3 CC ;
: 0PF		1 CC ;
: XPF		0 CC ;

12,000,000	:= _xin		--- P2D2
: XIN		' _xin 2+ ! ;


--- Set P2 CLOCK to selected MHZ ( simple PLL settings only )
: CLOCK ( HZ --- )
	' CLKHZ 2+ !
	_xin @ 20,000,000 =
	IF ( P2-ES )
	  15PF PLLEN 1 XIDIV
	  _xin / VCOMUL 1 PLLDIV USEXTAL
	ELSE
	  30PF PLLEN _xin 1,000,000 U/ XIDIV CLKHZ
	  1,000,000 U/ VCOMUL 1 PLLDIV USEPLL
	THEN
	_baud @ CONBAUD
	;

--- setup for P2-ES instead
: P2-ES		20,000,000 XIN ;
: P2D2		12,000,000 XIN ;

: P2MHZ		RCFAST M CLOCK ;

: SLOW		40 P2MHZ ;
: ECO		80 P2MHZ ;
: CRUISE	180 P2MHZ ;
: TURBO		240 P2MHZ ;
: HYPER		320 P2MHZ ;


\ ' 12-bit analog to digital to analog, 19.5k samples/second

pub DAC ( bits -- )	%101000000000001000110 WRPIN |< WXPIN L ;

pub ADC12
	@PIN DUP 1+ PIN %100011000000000000000 WRPIN
  	PIN %10000000000000000000000011000 WRPIN 4096 WXPIN L
	;


: PWM ( duty frame div -- )	$52
: PWM1				L WRPIN SWAP 16 << + WXPIN WYPIN ;
: TRI ( duty frame div -- )	$52 PWM1 ;



: U.R	<# FOR # NEXT #> PRINT$ ;

: .CLK
	CLKHZ 1 M // 0=
 	IF CLKHZ 1 M U/ . ." MHz" ELSE CLKHZ .DECL ." Hz" THEN
 ;

: .LAP
	LAP@ LAP LAP LAP@ -
	( cycles/clkhz )
	DUP .DECL ."  cycles = "
	1,000,000 CLKHZ 1000 U/ */  ( scale cycles to nanoseconds )
	.DECL ." ns @" .CLK
	;

{ MEASURE PIN CAPACITANCE AS A FLOAT TO HIGH TIME }
: ?PIN ( pin --  )
	CRLF ." P" DUP . 9 EMIT
	PIN
	0 8 FOR L 100 us F CNT@ BEGIN R UNTIL CNT@ SWAP - ABS + NEXT 3 >>
	10 U.R
	;
: ?PINS ( from for -- ) ADO I ?PIN LOOP ;


\ fibonacci - iterative method - but skip test for n = 0
: fibo ( n -- f )  	0 1 ROT FOR BOUNDS NEXT DROP ;

: fibos  1 46 ADO CRLF ." fibo(" I . ." ) = " LAP I fibo  LAP .LAP ."  result =" . 5 +LOOP ;
: .fibo  CRLF ." fibo(" DUP . ." ) = " LAP  fibo  LAP .LAP ."  result =" .  ;

END
