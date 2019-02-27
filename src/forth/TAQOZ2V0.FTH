\ : PBJ
TAQOZ ( 6,314 bytes )
!SP 11 22 33 --- check stack
pub .VER		." 190225-1700  " ^V KEY! ;


{
TAQOZ V1.1 EXTENSIONS
V1.2 integrates kernel components
V2 has new kernel
}


{
--- set new cfa to point back to DOES: code (skipped by DOES: itself)
pub DOES>	R> 0 REG W@ W! ;
--- create new dev with dummy cfa (save ptr to it)
pub CREATE	HERE [C] CREATE: [C] GRAB HERE 0 REG W! 0_0 [W] ;

pre Q  CREATE [W] DOES> W@ . ;
}


\ ALIAS <for> <as>
\ pre ALIAS	[C] NFA' [G] DUP CPA W@ [C] CREATE$ @WORDS C@++ $1F AND + W!   C@ $E0 AND @WORDS C+! ;

--- alternative comment for titles

pre *** [C] \ ;
\ ALIAS \ ***


( P2 CONTROL )
public
$1FA := DIRA
$1FB := DIRB
$1FC := OUTA
$1FD := OUTB
$1FE := INA
$1FF := INB

{

rx_pin		=	63		'pin serial receiver
tx_pin		=	62		'pin serial transmitter
spi_cs		=	61		'pin SPI memory select		(also sd_ck)
spi_ck		=	60		'pin SPI memory clock		(also sd_cs)
spi_di		=	59		'pin SPI memory data in		(also sd_di)
spi_do		=	58		'pin SPI memory data out	(also sd_do)
sd_cs		=	spi_ck
sd_ck		=	spi_cs
sd_di		=	spi_di
sd_do		=	spi_do
}

private
61	:= SDCK
\ 60	:= SDCS
59	:= SDDI
58	:= SDDO


private
6	:= KBCLK
7	:= KBDAT
8	:= SCL
9	:= SDA

31	:= AOUTL	--- directly coupled via 220R
30	:= AOUTR
29	:= AINL
28	:= AINR
27	:= USB+		--- via 22R series termination
26	:= USB-
25	:= USB1+
24	:= USB1-


\ $1.F000		:= BUFFER

{
*** EFM88BB10F CHIP ***
57	:= BB02
56	:= BB01
55	:= BB00
54	:= BBGND
53	:= BBVDD
52	:= C2CK
51	:= C2D
50	:= BB13
}

--- some common constants
public
64 KB		:= 64KB
1,000,000	:= 1M

pub RUN ( task cog -- )		DUP NEWCOG 2000 WAITX TASK W! ;

( to use: ' <mytask> 1 RUN )

private
long _el
byte _sp
pri SPINNER
---	check if enough time has elapsed -  then update
	CNT@ _el @ - ABS CLKHZ 10 / > 0EXIT CNT@ _el !
---	output next char and backspace
	_sp C@ 3 AND " |/-\" + C@ EMIT 8 EMIT _sp C++
	;

pub .BITS ( n bits -- ) 	FOR DUP 1& . 2/ NEXT DROP ;

pub .BYTES ( adr bytes -- )	ADO I C@ .BYTE SPACE LOOP ;

pub #c		',' ;

--- process all digits for printing from right to left while inserting commas every third digit
pri #S, ( val -- 0 )
	0 SWAP
	BEGIN
---	while double not zero and not first digit
	  DUP 12 REG @ OR 3RD 0= OR
	WHILE
---	  after 1st check group if comma
	  OVER IF OVER 3 // 0= #c 0<> AND IF #c HOLD THEN THEN
---	  prepend a digit and increment digit count
	  # b++
	REPEAT
	NIP
	;
--- print a double number
pub D.				0
--- print a double number right justified
pub D.R ( dval. digits -- )	SWAP <D>
pub U.R ( val digits -- )	>R <# #S, #> R> OVER LEN$ - 0 MAXS SPACES PRINT$ ;

--- print bytes as kilobytes
pri .KB				DUP 10 >> IF 10 >> .AS" *|kB" ELSE .AS" *|B" THEN ;

\ pub OP 				21 << ' OP2 COG@ $0FE0.0000 ANDN OR ' OP2 COG! OP2 ;

pub $= ( str1 str2 -- flg )
	OVER LEN$ OVER LEN$ =
	IF
	  DUP LEN$
pub C$= ( adr1 adr2 len -- flg )
	  ADO C@++ IC@ <> IF 0= LEAVE THEN LOOP
	  0<>
	BREAK
	2DROP FALSE
	;

private 32 bytes V$

pub $+ ( str1 str2 -- str1 )	OVER DUP LEN$ + OVER LEN$ 1+ CMOVE ;

--- replace the inline 10-bit literal with a new value
pub >!				$3FF AND $F800 + R> W! ;
{
pub WORDS ( cnt -- )
	0 @WORDS DUP .ADDR
	BEGIN ( cnt width words )
	  OVER 72 > IF DUP .ADDR NIP 0 SWAP THEN
	 \ 3RD IF ROT 1- -ROT 3RD 0<> OVER C@ 0<> AND
	  DUP C@
	WHILE ( cnt width words )
	  DUP C@ $1F AND 1+ ROT + SWAP
	  DUP C@++ $1F AND CTYPE SPACE CPA 2+
	REPEAT
	2DROP
	;
}

IFDEF WORDS
: WWORDS	WORDS ;
}
pub WORDS
	@WORDS
	BEGIN ( cnt width words )
	  DUP .ADDR
	  DUP C@
	WHILE ( cnt width words )
	  DUP CPA W@ .W
	  DUP C@ 5 >> DUP 3 + SPACES 3 * " pub-1-pri-3-pre-5--6--7-" + 3 CTYPE
	  SPACE
	  DUP C@++ $1F AND CTYPE
	  CPA 2+
	REPEAT
	DROP
	;



{

pub WORDS ( cnt -- )
	0 @WORDS DUP .ADDR
	BEGIN
	  OVER 90 > IF CRLF NIP 0 SWAP THEN
	  3RD IF ROT 1- -ROT 3RD 0<> OVER C@ 0<> AND
	WHILE ( cnt width words )
	  DUP C@ $1F AND 1+ ROT + -ROT
	  DUP C@++ $1F AND CTYPE SPACE CPA 2+
	REPEAT
	2DROP
	;
	             track maximum line width & clear words & word count
WORDS   word    rg+spincnt,CLRL
MWORDS
	word	ATNAMES,DUP,PRTADR
''		new line?
.l0     word    rg+spincnt+1,CFETCH,w+90,GT,_IF+03,CRLF,rg+spincnt+1,CLRC
	word	rg+spincnt,CFETCH,_IF+05,rg+spincnt,DUP,CDEC,CFETCH,_IF+19
        word    DUPCFT,_IF+17
        word    rg+spincnt+2,WINC
        ''       track width '
        word    DUPCFT,w+cntm,_AND,INC,rg+spincnt+1,CPLUSST
        word    DUP,CFETCHINC,w+cntm,_AND,CTYPE,SPACE,NFACPA,INC2,.l0+ex

        word    DROP,rg+spincnt+2,WFETCH,SPACE,PRTDEC+ex

QWORDS	word	w+80,rg+spincnt,STORE,MWORDS+ex

}






private
long _pinmode
IFDEF PIN
'p' NFA' PIN 1+ C! --- rename PIN to pIN to make way for new def
}

pub PIN		pIN _pinmode ~ ;

--- type out printable characters or substitute with a dot
\ pub CTYPE ( adr cnt -- )	ADO I C@ .EMIT LOOP ;

pri .OK		IF ."  OK!" THEN ;

pri .SUCCESS
	SPACE IF ." SUCCESS!" BREAK ." ERROR!"
	;


--- redirect (using uemit/ukey) all character I/O to the code that follows
pub EMIT:			R> uemit W! ;
pub KEY:			R> ukey W! ;
--- null output device - discard data
pub NULL			EMIT: DROP ;


--- create a table of preallocated bytes
pre TABLE ( bytes -- ) ( -- addr )
	HERE 2+ [G]
---	create name and allow bytes
	[C] CREATE: DUP ALLOT
---	erase any allocated bytes
	?DUP IF ERASE ELSE DROP THEN
	;


