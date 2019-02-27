TAQOZ

\ xxxxxx - wip

( ADAPT P1 VERSION FOR P2 )
pub EASYFILE    ." SDHC card + FAT32 Virtual Memory File System V1.2 171024-0000 " ;
\ PUBLIC

BUFFER		:= BUFFERS
BUFFER		:= SDBUFS
$10000		org

DECIMAL
\ PUBLIC
512		:= BLKSIZ   --- BLKSIZ is used because it is smaller & faster than a literal #512 - it is really constant
4		:= #files

\ PRIVATE
--- SD Tokens
$FE             := =dtk            --- data token for single block read/write
--- $FC         := =dtk1            --- data token for 1st block read/write
--- $FD         := =dtke            --- data token for last block read/write

( SD CARD REGISTERS )

\ 4 ALIGNORG
\ PUBLIC
\ 0		bytes sdinfo
16		bytes cid		--- Card ID
16		bytes csd		--- Card Specific Data
4		bytes ocr		--- Operating conditions register

\ PRIVATE
1		longs @sdwr
1		longs @sdrd

#files		longs @sectors		--- Current sector loaded in SDBUFs for the 4 files possible

#files		longs scrcs		--- Sector CRCs

		byte fsel		--- currently selected file 0..3

\ PRIVATE
		byte crc
		byte _card		--- card detect transition memory

#files		bytes wrflgs            --- byte flag for each channel to indicate current sector buffer has been written to


		TIMER sdtimer

\ PUBLIC
		clong _sdpins		--- lock SD pins in code memory

\ PRIVATE

--- create a pointer to where the cs pin is stored
_sdpins 3 +	:= cspin


--- indirect variables
pri *SDCS		cspin C@ ;

( programmable constants )

--- points to "sectors"
pri @sector		@sectors ;

pri wrflg ( -- adr )	wrflgs ;

--- initial value for SDBUF which depends upon which file handle is selected
pub sdbuf		BUFFERS ;

--- psuedo constant address of sd crc
pri scrc		scrcs ;


--- Detect SD card presence - the CS line must not have a pullup on it (redundant and undesirable).
--- pulse low, float, check, return high

pub CARD? ( -- flg )		*SDCS LOW *SDCS FLOAT 10 us *SDCS PIN@ *SDCS HIGH ;





--- Made SDIO RUNMOD handle 32-bit with normal entry and 8-bit with entry+2 including ROL
ALIAS RUNMOD SDIO8

NFA' SDIO8 CPA 2 SWAP W+! ( SDIO8 entry offset by 2)

ALIAS RUNMOD SDIO32



--- Fetch a byte from the SD card (clock in 1's) (5.5us) (RUNMOD 2.83us)
pri SD@ ( -- 8b )		-1 SDIO8 >B ;

--- Faster byte wide clocks (8/count)
pri SDCLK ( cnt -- )		FOR SD@ DROP NEXT ;

--- do what needs to be done if the SD card is busy (LED etc) - can be rewritten
pub SDBUSY ( state -- )		DROP ;
pub SDERR ( state -- )		DROP ;

--- set pins, save them for reboot and init with !SDIO see high level !SD
pub SDPINS ( ce-miso-mosi-clk --  )
	--- remember which pins were used for BACKUP
	DUP _sdpins ! _sdpins E!
--- Initialize the SD I/O and basic card
pri !SDIO
	--- init SD pins & select SDIO (14.3us)
	_sdpins @ ?DUP 0EXIT MODPINS [SDIO]
	--- select the card and Set MOSI high
	*SDCS LOW  @MOSI COG@ OUTSET
	--- clock low (and as an output)
	@SCK COG@ DUP OUTCLR
	100 FOR DUP OUTSET DUP OUTCLR NEXT DROP
	*SDCS HIGH
	--- 16 byte-wide clocking cycles
	16 SDCLK *SDCS LOW 16 SDCLK *SDCS HIGH
	--- setup CTRB for fast clock
	_sdpins C@ $1000.0000 + CTRB COG!
	;


( SD CARD RESPONSES )

pri RES@ ( -- res )
	2000 BEGIN -1 SDIO8 OVER 0<> OVER >B $FF = AND
	WHILE DROP 1- REPEAT NIP >B
	;
--- Issue a command to the SD card
--- Send the command to the SD card and read result - 108us
pub CMD    ( data cmd -- res )
	( 9.5us)
	[SDIO] _sdpins C@ LOW
	--- extra clocks (5.5us) --- Select the card
	-1 SDIO8 DROP *SDCS LOW
	--- send as a command & 32-bit transfer
	$40 OR SDIO8 DROP SDIO32 DROP
	--- dummy checksum ( is valid for initializing) --- fetch the response
	crc C@ SDIO8 DROP RES@
	;

--- Send an ACMD to the card and return with response
pub ACMD ( data acmd -- res )		0 #55 CMD DROP CMD ;

pri STAT@ ( -- stat )			0 #13 CMD RES@ 8<< OR ;

IFDEF EF+
pub SDERR? ( -- flg ; return SD bit flag errors)
	0 CARD? 0= 1 AND OR			--- b0 = card detect error
	@sdrd @ 0= 2 AND OR			--- b1 = read failure
	@sdwr @ 0= 4 AND OR			--- b2 = write failure
	ocr @ 0= 8 AND OR			--- b3 = card error
	;
}



--- In SPI Mode, only the OCR, CSD and CID registers are accessible.
pri ?SDTO
	sdtimer TIMEOUT? IF FALSE R> DROP EXIT THEN
	;

--- Find SD marker and return true before timeout
pri MARKER? ( marker -- flg  )
	2000 BEGIN OVER SD@ <> WHILE 1- DUP 0= IF NIP EXIT THEN REPEAT
	2DROP TRUE
	;

--- Wait for read token and read SD data into buffer
pri SDDAT! ( adr --  )
	=dtk MARKER? IF FROM 16 FOR SD@ I C! NEXT 3 SDCLK ELSE DROP THEN
	;

pri RDOCR ( -- ocr )
	-1 SDIO32 DUP ocr !
        IF
	  0 #10 CMD 0= IF cid SDDAT! THEN
          0 9 CMD 0= IF csd SDDAT! THEN
	THEN
	;


pri !sect		@sectors 16 $FF FILL ;

--- Initialise the SD card (with timeout)
pri _!SD ( -- ocr|false )
	ON SDERR _sdpins @ DUP 0EXIT DROP
	ON SDBUSY OFF SDERR
	--- init cid csd ocr & force an invalid sector (nothing cached)
	cid 36 ERASE !sect
	!SDIO CARD?
	IF
	---   overall timeout
	  1,000 sdtimer TIMEOUT
	  $95 crc C! BEGIN ?SDTO 0 0 CMD 1 = UNTIL
	  $87 crc C! BEGIN ?SDTO $1AA 8 CMD 1 = UNTIL
	  -1 SDIO32 $1AA =
	  IF
            BEGIN ?SDTO $40000000 #41 ACMD 0= UNTIL
            BEGIN ?SDTO 0 #58 CMD 0= UNTIL
          RDOCR
	  THEN
	THEN
	ocr @
	;

pub !SD			_!SD *SDCS HIGH	DUP 0= SDERR OFF SDBUSY ;


{ *** BLOCK BUFFERS *** }


