8 := CLK
9 := MOSI
10 := MISO
11 := SS

long _spihz
byte _msb
byte _cpha
pub !MSB 1 _msb C! ;
pub !LSB 0 _msb C! ;
pub MSB? _msb C@ ;
pub LSB? _msb C@ NOT 1& ;
pub CPHA!  _cpha C! ;
pub CPHA1? _cpha  C@ ;
pub CPHA0? _cpha  C@ NOT 1& ;
pub SPIHZ ( freq -- ) CLKHZ SWAP / DUP 15 << OR _spihz ! ;
pub !CLK ( 0/1 -- )	14 << $48 OR CLK PIN WRPIN _spihz @ WXPIN L ;
pub !MOSI ( b27 -- ) DUP 2/ SWAP 1& XOR 0= 1&	27 << MOSI PIN %0000_0111_000_0000_000_101_101 8 << OR %01_11100_0 OR WRPIN %101000 WXPIN ;
pub !MISO ( bx -- )	DUP DUP 2/ SWAP 1& XOR 27 << MISO PIN %0000_1110_000_0000_000_111_111 8 << OR %01_11101_0 OR WRPIN %000111 SWAP 1& 5 << OR WXPIN ;
pub !DAT ( bx -- )	DUP !MOSI !MISO ;
pub !SPI ( CPOL+CPHA -- ) DUP 1& CPHA! DUP 2/ !CLK !DAT ;

: SPI!@ ( TX_BYTE -- RX_BYTE )
  MOSI PIN F
  MSB? IF REV 23 >> CPHA0? IF 2/ THEN THEN
  LSB? IF CPHA1? IF 2* THEN THEN
  WYPIN L
  MISO PIN L
  CPHA0? IF _spihz @ 17 >> WAITX THEN
  CLK PIN 8 WYPIN WAITPIN
  MOSI PIN F
  SS PIN H
  MISO PIN RDPIN F
  MSB? IF REV ELSE 24 >> THEN
;

{
Setup examples:
15000 SPIHZ
1 !SPI --- Clock Polarity low, phase high
3 !SPI --- Clock Polarity high, phase high
0 !SPI --- Clock Polarity low, phase low
2 !SPI --- Clock Polarity high, phase low

!MSB
!LSB

$AA SPI!@ .BYTE
}