{
'**************** configuration block **************** '
$00004

		byte	"P2-ES   "		' 8 character ID'
_OPTIONS	byte	%0000_0011		' options    SD,FLASH
		byte	0,0,0

'	*** CLOCK ***	'
''$10
_XIN		long	XIN			' input freqency'
_CPUHZ		long	CPUHZ			' final clock '
_CLKCFG		long	CLKCFG	''$014CB3FC 'CLKCFG

'	*** SERIAL/VGA/KEYBOARD *** '
_BAUD		long	baud_rate
_VGACFG		long	vgapins			' VGA CONFIG '
		long	vspin
_VGAINIT	long	@vgainit		' VGA code '
_KBCFG		long	kbpins
		long	0

'	*** RESET VECTORS *** '
_RESET		long	@RESET
_IDLE		long	@IDLE
_TERMINAL	long	@TERMINAL		' COG0 TASK'
_COG1		long	0			' COG1 TASK ( 0=none )
_COG2		long	0
_COG3		long	0
_COG4		long	0
_COG5		long	0
_COG6		long	0
_COG7		long	0

$14	:= _cpuhz
$18	:= _clkcfg
$1C	:= _baud
$20	:= _vgacfg
$24	:= _vspin
$28	:= @vgainit
$2C	:= kbpins
\ $30
$34
}


 	*** SERIAL MODES ***
{
115200 RXD		--- 115200 baud (default 8-bit) receive
9 -bit 1 M TXD		--- 9-bit 1 megabaud transmit

}

pri dl				7 ; --- bit length of asynch serial smartpin interface
pub -bit ( n -- )		1- ' dl C! ;
pub TXD ( baud -- )		$7C
pri BAUD ( baud mode -- )	WRPIN CLKHZ SWAP U/ 16<< ( dl 0= IF 8 BIT THEN ) dl + WXPIN H 8 -bit ;
pub RXD ( baud -- )		$3E BAUD ;
---				config save	set rxd mode & tx mode
pub CONBAUD ( baud -- )		DUP $1C !  	63 PIN DUP RXD 62 PIN TXD ;





		*** P2 CLOCK CONTROL ***


( CLOCK MODES )
---	 1098_7654_321098_7654321098_7654_32_10
---	 0000_000E_DDDDDD_MMMMMMMMMM_PPPP_CC_SS
public
long _clk  \  _clk ~
private
long _fin
--- set the
pub CLKSET			_clk @ DUP $18 ! HUBSET ;
( PLL should run between 100 to 200MHz )

--- Usage: 30 pf or 15 pf or 0 pf or -15 pf to disable
pri pf ( pf -- )		15 / 1+   3 AND 2 << $0C
pri CLK! ( data mask -- )	_clk @ SWAP ANDN OR _clk ! ;
pub PLLEN			24 |< _clk SET ;
pub PLLOFF			24 |< _clk CLR ;

pub XIDIV ( 1..64 -- )		1- $3F AND 18 << $00FC0000 CLK! ;
( ends up as multiply)
pub VCOMUL ( 1..1024 -- )	1- $3FF AND 8 << $3FF00 CLK! ;
--- Divide the PLL by 1 2 4 6 ... 30 for the system clock when SS = %11
pub PLLDIV ( 2..30 -- ) 	2/ 1- $0F AND 4 << $0F0 CLK! ;
pub CLKSRC			CLKSET DUP 1 > IF 200,000 WAITX THEN 3 AND 3 CLK! CLKSET ;

pub USEPLL			3 CLKSRC ;
pub USEXTAL			2 CLKSRC ;
pub RCSLOW			1 HUBSET _clk ~ ;


--- Set P2 CLOCK to selected MHZ ( simple PLL settings only )

pub CLOCK ( HZ --- )
---	align to multiples of XIN
	$10 @ U/ $10 @ *
pri CLOCK1
	$14 ! _clk ~
---	defaults of 15pF and an XI divide of 1
	  15 pf PLLEN 1 XIDIV
---	then multiply up the base input frequency
	  CLKHZ 16 @ U/ VCOMUL
---	default PLL divider of 1 and enable
	  1 PLLDIV USEPLL
---	reload to calculate baud rate setting
	$1C @ CONBAUD
---	VGA clock settings
	25 M CLKHZ 1M U/ U/ 2* 30 |< 1M */ $2C !
	;

---			nominal rcfast freq ( Use <new value> ' RCFAST 2+ ! )
pub RCFAST		22,400,000	CLOCK1 0 HUBSET _clk ~ ;

pub P2MHZ		M CLOCK ;

\ pub IDLE		40 P2MHZ ;
pub COAST		120 P2MHZ ;
pub CRUISE		180 P2MHZ ;
\ pub FAST		240 P2MHZ ;
pub TURBO		300 P2MHZ ;



			*** SMART PINS ***


{
                     PIN CONTROL
       1098_7654_321_0987654321098_76_54321_0
D/# = %AAAA_BBBB_FFF_PPPPPPPPPPPPP_TT_MMMMM_0

PIN MODE 13 BITS
CIO HHH LLL

 PIN DRIVE MODES

1K5 SOURCE NO SINK
OPEN SOURCE FAST SINK
1K5 SOURCE FAST SINK
OPEN DRAIN
}

			*** PIN DRIVE MODES ***


pub FAST			0 ;
pub 1K5				1 ;
pub 15K				2 ;
pub 150K			3 ;
pub 1ma				4 ;
pub 100ua			5 ;
pub 10ua			6 ;
pub OPEN			7 ; ( float )

pub CLOCKED			$100
pri 14P				14
pri PINM			<< _pinmode SET ;

pub !IN				$80 14P ; --- inverted input
pub !OUT			$40 14P ;
pub DRAIN
pub SOURCE			11 PINM ;
pub SINK			8 PINM ;



pub WRFNC ( MMMMM -- )		F 2* _pinmode @ OR WRPIN L ;

pub MUTE			F 0 WRPIN ;
\ : NCOCNT ( hz -- cntval )	CLKHZ SWAP U/ 0 1 ROT UM// DROP NIP ;
\ : NCOCNT ( hz -- cntval )	CLKHZ 4 << SWAP U/ 0 $10 ROT UM// DROP NIP ;
pub NCOCNT ( hz -- cntval )	CLKHZ 4 << SWAP U/ $10.0000.0000. ROT UM// DROP NIP ;

\ : NCOCNT ( hz -- cntval )	CLKHZ SWAP 2* U/ $8000.0000 SWAP U/ ;
pub MHZ				1000 *
pub KHZ				1000 *
pub HZ				NCOCNT
pub NCO				%1_00110
pub SETNCO ( val mode --)	WRFNC 1 WXPIN WYPIN ;

pub DUTY ( val -- )		%01_00111 SETNCO ;

pub BLINK ( pin -- )		PIN 2 HZ ;

pub PWM ( duty frame div -- )	%1_01001
pri PWM!			WRFNC SWAP 16<< OR WXPIN WYPIN ;
pub TRI ( duty frame div -- )	%01_01000 PWM! ;
pub SMPS ( duty fram div -- )	%01_01010 PWM! ;

--- convert nanoseconds to counter value based on CLKHZ
pub ns				1000 * 1,000,000,000,000. CLKHZ UM// DROP NIP U/ ;

pub PW ( width -- )		%01_00101 WRFNC WXPIN ;

pub PULSE				1
pub PULSES ( cnt -- )		WYPIN ;
pub HILO ( high low -- )		%01_00100 WRFNC SWAP OVER+ SWAP 16<< OR WXPIN ;




( SMART PINS )
{
 %AAAA_BBBB_FFF_PPPPPPPPPPPPP_TT_MMMMM_0
}


\ ' 12-bit analog to digital to analog, 19.5k samples/second

pub DAC ( bits -- )		%101_000_0000000_01_00011 WRFNC |< WXPIN ;
\ pub V ( volts*1000 --- )	$1.0000 3300 */ WYPIN ;
pub V ( volts*1000 --- )	16 << 3300 U/ WYPIN ;

pub ADC ( cycles -- )		%100_011_0000000_00_01111 WRFNC WXPIN 0 WYPIN ;

private 64 words amin	64 words aref
pri AREF			@PIN 2* aref + ;
pri AMIN			@PIN 2* amin + ;
pub SETADC ( min ref -- )	AREF W! AMIN W! ;
pub VOLTS@ ( -- volts*1000 )	RDPIN AMIN W@ - 1000 AREF W@ */ ;
}


( 40 PIN 40,000 ADC 7191 7675 SETADC )


{ TRANSMITTING ASYNCH
TAQOZ# 34 PIN 8 BIT 115200 TXD  ok
TAQOZ# $55 WYPIN  ok
TAQOZ# $41 WYPIN  ok
TAQOZ# @NAMES 4 TXDAT  ok
'        1098 7654 321 0987654321098 76 54321 0
'           0 0001 000 0000000000000 01 11100 0
' D/# = %AAAA_BBBB_FFF_PPPPPPPPPPPPP_TT_MMMMM_0
' 11100*  = sync serial transmit         (A-data, B-clock)
}
\ pub SYNTX ( bits --- )		L $100.0078 WRPIN 1- $20 OR WXPIN ;

