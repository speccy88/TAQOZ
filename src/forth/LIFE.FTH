TACHYON [~
DECIMAL

IFNDEF P2	xxxxxxx ONLY FOR NOT P2 xxxxxxx }

FORGET LIFE.fth

pub LIFE.fth        PRINT" Conway's Game of Life for the Propeller  V1.1 160704 " ;

{
Adapted from code at:
http://www.forth-ev.de/wiki/doku.php/projects:4e4th:4e4th:start:beispiele

Optimized for cell widths so 32 wide for the Propeller
Modified so that lines print horizontally to optimize the cell width vertically
Widths of up to 512 can be used
Automatically expands horizontally if "expanding" mode is used: 16 wide expanding random lide

64x32 array updates every 129ms 110ms
128x32	305 XXX 185
256x32 array updates every 519ms 441ms  370ms

V1.1 assigns a task to nextgen and buffers this for printing to speed up wide displays
150604 - Add SYNCH to allow nextgen to be synch'd to slow serial interfaces. - ON SYNCH or OFF SYNCH
150605 - Optimized stack usage, coded an inline RUNMOD
150611 - removed ROL3 alias as FORGET ends up trying to remove RUNMOD - fix up FORGET later
	Changed exit key to CR to allow operation over Telnet clients.
}


ifndef CELLS pub CELLS		2* 2* ; }


32		== #lines
8 CELLS		== bits/cell
BUFFERS		== universe

pub line  ( n -- a-addr )		CELLS universe + ;

---             0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
TABLE #bits	0 | 1 | 1 | 2 | 1 | 2 | 2 | 3 | 0 | 1 | 1 | 2 | 1 | 2 | 2 | 3 |


BYTE ng,syn



{ Replace this sequence with code:
      2 AND R> OR 1 ROL >R
      1 ROL ROT  1 ROL ROT  1 ROL ROT		--- next cell in each line --- 8.4us --- x1 x2 x3 revert to original after 32 ROLs

0ED0(01DB) 02 5C FF 60 |                   and       tos,#2
0ED4(01DC) 8E 23 FF 5C |                   call      #RPOPX
0ED8(01DD) A6 5D BF 68 |                   or        tos,X
0EDC(01DE) 01 5C FF 24 |                   rol       tos,#1
0EE0(01DF) AE 4F BF A0 |                   mov       R0,tos
0EE4(01E0) 8A 1B FF 5C |                   call      #_PUSHR
0EE8(01E1) 70 F7 FE 5C |                   call      #POPX
0EEC(01E2) 01 5C FF 24 |                   rol       tos,#1
0EF0(01E3) 01 5E FF 24 |                   rol       tos+1,#1
0EF4(01E4) 01 60 FF 24 |                   rol       tos+2,#1
0EF8(01E5) A3 01 3C 5C |                   jmp       unext }


: ROL3
      2 AND R> OR ROL1 >R
      ROL1 ROT ROL1 ROT ROL1 ROT		--- next cell in each line --- 8.4us --- x1 x2 x3 revert to original after 32 ROLs
;

pub doline  ( x1 x2 x3 -- x1 x2 x3 x4 )	--- 2.8ms
   0  bits/cell FOR
      >R
\ pub alive  ( x1 x2 x3 -- flag ) \ return whether cell at bit1 in line1 is alive in next generation
     OVER 2 AND 0<> >R
     ( x1 x2 x3 )
     DUP >N #bits + C@
     ( x1 x2 x3 y )
     3RD >N #bits + C@ +  \ note: cell itself is counted, too. correction below.
     ( x1 x2 x3 y )
     4TH >N #bits + C@ +	--- 6.4us --- 0,1,2,3,4,5,6,7,8,9
     ( x1 x2 x3 y )
     DUP 3 = ( x1 x2 x3 y y=3 ) SWAP 4 = ( x1 x2 x3 y=3 y=4 ) --- 5.8us
     R> AND OR ( x1 x2 x3 y=3|y=4&x2&2 )

\      2 AND R> OR 1 ROL >R
\      1 ROL ROT  1 ROL ROT  1 ROL ROT		--- next cell in each line --- 8.4us --- x1 x2 x3 revert to original after 32 ROLs
	ROL3
      R>
   NEXT
   ;

