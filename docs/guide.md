# INDEX
+ [ARITHMETIC](#ARITHMETIC)
+ [BITWISE](#BITWISE)
+ [SHIFT](#SHIFT)
+ [STACK](#STACK)

# ARITHMETIC

## +
*( n1 n2 -- n3 )*

Add top two stack items together and replace with result

```
TAQOZ# 10 5 + . --- 15 ok
```

## 1+
*( n1 -- n2 )*

Increment n1

```
TAQOZ# 10 1+ . --- 11 ok
```

## 2+
*( n1 -- n2 )*

Add 2 to n1

```
TAQOZ# 10 2+ . --- 12 ok
```

## 4+
*( n1 -- n2 )*

Add 4 to n1

```
TAQOZ# 10 4+ . --- 14 ok
```

## -
*( n1 n2 -- n3 )*

Subtract n2 from n1

```
TAQOZ# 10 5 - . --- 5 ok
```

## 1-
*( n1 -- n2 )*

Decrement n1

```
TAQOZ# 10 1- . --- 9 ok
```

## 2-
*( n1 -- n2 )*

Subtract 2 from n1

```
TAQOZ# 10 2- . --- 8 ok
```

## *
*( n1 n2 -- n3 )*

Signed multiply n1 and n2 (32 bits result)
Max 32 bits positive number : 2147483647

```
TAQOZ# 10 5 * . --- 50 ok
```

## 2*
*( n1 -- n2 )*

Multiply n1 by 2 (shift left one bit)

```
TAQOZ# 10 2* . --- 20 ok
```

## 4*
*( n1 -- n2 )*

Multiply n1 by 4 (shift left two bit)

```
TAQOZ# 10 4* . --- 40 ok
```

## W*
*( n1 n2 -- n3 )*

Unsigned 16bit * 16bit multiply -- 32bit result
```
TAQOZ# $1_FFFF 2  * . --- 262142 ok
TAQOZ# $1_FFFF 2 W* . --- 131070 ok
TAQOZ# $FFFF   2 W* . --- 131070 ok
TAQOZ# 65535   2 w* . --- 131070 ok

```

## UM*
*( u1 u2 -- ud. )*

Unsigned 32bit * 32bit multiply -- 64bit result

```
TAQOZ# 1000000000 5 UM* .s ---
 DATA STACK (2)
1   $0000_0001   1
2   $2A05_F200   705032704 ok

```

## /
*( n1 n2 -- n3 )*

Divide n1 by n2

```
TAQOZ# 10 5 / . --- 2 ok
TAQOZ# 10 -5 / . --- -2 ok
```

## U/
*( u1 u2 -- quot )*

Unsigned divide u1 by u2

```
TAQOZ# -4 2 / . --- -2 ok
TAQOZ# -4 2 / U. --- 4294967294 ok
TAQOZ# -4 2 U/ . --- 2147483646 ok
TAQOZ# -4 2 U/ U. --- 2147483646 ok
```

## //
*( n1 n2 -- rem )*

Remainder of n1 divided by n2

```
TAQOZ# 10 3 // . --- 1 ok
```

## U//
*( n1 n2 -- rem quot )*

Divide n1 by n2, return remainder and quotient

```
TAQOZ# 10 3 U// .S ---
 DATA STACK (2)
1   $0000_0003   3
2   $0000_0001   1 ok
```

## UM//
*( Dbl.dividend divisor -- remainder Dbl.quotient)*

64 bits divide

```
TAQOZ# 1000000000 5 UM* .S ---
 DATA STACK (2)
1   $0000_0001   1
2   $2A05_F200   705032704 ok
TAQOZ# 5 UM// .S ---
 DATA STACK (3)
1   $0000_0000   0
2   $3B9A_CA00   1000000000
3   $0000_0000   0 ok
```

## */
*( u1 u2 div1 -- res )*

Multiply u1 and u2 and divide result by div1

```
TAQOZ# 10 5 2 */ . --- 25 ok
```

## SQRT
*( d. -- sqrt )*

Square root of 64 bits number d.

```
TAQOZ# 100 0 SQRT . --- 10 ok
TAQOZ# 1000000000 1000 UM* SQRT . --- 1000000 ok
TAQOZ# 1000000 1000000 UM* SQRT . --- 1000000 ok
```

## NEGATE
*( n1 -- n2 )*

equivalent to n2 = 0 - n1

```
TAQOZ# 10 NEGATE . --- -10 ok
```

# BITWISE

## NOT
*( n1 -- n2 )*

bitwise invert n1 and replace with result n2

```
TAQOZ# $FFFF_0000 NOT .L --- $0000_FFFF ok
TAQOZ# %1111 NOT .BIN --- %11111111111111111111111111110000 ok
```

## AND
*( n1 n2 -- n3 )*

bitwise n1 & n2 replace with result n3

```
TAQOZ# $AAAA_AAAA $0000_FFFF AND .L --- $0000_AAAA ok
TAQOZ# $DEAD_BEEF -1 AND .L --- $DEAD_BEEF ok
TAQOZ# $DEAD_BEEF 0  AND .L --- $0000_0000 ok
```

## ANDN
*( n1 n2 -- n3 )*

bitwise n1 & !n2 replace with result n3

```
TAQOZ# $AAAA_AAAA $0000_FFFF ANDN .L --- $AAAA_0000 ok
TAQOZ# $DEAD_BEEF -1 ANDN .L --- $0000_0000 ok
TAQOZ# $DEAD_BEEF 0  ANDN .L --- $DEAD_BEEF ok
```

## OR
*( n1 n2 -- n3 )*

bitwise n1 | n2 replace with result n3

```
TAQOZ# $AAAA_AAAA $0000_FFFF OR .L --- $AAAA_FFFF ok
TAQOZ# $DEAD_BEEF -1 OR .L --- $FFFF_FFFF ok
TAQOZ# $DEAD_BEEF 0  OR .L --- $DEAD_BEEF ok
```

## XOR
*( n1 n2 -- n3 )*

bitwise n1 ⊕ n2 replace with result n3

```
TAQOZ# $AAAA_AAAA $0000_FFFF XOR .L --- $AAAA_5555 ok
TAQOZ# $AAAA_5555 -1 XOR .L --- $5555_AAAA ok
TAQOZ# $AAAA_5555 0  XOR .L --- $AAAA_5555 ok
```

# SHIFT

# OTHER

#### TASK
```
: BLINKY BEGIN 5 HIGH 100 ms 5 LOW 100 ms KEY UNTIL ;
: BLINKER ( pin ms -- ) BEGIN OVER HIGH DUP ms OVER LOW DUP ms KEY UNTIL 2DROP ;
1 NEWCOG
: BLINKER BEGIN 7 HIGH 100 ms 7 LOW 100 ms AGAIN ;
' BLINKER 1 TASK W!
```

#### CONDITIONS
```
0 IF ." TRUE" ELSE ." FALSE" THEN
```

#### LOOP
```
62 56 DO I . SPACE LOOP 56 57 58 59 60 61  ok
62 56 DO I PIN 1 HZ LOOP
CRLF 3 FOR ." HELLO! " NEXT
BEGIN 56 HIGH 100 ms 56 LOW 100 ms AGAIN
BEGIN 5 HIGH 100 ms 5 LOW 100 ms KEY UNTIL
TAQOZ# 10 FOR I . SPACE I 5 = ?NEXT --- 10 9 8 7 6 5  ok
TAQOZ# 10 FOR I . SPACE NEXT --- 10 9 8 7 6 5 4 3 2 1  ok
TAQOZ# 10 0 DO I . SPACE LOOP --- 0 1 2 3 4 5 6 7 8 9  ok
```

#### COMPARE
```
=  <>  <  >
U<  U>  <=  =>
```

#### COMPARE TOS
```
0= 0<> 0<
```

#### SWITCH CASE
```
: SW
SWITCH
1  CASE 1 . BREAK
2  CASE 2 . BREAK
3  CASE 3 . BREAK
4  CASE 4 . SPACE CASE@ . BREAK
10 CASE 10 . CASE@ . BREAK
20 30 CASE> 5 . CASE@ . BREAK
;
```

#### FORMAT
```
12 .AS" 5|"
12 .AS" 5|\"
```

#### DATA
```
datram		= $12000
ramdict         = $14000
Donc 8192 long de user variable
```

#### TABLE
```
pre ,,	[G] 3 FOR 8<< + NEXT [C] , ;

\ 0=0.5 mA, 1=1 mA, 2=5 mA, 3=10 mA, 4=25 mA, 5=35 mA, 6=60 mA, 7=100mA
\ 0=1 mA, 1=5 mA, 2=10 mA, 3=25 mA, 4=35 mA, 5=45 mA, 6=80 mA, 7=200

0 TABLE ma
	000 001 005 010 ,,
	025 035 060 100 ,,
	001 005 010 025 ,,
	035 045 080 200 ,,

TAQOZ# 0 16 ADO I ma + C@ I . ." :" . SPACE LOOP --- 0:0 1:1 2:5 3:10 4:25 5:35 6:60 7:100 8:1 9:5 10:10 11:25 12:35 13:45 14:80 15:200
```

#### LUT
```
' Offsets in LUT for stacks
	datstk          = $000
	brastk          = $020
	lpstk           = $030
	retstk          = $040
	lutfree		= $080
' The LUT is essentially free from $80 onwards
```

#### STRING
```
16 bytes user$ " user" user$ $!
user$ user$ $=
user$ PRINT$
user$ LEN$ .
TAQOZ# 16 bytes user$ " user" user$ $!  ok
TAQOZ#   ok
TAQOZ# user$ PRINT$ user ok
TAQOZ# user$ UPPER$  ok
TAQOZ# user$ PRINT$ USER ok

pub .ASMONTH ( index -- )
    >N 1- 3 * " JanFebMarAprMayJunJulAugSepOctNovDec" + 3 CTYPE
    ;
```

#### BINARY
```
TAQOZ# 0 |< .BIN %00000000000000000000000000000001 ok
TAQOZ# 31 |< .BIN %10000000000000000000000000000000 ok
```

#### CONSTANTS
```
1	:= ONE
2	:= TWO
3	:= THREE
&192.168.0.1		:= myGW
&192.168.0.150		:= myIP
&255.255.255.0		:= mySN
```

#### MODIFY CONSTANTS
```
8 := leds	--- base pin of LED display
: LEDPINS ( pin -- )	' leds :=! ;
16 LEDPINS
```

#### PRE
```
pre PR [C] 4 4 + . ;
pre PR [C] 4 [C] 4 + . ;
pre PR [C] GRAB 4 4 + . ;
```

#### CREATE AND ALLOCATE STRING
```
16 bytes text$ " ALLO" text$ $!
```

#### ALLOCATE STRING
```
" FRED" text$ $!
```

#### PRINT STRING
```
: PR text$ PRINT$ ;
```

#### ITERATE STRING
```
text$ 16 0 DO C@++ EMIT LOOP
text$ 16 0 DO C@++ .B SPACE LOOP
text$ BEGIN C@++ DUP 0= IF TRUE ELSE .B SPACE FALSE THEN UNTIL DROP
```

#### ALLOCATE STRING WITH WORD
```
pre PASS GET$ pass$ $! ;
```

#### CONVERT STRING TO NUMBER
```
$>#
```

#### ANSI COLOR
```
: HELLO CRLF red PEN ." HELLO" blu PEN ."  WORLD" PLAIN ;
: STAR "*" EMIT ;
: STARS FOR RND 6 // 1+ PEN STAR NEXT ;
: P CLS 1 30 ADO I 50 STARS 30 <> IF CRLF THEN LOOP PLAIN ;
4 20 ADO I . LOOP
CRLF 30 FOR I 6 // 1+ . CRLF NEXT
```

#### CHANGE PROMPT
```
: CODEPROMPT HERE .W ." : " ;
' CODEPROMPT uprompt W!


1 byte TEMP1
pre ,, [C] GRAB TEMP1 C! 3 FOR 8<< + NEXT [C] , TEMP1 C@ [C] , ;
```

#### READING MEMORY
```
TAQOZ# $2C COG@ .L --- $0000_F7FF ok
00570 02c 0000f7ff coded			long	$F800-1
```

#### ENCODE (RETURN BIT POSITION OF MSb)
```
TAQOZ# 64 .BIN --- %00000000000000000000000001000000 ok
TAQOZ# 64 >| . --- 6 ok
TAQOZ# 65 >| . --- 6 ok
TAQOZ# -1 >| . --- 31 ok
TAQOZ# 0 >| . --- 0 ok
TAQOZ# 1 >| . --- 0 ok
TAQOZ# 2 >| . --- 1 ok
```

#### DECODE (MASK)
```
TAQOZ# 0 |< .BIN --- %00000000000000000000000000000001 ok
TAQOZ# 1 |< .BIN --- %00000000000000000000000000000010 ok
TAQOZ# 2 |< .BIN --- %00000000000000000000000000000100 ok
```

#### DISPLAY FONT
```
TAQOZ# font5x7 $20 7 * + 96 7 * ADO CRLF I 7 ADO I C@ .B ." ," LOOP 8 EMIT SPACE 7 +LOOP
```

#### CODE EXECUTION SPEED
OVERPLUS	_ret_	add	tos,tos1
```
: OVERPLUS SWAP DUP ROT + ;
TAQOZ# LAP OVER+ LAP .LAP --- 24 cycles= 300ns @80MHz ok
TAQOZ# LAP OVERPLUS LAP .LAP --- 240 cycles= 3,000ns @80MHz ok
```