{
pub TX		WYPIN ;
pub SERIAL ( pin -- )           PIN ' TX uemit W! ;

}






public
ukey 2+		:= keypoll
ukey 14 +	:= flags
delim 4 +	:= uprompt
delim 6 +	:= uaccept
delim 16 +	:= unum


{
@org		org
ukey 2+		org
	word	keypoll		--- poll user routines - low priority background task
	word	base		--- current number base + backup location during overrides
	long	baudcnt		--- SERIN SEROUT baud cnt value where baud = clkfreq/baudcnt each cog can have it's own
	long	uswitch		--- target parameter used in CASE structures
	word	fflags		--- echo,linenums,ipmode,leadspaces,prset,striplf,sign,comp,defining
	byte	keycol		--- maintains column position of key input
1	res	wordcnt		--- length of current word (which is still null terminated)
44	res	wordbuf		--- words from the input stream are assembled here
--- numpad may continue to build backwards into wordbuf for special cases such as long binary numnbers
44	res	numpad		--- Number print format routines assemble digit characters here builds from end - 18,446,744,073,709,551,615
1	res	padwr		--- write index (builds characters down from lsb to msb in MODULO style)
1	res	pflg
1	res	pbase
4	res	pfmt

2	res	delim           res 2           ' the delimiter used in text input and a save location
dcnt		res 1
prefix          res 1           ' NUMBER input prefix
uprompt         res 2           ' pointer to code to execute when Forth prompts for a new line
accept          res 2           ' pointer to code to execute when Forth accepts a line to interpret (0=ok)
keychar         res 4           ' override for key character

suffix          res 1           ' NUMBER input suffix
                res 3

unum            res 2           ' User number processing routine - executed if number failed and UNUM <> 0
ufind           res 2           ' runs extended dictionary search if set after failing precompiled dictionary search


'
' ------ console only registers not required for other tasks  --- can be accessed as globals
'


' these 4 variables are cleared as an array of 10 bytes
anumber         res 4           ' Assembled number from input
bnumber         res 4
digits          res 1           ' number of digits in current number that has just been processed
dpl             res 1           ' Position of the decimal point if encountered (else zero)

'createvec      res 2           ' If set will execute user create routines rather than the kernel's (CREATE revectored)

dmm             res 6           ' dump "fetch' vectors to allow dump to access special devices
dmp             res 2           ' DUMP vector
}
		!org



















		*** SD CARD SUPPORT ***


org@	org ( marks start of block for DATLEN )
private
0	bytes	sdvars
4	bytes	ocr
16	bytes	cid
16	bytes	csd
	long	sdsize
	long	@sdrd
	long	@sdwr
	long	sdsum		--- checksum of sector contents
	long	seccrc		--- sector crc
	long	@sector		--- current sector

	long	filesect	--- starting sector of open file'
	long	_fread
	long	mntd		--- serial number of mounted device
	word	_fkey

	byte	sdcmd
	byte	wrflg		--- true if sector has been modified
\	byte	mntd
\	byte	sdcrc

	byte	wrens		--- write enables
	byte	file#
	byte	fq
\	byte	cflg
	byte	sdhc
	byte	blklen
16 	bytes	bitbuf

	*** PARITION RECORDS ***

--- 4 primary partitions
64	bytes	parts	--- STATE,[HEAD,[SECT(2),TYPE,HEAD],SECT(2)],1STSECT(4),PARTSEC(4)
				---  00    82    03 00   0B   50    CA C6     $2000  $00ECC000
	word	parsig

	*** FAT32 BOOT RECORD ***

3	bytes	fat32		--- jump code +nop
8	bytes	oemname		--- MSWIN4.1
	word	b/s		--- 0200 = 512B (bytes/sector)
	byte	s/c		--- 40 = 32kB clusters (sectors/cluster)
	word	rsvd		--- 32 reserved sectors from boot record until first fat table
	byte	fats		--- 02
2	res			--- Maximum Root DirectoryEntries (non-FAT32)
2	res			--- Number of Sectors inPartition Smaller than 32MB (non-FAT32)
	byte	media		--- F8 hard disk  (IBM defined as 11111red, where r is removable, e is eight sectors/track, d is double sided. )
2	res			--- Sectors Per FAT in Older FATSystems (N/A for FAT32)
2	res			--- Sectors Per Track --- 3F 00
2	res			--- Number of Heads --- FF 00
	long	hidden		--- Number of Hidden Sectors before Partition --- 00 20 00 00
( 32 )
	long	s/p		--- $00EC_C000  Number of sectors * byte/sect (512) = capacity'
	long	s/f		--- $0000_0766 Number of sectors per FAT table'
2	bytes	fat?		--- 0000 fat flags (b3..0 = active fat copy, b7=mirroring)
2	res	fatver		--- 0000 fat version MAJOR.MINOR
( 44 )
	long	rootcl		--- $0000_0002 Cluster Number of the Start of the Root Directory'
	word	infosect	--- 0001 info = Sector Number of the FileSystem Information Sector  (from part start)
	word	bbsect		--- 0006 boot = Sector Number of the Backup Boot Sector (from part start)
12	res			--- 00s
( 64 )
	byte	ldn		--- 80 logical drive number of partition
1	res	ldnh		--- 01 unused or high byte of ldn
	byte	extsig		--- 29 extended sig
	long	serial		--- $63FE_C331 serial number of partition