--- Write from src to xdst in the SD
pub SDWR    ( src sect -- flg )
	ON SDBUSY
	--- finish off previous & prep
	*SDCS HIGH 1 SDCLK *SDCS LOW 3 SDCLK
	--- write block command
	#24 CMD 0= ( src res )
	IF
          3 SDCLK =dtk SDIO8 DROP
	  --- Write sector
          BLKSIZ [SDWR] RUNMOD
          [SDIO] 0 MARKER? $FF MARKER? AND
        ELSE
	  FALSE
	THEN
	*SDCS HIGH OFF SDBUSY
	DUP @sdwr ! [SDIO]
	;

--- write the current sector back to the storage media
pub WRSECT		sdbuf @sector @ SDWR DROP ;

--- Write the sector buffer if it has been modified
pub FLUSH		wrflg C@ 0EXIT WRSECT wrflg C~ ;

\ PRIVATE
	byte scanch
\	byte scan
	word scancnt
	word scanpos

--- set scan char or disable with -1
pub SCAN! ( ch/flg -- )
	scanch W!
        scancnt W~ \ for each round set to 0
        scanpos W~  ( xaddr cnt )
	;


pri RDSECT    ( dst -- crcflg )
	--- card has been prep'd for read  - proceed and read a block of data
---	MOSI high
	2 COG@ OUTSET  scanch 1+ C@
	IF --- use raw & fast method (no scan)
	  [SDRDF] BLKSIZ RUNMOD
	ELSE --- use slower scan method
	  [SDRD] ( dst eof  --  firstPos charcnt )
	  scanch C@ RUNMOD scancnt W+!
	  scanpos W@ 0= IF scanpos W! ELSE DROP THEN
	THEN
	\ scan C~~
	--- switch back to standard SPI mode (for commands etc)
	[SDIO] -1 SDIO8 SDIO8 $FFFF AND DUP 0= IF 31 MASK OR THEN
	;


pub SECTOR ( sect -- buffer ) ( 11.8us min )
     --- skip if sector has already been buffered (4us)
     DUP @sector @ = IF DROP sdbuf EXIT THEN
     --- update sector pointer for this file channel (3us)
     FLUSH DUP @sector !
     --- read sector into buffer
     sdbuf

--- Read sector from SD into dst
\ pub SDRD    ( sector dst -- )
	--- read block command (132us)
	ON SDBUSY SWAP #17 CMD
	IF --- didn't like that command - discard dst & return false
	  ( dst ) DROP FALSE
        ELSE --- process read token and read block
	( 53us  575us)
          RES@ =dtk =
	  IF
	    RDSECT
	  ELSE --- drop token and dst - discard cycles
            2DROP 2 SDCLK STAT@ DROP FALSE
	  THEN
	THEN
	--- release the SD card
	*SDCS HIGH OFF SDBUSY
	---  save crc/flg
	DUP @sdrd ! scrc !
	sdbuf
	;










--- DIR BUFFERS ---

--- A copy of the original virtual address of the directory entry is kept in this array (4 entries)


#files		longs diradrs			--- virtual memory address of file's directory entry
#files		longs _file			--- table entry for 4 open files - holds sector address
#files 32 *	bytes dirbufs			--- create a directory buffer for the opened file

		long fboot                      --- boot signature - determines whether it needs to remount





--- set the active file channel (0 ..3) (28us)
pub FILE ( index:0..3 -- )
	#files 1- AND DUP fsel C!
	wrflgs OVER+ ' wrflg WW!
	DUP 4* @sectors + ' @sector WW!
	DUP 4* scrcs + ' scrc WW!
	--- set SDBUF constant for faster operation
	9 << BUFFERS + ' sdbuf WW!
	;

--- return the current file channel
pub FILE# ( -- file# )			fsel C@ #files 1- AND ;

{ HELP @FILE ( addr -- addr+off )
returns the address offset into sector & sectcrc tables for active file channel
as set with    index FILE
e.g. val sector @FILE ! otherval sectcrc @FILE ! sector @FILE @
}
pub @FILE ( addr -- addr+off )		FILE# 4* +  ;


pub dirfsa				diradrs @FILE ;

--- return with the address of the directory buffer  in RAM
pub dirbuf				FILE# 5 << dirbufs + ;


--- DIRECTORY STRUCTURE ---

\ #00    := @FNAME		--- File name
\ #08    := @FEXT		--- File extension
#11    := @ATR			--- Attribute
\ #13    := @CMS         	--- creation millisecond (2ms)
#14    := @CTIME        	--- creation time
#16    := @CDATE		--- creation date
\ #18    := @ADATE		--- access data
#20    := @FCLSTH		--- First cluster (high word)
#22    := @FTIME		--- modification time
#24    := @FDATE		--- modification date
#26    := @FCLST		--- First cluster of file (low word)

#28    := @FSIZE		--- size of file


pub FSIZE			dirbuf @FSIZE + ;

pub FSIZE@			FSIZE @ ;

pub FSECT@ ( -- sect )		_file @FILE @ ;



(		*** VIRTUAL MEMORY ***			)

--- The X methods address the first 4GB of the SD card as virtual memory

--- Same as XADR but indicate a write operation for later flushing
pri XADR! ( xaddr -- addr )		1 wrflg C!
--- translate absolute 4GB SD memory address to a buffered address in hub RAM
pub XADR ( xaddr -- addr )		SPLIT9 SECTOR + ;

--- read a long from virtual memory address xaddr
pub X@ ( xaddr -- long )		XADR @ ;
--- write a long to virtual memory address xaddr
pub X! ( long xaddr -- )                XADR! ! ;
--- read a byte from virtual memory address xaddr - 18us min
pub XC@ ( xaddr -- byte )               XADR C@ ;
--- write a byte to virtual memory address xaddr
pub XC! ( byte xaddr -- )               XADR! C! ;
--- read a byte from virtual memory address xaddr
pub XW@ ( xaddr -- word )               XADR W@ ;

--- DUMP MEMORY ACCESS METHOD MODIFIER
--- Usage: 0 $200 SD DUMP
pub SD	         			DUMP: XC@ XW@ X@ ;

--- VIRTUAL FILE ACCESS ---
{ A 32-bit address can access any location of a file up to 4GB.


}

pri FSADR! ( faddr -- addr )     	1 wrflg C!
pub FSADR ( faddr -- addr )		SPLIT9 FSECT@ + SECTOR + ;

--- common FS store routines
pri ~!					FSECT@ IF 0 MAX FSIZE@ MIN FSADR! ELSE R> 3DROP THEN ;

pub FSC! ( byte faddr -- )		~! C! ;

pub FS! ( long faddr -- )		~! ! ;

--- 25.333us @96MHz  (26.5us)
pub FSC@ ( faddr --- byte )		FSADR C@ ;

pub FSW@				FSADR W@ ;

pub FS@					FSADR @ ;

pub FS					DUMP: FSC@ FSW@ FS@ ;



--- PARTITION TABLE ---

--- Partition table image - copied here

64 bytes parts			--- Room for 4 entries of 16 bytes

