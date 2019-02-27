
{
Simple ZIPCODE lookup - type in town and state to display zipcode

ZIPCODE.TXT file format
00.0000: 0D 0A 41 62 62 65 76 69 6C 6C 65 20 20 20 20 20    ..Abbeville
00.0010: 20 20 20 20 41 4C 20 33 36 33 31 30 0D 0A 41 62        AL 36310..Ab

Usage:
TAQOZ# ZIP Knoxville GA 31050  ok
TAQOZ# ZIP Londonderry NH 03053  ok
TAQOZ# ZIP Canton NY 13617  ok
}

18 BYTES town

pre ZIP ( <town> <state> -- )
	?MOUNT
	" ZIPCODES.TXT" FOPEN$ 0= IF PRINT" No ZIP file " EXIT THEN
	town 17 + C~ town 17 $20 FILL
---	Town
	GETWORD town OVER LEN$ CMOVE
---	State (2 characters) and leave on stack as a 16-bit word
	GETWORD W@
---	locate state first as 2 characters offset from start of file
	20 BEGIN 2DUP FSW@ <> WHILE 28 + REPEAT NIP
---	Found state - now point back to town field and search
	SPACE 18 - ( @town )
---	quick search based on first 4 chars <> next record
	town @ SWAP BEGIN 2DUP FS@ <> WHILE 28 + REPEAT NIP
---	matched first 4 characters, now match as strings
	town 4+ SWAP 4+ ( town+4 rcdptr )
---	        terminate rcd (temp) then compare as string
	BEGIN 2DUP FSADR DUP 13 + C~ COMPARE$ 0= WHILE 28 + REPEAT NIP
---	found it ( rcdptr ) type out zip code field
	17 + FSADR 5 CTYPE
	;

