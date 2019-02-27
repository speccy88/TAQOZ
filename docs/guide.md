#### TASK
```sh
: BLINKY BEGIN 5 HIGH 100 ms 5 LOW 100 ms KEY UNTIL ;
: BLINKER ( pin ms -- ) BEGIN OVER HIGH DUP ms OVER LOW DUP ms KEY UNTIL 2DROP ;
1 NEWCOG
: BLINKER BEGIN 7 HIGH 100 ms 7 LOW 100 ms AGAIN ;
' BLINKER 1 TASK W!
```

#### CONDITIONS
```sh
0 IF ." TRUE" ELSE ." FALSE" THEN
```

#### LOOP
```sh
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
```sh
=  <>  <  >  
U<  U>  <=  =>
```

#### COMPARE TOS
```sh
0= 0<> 0<
```

#### SWITCH CASE
```sh
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
```sh
12 .AS" 5|"
12 .AS" 5|\"
```

#### DATA
```sh
datram		= $12000
ramdict         = $14000
Donc 8192 long de user variable
```

#### TABLE
```sh
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
```sh
' Offsets in LUT for stacks
	datstk          = $000
	brastk          = $020
	lpstk           = $030
	retstk          = $040
	lutfree		= $080
' The LUT is essentially free from $80 onwards
```

#### STRING
```sh
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
```sh
TAQOZ# 0 |< .BIN %00000000000000000000000000000001 ok
TAQOZ# 31 |< .BIN %10000000000000000000000000000000 ok
```

#### CONSTANTS
```sh
1	:= ONE
2	:= TWO
3	:= THREE
&192.168.0.1		:= myGW
&192.168.0.150		:= myIP
&255.255.255.0		:= mySN
```

#### MODIFY CONSTANTS
```sh
8 := leds	--- base pin of LED display
: LEDPINS ( pin -- )	' leds :=! ;
16 LEDPINS
```

#### PRE
```sh
pre PR [C] 4 4 + . ;
pre PR [C] 4 [C] 4 + . ;
pre PR [C] GRAB 4 4 + . ;
```

#### CREATE AND ALLOCATE STRING
```sh
16 bytes text$ " ALLO" text$ $!
```

#### ALLOCATE STRING
```sh
" FRED" text$ $!
```

#### PRINT STRING
```sh
: PR text$ PRINT$ ;
```

#### ITERATE STRING
```sh
text$ 16 0 DO C@++ EMIT LOOP
text$ 16 0 DO C@++ .B SPACE LOOP
text$ BEGIN C@++ DUP 0= IF TRUE ELSE .B SPACE FALSE THEN UNTIL DROP
```

#### ALLOCATE STRING WITH WORD
```sh
pre PASS GET$ pass$ $! ;
```

#### CONVERT STRING TO NUMBER
```sh
$>#
``` 
 
#### ANSI COLOR
```sh
: HELLO CRLF red PEN ." HELLO" blu PEN ."  WORLD" PLAIN ;
: STAR "*" EMIT ;
: STARS FOR RND 6 // 1+ PEN STAR NEXT ;
: P CLS 1 30 ADO I 50 STARS 30 <> IF CRLF THEN LOOP PLAIN ;
4 20 ADO I . LOOP
CRLF 30 FOR I 6 // 1+ . CRLF NEXT
```

#### CHANGE PROMPT
```sh
: CODEPROMPT HERE .W ." : " ;
' CODEPROMPT uprompt W!


1 byte TEMP1
pre ,, [C] GRAB TEMP1 C! 3 FOR 8<< + NEXT [C] , TEMP1 C@ [C] , ;
```

#### READING MEMORY
```sh
TAQOZ# $2C COG@ .L --- $0000_F7FF ok
00570 02c 0000f7ff coded			long	$F800-1
```

#### ENCODE (RETURN BIT POSITION OF MSb)
```sh
TAQOZ# 64 .BIN --- %00000000000000000000000001000000 ok
TAQOZ# 64 >| . --- 6 ok
TAQOZ# 65 >| . --- 6 ok
TAQOZ# -1 >| . --- 31 ok
TAQOZ# 0 >| . --- 0 ok
TAQOZ# 1 >| . --- 0 ok
TAQOZ# 2 >| . --- 1 ok
```

#### DECODE (MASK)
```sh
TAQOZ# 0 |< .BIN --- %00000000000000000000000000000001 ok
TAQOZ# 1 |< .BIN --- %00000000000000000000000000000010 ok
TAQOZ# 2 |< .BIN --- %00000000000000000000000000000100 ok
```

#### DISPLAY FONT
```sh
TAQOZ# font5x7 $20 7 * + 96 7 * ADO CRLF I 7 ADO I C@ .B ." ," LOOP 8 EMIT SPACE 7 +LOOP
```

#### CODE EXECUTION SPEED
OVERPLUS	_ret_	add	tos,tos1
```sh
: OVERPLUS SWAP DUP ROT + ;
TAQOZ# LAP OVER+ LAP .LAP --- 24 cycles= 300ns @80MHz ok
TAQOZ# LAP OVERPLUS LAP .LAP --- 240 cycles= 3,000ns @80MHz ok
```