11	bytes	volname		--- volume name
8	res	fatname		--- "FAT32   " always FAT32 - (don't trust)
2	res			--- align to a long for FREAD
( 90 )

--- --- --- --- --- --- --- --- --- --- --- --- --- ---

	long freeclusters	--- Read from info sector
	long lastcluster	--- Read from info sector
---	calculated from scan at mount
	long usedcl		--- Used Clusters
	long freecl		--- Free Clusters
	long used%		--- percentage used *100


--- --- --- --- --- --- --- --- --- --- --- --- --- ---
--- create room for some system variables in this table

	long	rootdir		--- sector address of root directory (MBR,GAP,BOOT,INFO,BACKUP,FAT1,FAT,ROOT)
	long	fat1
	long	fat2
	long	cwdsect
org@ sdvars -	:= sdsz		--- size of array used to hold all raw SD card related values + FAT etc
cwdsect fat32 - := fatsz	--- size of array used to hold all fat32 related values

	byte	f?


	*** DIRECTORY STRUCTURE ***
private
0	org	--- use relative offsets

8	res	fnam
3	res	fext
1	res	fatr		--- 5=archive,4=subdir,3=vol-label,2=system/fixed,1=hidden,0=readonly
1	res	00		\ MUST BE 00' user atrs
( 13)
1	res	fcms		\ create time 10ms
2	res	fctime
2	res	fcdate
2	res	fadate
2	bytes	fch		--- no actual bytes in memory - just the label
2	bytes	ftime
2	bytes	fdate
2	bytes	fcl
4	res	fsize

	!org --- reset org back to previous
public
$10000		:= SDBUF	--- allocate 4k for buffers

--- erase 4 sector buffers
pri !SDBUF				SDBUF $800 ERASE ;


pri SDBUF+ ( offset -- adr )		SDBUF + ;

\ pub SDBUF		$1.0000 file# C@ 5 << + ;
\ pub FILE ( n -- )	3 AND file# C! ;

pri SDSPI				&60.58.59.61 SPIPINS ;
pri SDCS				' SDSPI 5 + C@ ;
--- set SD PINS
pub SDPINS				' SDSPI :=! ;

pub SD? ( -- flg )
--- assume SD CD pin may be floating --- check for pullup
	SDCS LOW 100 WAIT SDCS FLOAT 1000 WAIT SDCS PIN@ SDCS HIGH
--- clear mounted flag if SD not present
 	DUP ?EXIT mntd ~
	;

pri RELEASE				SPICE
pri SDCLK				8 CLKS ;
pri SDCLK3				24 CLKS ;
--- clock SD for token but timeout false if not found
pri TOKEN ( marker -- flgX )
	' SDSPI 3 + C@ HIGH
	10000 BEGIN OVER 0 SPIRD <> WHILE 100 us 1- DUP 0= IF NIP EXIT THEN REPEAT
	2DROP TRUE
	;
\ pri !CRC				$95 sdcrc C! ;
pub CMD ( data cmd -- res )
	DUP sdcmd C!
---	setup SD pins for SPI and preclock
	SDSPI SDCLK
---	write cmd and 32-bits of data
	SPIWC SPIWL
---	send a crc of CMD8 or CMD0 - others ignore value
	sdcmd C@ IF $87 ELSE $95 THEN SPIWB
pri SDRES
---	  retry for read until <> $FF
	0 4000 FOR SPIRD >B DUP $FF <> ?NEXT DROP
	;
pub ACMD ( data acmd -- res )
	0 55 CMD DROP CMD
	;
pri DAT?
	SDRES $FE =
	;

pri SDSTAT ( -- stat )	16 CLKS 0 13 CMD SDRES 8<< OR ;

\ pri SD4@ ( -- long ) 0 SPIRD SPIRD SPIRD SPIRD ;
pri SDDAT! ( adr -- ) --- read info into memory
	$FE TOKEN IF DUP 16 ADO 0 SPIRD I C! LOOP SDCLK3 THEN DROP
	;


--- CSD BIT FIELDS ---

pri XSHR
	0 DO
	0 bitbuf 16
	  ADO I C@ DUP 2/ ROT OR I C!
	    1& IF $80 ELSE 0 THEN
	  LOOP
	 DROP
 	LOOP
	;

pri CSD@
	csd
pri BITS@	( bith bitl adr -- dat )
	bitbuf 16 CMOVE
 	DUP XSHR - 1+ |<
	1-
	0 bitbuf 12 + 4 ADO 8 << I C@ OR LOOP
	AND
	;

pri !SX
	sdcmd C~~ 5 FOR 0 0 CMD 1 = ?NEXT 0EXIT
	5 FOR $1AA 8 CMD 1 = ?NEXT 0EXIT
	0 SPIRL $1AA = 0EXIT
	0 1000 0 DO 30 |< 41 ACMD IF 200 CLKS ELSE 1+ LEAVE THEN LOOP 0EXIT
	0 58 CMD ?EXIT 0 SPIRL DUP ocr ! 0EXIT
	0 10 CMD 0= IF cid SDDAT! THEN
	0 9 CMD 0= 0EXIT csd SDDAT!
	;

--- Initialise the SD card in SPI mode and return with the OCR
--- pub !SD ( -- ocr|false )
pub !SD ( --- ocr|false )
	SDSPI sdvars sdsz ERASE
	!SDBUF
	@sector ~~
	SD? IF
	  SDCLK3 20 FOR
	    !SX sdcmd C@ 9 = DUP 0= IF 50000 CLKS THEN
	  ?NEXT
	  DROP SPICE 800 CLKS
	  69 48 CSD@ 1+ 10 <<   sdsize !
	THEN
	ocr @
	;


		--- CARD INFO ---

pri .LINE	CRLF 4 SPACES DUP PRINT$ LEN$
pri .LINE@	32 - ABS '.' SWAP EMITS SPACE ;
pri .***	SPACES ." ***" SPACE ;
pri .TITLE	CRLF CRLF 20 OVER LEN$ 2/ - .*** PRINT$ 1 .*** ;


pri .MFG
	SWITCH
	1 CASE   ." PANASONIC" BREAK
	2 CASE   ." TOSHIBA  " BREAK
	3 CASE   ." SANDISK  " BREAK
	$1B CASE ." SAMSUNG  " BREAK --- PROGRADE
	$1D CASE ." AData    " BREAK
	$27 CASE ." PHISON   " BREAK --- AgfaPhoto, Delkin, Integral, Lexar, Patriot, PNY, Polaroid, Sony, Verbatim
	$28 CASE ." LEXAR PNY" BREAK
	$31 CASE ." SILICON POWER " BREAK
	$41 CASE ." KINGSTON " BREAK
	$74 CASE ." TRANSCEND" BREAK
	$76 CASE ." PATRIOT  " BREAK
	$82 CASE ." SONY     " BREAK
	CASE@  ."  UNKNOWN" .B
	;

{
pub .CID
	" CID" .TITLE
	" BRAND" .LINE cid C@ .MFG
	" OEM ID" .LINE cid 1+ 2 CTYPE
	" PRODUCT" .LINE cid 3 + 5 CTYPE
	" REV" .LINE cid 8 + C@ .B
	" SERIAL#" .LINE cid 9 + @ PRINT
	" MFG" .LINE cid 14 + C@ cid 13 + C@ >N 8 << + DUP 4 >>  2000 + . >N .AS" /*|"
	" CRC" .LINE cid 15 + C@ DUP .B SPACE 1& ?EXIT
}

pub .CID
	."  CARD: " cid C@ .MFG
	SPACE cid 1+ 2 CTYPE
	SPACE cid 3 + 5 CTYPE
	."  REV" cid 8 + C@ .B
	."  #" cid 9 + @ U.
	."  DATE:" cid 14 + C@ cid 13 + C@ >N 8 << + DUP 4 >>  2000 + . >N .AS" /*|"
	CRLF cid 15 + C@ 1& ?EXIT
	." BAD CID "
	;


\ pri 10^		FOR 10 * NEXT  ;



\ 0=0.5 mA, 1=1 mA, 2=5 mA, 3=10 mA, 4=25 mA, 5=35 mA, 6=60 mA, 7=100mA
\ 0=1 mA, 1=5 mA, 2=10 mA, 3=25 mA, 4=35 mA, 5=45 mA, 6=80 mA, 7=200

private
0 TABLE ma
--- min
	&010.005.001.000 ,
	&100.060.035.025 ,
--- max
	&025.010.005.001 ,
	&200.080.045.035 ,


\ Card information
pri .ma		ma + + C@ ?DUP IF .DECL ELSE ." 0.5" THEN ." ma" ;
pri .CURRENT
	  " Iread Vmin" .LINE	61 59 CSD@ 0 .ma
	  " Iread Vmax" .LINE	58 56 CSD@ 8 .ma
 	  " Iwrite Vmin" .LINE	55 53 CSD@ 0 .ma
	  " Iwrite Vmax" .LINE	52 50 CSD@ 8 .ma
{
	  " Read Current @VDD min" .LINE	61 59 CSD@ 0 .ma
	  " Read Current @VDD max" .LINE	58 56 CSD@ 8 .ma
 	  " Write Current @VDD min" .LINE	55 53 CSD@ 0 .ma
	  " Write Current @VDD max" .LINE	52 50 CSD@ 8 .ma
}
	  ;
}

pri .xs ( ns -- )
	DUP 1 M => IF 1 M / .AS" #~#ms" EXIT THEN
	DUP 1,000 => IF 1,000 / .AS" #~#us" EXIT THEN
	.AS" #~#ns"
	;

private
0 TABLE tval
	&13.12.10.00 ,
	&30.25.20.15 ,
	&50.45.40.35 ,
	&80.70.60.55 ,

pri TACC ( -- ns )
	119 112 CSD@ --- b6..3=tval b2..0=tru
	DUP 3 >> tval + C@ ( *10)
	SWAP 7 AND 1 SWAP 1+ FOR 10 * NEXT 100 / *
	;
pri .TACC
	" LATENCY" .LINE
 	TACC .xs
	119 112 CSD@ ?DUP 0EXIT 100 * .AS" +*|# clocks "
	;

pri .TRANS
	" SPEED" .LINE
	103 96 CSD@ .AS" ##Mbps "
	;
pub .CSD
	sdhc C~
	" CSD" .TITLE
	127 126 CSD@
	IF
	  " CARD TYPE" .LINE ." SDHC" sdhc C~~
	  .TACC  .TRANS
	  " CLASSES" .LINE 95 84 CSD@ 20 << REV 12 .BITS
 	  " BLKLEN" .LINE		83 80 CSD@ DUP blklen C! |< .DECL
---	                                    total sectors
	  " SIZE" .LINE  sdsize @ 2000 U/ .DECL ." MB"

	  .CURRENT

	  EXIT
	THEN
	."  NOT SDHC!"
	;

pub .OCR
	" OCR" .TITLE
	" VALUE" .LINE ocr @ .L ( $C0FF_8000 )
	ocr @ 30 >> 3 <> IF ."  invalid!" THEN
	" RANGE" .LINE
	27 ocr @ 15 >> $1FF AND BEGIN DUP 1& 0= WHILE 2/ b++ REPEAT OVER .AS" #.#V to "
	BEGIN DUP 1& WHILE 2/ b++ REPEAT DROP .AS" #.#V"
	;




--- Read only - write protected
pub RO		0
pri wm		wrens C! ;
--- Read/Write access - write enabled
pub RW		1 wm ;
--- Read/Write & create
pub RWC		3 wm ;
\ --- Create directory
\ pub +D		7 wm ;
--- Read/Write/System permission
pub RWS		7 wm ;
pri W?		1 wrens SET? ;

pri B>S ( bytes -- sectors )	L>S SWAP IF 1+ THEN ;


		*** SD CARD MEMORY ACCESS ***

pri SDWR?	@sdwr @ ;

pub SDWR ( src sect --  )
	@sdwr ~