pub nextgen  ( -- )
   0 line @   #lines 1- line @  OVER   ( s: line0   x1 x2 )
   #lines 1- line  0 line DO
      I 4 + @               ( s: line0  x1 x2 x3 )
      doline  I !
      ROT DROP                  ( s: line0  x2 x3 )
   4 +LOOP  
   ROT doline  #lines 1- line !   \ special treatment for last line
   3DROP 
   ;

IFNDEF EASYNET.fth
TABLE bufgen 2,000 ALLOT
}
IFDEF EASYNET.fth
BUFFERS $400 +	== bufgen
}

10 LONGS genstk
pub gentask
	genstk SP! !SP !RP 
	[ROL3]
	BEGIN 
	  nextgen 
	  syn C@ IF BEGIN ng C@ 0= UNTIL THEN				--- wait until the previous buffer has been displayed
	  BUFFERS bufgen #lines CELLS CMOVE 
	  ng C~~ 
	AGAIN
	;
	
--- define default characters for alive and dead
"O"	== live
BL	== dead   

pub .line  ( bit -- )
   MASK #lines 0 DO
     I line @ OVER AND IF live ELSE dead THEN EMIT
   LOOP  DROP 
   ; 

LONG generation
pub .universe  ( -- )  \ print current life state to console 
   OFF CURSOR REVERSE BOLD
   HOME 
   PRINT"  Conway's Game of Life - Tachyon Forth  " #lines . 
   PRINT" x32  Generation #" generation @ . 
   PRINT"  every " LAP .LAP
   CR PLAIN BOLD
   "-" #lines 2+ FOR DUP emit NEXT DROP CR
   bits/cell 0 DO "|" EMIT I .line "|" EMIT CR LOOP 
   "-" #lines 2+ FOR DUP EMIT NEXT DROP
   ;
   
   
--- commands ---   
   
--- set terminal screen width for matrix
pub WIDE			512 MIN ' #lines 1+ ! ;
pub SETDOTS IMMEDIATE		PRINT" dead=" WKEY DUP EMIT ' dead 1+ ! PRINT"  live=" WKEY DUP EMIT ' live 1+ !  PRINT"  ok" CR ;
   
pub WIDER			#lines 1+ wide 0 #lines 1- line ! ;
pub EXPAND			wider universe DUP 4 + #lines 1- CELLS <CMOVE 0 0 line ! ;

BYTE _exp
pub EXPANDING			_exp C~~ ;

pub SYNCH ( on/off -- )		syn C! ;

pub LIFE
        generation ~ 	
	' gentask 5 RUN
	ng C~		
	CLS BEGIN 
	  _exp C@ IF
	    0 line @ IF expand THEN
	    #lines 1- line @ IF wider THEN  
	  THEN
	    BEGIN ng C@ UNTIL ng C~ .universe generation ++
	KEY $0D = UNTIL  			
	_exp C~ 
	CR 
	syn C~~ ng C~~
	;



--- PATTERN CREATION ---

pub VOID  ( -- )		universe #lines CELLS ERASE ;

pub SEED  ( x1 .. xn n -- )	0 DO I line ! LOOP ;

--- some well known patterns:
pub GLIDER  ( -- )		7 1 2  3 seed ;
pub FPENT  ( -- )		4 $0C 6  3 seed ;
pub LWSS  ( -- )		$0F $11 1 $12  4 seed ;
pub DIEHARD			$47 $C0 2  3 seed ;
pub ACORN			$67 8 $20  3 seed ;

--- create a random pattern as a seed
--- usage: random life
\ pub BITS? ( n -- bits )		0 BL 0 DO OVER I MASK AND IF 1+ THEN LOOP NIP ;

pub RANDOM			#lines 0 DO RND I line ! LOOP ;

--- Copy a pattern of longs from memory (such as ROM)
--- Usage: $E000 copy life
pub COPY ( src -- )		#lines 0 DO DUP @ I line ! 4 + LOOP DROP ;
\ pub reload			#lines 0 DO I CELLS memory + @ I line ! LOOP ;

pub DEMO			VCLS ON SYNCH 64 wide random life ;



]~ END
