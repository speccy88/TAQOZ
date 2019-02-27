

(       DECOMPILER     )


BYTE ex
BYTE ind
WORD wc
20 BYTES ifs


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


pri 'EMIT	''' EMIT ;
pri $		'$' EMIT ;
pri .D		SPACE '(' EMIT DUP . ')' EMIT SPACE DUP BL $7E WITHIN IF 'EMIT EMIT 'EMIT EMIT ELSE DROP THEN ;

pri .B		$ .BYTE ;
pri .W		$ .WORD ;
pri .L		$ .LONG ;
pri .T		'"' EMIT SPACE 2+ DUP PRINT$ '"' EMIT DUP LEN$ 1+ + ;
pri INDENT	ind C@ 0 MAX SPACES ;
pri +ind	2 ind C+! ;
pri -ind	ind C@ IF -2 ind C+! THEN ;


--- add an IF branch to address so that indentation and a THEN can be added
pri +if ( addr -- )		ifs BEGIN DUP W@ WHILE 2+ REPEAT W! ;
pri if? ( addr -- flg )
	ifs BEGIN 2DUP W@ <> OVER W@ 0<> AND WHILE 2+ REPEAT
	DUP W@ ROT =
	  IF 0 OVER W! ELSE DROP 0 THEN
	;
pri fad? ( addr -- flg )	0 ifs 20 ADO OVER I W@ <= OR 2 +LOOP NIP ;

BYTE wc

pri .W9
	wc W@ $1FF AND
	DUP $20 $7E WITHIN IF 'EMIT DUP EMIT 'EMIT SPACE ELSE 4 SPACES THEN
	DUP '#' EMIT PRINT SPACE .W 2+
	;

pri (SEE)
	DUP wc W!
	DUP 1 AND OVER $3FF $FC00 WITHIN AND IF PRINT" GOTO " 1 ANDN DUP .W DUP fad? NOT IF ex C~~ THEN THEN
	( pc code )
	SWITCH
	' (.") CASE PRINT" PRINT" .T BREAK
	(") CASE .T BREAK
	(W) CASE 2+ DUP W@ DUP .W .D 2+ BREAK
	(L) CASE 2+ DUP @ DUP .L .D 4+ BREAK
	wc W@ 9 >> (S) = IF .W9 BREAK

	' EXIT CASE DUP fad? NOT IF PRINT" ;" ex C~~ ELSE PRINT" EXIT" THEN 2+ BREAK
---	decoded wordcodes $FC00->$FFFF
        SWITCH@ 8>> SWITCH
	(R) CASE PRINT" REG " wc C@ .B 2+ BREAK
	(IF) CASE wc C@ $80 AND 0=
	    IF
	      PRINT" IF " +ind
	      DUP 2+ wc C@ 2* + DUP +if
	    ELSE
	      PRINT" UNTIL "
	      DUP 2+ wc C@ $7F AND 2* -
	    THEN
	.W 2+ BREAK

---	default for anything else
	DUP W@ DUP $3FF > IF 1 ANDN THEN CFA>NFA ?DUP IF 1+ PRINT$ THEN 2+
;

pub SEE?
	BEGIN
	  ex C~
	  2 ALIGN
	  DUP if? IF CR 11 SPACES -ind INDENT PRINT" THEN" THEN
	  CR DUP .WORD ." : "
	  DUP W@ .WORD SPACE INDENT
	  DUP W@ (SEE)
	  ex C@ KEY OR
	  DUP fad? NOT AND
	UNTIL
	DROP
;
pre SEE
	ex 22 ERASE		--- clear all variables
	4 ind C!
	[C] NFA' [C] GRAB
	?DUP
	IF
	  DUP C@++ + C@ BL AND IF PRINT"  IMMEDIATE" THEN
	  NFA>CFA >PFA
	  SEE?
	ELSE PRINT"  not found "
	THEN
	;

