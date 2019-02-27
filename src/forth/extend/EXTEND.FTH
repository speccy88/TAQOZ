TAQOZ
( > )
$1FA := DIRA
$1FB := DIRB
$1FC := OUTA
$1FD := OUTB
$1FE := INA
$1FF := INB
{
: GLITCH	PIN L H F ;
: GLITCHES BEGIN 60 0 DO I GLITCH LOOP KEY UNTIL ;

}

( CLOCK MODES )
---	 1098_7654_321098_7654321098_7654_32_10
---	 0000_000E_DDDDDD_MMMMMMMMMM_PPPP_CC_SS
long _clk   _clk ~
long _fin
--- set the
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
: RCSLOW	1 HUBSET _clk ~ ;
: RCFAST	0 HUBSET _clk ~ ;

: CC		3 AND 2 << $0C CLK! ;
: 15PF		2 CC ;
: 30PF		3 CC ;
: 0PF		1 CC ;
: XPF		0 CC ;

12000000	:= _xin
: XIN		' _xin 2+ ! ;

long _baud 3 M _baud !	( DEFAULT 3M BAUD )

: CONBAUD	DUP _baud ! 63 PIN DUP RXD 62 PIN TXD ;
--- Set P2 CLOCK to selected MHZ ( simple PLL settings only )
: CLOCK ( HZ --- )
	' CLKHZ 2+ !
	30PF PLLEN _xin 1,000,000 U/ XIDIV
	CLKHZ 1,000,000 U/ VCOMUL 1 PLLDIV
\	_xtal @ IF USEXTAL ELSE USEPLL THEN
	USEPLL
	_baud @ CONBAUD
	;
\ 30PF PLLEN 1 XIDIV

: @MHZ	M CLOCK ;

: .CLK
	CLKHZ 1 M // 0=
 	IF CLKHZ 1 M U/ . ." MHz" ELSE CLKHZ .DECL ." Hz" THEN
 ;

: SLOW		40 @MHZ ;
: ECO		80 @MHZ ;
: CRUISE	180 @MHZ ;
: TURBO		250 @MHZ ;
: HYPER		340 @MHZ ;
: FLANK		360 @MHZ ;



: .LAP
	LAP@ LAP LAP LAP@ -
	( cycles/clkhz )
	DUP .DECL ."  cycles = "
	1,000,000 CLKHZ 1000 U/ */  ( scale cycles to nanoseconds )

	.DECL ." ns @" .CLK
	;



( > )
\ fibonacci - iterative method - but skip test for n = 0
: fibo ( n -- f )  	0 1 ROT FOR BOUNDS NEXT DROP ;

: fibos  1 46 ADO CRLF ." fibo(" I . ." ) = " LAP I fibo  LAP .LAP ."  result =" . 5 +LOOP ;
: .fibo  CRLF ." fibo(" DUP . ." ) = " LAP  fibo  LAP .LAP ."  result =" .  ;

{
\ fibonacci test - just a Q&D one liner
340 M CLOCK
1 46 ADO CRLF ." fibo(" I . ." ) = " LAP I fibo  LAP .LAP ."  result =" . 5 +LOOP
100 M CLOCK

320 @MHZ 360 @MHZ fibos 180 @MHZ
360 @MHZ fibos CRUISE
320 @MHZ 320 60 ADO I @MHZ fibos 320 @MHZ LOOP CRUISE



}

{
---             1098_7654_321_0987654321098_76_54321_0
SMARTPIN D/# = %AAAA_BBBB_FFF_PPPPPPPPPPPPP_TT_MMMMM_0
}
long _sp
: B! ( bitpos bits -- )		|< 1- OVER << _sp CLR ;
: ASEL 	28 4 B! ;
: BSEL	>N 24 << OR ;
: INV	8 OR ;
: FILT	7 AND 21 << ;



\ PUBLIC
--- ANSI color values ---
0	:= black
1	:= red
2	:= green
3	:= yellow
4	:= blue
5	:= magenta
6	:= cyan
7	:= white

\ PRIVATE
long _ansi 1 _ansi !
pri ANSI?			uemit W@ 0= _ansi @ 0<> AND ;
pri AEMIT			ANSI? IF EMIT ELSE DROP THEN ;
pub ESC ( ch -- )		$1B AEMIT AEMIT ;

pub HOME			'H'
pri ESCB ( ch -- )		'[' ESC AEMIT ;

pub PEN ( col -- )		7 AND '3'
pri COL ( col fg/bg -- )	ESCB '0' + AEMIT 'm' AEMIT ;
pub PAPER ( col -- )		'4' COL ;

pri CUR ( cmd n -- )		'[' ESC SWAP
pri .PAR			SWAP ANSI? IF .DEC ELSE DROP THEN AEMIT ;
pub XY ( x y -- )		';' SWAP CUR 'H' .PAR ;


--- Erase the screen from the current location
pub ERSCN			'2' ESCB 'J' AEMIT ;
--- Erase the current line
pub ERLINE			'2' ESCB 'K' AEMIT ;

pub CLS 			HOME ERSCN $0C EMIT ;


pub CURSOR ( on/off -- )	'?' ESCB 25 .
pri asw				IF 'h' ELSE 'l' THEN AEMIT ;

pub PLAIN			'0'
pri ATR ( ch -- )		ESCB 'm' AEMIT ;
pub REVERSE			'7' ATR ;
pub BOLD			'1' ATR ;

pub WRAP ( on/off -- )		'?' ESCB '7' AEMIT asw ;

pub MARGINS ( top bottom -- )	'[' ESC SWAP ':' .PAR 'r' .PAR ;

--- res = 1B5B.306E
pub ?ANSI 			 _ansi ~~ '5' ESCB 'n' EMIT 100 ms 0 4 FOR 8<< KEY OR NEXT _ansi ! ;


pub BACKUP			$0F.0000 SFER64 200 ms " TAQO" 4 $! 0 $0F.0000 $1.0000 SFWRS ;

pub TX		WYPIN ;
pub SERIAL ( pin -- )           PIN ' TX uemit W! ;


( > )
END
