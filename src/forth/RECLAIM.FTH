{
00.CA58: C8 32 02 6C 73 A0 74 32 04 4C 49 53 54 80 6C 32    .2.ls.t2.LIST.l2
00.CA68: 03 7E 6C 74 90 E4 31 04 28 6C 73 29 90 90 31 05    .~lt..1.(ls)..1.
00.CA78: 6C 73 63 6E 74 80 8A 31 03 44 49 52 80 82 31 02    lscnt..1.DIR..1. ok
$CA68 3+5

}
pub (STRIP) ( nameptr -- nameptr+ )
	CRLF ." Removing " DUP 1+ PRINT$			\ Ok, strip it out
	DUP DUP C@ 4+ ( 1 ANDN ) ( nameptr cnt )
	DUP >R @NAMES +
	@NAMES ROT SWAP - ( newnames len )
	@NAMES ROT ROT <CMOVE
	R> DUP names W+! +   	 			\ add to names pointer and to current pointer for next word
 	;

--- Strip a single header from the dictionary
\ pre STRIP			[C] NFA' [C] GRAB (STRIP) DROP;


--- RECLAIM <opt>
pre RECLAIM
	--- reclaim <from> or all
\	char C@ $20 = IF [C] NFA' ELSE $8000 THEN
	@NAMES DUP >R
	BEGIN
	  --- Test to see if ATR is private
  	  DUP CPA 1- C@ $10 AND
  	     --- strip header or proceed to next
  	    IF (STRIP) ELSE CPA 2+ THEN
	  2DUP U<
 	  OVER C@ 0= OR
	UNTIL
	--- Report results
	2DROP CRLF ." Reclaimed " @NAMES R> DUP >R  - DUP .AS" ##,#~## bytes"
	--- Clear the reclaimed area (not needed)
	R> SWAP ?DUP IF ERASE ELSE DROP THEN
	;




RECLAIM
FORGET (STRIP)
