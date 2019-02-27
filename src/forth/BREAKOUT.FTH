TAQOZ


\ TIMER duration

--- square wave output audio pin

\ pri audio	10 ;
--- hitting a wall sound
pub BONK			; \ audio APIN  300 HZ 50 duration TIMEOUT ;


--- back of the brick wall - leave room for the ball to bounce behind
3        := backwall


\ $7F00        := bram
\ $03FC        := bval

byte score
byte balls

pri BRICKS? ( -- cnt )
	score C~
	backwall cols * 2* screen + FROM 2 BY
	cols 4* FOR I C@ 14 <> IF score C++ THEN NEXT
	;
--- calculate how many bricks have been removed and display
pri .SCORE
	BRICKS?
	grn HUE cols 7 - 0 VXY
	VGA score C@ .AS" ###/128"
	<CR> balls C@ .AS" # balls"
	;

--- ball position variables
word	bx
word	by
word	abx
word	aby

pri bdir 	0 >N ;

--- initialize the brick wall with 4 rows of random colored bricks/tiles from backwall (gap)
pub WALL	0 backwall VXY cols 4* FOR RND 8>> 7 AND HUE 14 VCHAR NEXT ;

{ The ball is drawn with a single character but by using codes which force the driver to access RAM
for the font we can have finer movement by drawing a ball character dynamically in x 16x32 matrix
Use code $3FA to access table at $7E80
This routine is essentially the same as VCHAR but optimized for directly writing without scroll
Execution time: 48.8us
--- 10-bit character
}
pub VCHAR! ( ch -- )
	--- (color << 1 + c & 1 )
	DUP 1 AND color C@ 2* +
	--- form color field
	2* 1+ 9 <<
	--- merge 7 msb of data
	SWAP 1 ANDN +
	--- current screen position
	row C@ 5 << col C@ +
	DUP 960 <
	--- write to the screen word & inc column
	IF 2* screen + W! col C++ ELSE 2DROP THEN
	;


TIMER balldly                            --- timeout leads to next ball movement
word speed


--- rebound translation table looks up the corresponding rebound direction ( 7 into left returns with 9 )
TABLE rebound
---    0   1   2   3   4   5   6   7   8   9
    0 | 7 | 8 | 9 | 6 | 5 | 4 | 1 | 2 | 3 |             --- bottom/top rebound
    0 | 3 | 8 | 1 | 6 | 5 | 4 | 9 | 2 | 7 |             --- left/right rebound

--- lookup the table for the rebound action & sound
pub BOUNCE ( table-offset -- )	rebound + bdir + C@ ' bdir C! BONK ;
pri BALL@ ( -- word )		bx W@ 2/ 2/ by W@ 3 >> cols * + 2* screen + W@ ;

--- read the contents of the screen cell/tile where the ball will be next

pub NOBALL
	bx W@ 2/ 2/ by W@ 3 >> VXY
	$20 VCHAR!
	;

pri !BALL
	NOBALL
pri NEWBALL
	64  bx W! 60  by W!
	50 speed W! 1 ' bdir C!
	--- delay serving 1st ball for 1.5secs
	1500 balldly TIMEOUT
pub BALL
	--- limit ball x
	bx W@ cols 2* 2* MIN bx W!
	--- limit ball y
	by W@ rows 2* 2* 2* MIN by W!
	--- bounce off special tiles (not blank or alphanumeric)
	BALL@    >B 20 'z' WITHIN NOT IF 0 BOUNCE EXIT THEN
	--- bounce off bottom
	by W@ rows 3 << 1- =>  IF 0 BOUNCE EXIT THEN
	--- bounce off top
	by W@ 1 < IF 0 BOUNCE EXIT THEN
	--- bounce off left wall
	bx W@ 0= IF 10 BOUNCE EXIT THEN
	--- bounce off right wall
	bx W@ 2/ 2/ cols => IF 10 BOUNCE EXIT THEN
\ pub DRAWBALL ( -- )
	--- plot ball as 4x4 block - 185us
	wht HUE bx W@ by W@
	--- address the screen position for the tile - 17.2us
	OVER 2/ 2/ OVER 2/ 2/ 2/ VXY
	--- maps to programmable char at $7E80 - 63.6us
	bval VCHAR!
	--- generate a dot in the correct x position - 7.8us
	SWAP 3 AND 2* 2* 2* $AA SWAP <<
	--- wipe the character clean - 64.6us
	bram 128 ERASE
	--- calculate y position in character - 8.4us
	SWAP 7 AND 4 << bram + ( mask addr )
	--- create the pattern
	SWAP OVER ! DUP 4 + 12 CMOVE
	;

--- setup constants for ball x and y movement increments which contain 2 fractional bits
1    := abxcon
1    := abycon

pri BALL+! ( x y -- )
	NOBALL
	by W+! bx W+!
	BALL
	;

--- Check if ball is ready for next movement and proceed
pub ?BALL
	--- ready yet?
	balldly TIMEOUT? 0EXIT
	--- yes, set next timeout period
	speed W@ score C@  2/ 2/ - 0 MAXS  balldly TIMEOUT
	--- proceed using the ball direction
	bdir SWITCH
	7 CASE abxcon NEGATE abycon NEGATE BALL+! BREAK
	9 CASE abxcon abycon NEGATE BALL+! BREAK
	1 CASE abxcon NEGATE abycon BALL+! BREAK
	3 CASE abxcon abycon BALL+!  BREAK
	;


--- paddle xy
byte px
byte py

--- two characters that make up the paddle
$8E88        := mypad
$2020        := nopad

--- draw the paddle
pub PADDLE ( shape -- )		yel HUE px C@ py C@ VXY W>B VCHAR VCHAR	;


--- PADDLE MOVEMENTS
pub L    		px C@ IF nopad PADDLE px C-- mypad PADDLE THEN ;
pub R    		px C@ cols 2 - < IF nopad PADDLE px C++ mypad PADDLE THEN ;

--- check to see if the ball has hit the paddle and which change it's direction based on the edge hit
pub ?PADDLE		mypad PADDLE ;

pri NEWPADDLE		rows 1- py C! 15 px C! mypad PADDLE ;

pub GAMEOVER            red " GAME OVER" ( 11 8 TEXTBOX ) CON CONSOLE ;

pub NEWGAME
	VGA CLS NEWPADDLE NEWBALL WALL
	7 0 VXY 2 HUE PRINT"  TACHYON BREAKOUT "
	3 balls C! score C~
	;

pri FASTER		speed W@ IF speed W-- THEN ;
pri SLOWER		speed W++ ;

--- game control keys ---
pub GAMEKEY
	KEY ?DUP 0EXIT
	SWITCHES
	'Z' L   	'X' R
	'z' L   	'x' R
	'+' FASTER   	'-' SLOWER
	'B' !BALL  	$0D NEWGAME   	$1B GAMEOVER
	;

pub ACTION
	--- make it speed up proportionaly to the score
\	130 score C@ - 3 / speed W!
	GAMEKEY
	?BALL
	?PADDLE
	duration TIMEOUT? IF MUTE THEN
	.SCORE
	--- testing: autostart a new game
	score C@ 128 = IF NEWGAME THEN
	;

pub BREAKOUT
	!VGA
	audio APIN MUTE  0 duration TIMEOUT
	gamepal colors 64 CMOVE
	NEWGAME 2 s
pub RESUME
	30 FLOAT
	VGA BEGIN ACTION AGAIN
	;

END
