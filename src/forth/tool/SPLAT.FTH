TAQOZ

pub SPLAT.fth        ." SPLAT - Serial Propeller Logic Analyzer Terminal  150914-0200 " ;

{
CHANGELOG:
170309 Adapted for Tachyon V4
150915 Improved refresh speed, added division marker rows
150915 Experimenting with using cursor and function keys as they use ANSI escape sequences rather than a single keycode
150906 If baud sampling is set then cursor shows decoded ASCII if placed on start bit
150905 Allow settings to be remembered (via BACKUP) and not overridden on boot
150905 Changed help text so that it could be loaded into any area of EEPROM
150905 Various enhancements etc. Changed to V1.0
150903 Added input channels command I to set input channels from 8 to 32 - defaults to 28
150903 Changed some commands so that they are the same in the command line (i.e. Z instead of * etc)
150903 Moved <num> to top of stack to permit command line use.
150903 Changed KEY method to use standard KEY input plus maintain a latched copy in newkey
150903 Added aliases for ns us ms and baud as n u m b - so command line 115200 b will set the scale to baud rate

150902 Added: units can now be entered in ns us ms and baud modes to set the scale which is shown in ns/us
150902 Added: PASM capture function - it appears that 525ns is the fastest capture possible with one cog
150902 Added: PINLOAD function to display whether pin is pulled up/down or floating

TO DO:
add frequency/period measurement as well
add SD logging to allow 128kB/second to be saved
investigate recording one long of I/O + one long of CNT so only transitions need be recorded (up to CNT rollover 53.6sec)
- could even be much longer - post processing the file needs to take care of rollover
decode serial streams if scale was set with baud setting
dedicated capture cog to sample directly to cog ram at 20 MIPS using overwriting technique ( mov $,ina )
apply names next to channels
save to SD inc config
Make HELP text a standard text file that can be pasted in and saved in EEPROM (esp 64k) or SD card
Include DUMP format listing for ASCII decode view mode

Refresh time 123ms for 28 channels 100 wide @2M or 510ms @115200
250ms for 75x16 @115200

CODE STATS:
NAMES:  $56C5...7163 for 6,814 bytes (+356)
CODE:   $0924...4308 for 14,820 bytes (+1,601)


$A0BC01F2    == MOVINA        --- overwriting instruction
}

{ SAMPLE OUTPUT  CAPTURING and DISPLAYING VGA

 .:.:--TACHYON--:.:. SPLAT LOGIC ANALYZER V1.0
    01234567890123456789012345678901234567890123456789012345678901234567890123456789
 15x__________0_____________________________________________________________________
    ==========|=========|=========|=========|=========|=========|=========|=========
 16u----------1---------------------------------------------------------------------VSYN
 17u------____0__------------------------------------------------------_______------HSYN
 18x___-______0_________________-_________---___________--__________-_______________BLU0
 19d--_-______0___________----__-_____-__----_____-_--__--____--_--_-_______________BLU1
 20d___-______0______-__________---_______---_-_________---_________-_______________GRN0
 21u--_-______0______-_-_____-__----_____----_--_____-__-----____--_-_______________GRN1
 22u__--______0______-__-_____-----__-____---_-__-_____----________--_______________RED0
 23d__--______0______-__-__--_-----__-____---_-__-__-__----________--_______________RED1
 SCALE=525ns x1 @179=93,975.0ns

}



$2.0000 == CAPBUF

byte _channels
byte _schan

: channels	_channels C@ ;
: schan		_schan C@ ;

: SEND CONEMIT ;

--- VARIABLES ---

@org W@ == spvars
byte zoom
1 words newkey
word snew

1 longs samples
long width
long scale
long lbaud
long lcur
long curadr
long trig

128 bytes clabels

\ 32 LONGS clabels                    --- allow up to 4 characters per label

     --- maintain pullup/down or float status of pins
32 bytes pins


--- zoom scaling emit - simply repeats characters
\ pri EMITX     zoom C@ FOR DUP SEND NEXT DROP ;
: EMITX	CONEMIT ;

--- use 1 of 7 colors for channels, never black, with offset
pri LAHUE    4 + 7 MOD 1+ PEN ;

