TAQOZ

0 := blk
1 := red
2 := grn
3 := yel
4 := blu
5 := mag
6 := cyn
7 := whi

pri ESC ( ch -- ) $1B EMIT EMIT ;
pub HOME 'H'
pri ESC[ ( ch -- ) "[" ESC EMIT ;
pub PEN ( col -- ) "3" BEGIN ESC[ "0" + EMIT "m" EMIT ;
pub PAPER ( col -- ) "4" AGAIN
pub UL '4' GOTO
pub REVERSE	'7' GOTO
pub BOLD '1' GOTO
pub PLAIN '0' THEN THEN THEN ESC[ "m" EMIT ;
pub CUR ( cmd n -- ) '[' ESC SWAP BEGIN SWAP .DEC EMIT ;
pub XY ( x y -- ) ';' SWAP CUR 'H' AGAIN
pub CLS $0C EMIT HOME
pub ERLINE 'K' GOTO
pub ERSCR 'J' THEN '2' ESC[ EMIT ;
pub CURSOR ( on/off -- ) "?" ESC[ 25 .DEC IF "h" ELSE "l" THEN EMIT ;

END