---	never sector 0 or if write protected unless RWS used
	DUP 0<>	 W? AND 4 wrens SET? OR
	IF
---	 sector write command
	 SDCLK3  24 CMD
	  IF DROP
---		    start token, data
	  ELSE SDCLK3 $FE SPIWB 512 SPITX
---	    read data response
	    0 TOKEN $FF TOKEN AND
	  THEN
---	 always reset any RWS permissions after op
	  4 wrens CLR   @sdwr ! RELEASE
	BREAK
---	else write protect fail
	2DROP
	;

( 372ms @120MHz for 64KB SU04G )

pub SDWRS ( ram sector bytes -- )
	@sdwr ~ W?
	IF
	  B>S
	  ADO
	    DUP I SDWR 512 + SDWR? 0= IF LEAVE THEN
	  LOOP
	  DROP RELEASE
	BREAK
	3DROP
	;

--- only flush sector if it has been written to
pub ?FLUSH
	wrflg C@ 0EXIT
pub FLUSH
	SDBUF @sector @ SDWR wrflg C~
	;

pri SDRDBK ( dst -- crc/flg )
	512 SPIRX sdsum !
	0 SPIRD SPIRD $80000000 OR
	;

pub SDRD ( sector dst --  ) --- read sector into memory and update sector number
	OVER @sector !
pub SDRDX ( sector dst -- ) --- read sector into memory silently
	SDCLK
	SWAP 17 CMD DUP 0=
	IF DROP DAT?
	  IF SDRDBK ELSE SDSTAT 2DROP 0 THEN
	THEN
---	save crc as a flag  -- only lower 16-bits of seccrc = crc with flag in b31
	DUP @sdrd ! seccrc !
	RELEASE
	;


pri SDWAIT --- wait for data token with timeout (only used in SDRDS)
	1000 BEGIN 1- DAT? OVER 0= OR UNTIL DROP
	;

--- read multiple sectors in continuous multiblock mode
pub SDRDS ( sector dst bytes -- crc | false )
---	convert bytes to sectors '
	B>S
---	multiblock read   --  command not accepted '
	-ROT SWAP 18 CMD
	IF 2DROP FALSE
	ELSE
---	process read token and read block if available '
	  DAT?
	  IF
	    SWAP FOR DUP SDRDBK DROP SDWAIT 512 + NEXT DROP
	  ELSE
	    2DROP SDSTAT DROP SPICE FALSE
	  THEN
	THEN
	RELEASE	\ SDCLK SPICE
	DUP @sdrd !
---	cancel multiblock read on error
	  2000 BEGIN 1- 0 12 CMD 0= OVER 0= OR UNTIL DROP
	RELEASE
	;
{
0001_01B0: 00 00 00 00  00 00 00 00  B8 B6 06 5D  00 00 00 82     '...........]....'
0001_01C0: 03 00 0B 50  CA C6 00 20  00 00 00 C0  EC 00 00 00     '...P... ........'
0001_01F0: 00 00 00 00  00 00 00 00  00 00 00 00  00 00 55 AA     '..............U.' ok
}

pub SECTORF ( sect -- sdbuf )
	?FLUSH SDBUF SDRD
	SDBUF
	;

--- S>M
pub SECTOR ( sect -- sdbuf )
	DUP @sector @ <> IF SECTORF EXIT THEN
	DROP SDBUF
	;


--- at current FILE
pub @FILE ( -- sector )			filesect @ ;

pub SDADR!				wrflg C~~
pub SDADR ( sdadr -- ramadr )		L>S @FILE + SECTOR + ;
pub SD@ ( xaddr -- long )		SDADR @ ;
pub SD! ( data xaddr -- )		SDADR! ! ;
pub SDC@ ( sdaddr -- byte )		SDADR C@ ;
pub SDC!				SDADR! C! ;
pub SDW@				SDADR W@ ;
--- select SD for DUMP method
pub SD					DUMP: SDC@ SDW@ SD@ ;