--- Create a channel label of up to 4 characters in one long - usage: 6 LABEL RXD1
pub LABEL IMMEDIATE ( <n> <name> -- )
     [C] GRAB DUP 0 31 WITHIN IF GETWORD U@ SWAP 2* 2* clabels + ! ELSE DROP THEN
;

--- Print the long as a label
pri .LABEL ( long -- )    4 FOR DUP >B SEND 8 >> NEXT DROP ;

--- return with serial character found from this start bit position assuming 3 samples per bit
pri ASCII? ( addr chan -- byte )
    MASK 0 9 1 DO 2* 3RD I 12 * + @ 3RD AND 0<> 1 AND OR LOOP NIP NIP 24 REV ;
     ;



pri RUNNING		red
pri COND		2 2 XY PEN REVERSE ." ** " ;
pri STOPPED		white COND ;
pri ARMED		yellow COND ;


pri .CURSOR ( ch -- offset )
	REVERSE
	lbaud @ IF
        curadr @ J ASCII?
        DUP $20  $7E WITHIN
	  IF DUP SEND ELSE '?' SEND THEN .BYTE 12
	  ELSE I @ J MASK AND IF '1' ELSE '0' THEN EMITX 4
	  THEN
	PLAIN BOLD J LAHUE
	;

pri .ROW ( from rows -- )
	ADO	--- display one row
	--- check for cursor column
	  curadr @ I =
          IF .CURSOR
          ELSE I @ J MASK AND IF '-' ELSE '_' THEN  EMITX 4
          THEN
	+LOOP
	--- fill in right border
	white PEN REVERSE I 2* 2* clabels + @ ?DUP IF .LABEL ELSE SPACE THEN CR
;
pri GRID
	1 3 XY
	channels schan DO
	  I 7 AND 0= I AND
	  IF
	    4 SPACES PLAIN width W@ zoom C@ / zoom C@ *
	    0 DO I 10 MOD 0= I AND IF '|' ELSE '=' THEN SEND LOOP
	    BOLD REVERSE SPACE CR
	  THEN
	  CR
	  LOOP
	;

{ main logic display function
cycles through capture buffer one bit at a time to display a line of ASCII art for each channel (bit position)
 00d__________0_____________________________
 27u----------1-----------------------------
}
pub .LAD ( addr lcnt --- )
	OFF CURSOR
	OVER lcur @ 2* 2* + curadr !
	2* 2* --- convert count to longs in byte memory
	1 3 XY REVERSE
 --- cycle through all the memory 1 bit position at a time - one line per bit
	channels schan DO
\         ?GRID
	  I 7 AND 0= I AND IF CR THEN
	  trig @ I MASK AND IF '+' SEND ELSE SPACE THEN PLAIN
	  I LAHUE
	  I REVERSE $20A .NUM white PEN REVERSE I pins + C@ $20 + SEND PLAIN BOLD
          I LAHUE --- set channel color
	  2DUP .ROW
	LOOP
	2DROP     CR PLAIN
	;

--- save old key in upper byte and clear current entry
pri !KEY		newkey W@ 8 >> newkey W!  ;

--- add another digit to the current number
pri +ENTRY		10 * SWITCH@ $30 - + ;

pri !ENTRY		>R !SP R> 0 !KEY ;

--- The early version of SPLAT did not have the assembly capture module loaded, so this one is implemented in Forth
IFNDEF [CAP]
--- simple capture takes samples about every 7us - to be replaced by a fast RUNMOD function with trig function
pub CAPTURE
	$1F2 CAPBUF 512
	scale @
	  IF FOR OVER COG@ OVER ! scale @ us 2+ 2+ NEXT
	  ELSE FOR OVER COG@ OVER ! 2+ 2+ NEXT
	  THEN
	2DROP
	;
}

