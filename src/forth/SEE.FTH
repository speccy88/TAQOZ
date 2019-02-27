TAQOZ

(       DECOMPILER    810 bytes )

FORGET ~x
byte ~x
byte ~i
word ~w
20 bytes ~f

\ IFNDEF >NFA
--- find the nfa else false
pub >NFA ( cfa -- nfa  )
	@NAMES
	BEGIN
	  DUP C@
	WHILE
	  DUP CFA 3RD = IF NIP EXIT THEN
---  advance to after the code pointer
	  CPA 2+
 	REPEAT
	2DROP 0
	;



--- create a temporary dummy def so that we can find the CFAs for unnamed words
: T BEGIN $1234 $12345678 UNTIL uemit $0FF " STRING" ;
' T 16 + W@		--- address and read " string literals
' T 14 + W@		--- 9-bit literal
' T 12 + W@		--- register offset
' T 10 + W@		--- address and read UNTIL
' T 4 + W@		--- address and read a LONG literal
' T W@			--- address and read a WORD literal
FORGET T		--- discard temp def and now use parameters for constants
== (W)			--- 16-bit WORD
== (L)			--- 32-bit LONG
8>> == (IF)		--- IF or UNTIL branch
8>> == (R)		--- 8-bit register offset
9 >> == (S)		--- 9-bit literal
== (")

: T ." STRING" ;
' T W@
FORGET T
== (.")
: T .AS" #" ;
' T W@
FORGET T
== (.AS)


pri .D			DUP .AS"  (*|) '@|' " DROP  ;

pri .T			'"' EMIT SPACE 2+ DUP PRINT$ '"' EMIT DUP LEN$ 1+ + ;
pri INDENT		~i C@ 2* 0 MAX 4+ SPACES ;
pri +~i			~i C++ ;
pri -~i			~i C@ IF ~i C-- THEN ;


--- add an IF branch to address so that indentation and a THEN can be added
pri +if ( addr -- )		~f BEGIN DUP W@ WHILE 2+ REPEAT W! ;
pri if? ( addr -- flg )
	~f BEGIN 2DUP W@ <> OVER W@ 0<> AND WHILE 2+ REPEAT
	DUP W@ ROT =
	  IF 0 OVER W! ELSE DROP 0 THEN
	;
pri fad? ( addr -- flg )	0 ~f 20 ADO OVER I W@ <= OR 2 +LOOP NIP ;

pri .W9
	~w W@ 9BITS
---	 print as ASCII ?                  PRINT DECIMAL        PRINT HEX IF > 9
	DUP $1F > IF DUP .AS" '@|' " THEN DUP .AS" #|##~# " DUP 9 > IF .W ELSE DROP THEN 2+
	;

pri DECODE ( addr wordcode -- addr+ )
	DUP ~w W!
---	    jump bit  & if threaded
	DUP 1 AND OVER ' SPACE $FC00 WITHIN AND
	IF 1 ANDN  ." GOTO " DUP >NFA ?DUP
	  IF 1+ PRINT$ ELSE DUP .W THEN
	  fad? IF ~x C~~ THEN 2+ EXIT
	THEN
		( pc code )
	SWITCH
	(.") CASE ." ." .T BREAK
	(.AS) CASE ." .AS" .T BREAK
	(") CASE .T BREAK
	(W) CASE 2+ DUP W@ DUP .W .D 2+ BREAK
	(L) CASE 2+ DUP @ DUP .L .D 4+ BREAK
	~w W@ 9 >> (S) = IF .W9 BREAK

	' EXIT CASE DUP fad? NOT IF ." ;" ~x C~~ ELSE ." EXIT" THEN 2+ BREAK
---	decoded wordcodes $FC00->$FFFF
        CASE@ 8>> SWITCH
	(R) CASE ." REG " ~w C@ .B 2+ BREAK
	(IF) CASE ~w C@ $80 AND 0=
	    IF
	      ." IF " +~i
	      DUP 2+ ~w C@ 2* + DUP +if
	    ELSE
	      ." UNTIL "
	      DUP 2+ ~w C@ $7F AND 2* -
	    THEN
	.W 2+ BREAK
---	default for anything else
	DUP W@ DUP $3FF > IF 1 ANDN THEN >NFA ?DUP IF 1+ PRINT$ THEN 2+
;

pub SEE? ( cfa -- )
	BEGIN
	  ~x C~ \ ~q C~
\	  1 ANDN
	  2 ALIGN
---	  print THEN if matching address in IF THEN table
	  DUP if? IF CRLF 11 SPACES -~i INDENT ."   THEN" THEN
---	  Print address
	  CRLF DUP .W ." : "
---	  Print wordcode hex and then indent
	  DUP W@ .W SPACE INDENT
---	  decode wordcode
	  DUP W@ DECODE
	  DUP >NFA DUP IF CRLF 1+ PRINT$ THEN
---	  stop & exit now?
	  OVER fad? NOT OR
	  ~x C@ KEY OR AND
	  OVER W@ 0= OR
	UNTIL
	DROP
;
pre SEE
	~x 24 ERASE		--- clear all variables
	\ 2 ~i C!
	[C] NFA' [C] GRAB
	?DUP
	IF
	  DUP C@++ + C@ $20 AND IF ."  IMMEDIATE" THEN
	  CFA SEE?
	ELSE ."  not found "
	THEN
	;

\ pub !CNTS	29 5 ADO 0 I COG! LOOP ;
\ pub .CNTS	5 0 DO CR " ASMTHDIFSREGLIT" I 3 * + 3 CTYPE SPACE I 29 + COG@ $2A0A PRINTNUM LOOP ;

END