--- at ROOT sector
pub @ROOT ( -- sector )			rootdir @ ;
--- at BOOT sector
pub @BOOT ( -- sector )			parts 8 + @ ;
pri @FAT ( fat# -- sector )		s/f @ * @BOOT rsvd W@ + + ;

pri FATSZ ( -- fatsz )			sdsize @ @BOOT - ;

--- open ROOT sector as a file
pub ROOT				@ROOT
pub OPEN-SECTOR
pri FOPENS!				_fread ~ filesect ! ;
--- Close file by flushing, switching to read-only and use sector 0
pub CLOSE-FILE
pub FCLOSE				FLUSH RO 0 OPEN-SECTOR ;


--- change current working directory
pub CD# ( sect -- )			cwdsect ! ;


		*** CLUSTERS ***
{

...............MEDIA
0001_0000: 0FFF_FFF8 0FFF_FFFF 0FFF_FFF8 0000_0004     '................'
0001_0010: 0000_0005 0000_0006 0000_0007 0000_0008     '................'
0001_0020: 0000_0009 0000_000A 0000_000B 0000_000C     '................'
0001_0030: 0000_000D 0000_000E 0000_000F 0000_0010     '................'
0001_0040: 0000_0011 0000_0012 0000_0013 0000_0014     '................'
0001_0050: 0000_0015 0000_0016 0000_0017 0000_0018     '................'
0001_0060: 0000_0019 0000_001A 0000_001B 0000_001C     '................'
0001_0070: 0000_001D 0000_001E 0000_001F 0000_0020     '............ ...'
0001_0080: 0000_0021 0000_0022 0FFF_FFFF 0000_0000     '!..."...........'
0001_0090: 0000_0000 0000_0000 0000_0000 0000_0000     '................'

  1:   _BOOT_P2.BIN 20 $0000_5B26   2018-12-24 06:48   X...P2D2F   ....   131,072  ok
TAQOZ# @ROOT .L --- $0000_5B1E ok
TAQOZ# s/c C@ . --- 8 ok


CLUSTER0 = MEDIA BYTE
CLUSTER1 = b27 = clean ; b26 = no errors

}

pub FAT1				fat1 @ OPEN-SECTOR ;
pub FAT2				fat2 @ OPEN-SECTOR ;


{ CLUSTER CHAIN CODES
If value => $0FFF.FFF8 then there are no more clusters in this chain.
$0FFF.FFF7 = bad
0 = free

}
pri @CLUSTER ( index -- xadr )		FAT1 4* ;

pri CLUSTER@ ( index -- cluster )	@CLUSTER SD@ ;


pri FreeClusters? ( size -- #clusters clust1 )
	--- calculate clusters required
     B>S s/c C@ U/ ( clusters )
      0
     BEGIN
       --- find a free cluster
       BEGIN DUP CLUSTER@ WHILE 1+ REPEAT
       --- check for sufficient contiguous clusters ( clusters index )
       0 OVER 3RD ADO I @CLUSTER SD@ OR DUP IF NIP I SWAP LEAVE THEN LOOP
       ( clusters chain flag )
     WHILE
       1+
     REPEAT
     ;



--- count number of clusters used from start cluster
pub #C ( cluster# -- clusters )
---	backup current sector
	filesect @ >R
--- scan through fat1 as a file
	FAT1
	0 SWAP BEGIN b++ 4* SD@ DUP $0FFF_FFF8 => UNTIL DROP
---	restore sector
	R> OPEN-SECTOR
	;

pub I>D ( dirIndex -- diradr )
	ROOT 5 << SDADR
	;


--- Directory address to first cluster
pub D>C ( diradr -- cluster#0 )
---	cluster low and cluster high
	fcl OVER+ W@ SWAP fch + W@ W>L
	;

--- Directory address to starting sector
pub D>S ( diradr -- sector )
	D>C
--- Cluster to sector
pub C>S ( clust# -- sector )
	rootcl @ -
pri C>S2
	s/c C@ * @ROOT +
	;

--- convert a sector to a cluster ( result 0 = out of range  ; 2 = 1st )
pub S>C ( sector -- cluster )
\	@BOOT - s/c C@ U/
	@ROOT - s/c C@ U/ 2+
	;

--- convert sector to total allocated clusters
pri S>C# ( sector -- clusters )
	S>C #C s/c C@ * 9<<
	;

pub I>S ( dirIndex -- sector )
	I>D D>S
	;

--- find the directory entry that matches the file sector ( 2.3us @120MHZ for entry #30)
pub S>D ( sector -- diradr )
	0 BEGIN DUP I>D C@ WHILE DUP I>D D>S 3RD = IF NIP I>D EXIT THEN 1+ REPEAT
	2DROP 0
	;

pub @FSIZE ( -- adr )
	@FILE S>D 28 +
	;


pri ?USED
---	Calculate used/unused
	0 0 usedcl 12 ERASE
	sdsize @ @ROOT - ( data-sectors )
	s/c C@ U/ ( data-clusters ) 2+ ( where root is cluster 2 )
	2 DO I CLUSTER@ IF b++ ELSE 1+ THEN LOOP
	2DUP + 3RD 10000 * SWAP U/
	used% ! freecl ! usedcl !
	;

pub GETFAT
---	read fat32 as a byte array
	@BOOT SECTORF fat32 90 CMOVE
---	sectors rsvd to fat1  ... size of fat tables
	rsvd W@                s/f @ fats C@ *  + ( offset from fat boot )
\	rootcl @ 2- C>S2
	hidden @ + 	rootdir !
---	'' save time by precalculating FAT table addresses
	0 @FAT fat1 ! 1 @FAT fat2 !
	?USED
---	Open info sector
	@BOOT infosect W@ + OPEN-SECTOR
	$1E8 SD@ freeclusters !
	$1EC SD@ lastcluster !
	;

{
00h 	First Signature (52h 52h 61h41h) 	1 Double Word
04h 	Unknown, Currently (Mightjust be Null) 	480 Bytes
1E4h 	Signature of FSInfo Sector(72h 72h 41h 61h) 	1 Double Word
1E8h 	Number of Free Clusters (Setto -1 if Unknown) 	1 Double Word
1ECh 	Cluster Number of Clusterthat was Most Recently Allocated. 	1 Double Word
1F0h 	Reserved 	12 Bytes
1FCh 	Unknown or Null 	2 Bytes
1FEh 	Boot Record Signature (55hAAh) 	2 Bytes
}

{

	--- Read and buffer the FAT32 boot record
	@BOOT SECTOR fat32 90 CMOVE
	--- make a fast multiply using a shift left constant
	sect/clust C@ >| clshift C!

	rsvd W@ sect/fat @ fats C@ *
	rootcl @ 2- clshift C@ << + + @BOOT + rootdir !
	--- save time by precalculating FAT table addresses
	0 @FAT fat1 !  1 @FAT fat2 !
}


pub MOUNT
	SD? 0EXIT !SD 0EXIT
	0 SECTORF $1FE + W@ $AA55 <> " INVALID PARTITION" ?ERROR
	$1BE SDBUF+ parts 66 CMOVE
	fat32 fatsz ERASE
	RO --- disable sector sdwr
	GETFAT
	ROOT serial @ mntd !
--- PRINT CID AS CONFIRMATION
	.CID
	;
---	MOUNT FAT32 if not already mounted
pub ?MOUNT
	SD? serial @ mntd @ = AND mntd @ 0<> AND 0=
	  IF 10 ms MOUNT ( $0D KEY! ) ELSE SD? 0= IF mntd ~ THEN THEN
	;
pri MOUNTED?
	?MOUNT mntd @
	;
{
--- Open the starting sector as a file
pub FOPENS ( sect -- )
	?MOUNT OPEN-SECTOR
	;
}

		*** DIRECTORY ***

pri @FNAME ( -- hubadr )
	0
pri @DIR ( offset -- hubadr ) --- return with the indexed directory plus offset in hub RAM
	I 5 << + ROOT SDADR
	;

pub .NAME
	@FNAME 8 CTYPE
	8 @DIR C@ $20 <> IF '.' EMIT 8 @DIR 3 CTYPE EXIT THEN
	SPACE
pri GAP	3 SPACES
	;

pub .DECX ( num ch -- )		EMIT .AS" ##" ;
pub .DATE
	fdate @DIR DUP W@ DUP 9>> 1980 + .DEC4
	5 >> >N '-' .DECX $1F AND '-' .DECX
	ftime @DIR W@ DUP 11 >> $20 .DECX
	5 >> $3F AND ':' .DECX
	;

{ DIRECTORY STRUCTURE
8	res	fnam
3	res	fext
1	res	fatr		--- 5=archive,4=subdir,3=vol-label,2=system/fixed,1=hidden,0=readonly
1	res	00		\ MUST BE 00' user atrs
( 13)
1	res	fcms		\ create time 10ms
2	res	fctime
2	res	fcdate
2	res	fadate
2	bytes	fch		--- no actual bytes in memory - just the label
2	bytes	ftime
2	bytes	fdate
2	bytes	fcl
4	res	fsize
}

--- Print dir entry rg+1=mode
pri .ENTRY
	8 f? SET? IF CRLF I .AS" ##\#: " THEN
	.NAME SPACE 8 f? SET? ( ls or dir ? )
	IF
	  11 @DIR C@ DUP .BYTE SPACE 8 AND 0=
	  IF
---	 $0000_9678   2018-12-24 02:56
	  @FNAME D>S .L GAP .DATE
---	 display file size
	  SPACE 28 @DIR @ DUP 14 U.R
\	  100,000,000 U< DUP 1& . 0EXIT
	  27 >> ?EXIT
	  ."  /" @FNAME D>S S>C# 14 U.R
---	 display file header
	    GAP @FNAME D>S 512 SDBUF+ SDRDX
	    512 SDBUF+ 20 ADO I C@ .EMIT LOOP
	    EXIT
	  THEN
	THEN
	fq C++ fq C@ 7 AND ?EXIT CRLF
	;
{
0123456789*123456789*123456789*123456789*123456789*123456789*123456789*123456789*123456789*123456789*123456789*
    FILENAME.EXT ATR  SECTOR     DATE       TIME         FILE SIZE      ALLOCATED  CONTENTS
 1: _BOOT_P2.BIN 20 $0000_5B18   2018-12-24 06:48        131,072 /       131,072   X...P2D2F   ........
}
pub DIR
	8
pri .DIR
	f? W! MOUNTED? 0EXIT
---	scan root directory from start sector for max dir entries of 1 cluster? (index)
	0 s/c C@ 4 <<
	ADO
---	  Look for a valid dir entry and print it '
	  @FNAME C@ $20 $7E WITHIN IF .ENTRY THEN
	LOOP SPACE
	;

pub DIRW
pub ls
	CRLF 0 .DIR
	;



--- Load text input from a sector
pub FLOADS ( sector -- ) --- load file as console input then restore on null to console input '
	OPEN-SECTOR ukey W@ _fkey W!
	KEY:
pub FGET ( -- ch ) --- Read the next byte from the file
	_fread @ SDC@ ?DUP
	IF
	_fread ++ EXIT
	THEN
	_fkey W@ ukey W! _fkey W~
	FALSE
	;

--- Read file offset to memory
pub FREAD ( sdsrc hubdst bytes -- )
	4 ALIGN ADO DUP SD@ I ! 4+ 4 +LOOP DROP
	;
--- Write memory to file offset
pub FWRITE ( hubsrc sddst bytes -- )
	4 ALIGN ADO DUP @ I SD! 4+ 4 +LOOP DROP
	;


private --- 8.3 directory entry structure
0 bytes dirbuf
8 bytes -fname
3 bytes -ext
1 bytes -atr		---  (0:read-only, 1:hidden, 2:system, 3:volume label, 4:directory, 5:archive, 6-7: undefined)
1 res 0
1 bytes -fcms
2 bytes -fctime
2 bytes -fcdate
2 bytes -fadate
2 bytes -fclsth
2 bytes -ftime
2 bytes -fdate
2 bytes -fclstl
4 bytes -fsize


16 bytes file$
pri GETF$
	GET$
pub >F83 ( str -- buf )
	DUP file$ $!
	dirbuf $20 ERASE
	-fname 12 $20 FILL
---	str buf
	-fname OVER LEN$ 0 DO
	  OVER I+ C@ DUP 'a' 'z' WITHIN IF $20 - THEN
	  DUP '.' = IF 2DROP -ext ELSE OVER C! 1+ THEN
	LOOP
	2DROP -fname
	;
{
--- compare file name at dirptr with fname
pub FNAME= ( dirptr -- flg )
	fname 11 C$=
	;
}
pub FOPEN# ( index -- )
	I>D D>S OPEN-SECTOR
	;

--- find current f83 name and return with file offset to directory entry

pri FFIND ( -- sdrel )
	0 BEGIN DUP I>D DUP C@ WHILE -fname 11 C$= IF I>D EXIT THEN 1+ REPEAT
	2DROP 0
	;

{
pri +DIR ( index -- index+1 hubadr )
	1+ DUP I>D
	;
--- find current f83 name and return with file offset to directory entry
pri FFIND ( -- sdrel )
	0 BEGIN DUP I>D FNAME= NOT WHILE DUP I>D C@ 0= IF DROP 0 EXIT THEN 1+ REPEAT
	I>D
	;

}




pri FreeDir? ( --- faddr )
	ROOT 0 BEGIN DUP SDC@ WHILE 32 + REPEAT
	;


---
pri ClaimClusters ( for from -- from )
     FAT1 \ RW
     DUP 3RD ADO 1 I+ I @CLUSTER SD! LOOP					--- link clusters
     ( #clusters clust1 )
     SWAP OVER+ 1- $0FFFFFFF SWAP @CLUSTER SD!					--- mark end cluster
     FLUSH
     ;


--- Create a new file by name but if it already exists then delete the old one and reuse the dir entry.
--- if size = 0 then max = 4GB

pre mk  [G] GET$
pub mk$ ( size namestr --  )
	dirbuf $20 ERASE
	--- as 8.3 and write the name of the file to the directory buffer
	>F83 dirbuf 11 CMOVE
	--- set archive attribute
	$20 -atr C!
	--- stamp create date and time
\	DATE@ @CDATE FDATE! TIME@ @CTIME FTIME!
	--- Set size of file to maximum & preallocate clusters
		DUP -fsize ! FreeClusters? ClaimClusters
	--- write first cluster
	ROOT L>W -fclsth W! -fclstl W!
\	FSTAMP
	--- add directory record to directory
	FreeDir? DUP ( xadr ) SDADR ( bufptr )
	--- write directory entry
	dirbuf SWAP 32 CMOVE FLUSH

\	<OPEN FILE>
     ;


{

64 KB MAKE OPEN-FILE <name>


}
--- size used to create a file if file not found - 0 = none
long mksiz

--- Force file open  - create to size of it not found
pub MAKE ( size -- )	mksiz ! RWC ;



pre OPEN-FILE
--- File Open using name in stream - use @FILE to return file sector handle which is 0 is not open
pre FOPEN ( <name> -- )
	[G] GET$
pub OPEN-FILE$
pub FOPEN$ ( str -- )
	>F83 DROP
pub REOPEN-FILE
	FFIND ?DUP
	IF D>S
	ELSE
	  2 wrens SET? IF mksiz @ file$ mk$ D>S  ELSE 0 THEN
	THEN
	OPEN-SECTOR
	;


pre DEL-FILE ( <name> -- )
	OPEN-FILE
	;



{










}
--- ---
pre FLOAD ( <name> -- )
	[C] FOPEN @FILE FLOADS
	;

pre RENAME# ( dir# <new> -- )
	[G] GETF$ ROOT SWAP 5 << SDADR
pri RENAME!
	11 CMOVE FLUSH
	;

pre RENAME ( <old> <new> -- )
	GETF$ DROP FFIND DUP
	  IF GETF$ SWAP RENAME! BREAK
	.SUCCESS
	;

pre cat
	[C] FOPEN 0 SD PRINT$
	;

pre QV
	[C] FOPEN 0 SDADR $80 DUMP
	;













		*** DISK REPORTING ***


pri .SPD ( sector -- )
	CNT@ 8 FOR OVER SDBUF SDRD NEXT
	CNT@ SWAP - ABS 3 >> CLKHZ 1M / / .AS" *|#us" DROP
	;
pub .SPEEDS
	" SPEEDS" .TITLE
---				  Up to 4GB print sector speed in 0.5GB increments
	" SECTOR" .LINE $80.0000 0 DO I .SPD ',' EMIT $10.0000 +LOOP
---	Read a 256k block into unused memory
	" BLOCKS" .LINE 0 $8.0000 $4.0000 LAP SDRDS DROP LAP
---	Report the equivalent multi-block read speed
	CLKHZ $4.0000 1000 / LAP@ */ .DECL ." kB/s @" .CLK
	;

\ pub .CARD	' SDSPI 2+ @ DUP 24 >> >B .AS" CS:## " DUP 16>> >B .AS" SO:## " DUP 8>> >B .AS" SI:## " >B .AS" CK:## " ;

pub .SD
	.CID .OCR .CSD .SPEEDS
	;

		*** PARTITIONS ***

--- Check file system type and return with known name
pri ?FS ( n -- str/flg )
	SWITCH
	11 CASE " FAT32 CHS" BREAK
	12 CASE " FAT32 LBA" BREAK
	7 CASE " exFAT?" BREAK
	6 CASE " FAT16" BREAK
	FALSE
	;

--- Print Cylinder Head Sector
pri .CHS ( xxcccshh -- )
	24 BITS
	DUP 16 >> OVER 14 >> 3 AND 8 << + PRINT ',' EMIT
	DUP >B PRINT ',' EMIT
	8>> $3F AND PRINT
	;



{
Disk /dev/sdb: 7948 MB, 7948206080 bytes
255 heads, 63 sectors/track, 966 cylinders, total 15523840 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x000edc02

    CHS START....................... 1023,254,63
    CHS END......................... 1023,254,63

HHHHHHHH,CCSSSSSS,CCCCCCCC


}
pub !MBR
	!SDBUF
---	copy boot config table for reference in unused area at start
	0 SDBUF $100 CMOVE
---	MBR NAME OF FORMAT TOOL
\	" TAQOZ V2" 3 SDBUF+ $!
--- 1023, 254, 63
	parts 66 ERASE
---	valid partition flags
	$AA55 parsig W!

\	$80 parts C!
---	fs+CHS
	$0CFFFFFE parts 1+ !
--- This sets up 4MB hiddenbefore parition according to SD compliance (But >32GB 16MB)
	sdsize @ 70,000,000 U> IF $8000 ELSE $2000 THEN  parts 8 + !
---	TOTAL SECTORS = SDSIZE-<hidden>
	FATSZ parts 12 + !
---	copy parts to buffer
	parts $1BE SDBUF+ 66 CMOVE
---	Write MBR
	RWS SDBUF 0 SDWR
	;

--- Fetch sectors, print, and display in MB as well (  15,515,648 = 7,944MB )

pri .MBS ( adr -- )
	@ DUP .DECL ."  = "
pub .MB ( sectors -- )
	512 1,000 */
	DUP 1,000 U<
	IF .DECL ." kB"
	ELSE 1,000 U/ .DECL ." MB"
	THEN
	;

pub .MBR
	" MBR" .TITLE
---	Scan all 4 antries : check active partition type
	4 0 DO I 4 << parts + DUP 4+ C@
	  IF
	    " PARTITION" .LINE I PRINT SPACE DUP C@ DUP .BYTE SPACE 0= IF ." IN" THEN ." ACTIVE"
	    " FILE SYSTEM" .LINE DUP 4+ C@ ?FS ?DUP IF PRINT$ ELSE ." UNFORMATTED " THEN
	    " CHS START" .LINE 1+ DUP @ .CHS
	    " CHS END" .LINE 4+ DUP @ .CHS
	    " FIRST SECTOR" .LINE 3 + DUP @ .L
	    " TOTAL SECTORS" .LINE 4+ .MBS
	    CRLF
	  ELSE DROP
	  THEN
	LOOP
	0 OPEN-SECTOR $170 16 SD DUMPL
	;


{
MS FORMULA
RootDirSectors = ((BPB_RootEntCnt * 32) + (BPB_BytsPerSec – 1)) / BPB_BytsPerSec;
TmpVal1 = DskSize – (BPB_ResvdSecCnt + RootDirSectors);
TmpVal2 = (256 * BPB_SecPerClus) + BPB_NumFATs;
TmpVal2 = TmpVal2 / 2;
FATSz = (TMPVal1 + (TmpVal2 – 1)) / TmpVal2;
    BPB_FATSz16 = 0;
    BPB_FATSz32 = FATSz;
}

--- assign cluster size for format ---  limit 512..64k    power of 2 scaled
pri CLSZ ( bytes -- )
	DUP 0= IF DROP FATSZ 10 >> THEN
	512 MAX 64KB MIN >| |< 9>>  >!
pri #s/c
	64
	;

{
000_2001 SECTOR
0001_0000: 52 52 61 41  00 00 00 00  00 00 00 00  00 00 00 00     'RRaA............'

0001_01E0: 00 00 00 00  72 72 41 61  1D BA 0E 00  02 00 00 00     '....rrAa........'
0001_01F0: 00 00 00 00  00 00 00 00  00 00 00 00  00 00 55 AA     '..............U.'

Offset 	Description 	Size
00h 	First Signature (52h 52h 61h41h) 	1 Double Word
04h 	Unknown, Currently (Mightjust be Null) 	480 Bytes
1E4h 	Signature of FSInfo Sector(72h 72h 41h 61h) 	1 Double Word
1E8h 	Number of Free Clusters (Setto -1 if Unknown) 	1 Double Word
1ECh 	Cluster Number of Clusterthat was Most Recently Allocated. 	1 Double Word
1F0h 	Reserved 	12 Bytes
1FCh 	Unknown or Null 	2 Bytes
1FEh 	Boot Record Signature (55hAAh) 	2 Bytes
}
pri !FSINFO
	!SDBUF
	" RRaA" SDBUF $!
	" rrAa" $1E4 SDBUF+ $!
	-1 $1E8 SDBUF+ !
	2 $1EC SDBUF+ !
	$AA55 $1FE SDBUF+ W!
---	update file information sector
	SDBUF @BOOT 1+ SDWR
	;

pri !FATX
	!SDBUF
	$0FFF_FFF8 DUP 0 SDBUF+ ! 8 SDBUF+ !
	$0FFF_FFFF 4 SDBUF+ !
	RW s/f @ ADO SDBUF I SDWR !SDBUF SPINNER LOOP
	;

pub !FATS
	fat1 @ !FATX
	fat2 @ !FATX
	;

pub !FAT
	fat32 fatsz ERASE
---	jump code (redundant?)
	$905BEB fat32 !
---	name of formatting system
	" TAQOZ P2" oemname $!
	512 b/s W!
	#s/c 0= IF 0 CLSZ THEN #s/c s/c C!
---	RESERVED ???
\	#s/c 8 + rsvd W!	( should this be set to a constant 32? )
	32 rsvd W!
	2 fats C!
	$F8 media C!
	@BOOT hidden !

---	sectors/track
\	#s/c media 3 + W!
	$3F media 3 + W!
---	number of heads
\	#s/c 2* media 5 + W!
	$FF media 5 + W!
---	sectors/partition = sectors/sd - hidden
	FATSZ DUP s/p !

---	calculate sectors/fat +  fudge

	sdsize @ @BOOT - #s/c >| 7 + >> ( #s/c 2/ +  )    s/f !
\	#s/c >| 7 + >>          #s/c 2/ +     s/f !
	0 fat? !		--- clear fat flags and fatver (4 bytes)
	2 rootcl !
	1 rootcl 4+ W!		--- partition info sector
	6 bbsect W!		--- backup boot sector
	128 ldn W!		--- logical drive#
	$29 extsig C!
	RND serial !
---	 Volumne name FAT name
	" P2 CARD    FAT32   " volname 19 CMOVE
---
	@BOOT rsvd W@ + DUP fat1 !  s/f @ + fat2 !
---	update buffer with our copy of FAT
	!SDBUF fat32 SDBUF 96 CMOVE
	$AA55 $1FE SDBUF+ W!
---	write FAT32 boot sector
	SDBUF @BOOT SDWR
---	write backup boot sector
	SDBUF @BOOT 6 + SDWR
---	then info sector
	!FSINFO
---	and init and zero all the FAT entries (takes a while)
	!FATS
	;

pri .res	" res" .LINE  ;
pri .PS		SWAP .LINE rootcl + W@ DUP .W ."  = " @BOOT + .L ;

{
	byte	fats		--- 02
2	res	Maximum Root DirectoryEntries (non-FAT32)
2	res	Number of Sectors inPartition Smaller than 32MB (non-FAT32)
	byte	media		--- F8 hard disk
2	res	Sectors Per FAT in Older FATSystems (N/A for FAT32)
2	res	Sectors Per Track --- 3F 00
2	res	Number of Heads	--- FF 00
	long	hidden	Number of Hidden Sectors inPartition --- 00 20 00 00
}


pub .FAT --- print FAT32 BOOT RECORD
	parts 4 + C@ ?FS 0= " FORMAT" ?ERROR
	  " FAT32" .TITLE
	  " OEM" .LINE oemname 8 CTYPE
	  " Byte/Sect" .LINE b/s W@ DUP PRINT
	  " Sect/Clust" .LINE s/c C@ DUP PRINT ."  = " * .KB
\	  .res s/c 1+ 2 .BYTES
	  " FATs" .LINE fats C@ PRINT
\	  .res fats 1+ 4 .BYTES
	  " Media" .LINE media C@ .BYTE
\	  .res media 1+ 2 .BYTES
	  " Sect/Track" .LINE media 3 + W@ .W
	  " Heads" .LINE media 5 + W@ .W
	  " Hidden Sectors" .LINE hidden .MBS
	  " Sect/Part" .LINE s/p .MBS
	  " Sect/FAT" .LINE s/f .MBS
	  " Flags"  .LINE 8 fat? SET? IF ." Mirroring to" THEN fat? C@ >N PRINT
	  " Ver" .LINE fat? 2+ 2 .BYTES
	  " ROOT Cluster" .LINE rootcl @ .L ."  SECTOR: " rootdir @ .L
	  " INFO Sector"  4 .PS
	  " Backup Sector"  6 .PS
	  .res rootcl 8 + 12 .BYTES
	  " Drive#"  .LINE ldn C@ PRINT --- Should be 0 or 128
	  " Ext sig" .LINE extsig C@ DUP .B $29 = .OK
	  " Part Serial#" .LINE serial @ DUP .L ."  #" U.
	  " Volume Name" .LINE volname 19 CTYPE
	\  " FAT Name" .LINE  volname 11 + 8 CTYPE
	;
{
                  *** FAT32 ***
    OEM............................. mkfs.fat
    Byte/Sect....................... 512
    Sect/Clust...................... 8 = 4kB
    FATs............................ 2
    MEDIA........................... F8
    Sect/Track...................... $003E
    Heads........................... $007A
    Hidden Sectors.................. 8192
    Sect/Part....................... 7,736,320 = 3,960MB
    Sect/FAT........................ 7,544
    FLAGS........................... 0
    VERSION......................... 00 00
    ROOT Cluster.................... $0000_0002 SECTOR: $0000_5B10
    INFO Sector..................... $0001 = $0000_2001
    BACKUP Sector................... $0006 = $0000_2006
    res............................. 00 00 00 00 00 00 00 00 00 00 00 00
    Drive#.......................... 384
    Ext sig......................... $29 OK!
    Part Serial#.................... $7806_E39C 2013717404
    Volume Name..................... TEST
    FAT Name........................ FAT32    ok
TAQOZ#
}

pub .USED
	" USED" .LINE usedcl @ s/c C@ * .MB  ."  of " freecl @ s/c C@ * .MB ."  = "
pub .USED%
	used% @ .AS" ##~#.##% "
	;


pub .DISK	.SD  .MBR .FAT .USED ;

--- erase root directory cluster
pub !ROOT
	!SDBUF RW
---	populate with a single volume entry
	" ROOTDIR    " SDBUF $! 8 11 SDBUF+ C!
	@ROOT s/c C@ ADO SDBUF I SDWR !SDBUF LOOP
	;


pub FORMAT \ ( cluster-size -- )
\	DEPTH IF 0 MAX 64KB MIN ELSE 0 THEN
	!SD
	IF
	  !MBR
\	  DUP 0= IF DROP FATSZ 10 >> THEN CLSZ
	  !FAT
	  GETFAT
 	  !ROOT
	  MOUNT .DISK
 	ELSE
	  ."  FAILED!"
	THEN
	0 CLSZ
	;




{
RAW BOOT SECTOR INFO
MBR:
$17C	= "ProP"
$174	= SECTOR
$178	= BYTES

RW " ProP"  @ $17C SD! 1 $174 SD! 65536 $178 SD! FLUSH

}

pri BIX		" _BOOT_P2.BIX" ;

pre BACKUP ( backup to filename or FLASH )
	GET$
pub BACKUP$ ( " MBR" BACKUP$ )
	DUP UPPER$
\	SPACE NFA' END 8 + $1.0000 OVER - ERASE
	DUP " FLASH" $=
	  IF DROP SFJID 1+ IF SFBU THEN SFJID 1+ .SUCCESS BREAK
	MOUNTED?
	IF
	DUP " BIX" $= IF DROP BIX THEN
	DUP " MBR" $=
---	    Create MBR signature and          point to sector 1 as 64k file       then open sector 1
	  IF ( backup to MBR )
	    DROP 0 OPEN-SECTOR RWS " ProP"  @ $17C SD!
	    1 $174 SD! 64KB $178 SD!
---	    Use sector 1 in the hidden partition for the file
	    FLUSH 1 OPEN-SECTOR
---	    else open the specified filename
	  ELSE FOPEN$
	  THEN
	@FILE
	  IF ( backup to file - including hidden file )
	    0 @FILE 64KB RW SDWRS
\	    $100 $300 ADO 0 I SD! 4 +LOOP 1 FLUSH
	    RO SDWR? .SUCCESS
	  BREAK
	THEN
	0 .SUCCESS
	;

pub BU	" MBR" BACKUP$ ;



mntd ~

pub MAIN	' ?MOUNT keypoll W! ;
\ AUTO MAIN


END
DEPTH 3 <> IF ."  STACK ERRORS " .S THEN !SP




