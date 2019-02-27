
	--- STRINGS ---


--- 40 STR" HELLO WORD"
--- " HELLO WORLD" 40 STR

pre STRING ( str max -- )
	[C] GRAB  ( str max )
	OVER LEN$ MAX 1+ ( str max )
	SWAP DATPTR 3RD CMOVE
	[C] BYTES
	;



\ Create a NULL$ constant

BYTE NULL$    NULL$ C~

{ Copy one string to another (store)
Usage:
" NOW IS THE TIME" $20 STRING A$
NULL$ $20 STRING B$
A$ B$ COPY$
}
pub COPY$ ( str1 str2 -- )
	OVER LEN$ 1+ CMOVE
 	;

ALIAS COPY$ $!			\ Just an alias plus I like to think of this as "string store" analogous to ! operation

{ Append a string
Usage: " MY NAME IS " $20 STRING NAME
" PETER" NAME APPEND$
NAME PRINT$ MY NAME IS PETER ok
}
pub APPEND$ ( str1 str2 -- \ append str1 at the end of str2 )
	DUP LEN$ + COPY$
	;
{ Append a character to a string and null terminate
Usage:
"*" NAME +CHAR  ok
NAME PRINT$ MY NAME IS PETER* ok
}
--- add a character to a string
pub +CHAR ( ch str2 --  )
	DUP LEN$ + OVER 1+ C~ C!
	;
--- extract the substring of str starting at offset len chars long
pub MID$ ( str offset len -- str  )
	>L + L>

--- Destructive LEFT$ - uses same string
pub LEFT$ ( str len -- str  )
	OVER + C~
	;
--- give a copy of the rightmost len chars of str
pub RIGHT$ ( str len -- str  )
	OVER LEN$ SWAP - +
	;
--- Fully erase the string - reads max len from header
pub ERASE$ ( str -- )
	DUP 3 - C@ ERASE
	;
--- Locate the first ch in the string and return else null
pub LOCATE$ ( ch str -- str  )
	0 SWAP DUP LEN$ ADO OVER IC@ = IF DROP I LEAVE THEN LOOP
	NIP
	;

--- Compare two strings for equality
pub $= ( str1 str2 -- flg )
	OVER LEN$ OVER LEN$ =
	IF
	DUP LEN$
	ADO C@++ IC@ <> IF DROP 0 LEAVE THEN LOOP
	0<>
	ELSE 2DROP FALSE
	THEN
	;
{
pri >UPPER  ( str1 --  ) --- Convert lower-case letters to upper-case
	DUP LEN$ ADO IC@ "a" "z" WITHIN IF IC@ $20 XOR I C! THEN LOOP
	;
}
#40 BYTES _str
pri >CSTR 			_str 1+ $! _str 1+ LEN$ _str C! _str ;

pub FIND ( str -- cfa )		>CSTR @NAMES FINDSTR DUP IF NFA>CFA >PFA THEN ;
pub CALL$			FIND ?DUP IF CALL THEN ;
