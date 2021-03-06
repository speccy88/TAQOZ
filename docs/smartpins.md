{
WRPIN WXPIN WYPIN RDPIN RQPIN AKPIN
MODE = WRPIN
%AAAA_BBBB_FFF_PPPPPPPPPPPPP_TT_MMMMM_0
%AAAA = 0010 - NOT INVERTED - relative +2 pin’s read state
%BBBB = 0000
%FFF = 000 = A, B (default)
%P…P
0000_CIOHHHLLL
0000 - IN = PINA LOGIC - OUT = OUT
C = 0 = LIVE
I = IN = TRUE
HHH = DRIVE = 111 = FLOAT
LLL = 111 = FLOAT
%TT = 00 = OUT DRIVE OUTPUT - OUTPUT DISABLED
%MMMMM = 00000 = SMARTPIN OFF

%AAAA_BBBB_FFF_PPPP.P.P.P.PPP.PPP_TT_MMMMM_0
%0010_0000_000_0000.0.0.0.111.111_00_00000_0
}


#### PULSE OUTPUT
12 PIN F
( %AAAA_BBBB_FFF_PPPP_P_P_P_PPP_PPP_TT_MMMMM_0 )
%1_00100_0 WRPIN
10 WYPIN
12.5ns

1 WXPIN
1 WYPIN
( PULSES DE 12.5ns - 80MHZ )
10 WXPIN ( PULSE DE 125ns)
1000 ( PULSE DE 12.5us)

56 PIN F
%0000_0_0_1_000_000 8 << %1_00100_0 OR WRPIN
30_000 16 << 60_000 OR WXPIN
1 WYPIN
L

#### INVERT PIN
58 PIN
1 14 << WRPIN

1ma drive mode
4 11 << WRPIN


pub FAST			0 ;
pub 1K5				1 ;
pub 15K				2 ;
pub 150K			3 ;
pub 1ma				4 ;
pub 100ua			5 ;
pub 10ua			6 ;
pub OPEN			7 ; ( float )


#### TRANSITION OUTPUT
12 PIN L
%1_00101_0 WRPIN
$FFFF WXPIN
2 WYPIN
{
BIGGEST PULSE IS 820.2us AT 80MHZ
12.5E-9*65536
0.0008192
}

#### NCO FREQUENCY
56 PIN L
%1_00110_0 WRPIN
8000 WXPIN ( 100us )
$FFFF_FFFF 20 100 * U/ WYPIN ( 100ms )
$FFFF_FFFF 20000 U/ WYPIN ( 1s ON 1s OFF )

12 PIN L
%1_00110_0 WRPIN
8000 WXPIN ( 100us )
$FFFF_FFFF 20 U/ WYPIN ( 1ms +WID   500Hz FREQ )

10 WXPIN
$0000_0001 WYPIN
RDPIN .L
------
12 PIN L
%1_00110_0 WRPIN
8000 WXPIN
$1000_0000 WYPIN
BEGIN WAITPIN AKPIN 10 HIGH 50 us 10 LOW KEY UNTIL
---
12 PIN L
%1_00110_0 WRPIN
74 WXPIN
$8000_0000 WYPIN
BEGIN WAITPIN AKPIN 10 HIGH 10 LOW KEY UNTIL
----------


#### NCO DUTY
12 PIN L
%1_00111_0 WRPIN
8000 WXPIN ( 100us )
$FFFF_FFFF 20 U/ WYPIN ( 100us +WID   2ms PERIOD   5% DUTY   500Hz FREQ )

#### PWM TRIANGLE
12 PIN L
%1_01000_0 WRPIN
100 16 << 800 OR WXPIN ( 10us * 100 = 1ms )
50 WYPIN ( 50% DUTY   FREQ 500Hz   PERIOD 2ms )
20 WYPIN ( 20% DUTY )

100 16 << 80 OR WXPIN ( 1us * 100 = 100us )
35 WYPIN ( 35% DUTY   FREQ 5kHz   PERIOD 200us )

#### PWM SAWTOOTH
12 PIN L
%1_01001_0 WRPIN
100 16 << 800 OR WXPIN ( 10us * 100 = 1ms )
50 WYPIN ( 50% DUTY   FREQ 1kHz   PERIOD 1ms )
20 WYPIN ( 20% DUTY )

100 16 << 80 OR WXPIN ( 1us * 100 = 100us )
35 WYPIN ( 35% DUTY   FREQ 10kHz   PERIOD 100us )

#### DAC
pub DAC ( bits -- )	%101000000000001000110 WRPIN |< WXPIN L ;
pub V ( volts*1000 --- )	$1.0000 3300 */ WYPIN ;
38 PIN 12 DAC
1.850 V

#### ADC ( https://forums.parallax.com/discussion/comment/1462605#Comment_1462605 )
pub ADC ( cycles -- )	F %100_011_0000000_00_01111 WRFNC WXPIN 0 WYPIN L ;
64 words amin	64 words aref
: AREF	@PIN 2* aref + ;
: AMIN	@PIN 2* amin + ;
pub SETADC ( min ref -- )	AREF W! AMIN W! ;
pub VOLTS@ ( -- volts*1000 )	RDPIN AMIN W@ - 1000 AREF W@ */ ;
TAQOZ# 24 PIN 40,000 ADC ---  ok
TAQOZ#  ---  ok
TAQOZ# RDPIN . --- 6903 ok
TAQOZ# 6903 AMIN W! ---  ok

#### SYNC SERIAL
NCO_FREQ =%0000_0000_000_00000_00000000_01_00110_0
SYNC_TX = %0000_1001_000_00000_00000000_01_11100_0 ' sync serial tx using pin+1 as clk
SYNC_TX = %0000_1010_000_00000_00000000_01_11100_0 ' sync serial tx using pin+2 as clk
%1010 24 << %1_11100_0 OR := SYNC_TX
%1_00110_0 := NCO_FREQ
12 PIN NCO_FREQ WRPIN 1000 WXPIN $8000_0000 WYPIN L
10 PIN SYNC_TX WRPIN %011111 WXPIN $F000_000F WYPIN L
$000F_1000 REV WYPIN
$F00F_0000 REV WYPIN

#### SYNC SERIAL 2
%0010 24 << %1_11100_0 OR := SYNC_TX ( FALLING EDGE NON INVERTED )
%1_00110_0 := NCO_FREQ
12 PIN NCO_FREQ WRPIN 1000 WXPIN $8000_0000 WYPIN L
10 PIN SYNC_TX WRPIN %011111 WXPIN $F000_000F WYPIN L
$00FF_FFFF FOR I WYPIN NEXT