parts 8 +	:= fatptr
{
--- These are the offset constants compiled as absolute addresses (for 1st partition)
--- Many names have not been added to the dictionary to save space
@org W@
parts    org
1    DS+ --- state		--- 00 = inactive, $80 = active
1    DS+ --- head		--- beginning of paritiion
2    DS+ --- cylsec		--- beginning of partition cylinders/sector
1    DS+ --- partype		--- type of partition
1    DS+ --- ehead		--- end of partition head
2    DS+ --- ecylsec		--- end of partitiion cylinder/sector
4    DS fatptr			--- Number of Sectors Betweenthe MBR and the First Sector in the Partition
4    DS+ --- size		--- number of sectors in partition /2 =
	org
}
--- BOOT RECORD ---

{
Boot Record
The boot record occupies one sector, and is always placed in logical sector number zero of the "partition".
If the media is not divided into partitions, then this is the beginning of the media.
This is the easiest sector on the partition for the computer to locate when it is loaded.
If the storage media is partitioned (such as a hard disk), then the beginning of the actual media contains an MBR (x86)
 or other form of partition information.
In this case each partition's first sector holds a Volume Boot Record.
}

{
7A2D lscnt       7A2C eof        0000 >|RCDSZ    0001 RCDSZ      7A28 mksiz      7A26 fkey
7A24 fstat       7A14 fwrites    7A04 freads     79F4 fname$     79B4 _file$     79A4 cwd$
79A0 cwdsect     799C fat2       7998 fat1       7994 rootdir    7993 clshift    7992 mounted
798A fatname     797F volname    797B serial     7964 rootcl     795C sect/fat   7958 sdsize
7948 fats        7946 rsvd       7945 sect/clust 7943 byte/sect  793B oemname    7938 fat32
7900 fatptr      78F8 parts      001C @FSIZE     001A @FCLST     0018 @FDATE     0016 @FTIME
0014 @FCLSTH     0010 @CDATE     000E @CTIME     000B @ATR       78F4 fboot      76F4 dirbufs
76E4 _file       76D4 diradrs    76D0 scanpos    76CE scancnt    76CD scan       76CC scanch
3C63 cspin       3C60 _sdpins    76BC sdtimer    76B7 wrflgs     76B6 _card      76B5 crc
76B4 fsel        76A4 scrcs      7694 @sectors   7690 @sdrd      768C @sdwr      7688 ocr
7678 csd         7668 cid        7668 sdinfo     00FE =dtk       0004 #files     0200 BLKSIZ
}



24 longs fat32 ( 90/96 used )
@org W@
fat32    org
3    DS+
8    DS oemname
2    DS byte/sect
1    DS sect/clust
2    DS rsvd
( 16 )
1    DS fats			--- Copies of FAT
4    DS+			--- root entry count (FAT16)
1    DS+			--- media
2    DS+
2    DS+			--- sect/trk
2    DS+			--- heads
4    DS+			--- hidden sectors
( 32 )
4    DS sdsize			--- Number of sectors * byte/sect (512) = capacity
--- offset = 36
4    DS sect/fat		--- Number of sectors per FAT table
2    DS+			--- fatflags
2    DS+			--- fatver
4    DS rootcl			--- Cluster Number of the Start of the Root Directory
2    DS+			--- info = Sector Number of the FileSystem Information Sector  (from part start)
2    DS+			--- boot = Sector Number of the Backup Boot Sector (from part start)
#12  DS+
--- offset 64
3    DS+
4    DS serial			--- #67 serial number of partition
11   DS volname			--- #71 volume name
8    DS fatname			--- always FAT32 - (don't trust)

--- create room for some system variables in this table
1    DS mounted			--- true flag if mounted (but also depends upon other checks)
1    DS clshift			--- cluster shift (fast  multiplier)
4    DS rootdir			--- sector address of root directory

	org




--- FAT HANDLERS ---

--- start sector of the root directory )
pub @ROOT ( -- rootdirsect )		rootdir @ ;

pub @BOOT ( -- bootsect )		fatptr @ ;