--- call the small capture module (8 instructions)
IFDEF [CAP]
pub CAPTURE
	[CAP]
	trig @ DUP 0= IF DROP -1 THEN 1 COG!        --- set trigger but if no parameter then select all
	CAPBUF 512 scale @ ( 42 MAX ) RUNMOD
	;
}
{ PASM CAPTURE LOOP
        org    _RUNMOD
' CAPTURE ( buf lcnt dly -- )
CAPTURE
              mov       R1,tos
              add       R1,cnt
CAPLP         waitcnt   R1,tos            ' (6+) if dly is set correctly then waitcnt can be considered a 6+ cycle NOP
              mov       ina,ina                 ' (4) read INA into its shadow (for dest field)
              wrlong    ina,tos+2               ' (8..23) save it
              add       tos+2,#4                ' (4) next long in memory
              djnz      tos+1,#CAPLP            ' (4)
              jmp       #DROP3

}

--- use the PINLOAD function to give us some idea about the pin, whether it is pulled up or down or floating
IFNDEF PINLOAD
pub PINLOAD? ( pin# -- flg ) \ check if a pin is pulled down, up or highZ = floating
	$1F4 COG@ >R $1F6 COG@ >R
	DUP HIGH DUP FLOAT #100 us DUP PIN@        --- returned to low if pulled down
	0= 'D' AND
	OVER LOW OVER FLOAT #100 us SWAP PIN@    --- returned to high if pulled up
	'U' AND OR
	R> $1F6 COG! R> $1F4 COG!
	DUP 0= IF DROP 'X' THEN
	;
}