--- return with the starting address of the selected FAT (normally 0 or 1)
pub @FAT ( fat# -- sector )
    sect/fat @ *
    @BOOT rsvd W@ +  +
    ;


--- convert a cluster number to a physical start sector (normally 64 sectors/cluster)
pub CLUST>SECT ( clust# -- sector )	rootcl @ - clshift C@ << @ROOT + ;

pri cid+	cid + ;
pri .CARD
	3 cid+ 5 CTYPE SPACE
	1 cid+ 2 CTYPE
	cid C@ .BYTE ." ."
	8 cid+ C@ .BYTE ."  #"
	9 cid+ U@ .LONG SPACE
	13 cid+ C@ 8 << 14 cid+ C@ OR
	DUP 4 >> 2000 + PRINT ." /" >N PRINT
	."  !" ocr @ .LONG SPACE
	CNT@ 8192 BY 64 FOR I SECTOR DROP NEXT CNT@ SWAP - ABS CLKMHZ / 6 >> .AS" ##,~###us"
	;

long fat1
long fat2

pri READFAT32
	--- Read and buffer the FAT32 boot record
	@BOOT SECTOR fat32 90 CMOVE
	--- make a fast multiply using a shift left constant
	sect/clust C@ >| clshift C!
	rsvd W@ sect/fat @ fats C@ *
	rootcl @ 2- clshift C@ << + + @BOOT + rootdir !
	--- save time by precalculating FAT table addresses
	0 @FAT fat1 !  1 @FAT fat2 !
\	;


--- Mounted 7401.170D-3437.3130          NO NAME     FAT32   7,944MB (32,768/cluster)
{
Manufacturer ID	MID	manfid	Assigned by SD-3C, LLC.
OEM/Application ID	OID	oemid	Identifies the card OEM and/or the card contents. Assigned by SD-3C, LLC.
Product Name	PNM	name	5 characters long (ASCII)
Product Revision	PRV	hwrev, fwrev	Two binary coded decimal (BCD) digits. Each is four bits. The PRV is in the form x.y. The PRV can also be found by using the hwrev and fwrev, where x=hwrev and y=fwrev
Serial Number	PSN	serial	This 32 bit field is intended to be read as an unsigned integer
Manufacture Date Code	MDT	date	Manufacture date is stored in the form yym (offset from 2000)
CRC7 checksum	CRC		7 bit code used for checking errors in the card register
}

pri .FAT
	CR ." CARD: " .CARD
	CR ." FAT: #"
 	--- print SD card serial#
\	cid 9 + U@ .LONG
\	." -"
	serial U@ .LONG
	SPACE oemname 8 CTYPE
	SPACE volname 11 CTYPE
	SPACE fatname 8 CTYPE
	sdsize @ 512 UM* <D> .DECL ."  bytes ("
	sect/clust C@ 2/ PRINT ." kB clusters)"
	CR
	;


pub FMAX@			FSIZE@ sect/clust C@ 9 << ALIGN ;


long cwdsect
16 bytes cwd$

pub ROOT			@ROOT " /"
pri cd! ( sect str -- )		cwd$ $! cwdsect ! ;



{ HELP: MOUNT
Mount the currently selected storage device and init all 4 file handles
Read the FAT32 and set variables accordingly
}
pub MOUNT
	mounted C~
	wrflgs #files ERASE
	--- invalidate sectors and clear bufs
	!sect diradrs 160 ERASE
	3 FILE sdbuf BLKSIZ ERASE
	--- Init SD card - turn on error LED - only cleared if FAT passes muster
	!SD ON SDERR
	IF
	  mounted C~~
	  --- read partition info and check partition signature
	  0 SECTOR $01FE + W@ $AA55 =
	  IF
	    --- buffer patitions
            $01BE sdbuf + parts $40 CMOVE
	    --- read the FAT32 sector
	    READFAT32 \ .FAT
            ROOT
	    --- clear error indication - copy boot signature to validate mount status
            OFF SDERR  boot @ fboot !
         ELSE
           ."  *Format Error* "
         THEN
	ELSE
         ." *Card Error* "
	THEN
	;

pub ?MOUNT
	_card C@ 0= CARD? DUP _card C! AND
	boot @ fboot @ <> mounted C@ 0= OR
	OR IF MOUNT THEN
	CARD? NOT
	IF
          ."  *No Card inserted!* "
          ON SDERR MOUNT
	THEN
\	boot @ fboot @ <> mounted C@ 0= OR IF MOUNT THEN
	;


{ HELP ?SDCARD
Make sure the card is inserted or mount it if it has just been inserted
}
{
pub ?SDCARD
	--- check previous card state with now and update
	_card C@ 0= CARD? DUP _card C! AND
	--- just inserted so mount automatically
	  IF MOUNT THEN
	--- indicate an error if it's not inserted
	CARD? NOT IF ON SDERR mounted C~ THEN
	;
}



--- FILE NAME HANDLERS ---

16 #files *	bytes _file$
16		bytes fname$


\ " FILENAME.TXT" 16 4 * STRING file$			--- The actual name of the file requested
--- file$ stores 4 8.3 filenames at 16 byte boundaries

pub FILE$  ( -- addrOfFilenameString )    FILE# 4* 4* _file$ + ;


--- format friendly file name into directory format
--- FILE.TXT --> FILE    TXT
pri >F83 ( str1 -- str2 )
	--- prep fname$ as all blanks
	fname$ #11 32 FILL
	--- ensure terminator is set
	fname$ #11 + C~
	fname$ ( str1 fname$ )
	OVER C@ $2E = IF OVER LEN$ CMOVE fname$ EXIT  THEN
	--- located the extension?
	'.' 3RD LOCATE$ ( str1 fname$ str1ext )
	?DUP IF --- found an ext
	( str1 fname$ name8len )
	--- copy across the filename part
	  DUP >R 3RD - CMOVE
	  --- get the extension & len
	  R> 1+ DUP LEN$
	  --- only move LEN$ chars  MJB so .JS becomes .JS(sp)
	  fname$ 8 + SWAP
	ELSE --- no ext found, just copy the string
	  OVER LEN$
	THEN
	CMOVE fname$
	;







--- make the current working directory accessible as a file itself
pub OpenDir		cwdsect @ _file @FILE ! ;

--- update current directory entry from buffer
pub UpdateDir
	OpenDir
	--- copy that to the virtual address
	dirbuf dirfsa @ FSADR 32 CMOVE
	--- Force an update
	WRSECT
	;


pub FSIZE!			FSIZE ! UpdateDir ;

--- Find the name in the current directory and return with (virtual memory address)  XXXXthe dir buffer address
pub DIR?    ( str -- diraddr | FALSE )
	?MOUNT
	mounted C@
	IF
	  --- get virtual address of current working directory
	  OpenDir
	  0
	  BEGIN
	    BEGIN ( str dirptr )
	      DUP FSC@
	    WHILE
	      DUP FSADR 3RD ( str dirptr xadr str )
	    --- compare 8.3 strings using the xadr as a flag
	      FROM 11 FOR C@++ I C@ <> IF DROP FALSE LEAVE THEN NEXT
	        IF NIP EXIT THEN
	    --- skip to next dir entry (32 bytes)
              32 +
	    REPEAT
	    32 + DUP $7FFF >	--- has directory cluster been exhausted?
	  UNTIL
	  --- failed to find it - discard parameters
          2DROP
	ELSE
          DROP
	THEN
	--- failed
	FALSE
	;

--- DIRECTORY ENTRY HANDLERS ---

{

--- DIRECTORY STRUCTURE ---

\ #00    := @FNAME		--- File name
\ #08    := @FEXT		--- File extension
#11    := @ATR			--- Attribute
\ #13    := @CMS         	--- creation millisecond (2ms)
#14    := @CTIME        	--- creation time
#16    := @CDATE		--- creation date
\ #18    := @ADATE		--- access data
#20    := @FCLSTH		--- First cluster (high word)
#22    := @FTIME		--- modification time
#24    := @FDATE		--- modification date
#26    := @FCLST		--- First cluster of file (low word)

#28    := @FSIZE		--- size of file


TACHYON .ROM    .....a 0000.5040 5536  m20170718 16:43  c20170718 16:43.000  a20170718

             --------NAME------------  ---EXT-- ATR  ? CMS CTIME
0000.7E20:   54 41 43 48  59 4F 4E 20  52 4F 4D 20  00 00 6D 85    TACHYON ROM ..m.
	     CDATE ADATE  CLUSTH FTIME FDATE CLUSTL ----SIZE---
0000.7E30:   F2 4A F2 4A  00 00 6D 85  F2 4A 43 00  00 00 01 00    .J.J..m..JC.....

}


--- update file modification/create date in dir buf
--- Date (7/4/5 bits, for year-since-1980/month/day)
pri FDATE! ( #yymmdd field -- )
	--- arrange as decimal YYMMDD from 1980 ( 2000.0000 + 1980.0000 - )
	SWAP 200000 +
	HMS 9 << SWAP 5 << + +
	SWAP
pri @DIRBUF! ( word field -- )
	--- write to directory entry as new date
	dirbuf + W!
	;

--- update file modification/create time in dir buf
--- Time (5/6/5 bits, for hour/minutes/doubleseconds)
pri FTIME! ( #hhmmss field -- )
	SWAP HMS 11 << SWAP 5 << + SWAP 2/ +
	SWAP @DIRBUF!
	;


--- DATE TIME STAMPING ---

--- Update the modified time and date of the current file
pub FSTAMP ( -- )
	TIME@ @FTIME FTIME!
	DATE@ @FDATE FDATE!
	;




\ IFNDEF .ASMONTH
pri .ASMONTH ( index -- )
     >N 1- 3 * " JanFebMarAprMayJunJulAugSepOctNovDec " + 3 CTYPE
     ;
}



--- CLUSTER HANDLERS ---

{
--- display cluster usage from FAT
pub .FATMAP
     0 sect/fat 1 DOFOR
       I $3F AND 0= IF CR I .LONG ." : " THEN
       I 0 @FAT + SECTOR
       0 sdbuf 128 4 DOFOR I @ + LOOP
       IF ." *" ELSE ." ." THEN
       KEY $1B = IF LEAVE THEN
     LOOP
     ;

}

--- Find the next free directory entry and also set dirfsa
pri FreeDir? ( -- fsadr )
     OpenDir
     --- start - for max directory entries in a sector (1,024)
     0 sect/clust C@ 4 <<
     32 BY FOR I FSC@ 0= IF I OR LEAVE THEN NEXT
     DUP dirfsa !
     ;



{ CLUSTER CHAIN CODES
If value => $0FFF.FFF8 then there are no more clusters in this chain.
$0FFF.FFF7 = bad
0 = free

}
pri @CLUSTER ( index -- xadr )		4* fat1 @ 9 << + ;

pri CLUSTER@ ( index -- cluster )	@CLUSTER X@ ;

$0FFFFFFF := endcl



{ HELP FreeClusters?
Find free clusters for the file size in bytes - 0 = all
return with address of first free cluster
Here's a dump of the end of the cluster table.
0062_7820:   0000.0409  0000.040A   0000.040B  0000.040C   ................
0062_7830:   0FFF.FFFF  0000.040E   0000.040F  0000.0410   ................
0062_7840:   0FFF.FFFF  0FFF.FFFF   0000.0413  0000.0414   ................
0062_7850:   0FFF.FFFF  0000.0000   0000.0000  0000.0000   ................
0062_7860:   0000.0000  0000.0000   0000.0000  0000.0000   ................

Freshly formatted
..  0 @CLUSTER $40 SD DUMPL
0040.4000:   0FFF.FFF8     0FFF.FFFF     0FFF.FFF8     0000.0000
0040.4010:   0000.0000     0000.0000     0000.0000     0000.0000

check for fragmented clusters
$4.0000 0 DO I CLUSTER@ DUP $0FFF.FFF8 < OVER 1- I <> AND SWAP 0<> AND IF CR I .LONG THEN LOOP
}
pri FreeClusters? ( size -- size startcluster )
	--- calculate clusters required
     BLKSIZ 1- + 9 >> sect/clust C@ / ( clusters )
      0
     BEGIN
       --- find a free cluster
       BEGIN DUP CLUSTER@ WHILE 1+ REPEAT
       --- check for sufficient contiguous clusters ( clusters index )
       DUP FROM 0 3RD FOR I @CLUSTER X@ OR DUP IF NIP I SWAP LEAVE THEN NEXT
       ( clusters chain flag )
     WHILE
       1+
     REPEAT
     ;

pri ClaimClusters ( size startcluster -- )
     2DUP FROM FOR 1 I+ I @CLUSTER X! NEXT					--- link clusters
     SWAP OVER+ 1- endcl SWAP @CLUSTER X!					--- mark end cluster
     ;

--- find first cluster of this directory entry
pri FirstCluster ( diradr -- cluster )						--- get the file starting cluster for diradr
--- = virtual memory address of file's directory entry
    @FCLST OVER+ W@ SWAP @FCLSTH + W@ W>L
    ;

\ pub CLUSTERS ( start -- clusters )	DUP BEGIN CLUSTER@ DUP endcl = UNTIL SWAP CLUSTER@ - ;

--- SEQUENTIAL FILE ACCESS ---


--- maintain read and write pointers for 4 files ---
4		longs freads
4		longs fwrites

		byte fstat						--- current status of file system


pub fread ( -- readptr )	freads @FILE ;

pub fwrite ( -- writeptr )	fwrites @FILE ;

--- return with remaining bytes in file
pub FREM ( --- rem )		FSIZE@ fwrite @ - ; \ DUP IF FILE@ FSIZE@ + SWAP - THEN ;



pri FABORT ( code -- )		fstat C! R> DROP ;

--- backup0 for input device when input is switched to file
		word fkey

--- Read in the next character in the virtual buffer as part of the console input stream
pub FGET ( -- ch )
 \   FSIZE@ fread @ <=
	0
    fread @ FSC@					--- Read a single character
    DUP 0= ROT OR
	--- stop when null encountered and return to previous input device
       IF ukey W@ IF fkey W@ ukey W! THEN DROP 0 'X' FABORT THEN
       fread ++					--- update index otherwise
    ;


--- Write a character into the logical end of the file and update the write pointer
\ 280us typical
pub FPUT ( ch -- )
    ?DUP IF						--- ignore null characters (but will write nulls if another bit in long is set)
pub FPUTB ( byte -- )					--- write byte even if it is null
	--- check if file is opened and a valid write pointer is set (APPEND)
	FSECT@ fwrite @ -1 <> AND
	IF --- don't write if a file is not opened
	  fwrite @ FSIZE@ BLKSIZ ALIGN =>
	  --- Don't write to beyond end of file - fstat = O for OVERFLOW
	    IF 'O' FABORT THEN
	  --- still room in the file so just write it
	  fwrite @ FSC!
	  --- last byte in file?
	  fwrite @ FSIZE@ BLKSIZ ALIGN 1- =
	    --- Warn file is now full - fstat = F for FULL, exit now!
            IF 'F' FABORT THEN
	fwrite ++
	--- Insert a null terminator (overwritten by the next character)
	0 fwrite @ FSC!
	ELSE
	  --- no file - fstat = N
	  DROP 'N' FABORT
	THEN
	THEN
     ;



--- Redirect the console input to read the file sequentially
pub FILE>			FSECT@ IF ukey W@ fkey W! ' FGET ukey W! THEN ;


\ ALIAS FILEIN FILE>


{ HELP >FILE ( -- )
Redirect character output via uemit to the open file using "fptr" which is set to the start of the file when opened
If the file is not opened and a valid write pointer set then output will be discarded
}

pub >FILE			FSECT@ IF ' FPUT uemit W! ELSE NULLOUT THEN ;

--- Close the current file
pub FCLOSE
	--- flush and clear sector (-1)
	FLUSH @sector ~~
	--- clear file pointer
	_file @FILE ~
	--- blank out file name
	NULL$ FILE$ $!
	--- wipe dir entry
	dirbuf 32 ERASE
	;



--- size used to create a file if file not found - 0 = none
long mksiz

--- Force file open  - create to size of it not found
pub MAKE ( size -- )	mksiz ! ;

{ HELP: FCREATE$ ( size namestr -- flg )
--- Create a new file by name but if it already exists then delete the old one and reuse the dir entry.
}
pub FCREATE$ ( size namestr --  )
	DUP FILE$ $!
	--- as 8.3 and write the name of the file to the directory buffer
	>F83 dirbuf 11 CMOVE
	--- set archive attribute
	$20 dirbuf @ATR + C!
	--- stamp create date and time
	DATE@ @CDATE FDATE! TIME@ @CTIME FTIME!
	--- Set size of file to maximum & preallocate clusters
	DUP FSIZE ! FreeClusters? ( startcluster )
	--- write first cluster
	L>W @FCLSTH @DIRBUF! @FCLST @DIRBUF!
	FSTAMP
	--- add directory record to directory
	FreeDir? DUP ( xadr ) FSADR ( bufptr )
	--- write directory entry
	dirbuf SWAP 32 CMOVE WRSECT
\     ;
{ HELP FOPEN# ( dirfsa -- sector )
Open the file pointed to by the virtual directory entry address
fsa = file system address (offset into directory file)
}
pub FOPEN# ( dirfsa --- sector )
       DUP dirfsa !					--- save dirfsa
       FSADR DUP dirbuf 32 CMOVE			--- copy directory entry to local buffer
       FirstCluster CLUST>SECT
       DUP _file @FILE !					--- save address of file
       DUP 8<< 2* fread !				--- Set virtual memory FREAD address to start of file
pub RO
	fread ~  fwrite ~~
	;

{ HELP RW
Make current file read/write
}
pub RW			fwrite ~ fread ~ FMAX@ FSIZE ! ;


--- make file
pre mk ( size <name> -- )			( [C] GRAB ) DEFER FCREATE$ ;


{ HELP FOPEN$ ( namestr -- sector )
Open the file with the 8.3 name and return with its sector or 0 if failed
The variable fstat can be checked for more information if there was an error

Execution time
( 0003 $43BA  ok )   " LIFE.FTH" LAP FOPEN$ LAP .LAP
164720 cycles at 96MHz = 1.715ms

Usage: " SYSLOG.TXT" FOPEN$ IF etc etc
}
pub FOPEN$ ( namestr -- sector )
     FCLOSE DUP FILE$ $! DUP C@
     --- skip null name
     IF
       --- ignore leading / in file name
       DUP C@ '/' = IF 1+ THEN
       --- abort with ! status if name is too long
       DUP LEN$ #12 > IF DROP FALSE '!' FABORT THEN
       --- find the dir entry
       >F83 DIR? DUP
         IF FOPEN#
	 ELSE mksiz @ ?DUP IF FILE$ FCREATE$ ELSE '?' FABORT THEN
	 THEN
     ELSE
       DROP FALSE '?' FABORT
     THEN
     --- Clear mksiz to set default to not create
     mksiz ~
    ;



{ HELP FOPEN ( <name> -- )
Open a file interactively with the name specified in the input stream
Report back to the console
}
pre FOPEN ( <name> -- )
    DEFER
     FOPEN$ ?DUP
       IF ." ...opened at "  .LONG ."  for " FSIZE@ . CR
       ELSE ."  not found "
       THEN
    ;




--- Open or create a file
pub FMAKE$ ( name -- flg )
	--- create default 1MB file if it doesn't exist
	FOPEN$ NOT IF 64 MB FILE$ FCREATE$ FOPEN$ THEN
	;






--- FILE APPEND OPERATIONS ---

--- APPEND TO TEXT FILES USING AN EOF MARKER


\ #1         := RCDSZ					--- Minimum record increment, normally 1 for text files, needs to be 2^n, n>=0

\ RCDSZ >|    := >|RCDSZ

--- virtual memory address for rcd record number (for text files rcd = char pos)
\ pub @RCD    ( rcd -- xadr )	     >|RCDSZ << FILE@ +  ;

--- Erase the current file by overwriting with nulls
pub -FERASE
     FSECT@ 0EXIT
     sdbuf BLKSIZ ERASE
     FSECT@ FROM FSIZE@ BLKSIZ ALIGN 9 >> FOR sdbuf I SDWR DROP NEXT
     ;


pri APPEND.BLK ( -- relblk )
	FSECT@ FSIZE@ 9 >> OVER+ SWAP     ( max min )
	BEGIN
	  --- Find new mid point ( max min mid )
	  2DUP - 2/ OVER+
          --- flag scan method ( max min )
	  SECTOR DROP
	  2DUP - 1 >
	WHILE
	  --- if true then too high ( max min flg )
	  sdbuf C@ scanch C@ =
	    IF 2DUP - 2/ OVER+ ROT DROP SWAP
            ELSE 2DUP - 2/ OVER+ NIP
            THEN
	REPEAT
	NIP FSECT@ -
	;



{ HELP APPEND ( eof -- xptr )
Find the EOF marker (normally a null) and set the write pointer and result to this ready to append
return with null if failed.
}
pub APPEND ( eof -- fsptr )
     SCAN!
     FSECT@ DUP
     IF
       --- find the active block to use
       APPEND.BLK ( -- relblk )
       --- add in offset allowing for a full block as well
       9 << sdbuf LEN$ BLKSIZ MIN +
       FSIZE@ OVER = IF DROP FALSE THEN
       DUP fwrite !
     THEN
     scanch W~~
     ;





--- FILE SHELL COMMANDS ---

pub RENAME$ ( new$ -- )
     FSECT@ IF
       >F83 dirbuf 11 CMOVE				--- update local copy of directory entry
       UpdateDir
    THEN
      DROP
    ;

pre RENAME ( <oldname> <newname> )
    DEFER SWAP FOPEN$ IF RENAME$ ELSE DROP ."  No file opened " THEN
    ;

{
pre DELETE ( <name> -- )
     GETWORD FOPEN$ IF ." NOT IMPLEMENTED YET" THEN
     ;

ALIAS DELETE rm

}





pub FCOPY$ (  src$ dst$ -- flg )
	3 FILE FOPEN$ 0<> SWAP
	2 FILE FOPEN$ 0<> AND
	IF
pri _FCOPY
	  FSIZE@ 3 FILE FSIZE@ <=
	  IF
	    2 FILE FSIZE@ FSIZE@ BLKSIZ ALIGN 9 >> ( sectors_to_copy )
	    FSECT@ 3 FILE FSECT@ FROM SWAP FOR
	      I SECTOR OVER SDWR DROP 1+
	      NEXT
	  ( leave src sector as a flag )
	  ELSE FALSE
	  THEN
	ELSE FALSE
	THEN
	;


pre FCOPY ( <from> <to> -- )
	 DEFER
	 SWAP 2 FILE FOPEN$
	IF DROP ( ."  to " ) 3 FILE FOPEN$
	  IF ."  Copying..." 2 FILE FSIZE@ PRINT SPACE _FCOPY THEN
	THEN
	IF ." Success" ELSE ." Fail" THEN
	;


--- Load a file as console input - scripts or source code
pre FLOAD ( <name> -- )
    DEFER FOPEN$ 0EXIT FILE>
    ;


--- Print the contents of the file specified by the string if it exists
pub FPRINT$ ( file$ -- )
     FOPEN$ 0EXIT
pub (cat) --- type out the currently open file else ignore
     FSECT@ 0EXIT
     BEGIN
       --- null end of file or escape key?
       FGET DUP \ KEY $1B <> AND
     WHILE						--- no, continue
       DUP $0A = IF <CR> THEN			--- insert CR for an LF
       DUP $0D = IF DROP CR ELSE EMIT THEN
     REPEAT
     DROP
     ;

{

pub fcat --- type out the currently open file else ignore
     FILE@ 0EXIT
     FSECT@ FSIZE@ 9 >> ADO
	I SECTOR BLKSIZ ADO I C@ DUP EMIT $0A = IF $0D EMIT THEN LOOP
     LOOP
     ;

}


{ HELP cat <name>
List the contents of the specified file
}
pre cat ( <name> -- )				DEFER CR FPRINT$ ;


--- DIRECTORY PATH CONTROL ---

pub pwd						cwd$ PRINT$ ;

\ pre cd
\	GETWORD
pub cd$ ( dirstr -- )
	--- from root directory?
	DUP C@ '/' =
	--- point to remainder of string after preceding /
	IF ROOT 1+ THEN
	DUP FOPEN$ IF $10 dirbuf @ATR + SET?
	  IF FSECT@ SWAP cd! EXIT THEN THEN
	DROP
	;
pre cd		DEFER cd$ ;


\ pub .PATH      ( PCB$ ) PRINT$ '@' EMIT serial U@ .LONG SPACE pwd ."  $ " ;

{ HELP PROMPT ( on/off -- )
Turn on the path prompt and and suppress the ok response or revert back to normal Forth ok
}
\ pub PROMPT ( on/off -- )        DUP NOT OK ' .PATH AND prompt W! ;




--- DIRECTORY LISTING ---

{
DIRECTORY ENTRY
0 FILENAME
11 EXT
12 ATR
13 CMS
14 CTIME
CTIME
CTIME
CDATE
CDATE
ADATE
ADATE
FCLSTH
FCLSTH
FTIME
FTIME
FDATE
FDATE
CLUST
CLUST
FSIZE
FSIZE
FSIZE
FSIZE
0080_0140:   57 45 4C 43  4F 4D 45 20   46 54 50 20  00 00 87 83   WELCOME FTP ....
0080_0150:   A2 44 A2 44  00 00 D9 BE   83 44 0F 00  90 00 00 00   .D.D.....D......

LEGAL SYMBOLS
! # $ % & ' ( ) - @ ^ _ ` { } ~
Directory Attribute flags
0    Read Only
1    Hidden
2    System
3    Volume label
4    Directory
5    Archive

Directory types - first byte
Normal record with short filename - Attrib is normal
Long filename text - Attrib has all four type bits set
Unused - First byte is 0xE5
End of directory - First byte is zero
}


--- print the symbol(s) for each active directory name attribute
pri .ATR ( atr -- )
    " rhsvda " SWAP 6
     FOR
       DUP 1 AND IF OVER C@ ELSE '.' THEN EMIT
       2/ SWAP 1+ SWAP
     NEXT 2DROP
    ;






( FIRMWARE.ROM .....a 0000.620A    07/07/2014 11:58:14   5,536 )
{
--- DIRECTORY STRUCTURE ---

\ #00    := @FNAME		--- File name
\ #08    := @FEXT		--- File extension
#11    := @ATR			--- Attribute

\ #12	:= @USR			--- User attributes
\ #13    := @CMS         	--- creation millisecond (10 ms 0..199)
#14    := @CTIME        	--- creation time
#16    := @CDATE		--- creation date
\ #18    := @ADATE		--- access data
#20    := @FCLSTH		--- First cluster (high word)

#22    := @FTIME		--- modification time
#24    := @FDATE		--- modification date
#26    := @FCLST		--- First cluster of file (low word)

#28    := @FSIZE		--- size of file

valid symbols ! # $ % & ' ( ) - @ ^ _ ` { } ~

}

--- print date in Unix format
pri .FDATE ( fdate -- )
     DUP 5 >> .ASMONTH					--- extract day of the month to index into name string
      ( date )
      $1F AND .AS"  #`#" 				--- day of the month
     ;


pri .FDATES ( diradr field ch -- diradr )
       2 SPACES EMIT OVER+ W@  \ DUP .FDATE            --- print date
       DUP 9 >> #1980 + .AS" ####"
       '/' EMIT
       DUP 5 >> >N .DEC2
       '/' EMIT
       $1F AND .DEC2
\       SPACE
\ pri .FYEAR ( fdate -- )
\     9 >> #1980 + $250A PRINTNUM
     ;

pri .FTIMES
	--- print time
	SPACE OVER+ W@
pri .FTIME ( ftime -- )
	DUP 11 >> .AS"  ##:"
	5 >> $3F AND .DEC2
	;

--- 9999 or 26k or 9.9M or 3.4G
pri .SIZE
	DUP 10,000 < IF .DEC4 EXIT THEN
	DUP 1,000,000 < IF 1,000 / .AS" ##`#k" EXIT THEN
	DUP 1,000,000,000 < IF 1,000,000 / .AS" ##`#M" EXIT THEN
	100,000,000 /  .AS" #.#G"
	;

pri .DIR$
	$10 @ATR I+ SET?					--- format a directory name
	IF
	  '[' EMIT I 8 CTYPE ']' EMIT 5 SPACES		--- Use [ ] to enclose name
	ELSE
	  I 8 CTYPE 					--- normal, print name and opt ext
	  8 I+ C@ 32 <>
	    IF  DOT 8 I+ 3 CTYPE 3 ELSE 7 THEN
	  SPACES
	THEN
	;


--- Print the file name at the current loop index I
pub .FNAME ( --- )
     --- skip invalid index/entry
     I C@ 32 >
     IF
       $10 @ATR I+ SET? IF '[' EMIT THEN
       11 FOR
         J I+ C@ DUP 32 > IF I 8 = IF DOT THEN DUP EMIT THEN DROP
       NEXT
       $10 @ATR I+ SET? IF ']' EMIT THEN
     THEN
;

( HOME    .HTM    .....a 0004.3892  68k  m20140615 15:45  c20170804 07:55.080  a20170804 )

pri (.DIR)
	I CR
pri .DIR ( addr -- )
	--- ignore blank entries as closed
     	DUP C@
     	IF
     	  --- print the file name with spaces included (formatted listing)
	  DUP 8 CTYPE DOT 8 OVER+ 3 CTYPE
	  --- print attributes as alphas
	  TAB @ATR OVER+ C@ .ATR SPACE
	  --- print sector number
	  DUP FirstCluster CLUST>SECT .LONG
	  --- print size
	  SPACE @FSIZE OVER+ @ .SIZE
	  --- modified date
	@FDATE 'm' .FDATES @FTIME .FTIMES
	--- creation date
        @CDATE 'c' .FDATES @CTIME OVER+ W@ 13 OVER+ C@ 10 * 1000 U/MOD ROT + SPACE .FTIME .AS" ###."
	--- accessed date
	18 'a' .FDATES
     ELSE
       ." *CLOSED*"
     THEN
     DROP
    ;


{
DIR     PBJTECH.SDL
------------------------------------------------------------------------------
NAME    .EXT ATRS   SECTOR     DATE       TIME       SIZE
CE1372  .JPG .....a 0000.7C17    20/06/2013 02:36:52   736,486
}

pri udir	(.DIR) ;

pri lsdirs ( buffer -- )
	--- scan the buffer for dir entries -- 32 bytes/entry
        FROM BLKSIZ 5 >>
        --- up to 16 dir entries/sector
         32 BY FOR
           --- accept only valid entries
           @ATR I+ C@ $0F >
           --- but ignore if 1st character has 8th bit set
           I C@ $80 U< AND
           --- ignore "deleted" entries
           I C@ $3F <> AND
	   I C@ $20 > AND
           --- all good, list this one using the directed method
            IF udir THEN
        --- next dir entry 32 bytes (assumes standard 8.3)
        NEXT
	;

pub DIR
	' (.DIR) --- use this method for listing the directory
pri (DIR) ( code -- )
	?MOUNT CR volname 11 CTYPE
pub (SLIST) ( 'method -- )
	1+ ' udir W!
	--- always use FILE#1 for directory and any temp read only
	FCLOSE
	--- ( sector count ) scan and list rootdir by sector up to one cluster long
	cwdsect @ FROM sect/clust C@
	FOR I SECTOR lsdirs
\       scrc @ $80000000 <>
\       IF lsdirs
	--- no more dir sectors - leave loop
\       ELSE LEAVE
\       THEN
	NEXT
	;











--- print the Unix file mod time or year if the file is older than 6 months
pri .UTIME 	2 SPACES @FTIME I+ W@ .FTIME ;


byte lscnt

--- directory list method for ls
--- FORMAT: CE1372  .FTH   CE1372  .PDF   CHARLCD .JPG   IOT5500 .ROM   DRAGON  .JPG
pri (ls)
	lscnt C@ 5 MOD 0= IF CR THEN			--- 5 files per line
	.DIR$
	1 lscnt C+!
	;

--- List a single directory entry in FTP compatible format
pri (.LIST) ( <index> )
      ." -rwxrwxrwx 1 502     500 "			--- dummy permissions
      @FSIZE I+ @ .AS" ###########`# "			--- print file size "1048576" (  $2C0A PRINTNUM )
      @FDATE I+ W@ .FDATE				--- DATE

--- most systems expect either the time or the year if it is older than 6 months
       .UTIME
       SPACE .FNAME CR					--- FILE NAME "LOG0001.TXT"
    ;

pub .LIST        ' (.LIST) (SLIST) ;			--- set list method


--- list the directory in wide and simple format
--- ls -l in long format

pre ls
	--- no need to check
	lastkey C@ $0D <>
	IF GETWORD " -l" $=
	  --- long list  else
	  IF CR .LIST EXIT THEN
	--- else short list
	THEN
	lscnt C~ ' (ls) (DIR)
	;

--- change the FAT VOL name
pub VOLNAME! ( str -- )		DUP LEN$ 11 MIN @BOOT 9 << $47 + XADR DUP 11 ERASE SWAP CMOVE WRSECT ;

pub lss ( sector -- )		SECTOR sdbuf $200 DUMP ;

--
pub .FILE			FILE#
pub .FX ( index -- )		CR '#' EMIT DUP PRINT SPACE FILE dirbuf .DIR ;
pub .FILES			FILE# #files FOR I .FX NEXT FILE   ;


{			*** UTILITIES ***			}


--- exception handler - if word not found then run from file - point unum to this code
pub FRUN        		@WORD DUP C@ $2E = IF 1+ THEN FOPEN$ 0EXIT FILE> ;

--- File write text input to file
pre SAVETEXT ( <name> -- )
	3 FILE
\	lastkey C@ $20 = IF GETWORD FOPEN$ ELSE " TEMP.TXT" FOPEN$ NOT IF 128 KB " TEMP.TXT" FCREATE$ THEN FOPEN$ 0EXIT
	lastkey C@ $20 = IF DEFER ELSE " TEMP.TXT" THEN FMAKE$ 0EXIT
---	   line#
	RW 0	CR DUP PRINT SPACE
	  BEGIN WKEY DUP $0D = IF <CR> OVER U. SPACE THEN
	  DUP $1B <> WHILE OVER FSC! 1+
	  REPEAT
---	done, terminate file and flush
	DROP 0 OVER FSC! FLUSH
---	set new size and update
	FSIZE ! 2 FILE UpdateDir 3 FILE
	;

--- FAST LOAD - Load text input into specified file or TEMP.TXT and then process
pre FL		[C] SAVETEXT RO FILE> ;

{
--- convert line-feeds in text file to CRs or CRLF sequences
pub LF>CR
	FSECT@ 0EXIT
	0
	FSIZE@ FOR $0D <> I FSC@ $0A = AND IF $0D I FSC! THEN I FSC@ NEXT DROP FLUSH
	;
}

{ HELP: QV ( <filename> -- )
Quick view of file header in ASCII dump format
}
pre QV		DEFER FOPEN$ 0EXIT 0 $100 FS DUMPA ;


{

TACHYON
\ PRIVATE
$7FF0	:= extbuf
pri XSHR1
	0 extbuf FROM
	  16 FOR I C@ DUP 2/ ROT OR I C!
	    1 AND IF $80 ELSE 0 THEN
	  NEXT
	 DROP
	;
pri XSHR	?DUP IF FOR XSHR1 NEXT THEN ;
pri CSD@	( bith bitl -- n ) csd
pri BEXT	( bith bitl adr -- )
	extbuf 16 CMOVE DUP XSHR - 1+ MASK 1-
	0 extbuf $0C + FROM 4 FOR 8<< I C@ OR NEXT
	AND
	;

\ pri CID@	( bith bitl -- n ) cid BEXT ;

TACHYON
pri cid+	cid + ;
pri .CARD
	3 cid+ 5 CTYPE SPACE
	1 cid+ 2 CTYPE
	cid C@ .BYTE ." ."
	8 cid+ C@ .BYTE ."  #"
	9 cid+ .LONG SPACE
	13 cid+ C@ 8 << 14 cid+ C@ OR
	DUP 4 >> 2000 + PRINT ." /" >N PRINT
	."  !" ocr @ .LONG SPACE
	CNT@ 8192 BY 64 FOR I SECTOR NEXT CNT@ SWAP - ABS CLKMHZ / 6 >> .AS" *|# us"
\	  cid 16 DUMP csd 16 DUMP
	;

END




pri .CARD
	!SD 0EXIT
	  CR ." MFG:    " cid C@ .BYTE
	  CR ." OEM:    " cid 1+ 2 CTYPE
	  CR ." PROD:   " cid 3 + 5 CTYPE
	  CR ." REV:    " cid 8 + C@ .BYTE
	  CR ." S/N:    " cid 9 + U@ .LONG
	  CR ." DATE:   " cid #13 + C@
	  8 << cid #14 + C@ OR
	  DUP 4 >> #2000 + #10 PRINTNUM
	  ." /" >N #10 PRINTNUM
	  CR ." CRC:    " cid #15 + C@ 2/ .BYTE
	  CR ." OCR:    " ocr @ .LONG
	  CR ." SPEED:  " CNT@ 256 FOR I SECTOR NEXT CNT@ SWAP - ABS CLKFREQ 1000000 / / 8 >> .
	  cid 16 DUMP csd 16 DUMP
	;

END


( SanDisk 4GB microSD )
MFG:    03
OEM:    SD
PROD:   SU04G
REV:    80
S/N:    C887.650D
DATE:   2011/3
CRC:    6B
0000.76D8:   03 53 44 53  55 30 34 47  80 0D 65 87  C8 00 B3 D7    .SDSU04G..e.....
0000.76E8:   40 0E 00 32  5B 59 00 00  1D 8A 7F 80  0A 40 40 B9    @..2[Y.......@@.C0FF.8000


( SanDisk 8GB Ultra microSD )
MFG:    03
OEM:    SD
PROD:   SL08G
REV:    80
S/N:    F234.313A
DATE:   2016/7
CRC:    0C
C0FF.8000
0000.76D8:   03 53 44 53  4C 30 38 47  80 3A 31 34  F2 01 07 19    .SDSL08G.:14....
0000.76E8:   40 0E 00 32  5B 59 00 00  3B 37 7F 80  0A 40 40 AF    @..2[Y..;7...@@.


}

{
--- I/O pin constants for some pcbs - Usage: IO1656 SDPINS MOUNT

--- some predefined pinouts for my boards - names can be reclaimed later,
--- Usage: SD8 SDPINS  will lock the pin config into EEPROM directly ready for MOUNT
\ PRIVATE
&21.24.23.22 	:= SD1200
&24.27.26.25	:= SD1377
&27.24.26.25	:= SD8
&04.09.05.08	:= SD1656
&26.27.29.28	:= SD1372
&24.27.26.25	:= SD1144
&27.24.26.25	:= SD1419

--- Some Parallax configs
&11.08.10.09	:= SDQS		--- quickstart
&25.22.24.23	:= SDPAB	--- Prop activity board
&19.16.20.21	:= SDSPIN	--- Spinneret
				--- C3 (why would anyone put CS on a shift register??? & then not gate it?)
}

@rest @org W@ OVER - ERASE

END

' MOUNT +INIT


?BACKUP

--- my default - can be changed at runtime, no need to edit source
&26.27.29.28 SDPINS ( P1372 )
\ &04.09.05.08 SDPINS
\ &21.24.23.22 SDPINS ( P1200 )