{ --- Trigger system     UNTESTED - no HW right now  MJB
\  needs commands to be defined
\  High, Low, /up, \down, Xchange, *don't care
\ longs to store a 1-bit if this type of trigger is active for the pin
LONG trigH,trigL,trigU,trigD,trigX,trig*     \ most can be removed later
LONG waitA,waitB,tmask      \ store the static trigger patters before and after change

pub TRIGH ( pin# -- ) MASK DUP
\ trigH @ OR trigH ! DUP trigL @ SWAP ANDN trigL ! DUP trigU       \ changed - go directly to waitA/waitB
    waitA @ OR waitA ! DUP waitB @ OR waitB ! tmask @ OR tmask ! ;
pub TRIGL MASK DUP
    waitA @ SWAP ANDN waitA ! DUP waitB @ SWAP ANDN waitB ! tmask @ OR tmask ! ;
pub TRIG/ MASK DUP
    waitA @ SWAP ANDN waitA ! DUP waitB @ OR waitB ! tmask @ OR tmask ! ;
pub TRIG\ MASK DUP
    waitA @ OR waitA ! DUP waitB @ SWAP ANDN waitB ! tmask @ OR tmask ! ;
pub TRIGX MASK DUP trigX @ OR trigX ! tmask @ OR tmask ! ;
pub TRIG* MASK tmask @ SWAP ANDN tmask ! ;

\ maybe better do in PASM if there is space in RUNMOD
pub MERGEtrigX \ merge the current INA values for change trigger
    INA COG@         \ get current INA
    DUP trigX @ AND  \ get high trigX bits
        DUP waitA @ OR waitA !           \ set waitA bits
            waitB @ SWAP ANDN waitB !    \ clr waitB bits
        trigX @ NOT OR  \ get low trigX bits
        DUP waitA @ AND waitA !          \ clr waitA bits
            waitB @ SWAP NOT OR waitB !  \ set waitB bits
    \ now store to COGREGS for RUNMOD
    tmask @ REG0 COG!
    waitA @ REG1 COG!
    waitB @ REG2 COG!
            ;
}
{ PASM CAPTURE LOOP
\ store alternating INA and corresponding CNT values
        org    _RUNMOD
' CAPTURE ( buf lcnt  -- )
'  REGO = tmask
'  REG1 = waitA
'  REG2 = waitB

CAPTURE2
              waitpe    REG1,REG0           '  waitA,tmask   two waits to capture / or \ triggers as well
              waitpe    REG2,REG0           '  waitB,tmask
CAPLP         mov       ina,ina                 ' (4) read INA into its shadow (for dest field)
              wrlong    ina,tos+1               ' (8..23) save it
              add       tos+1,#4                ' (4+4) next long in memory
              wrlong    cnt,tos+1               ' (8) save CNT
              add       tos+1,#4                ' (4) next long in memory
              waitpne   ina,REG0                 ' use current value value, mask(REG0)
              djnz      tos+1,#CAPLP            ' (4)
              jmp       #DROP2

\ end MJB }

pri ?PINS			30 0 DO I PINLOAD? I pins + C! LOOP ;

--- Print the scale in units of ns/us/ms etc - input is in tenths of ns - i.e. 28875 = 2.8875us
pri .SCALE ( ns*10 -- )		0 1 .DP ." ns" ;

pri @footer ( offset -- y )     channels schan - DUP 1- 3 >> + + XY ;

pub FOOTER
	1 3 @footer
	PLAIN white PEN black PAPER REVERSE
	--- 525ns/3div
	."  SCALE=" lbaud @ ?DUP
	IF
	  $400A PRINTNUM ." baud"
	ELSE
         scale @ 42 MAX 1,000,000,000 CLKFREQ */
         DUP 999 > IF 0 3 .DP ." us" ELSE $400A PRINTNUM ." ns" THEN
	THEN
	."  x" zoom C@ .
	."  @" samples @ lcur @ 2* 2* + CAPBUF - 2/ 2/ DUP .
	." =" scale @ 125 * * .SCALE
	2 SPACES DUP ?DUP IF $480A PRINTNUM ELSE 8 SPACES THEN
	6 SPACES
	;

--- draws frame etc - still need to move some stuff from .LAD to here
pub NEWFRAME
	CLS                 --- EXTEND defines $0C + HOME + ERSCN to work with most terminals - test req.
	!ENTRY
pub FRAME ( addr cnt -- addr cnt )
\ \\ 	?PINS
\     4 lax W! 3 lay W!

	OFF CURSOR
	HOME PLAIN BOLD
	white PAPER
	black PEN ."  .:.:--TACHYON--:.:. "
	red PEN ." SPLAT "
	black PEN ." LOGIC ANALYZER V1.0 "

	--- print top border
	PLAIN white PAPER black PEN
	1 2 XY 4 SPACES
	--- print horizontal digit position
	0 width @ zoom C@ / FOR DUP 10 MOD '0' + EMITX 1+ NEXT SPACE DROP
	GRID

	--- bottom frame
	1 3 @footer
	width @ zoom C@ / zoom C@ * 5 + SPACES
	--- stats
	FOOTER
	--- reset colors etc
	PLAIN black PAPER white PEN
	1 4 @footer SPLAT.fth
	;


--- return with an entered parameter or else the default supplied
pri PR ( default -- res )        OVER DUP IF NIP ELSE DROP THEN ;

--- set trigger pattern - always allow console RXD to also trigger this so that it can escape
--- Enter >31 for all or toggle bits with <pin> T
pub SETTRIG
	DUP 32 <
	  IF MASK trig @ XOR
	  ELSE DROP -1
	  THEN
	trig !
	!ENTRY
	;


pub SETCUR			DUP lcur ! !ENTRY ;

long ps
12500 ps !            --- picoseconds/cycle (calculated from CLKFREQ )

pri SETSCALE			lbaud ~

pri SCALE!			42 MAX scale ! !ENTRY ;

pri SETns			1,000 ps @ */ SCALE! lbaud ~ ;

pri SETus			1,000,000 ps @ */ SCALE! lbaud ~ ;

pri SETms			1,000,000,000 ps @ */ SCALE!  lbaud ~ ;

pri SETbaud			CLKFREQ SWAP DUP lbaud ! 3 * / SCALE! ;

pri SETWIDTH			64 PR width ! !ENTRY ;

pri SETZOOM			1 MAX 10 MIN zoom C! !ENTRY ;

pri SETchan ( from to -- )	8 MAX 32 MIN _channels C! 0 32 LIMIT _schan C! !ENTRY ;

pri FINDMATCH
	curadr @ @ curadr BEGIN 4 + OVER OVER @ = UNTIL lcur @ 4 * - samples !
	;

--- HELP TEXT SUPPORT ---
{ Help text is held in EEPROM at the address specified @HELP
It is loaded independently from the code and may use the upper areas of a 64k EEPROM etc }

long @HELP
@HELP ~

pub SPLATHELP ( eeprom_adr <data> -- ) IMMEDIATE
	[C] GRAB ?DUP
	IF
	  HERE MAX DUP @HELP ! SPACE .LONG CR
          CAPBUF
            BEGIN WKEY DUP $1B <> WHILE OVER C! 1+ REPEAT DROP
          0 OVER C! CAPBUF DUP ROT 1+ SWAP - @HELP @ SWAP ESAVE
         CR ." HELP FILE DONE "
	ELSE
          DISCARD
	THEN
	;

pub LAHELP
	DISCARD CLS .VER SPLAT.fth CR
	@HELP @ ?DUP IF BEGIN DUP EC@ DUP WHILE DUP SEND $0D = IF $0A SEND THEN 1+ REPEAT
	2DROP
	WKEY DROP
	;

{
pub LAHELP
    DISCARD CLS .VER SPLAT.fth CR
    ."   SPLAT COMMANDS " CR
     ." num *  Set zoom  " CR
     ." num =  Set width " CR
     ." num C  Set cursor " CR
     ." num S  Set scale in clocks or use 'n's 'u's 'm's 'b'aud" CR
     ." T      Set trigger " CR
    ." num >  Scroll right by 4 or n " CR
     ." num <  Scroll left by 4 or n " CR
      ." /      Reset scroll to start" CR
    ." TAB    Start Capture " CR
    ." R      Continous RUN mode" CR
     ." SPACE  Clear entry and Refresh screen " CR
    ." 0..9   number entry " CR
     ." CR     Exit to Tachyon console - (type R to resume) " CR
     WKEY DROP
    ;
}

pri SHELL			1 4 @footer DISCARD ON CURSOR PLAIN !RP CONSOLE ;

pub REFRESH			FRAME samples @ width @ zoom C@ / .LAD ;


{ ESCAPE SEQUENCE KEYS


LEFT     1B 5B A2
RIGHT     1B 5B E8
UP    1B 5B D0
DOWN    1B 5B A1

SHIFT KEY
        ~  [  1  ;  2  D
SHIFT LEFT    1B 5B 31 3B 32 44
SHIFT RIGHT    1B 5B 31 3B 32 43
SHIFT UP    1B 5B 31 3B 32 41
SHIFT DOWN    1B 5B 31 3B 32 42

        ~  [  1  ;  5  D
CTL LEFT    1B 5B 31 3B 35 44
CTL RIGHT    1B 5B 31 3B 35 43
CTL UP        1B 5B 31 3B 35 41
CTL DOWN    1B 5B 31 3B 35 42

        ~  [  1  ;  3  D
ALT LEFT    1B 5B 31 3B 33 44
ALT RIGHT    1B 5B 31 3B 33 43
ALT UP        1B 5B 31 3B 33 41
ALT DOWN    1B 5B 31 3B 33 42

        ~  [  1  ;  6  D
CTSH LEFT    1B 5B 31 3B 36 44
CTSH RIGHT    1B 5B 31 3B 36 43

PAGE UP    1B 5B FF ( PAGE DOWN & HOME ??)
END        1B 4F 46

F2        1B 4F D4
F3        1B 4F A9
F4        1B 4F EA
F5        1B 5B 93 FF
F6        1B 5B 4C 93 FF
F7        1B 5B 27 FF
F8        1B 5B 4C 27 FF
F9        1B 5B FF
}

pri SHIFTS
	SWITCH
	'D' CASE lbaud @ IF 30 ELSE 10 THEN NEGATE lcur @ + 0 MAX lcur ! !ENTRY REFRESH	BREAK
	'C' CASE lbaud @ IF 30 ELSE 10 THEN lcur +! !ENTRY REFRESH			BREAK
	;
pri ALTS
	SWITCH
	;
pri CTLS
	SWITCH
	'D' CASE 1 '<' KEY!	BREAK
	'C' CASE 1 '>' KEY!	BREAK
	;
pri CTSHS
	SWITCH
	;


pri LAESC ( n -- )
	SWITCH WKEY
	'2' CASE SHIFTS		BREAK
	'3' CASE ALTS		BREAK
	'5' CASE CTLS		BREAK
	'6' CASE CTSHS		BREAK
	DROP
	;


: UPPER ;

pub LAKEY
	KEY ?DUP IF newkey C! THEN
	newkey C@ SWITCH

\    SWITCH@ IF REFRESH THEN				--- otherwise refresh the screen before checking these repeat keys
	'R' CASE RUNNING CAPTURE REFRESH STOPPED	BREAK
	'>' CASE 4 PR 2* 2* samples +! REFRESH 		BREAK
	'<' CASE 4 PR 2* 2* NEGATE samples +! REFRESH 	BREAK

	';' CASE WKEY LAESC !ENTRY			BREAK

	'.' CASE 1 PR lcur +! !ENTRY REFRESH 		BREAK	--- move cursor by amount or 1

	$E8 CASE 1 PR lcur +! !ENTRY REFRESH 		BREAK	--- move cursor by amount or 1

	',' CASE 1 PR NEGATE lcur @ + 0 MAX lcur ! !ENTRY REFRESH 		BREAK

	$A2 CASE 1 PR NEGATE lcur @ + 0 MAX lcur ! !ENTRY REFRESH 		BREAK

	'/' CASE CAPBUF samples ! !ENTRY REFRESH 		BREAK

	'@' CASE 2* 2* CAPBUF + samples ! !ENTRY REFRESH 	BREAK

	'+' CASE FINDMATCH !ENTRY REFRESH 		BREAK

	newkey C@ UPPER SWITCH !KEY
	SWITCH@  '0' '9' WITHIN IF +ENTRY FRAME 	BREAK	--- accumulate entry

	'Z' CASE SETZOOM REFRESH				BREAK

	'W' CASE SETWIDTH CLS !ENTRY REFRESH 		BREAK	--- RESET WIDTH & ZOOM or use entry


	'?' CASE LAHELP !ENTRY REFRESH			BREAK

	'T' CASE SETTRIG REFRESH				BREAK

	'C' CASE SETCUR REFRESH				BREAK

	'S' CASE SETSCALE FRAME				BREAK			--- set scale in clock cycles

	'N' CASE SETns FRAME				BREAK

	'U' CASE SETus FRAME				BREAK

	'M' CASE SETms FRAME				BREAK

	'B' CASE SETbaud REFRESH				BREAK			--- set scale by 3*baudrate

	'I' CASE SETchan CLS !ENTRY REFRESH 		BREAK

	^I  CASE RUNNING CAPTURE FRAME REFRESH STOPPED 	BREAK                --- TAB - take a sample

	^H  CASE 10 / FRAME				BREAK			--- BS clear last digit

	$7F CASE !ENTRY FRAME				BREAK			--- DEL to clear entry (was BACKSPACE )

	$20 CASE !ENTRY REFRESH				BREAK			--- stop, clear entry and refresh screen

	$0D CASE SHELL					BREAK				--- exit to Forth shell

\	$1B CASE 		BREAK
\
\	'[' CASE 		BREAK
	;

@org W@ spvars - == spsz
pub SPLAT
	CLS
	28 _channels C! _schan C~
	spvars spsz ERASE
	snew W@ $A55A <>
	IF
	  75 width !					--- set defaults for 80 columns total
	  10 lcur ! 1 zoom C!
	  42 scale !					--- minimum sample time
	  $A55A snew W!					--- used to detect that settings were backed up
	THEN

	1,000,000,000 1,000 CLKFREQ */ ps !        --- calculate constant used by scale
	CAPBUF samples !
	!ENTRY						--- lnum is now on the stack to permit cli use

\	IFDEF BIG
\	  yellow PEN ghome BIG ." SPLAT" 500 ms CON     --- Splash screen
	}
pub R							--- RESUME
	STOPPED
	CLS !ENTRY REFRESH
	BEGIN LAKEY AGAIN				--- exit to console on <CR> (for now)
;

{
--- aliases for command line use
ALIAS SETns N		PUBLIC
ALIAS SETus U		PUBLIC
ALIAS SETms M		PUBLIC
ALIAS SETbaud B		PUBLIC
ALIAS SETWIDTH W	PUBLIC
ALIAS SETZOOM Z		PUBLIC
ALIAS SPLAT S		PUBLIC
}
: N	SETns ;
: U	SETus ;
: M	SETms ;
: B	SETbaud ;
: W	SETWIDTH ;
: Z	SETZOOM ;
: S	SPLAT ;

END
\ ?BACKUP
