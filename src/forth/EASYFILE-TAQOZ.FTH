TAQOZ

\ FORGET EASYFILE.fth

pub EASYFILE.fth    ." P2 EASYFILE FAT32 SD FILE SYSTEM - 190101.0000 " ;

--- create deallocation markers for reload
\ DATPTR	:= efdat


( Tachyon Forth for the P2 - SD card utilities )

--- CVA9 microSD ( default unless changed by SDPINS )
39    := *SDCS            --- SDCARD CS
\ #P36    := *SDDO            --- Data out from SDCARD
\ #P41    := *SDCK            --- SDCARD clocks
\ #P40    := *SDDI            --- Data to SDCARD


{
BeMicroCV-A9            SW1
41	CLK     CLK  	60
40	CMD 	DI      58
36	D0      DO      59
37	D1
38	D2
39	D3	CS  	61
}
&39.36.40.41 	:= SDA

--- v27 remapped
( SD CARD PIN ASSIGNMENTS )
( CS.DO.DI.CK )
&61.59.58.60	:= SDC	--- SW1 remapped standard SD boot pins
&57.40.36.41	:= SDD	--- CVA9 ext SW1 remapped
&56.40.36.41	:= SDE	--- CVA9 ext SW1 remapped


{ V26
&39.36.40.41	:= SDC	--- unmapped BeMicro CVA9 microSD
&57.58.59.60	:= SDD	--- CVA9 ext
&56.58.59.60	:= SDE	--- CVA9 ext
}

&15.14.13.12	:= SDF		--- DE2-115 EXT

SDC		:= =sdpins	--- Default pins

512		:= BLKSIZ


            --- make the following definitions private until
--- SD Tokens
$FE             := =dtk            --- data token for single block read/write
--- $FC         := =dtk1            --- data token for 1st block read/write
--- $FD         := =dtke            --- data token for last block read/write

4		:= #files

--- SD CARD REGISTERS ---

---	Card ID
16	bytes cid
---	Card Specific Data
16	bytes csd
---	Operating conditions register
4	bytes ocr

4	bytes _sdwr
4	bytes _sdrd
1	bytes crc		--- SD CMD crc



#files	bytes wrflgs		--- byte flag for each channel to indicate current sector buffer has been written to
#files	longs sectors		--- Current sector loaded in SDBUFs for the 4 files possible
#files	longs scrcs		--- Sector CRCs

--- constant pointers to current file variables - changed when new file channel selected
wrflgs	:= wrflg		--- make @WRFLG a constant byte address, one for each file (faster than bit ops)
sectors := @sector		--- fast access to current sector than sector @FILE
scrcs	:= @scrc
BUFFER  := SDBUF		--- initial value for SDBUF which depends upon which file handle is selected
BUFFER	:= BUFFERS

	byte sdcmd





--- Detect SD card presence - the CS line must not have a pullup on it (redundant and undesirable).
pub CARD?    ( -- flg ; Is SD card present? )
    =sdpins 24 >> PIN
    L 10 us F 0 DROP R H
    ;

pri SDCLK			-1 SPIWB ;
pri SDCLK3			SDCLK SDCLK SDCLK ;

20,000 := *SDto                            --- SD timout period - can be very long

--- do what needs to be done if the SD card is busy (LED etc) - can be rewritten
--- LEDs are defined in PCB header files
pub SDBUSY ( state -- )		DROP ;
pub SDERROR ( state -- )	DROP ;


pub SDPINS ( ce-miso-mosi-clk -- --- set pins, save them for reboot and init with !SDIO see high level !SD )
	DUP			' =sdpins :=!                        --- remember which pins were used for BACKUP
    	DUP >B			' *SDCK :=!
	24 >>			' *SDCS :=!            --- setup SDCS mask
	;


( SD CARD RESPONSES )


--- Wait for read token and read SD data into buffer
pri MARKER? ( marker -- flgX )
    *SDto BEGIN OVER 0 SPIRD <> WHILE 1- DUP 0= IF NIP EXIT THEN REPEAT
    2DROP TRUE
    ;

--- Wait for read token and read SD data into buffer
pri SDDAT! ( adr -- )
    =dtk MARKER? IF 16 ADO 0 SPIRD I C! LOOP SDCLK3 ELSE DROP THEN
    ;

pub SDRES ( -- res ) 0 BEGIN SPIRD >B DUP $FF <> UNTIL ;


--- Send the command to the SD card and read result
pub CMD    ( data cmd -- res )
    DUP sdcmd C!
    =sdpins SPIPINS
    SDCLK
    SPIWC SPIWL
    crc C@ SPIWB				--- dummy checksum ( is valid for initializing)
    SDRES					--- fetch the response
    ;

--- Send an ACMD to the card and return with response
pub ACMD ( data acmd -- res )
     0 55 CMD DROP CMD
     ;
pri STAT@ ( -- stat )
     0 13 CMD SDRES 8<< OR
     ;

pub SDERR? ( -- flg ; return SD bit flag errors)
    0 CARD? 0= 1 AND OR        --- b0 = card detect error
    _sdrd @ 0= 2 AND OR        --- b1 = read failure
    _sdwr @ 0= 4 AND OR        --- b2 = write failure
    ocr @ 0= 8 AND OR            --- b3 = card error
    ;


pri SD4@ ( -- long )			0 SPIRDL ;

pri (!SD)
	sdcmd C~~
	5 FOR $95 crc C! 0 0 CMD 1 = ?NEXT 0EXIT	( Sandisk 8G takes x3)
	5 FOR $87 crc C! $1AA 8 CMD 1 = ?NEXT 0EXIT
        SD4@ $1AA = 0EXIT				( check pattern correct )
	--- Initialization R1 b30=HCS     --- requires quite a bit of time vs just clocks
\	 1000 FOR SDCLK $4000.0000 41 ACMD 0= ?NEXT 0EXIT
	0 1000 0 DO
	   $4000.0000 41 ACMD
	     IF SPICE ( *SDDI HIGH ) =sdpins C@ PIN 200 FOR H L NEXT
	     ELSE 1+ LEAVE
	     THEN
	LOOP
	0EXIT
	--- read OCR R3  - OCR(30)=CCS
	0 58 CMD ?EXIT SD4@ DUP ocr !
	IF
	  0 10 CMD 0= IF cid SDDAT! THEN			--- optional read cid and csd
	  0 9 CMD 0= IF csd SDDAT! THEN
	THEN
	;

--- Initialise the SD card in SPI mode and return with the OCR
pub !SD ( -- ocr|false )
	=sdpins	SPIPINS
	ON SDBUSY OFF SDERROR
	--- erase all module variables, selects file
	cid sdcmd 1+ OVER - ERASE
	--- erase all n file buffers
	SDBUF #files 9<<  ERASE
	--- force an invalid sector (nothing cached)
	sectors #files 4* -1 FILL
	--- stop slow clock from smartpin
	CARD?
	IF 20 FOR (!SD) sdcmd C@ 9 = ?NEXT DROP THEN
	OFF SDBUSY
	ocr @ DUP NOT SDERROR						--- indicate an error visually if enabled
	;



{ *** BLOCK BUFFERS *** }


{ HELP SDWR ( src sect -- flg )
Write to a sector in the SD card - measured 2.84ms on 4GB SanDisk
Testing 32k write: LAP 0 FILE@ 9 >> 64 ADO DUP I SDWR DROP BLKSIZ + LOOP LAP .LAP 274.111ms ok
 TF2: LAP 0 FILE@ 9 >> 64 ADO DUP I SDWR DROP BLKSIZ + LOOP LAP .LAP 88.418ms
 TF2: LAP 0 FILE@ 9 >> 64 ADO DUP I SDWR DROP BLKSIZ + LOOP LAP .LAP 74ms (using BUF>SPI)
 TF2 single sector = 1.275ms
}
pub SDWR    ( src sect -- flg ; Write from src to xdst in the SD )
	ON SDBUSY
	SDCLK3						--- Prep card
	24 CMD 0= ( src res )					--- write block command
	IF
	  SDCLK3 =dtk SPIWB
	  BLKSIZ SPITX						--- write block to SD
	  0 MARKER? $FF MARKER? AND
	ELSE FALSE
	THEN
	SPICE OFF SDBUSY
	DUP _sdwr !							--- save write flag
	;



--- card has been prep'd for read  - proceed and read a block of data
--- write the current sector back to the storage media
pri SDRDBLK ( dst -- crc|flg )
	BLKSIZ SPIRX
	--- read crc and force as true flag
	0 SPIRD SPIRD 1 OR
	;

\ pri ACTIVE? ( -- flg )	@scrc @ $8000.0000 <> ;
pri ACTIVE? ( -- flg )		0 SDBUF $200 ADO I @ OR $20 +LOOP ;

--- write the current sector back to the storage media
pub WRSECT ( -- flg )	SDBUF @sector @ SDWR ;

--- Write the sector buffer if it has been modified
pub FLUSH		wrflg C@ IF WRSECT DROP wrflg C~ THEN ;


{ HELP: SECTOR ( sect -- )
Read the sector into the SDBUF
takes around 1.9ms, 2.55ms
}
pub SECTOR ( sect -- )
	DUP @sector @ = IF DROP EXIT THEN			--- skip it if we already have  its
pub (SECTOR)
	FLUSH DUP @sector !						--- update sector pointer for this file channel
	SDBUF
--- SD CARD READ BLOCK -
--- Read sector from SD into dst
pub SDRD    ( sector dst --  )
	ON SDBUSY
	SWAP 17 CMD ( data cmd -- res )			--- read block command
	IF
	  DROP FALSE						--- didn't like that command - discard dst & return false
	ELSE
	  SDRES =dtk = IF SDRDBLK ELSE DROP SDCLK SDCLK STAT@ DROP FALSE THEN
	THEN
	OFF SDBUSY					--- release the SD card
	SDCLK
	DUP _sdrd !						---  save crc/flg
	@scrc !
	SPICE
	;

--- Read multiblock sectors from SD into dst
pub SDRDS    ( sector dst sectors -- crc | false )
	ON SDBUSY
	-ROT
	SWAP 18 CMD ( data cmd -- res )			--- read block command
	IF
	  --- didn't like that command - discard dst & return false
	  2DROP FALSE
	ELSE
	  --- process read token and read block if available
	  SDRES =dtk = IF SWAP FOR DUP SDRDBLK DROP BLKSIZ + NEXT ELSE 2DROP SDCLK SDCLK STAT@ DROP SPICE FALSE THEN
	THEN
	--- release the SD card
	OFF SDBUSY SDCLK SPICE
	---  save crc/flg
	DUP _sdrd !
	BEGIN 0 12 CMD 0= UNTIL
	SPICE
	;



--- --- --- --- --- --- --- ------ --- --- ------ ------ --- --- ------ --- --- ---



( Virtual memory addressing is suitable for addressing the first 4GB of the memory )


\ 0	:= @SECTOR

--- Translate a virtual address into a HUB RAM address - may have to flush and read a sector

pri XADR! ( xaddr -- addr )		1 wrflg C!
--- translate absolute 4GB SD memory address to a buffered address in hub RAM
pub XADR ( xaddr -- addr )		L>S ( @SECTOR + ) SECTOR sdbuf + ;


--- read and write from virtual memory address xaddr
pub X@ ( xaddr -- long )	XADR @ ;
pub X! ( long xaddr -- )	XADR! ! ;

pub XC@ ( xaddr -- byte )	XADR C@ ;
pub XC! ( byte xaddr -- )	XADR! C! ;

pub XW@ ( xaddr -- word )	XADR W@ ;


--- DUMP MEMORY ACCESS METHOD MODIFIER
--- Usage: 0 $200 SD DUMP

pub SD        DUMP: XC@ XW@ X@ ;


--- return the current file channel
0	:= FILE#

--- Set the active file channel (0 ..n) by setting psuedo constants
pub FILE ( index:0..n -- )
     #files 1- AND
     DUP ' FILE# :=!
     DUP 4* sectors + ' @sector :=!
     DUP 4* scrcs + ' @scrc :=!
     DUP wrflgs + ' wrflg :=!
     9<< BUFFERS + ' SDBUF :=!
     ;



{ HELP @FILE ( addr -- addr+off )
returns the address offset into sector & sectcrc tables for active file channel
as set with    index FILE
e.g. val sector @FILE ! otherval sectcrc @FILE ! sector @FILE @
}
pub @FILE ( addr -- addr+off )		FILE# 4* +  ;



{
pub SDMAP ( sec secnt -- )
 	HEX
	ADO
	  I $3F AND 0= IF CR I .ADDR ." : " THEN
	  I SECTOR 0 SDBUF BLKSIZ ADO I @ IF 1+ LEAVE THEN 4 +LOOP
	  IF "*" ELSE "." THEN EMIT
	LOOP
	 ;

pub SDMAP2 ( sec secnt -- )
	CR ." SD SECTOR MAP - 32K/char 2MB/line"
 	HEX
	ADO
	  I $FFF AND 0= IF CR I .ADDR ." : " THEN
	  --- read 64 sectors (32kB) and display as single character
	  0 I #64 ADO I SECTOR SDBUF BLKSIZ ADO I @ OR 4 +LOOP LOOP
	  IF "*" ELSE "." THEN EMIT
	#64 +LOOP
	 ;


pub BACKUP	1 @FAT $400 - 0 $8.0000 ADO I OVER SDWR DROP 1+ BLKSIZ +LOOP DROP ;

	   0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
 $00.B000: .........................................*......................
}













\ pub EASYFILE.fth    ." FAT32 Virtual Memory Access File System Layer V1.1 for TF2 151119-1200 " ;


--- EASYFILE CODE ---

--- PARTITION TABLE ---

--- Partition table image - copied here
16	longs parts             --- Room for 4 entries of 16 bytes

\ parts 8 +	:= fatptr	--- long that points to sector containing fat info
pri @FAT32 	parts 8 + @ ;

--- These are the offset constants compiled as absolute addresses (for 1st partition)
--- Many names have not been added to the dictionary to save space (but could be reclaimed later)
{

Offset 	Description 	Size
00h 	Current State of Partition(00h=Inactive, 80h=Active) 	1 Byte
01h 	Beginning of Partition - Head 	1 Byte
02h 	Beginning of Partition - Cylinder/Sector (See Below) 	1 Word
04h 	Type of Partition (See List Below) 	1 Byte
05h 	End of Partition - Head 	1 Byte
06h 	End of Partition - Cylinder/Sector 	1 Word
08h 	Number of Sectors Betweenthe MBR and the First Sector in the Partition 	1 Double Word
0Ch 	Number of Sectors in thePartition 	1 Double Wor

parts    ORG
1    res --- state		--- 00 = inactive, $80 = active
1    res --- head		--- beginning of paritiion
2    res --- cylsec		--- beginning of partition cylinders/sector

1    res --- partype		--- type of partition
1    res --- ehead		--- end of partition head
2    res --- ecylsec		--- end of partitiion cylinder/sector

4    DS fatptr
4    res --- size
pub .parts
	4 0 DO I 4 SHL $1BE +
	CR DUP C@ .BYTE SPACE
	DUP 1+ C@
	;

File System Information Sector
Offset 	Description 	Size
00h 	First Signature (52h 52h 61h41h) 	1 Double Word
04h 	Unknown, Currently (Mightjust be Null) 	480 Bytes
1E4h 	Signature of FSInfo Sector(72h 72h 41h 61h) 	1 Double Word
1E8h 	Number of Free Clusters (Setto -1 if Unknown) 	1 Double Word
1ECh 	Cluster Number of Clusterthat was Most Recently Allocated. 	1 Double Word
1F0h 	Reserved 	12 Bytes
1FCh 	Unknown or Null 	2 Bytes
1FEh 	Boot Record Signature (55hAAh) 	2 Bytes

FAT32 Drive Layout
Offset 	Description
Start of Partition 	Boot Sector
Start + # of ReservedSectors 	Fat Tables
Start + # of Reserved + (#of Sectors Per FAT * 2) <Assuming that FAT Mirroring isEnabled, I personally haven't seen a case where itwasn't, but I guess there is always the possibility> 	Data Area (Starts withCluster #2)


}

--- BOOT RECORD ---

{
Boot Record
The boot record occupies one sector, and is always placed in logical sector number zero of the "partition". If the media is not divided into partitions, then this is the beginning of the media. This is the easiest sector on the partition for the computer to locate when it is loaded. If the storage media is partitioned (such as a hard disk), then the beginning of the actual media contains an MBR (x86) or other form of partition information. In this case each partition's first sector holds a Volume Boot Record.

vbr
40.0000: EB 3C 90 4D 53 57 49 4E 34 2E 31 00 02 40 0E 11    .<.MSWIN4.1..@..
40.0010: 02 00 00 00 00 F8 00 00 3F 00 FF 00 00 20 00 00    ........?.... ..
40.0020: C0 37 EF 00 79 07 00 00 00 00 00 00 02 00 00 00    .7..y...........
40.0030: 01 00 06 00 00 00 00 00 00 00 00 00 00 00 00 00    ................
40.0040: 80 01 29 87 D6 12 00 50 32 53 44 43 41 52 44 20    ..)....P2SDCARD
40.0050: 20 20 46 41 54 33 32 20 20 20 00 00 00 00 00 00      FAT32   ......

problem vbr 16GB
00.E13E: 45 46 49 20 50 41 52 54 00 00 01 00 5C 00 00 00    EFI PART....\...
00.E14E: 89 B1 D7 CB 00 00 00 00 01 00 00 00 00 00 00 00    ................
00.E15E: FF CB DA 01 00 00 00 00 22 00 00 00 00 00 00 00    ........".......
00.E16E: DE CB DA 01 00 00 00 00 D9 F8 06 10 B2 F6 8D 44    ...............D
00.E17E: 81 B9 CE A0 1F 9D 89 E5 02 00 00 00 00 00 00 00    ................
00.E18E: 80 00 00 00 80 00 00 00 DE 97 FF 00 FF FF FF FF    ................
00.E19E: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00    ................
00.E1AE: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00    ................ ok

fsis
40.0200: 52 52 61 41 00 00 00 00 00 00 00 00 00 00 00 00    RRaA............
40.03E0: 00 00 00 00 72 72 41 61 1F 77 00 00 43 2A 01 00    ....rrAa.w..C*..
40.03F0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 55 AA    ..............U. ok

}

0	bytes vbr		--- 96 byte array

3	res
8	res 			--- 3: oemname
2	res  			--- 11: byte/sect
1	res			--- 13: sectors/cluster
2	res  			--- 14: rsvd
--- $10 ---
1	res  			--- 16: Copies of FAT
4	res			--- root entry count (FAT16)
1	res			--- media $F8
2	res			--- n/a
2	res			--- sect/trk
2	res			--- heads
4	res			--- hidden sectors
--- $20 ---
\ 4	bytes capacity		--- 32: Number of sectors * byte/sect (512) = capacity
4	res
--- $24 ---
4	res   			--- 36: Number of sectors per FAT table
2	res			--- 40: fatflags
2	res			--- 42: fatver
4	res 			--- 44: Cluster Number of the Start of the Root Directory (02 -> $4000)
\ 2	bytes fsis		--- info = Sector Number of the FileSystem Information Sector  (from part start)
2	res 			--- filesystem information sector
2	res			--- boot = Sector Number of the Backup Boot Sector (from part start)
#12	res
--- $40 ---
3	res
4	res 			--- #67 serial number of partition
#11	res 			--- #71 volume name
8	res 			--- #82 always FAT32 - (don't trust)
--- END $5A ---




--- create room for some system variables in this table
	byte mounted		--- true flag if mounted (but also depends upon other checks)
\ 1	bytes clshift		--- cluster shift (fast  multiplier)
\ 4	bytes rootdir		--- sector address of root directory


--- DIR BUFFERS ---

--- A copy of the original virtual address of the directory entry is kept in this array (4 entries)

4	longs diradr		--- virtual memory address of file's directory entry

4	longs _file		--- table entry for 4 open files - holds sector address

--- Directory entry table
32	longs dirbuf		--- create a directory buffer for the opened file

	byte _rw		--- file r/w permissions

	long cwdsect
	long fboot		--- boot signature - determines whether it needs to remount

pri vbr+ 	vbr + ;


pub RW?		FILE# |< _rw SET? ;
pub RW		FILE# |< _rw SET ;
pub RO		FILE# |< _rw CLR ;

--- FAT HANDLERS ---

pub @ROOT ( -- rootdirsect )		$FFFF.FFFF ;
pub ROOT 				@ROOT cwdsect ! ;

--- return with the starting sector of the selected FAT (normally 0 or 1)
pub @FAT ( fat# -- sector )
	36 vbr+ @ *
	@FAT32 14 vbr+ W@ + +
	;

--- FAT pointers (changed by READFAT32)
0    := FAT1
0    := FAT2

--- convert cluster to sector
pri SC* ( cluster -- sector )		6 << ;
--- sectors/cluster
pri S/C ( -- sectors )			13 vbr+ C@ ;

pri READFAT32
	@FAT32 SECTOR					--- Read the FAT32 boot record
	SDBUF vbr 90 CMOVE				--- backup the FAT32 entry for direct access
	S/C >| ' SC* C! \ clshift C!			--- make a fast multiply using a shift left constant
	14 vbr+ W@ 36 vbr+ @ 16 vbr+ C@ *
	44 vbr+ @ 2- SC* + + @FAT32 + ' @ROOT :=!	--- rootdir constant
	0 @FAT ' FAT1 :=!				--- save time by precalculating FAT table addresses
	1 @FAT ' FAT2 :=!
	;

8 bytes drive$

pri .SER 	67 vbr+ @ .LONG SPACE ;
pri .VOL 	71 vbr+ 11 CTYPE SPACE ;
pri .CID	'[' EMIT cid 1+ 7 ADO IC@ $20 MAX $7E MIN EMIT LOOP ']' EMIT SPACE ;

pri .FAT
	CR ." Mounted " drive$ PRINT$ SPACE
	--- read FAT32 boot record
	@FAT32 SECTOR .VOL
	--- display card & fat serial
	cid 9 + @ .LONG '-' EMIT .SER
	--- card info name & oemname
	.CID 3 vbr+ 8 CTYPE SPACE
	--- FAT32 names
	82 vbr+ 8 CTYPE SPACE
	--- display memory capacity
	32 vbr+ @ BLKSIZ 1,000,000 */ .DECL ." MB ("
	--- display cluster size
	S/C 2/ PRINT ." kB/cluster) "
	;



pub UNMOUNT		parts fboot OVER - ERASE ;

pub DRIVE ( name$ -- )	drive$ $!
{ HELP MOUNT
Mount the currently selected storage device and init all 4 file handles
Read the FAT32 and set variables accordingly
}
pub MOUNT
	ON SDERROR					--- turn on error LED - only cleared if FAT passes muster
	UNMOUNT !SD
	IF
	  mounted C~~
	  --- read and check partition info
	  0 FILE $01FE XW@ $AA55 =
	  IF
	    --- buffer patitions
	    $01BE XADR parts $40 CMOVE
	    --- read the FAT32 sector and display
	    READFAT32 .FAT
	    --- use root directory
	    ROOT
	    --- clear error indication & copy boot signature to validate mount status
	    OFF SDERROR	 ( bootsig @ fboot ! )
	  ELSE
            ."  *MBR Format Error* "
	  THEN
	ELSE
	  ." *Card Error* "
	THEN
	;

pub C:        SDC SDPINS " C:" DRIVE ;
pub D:        SDD SDPINS " D:" DRIVE ;
pub E:        SDE SDPINS " E:" DRIVE ;
pub F:        SDF SDPINS " F:" DRIVE ;


pri ?NEW
	CARD? NOT
	  IF mounted C~ EXIT
	  ELSE mounted C@ 0= IF 50 ms MOUNT THEN
	  THEN
	;

pub !FS
	mounted C~
	' ?NEW +POLL
	;




pub ?MOUNT
    CARD? NOT
     IF
       ."  *No Card inserted!* "
       ON SDERROR MOUNT
     THEN
    \ bootsig @ fboot @ <> mounted C@ 0= OR IF MOUNT THEN
    mounted C@ 0= IF MOUNT THEN
     ;




1	bytes _card		--- card detect transition memory

{ HELP ?SDCARD
Make sure the card is inserted or mount it if it has just been inserted
}
pub ?SDCARD
    _card C@ 0= CARD? DUP _card C! AND			--- check previous card state with now and update
      IF MOUNT THEN					--- just inserted so mount automatically
    CARD? NOT IF ON SDERROR mounted C~ THEN		--- indicate an error if it's not inserted
    ;


--- FILE NAME HANDLERS ---

" FILENAME.TXT" 16 4 * STRING file$			--- The actual name of the file requested
--- file$ stores 4 8.3 filenames at 16 byte boundaries

pub FILE$  ( -- addrOfFilenameString )    FILE# 4 << file$ + ;

" FILENAMESTR " 0 STRING fname$                --- The formatted name of the file requested for internal use

--- format friendly file name into directory format
--- FILE.TXT --> FILE    TXT
pri >F83 ( str1 -- str2 )
    fname$ 11 BL FILL			--- prep fname$ as all blanks
    fname$ 11 + C~			--- ensure terminator is set
    fname$ BEGIN OVER C@ DUP '.' <> SWAP 0<> AND WHILE OVER C@ OVER C! 1+ SWAP 1+ SWAP REPEAT
    --- process the extension if it has one
    DROP DUP C@ IF 1+ DUP LEN$ ?DUP IF fname$ 8 + SWAP CMOVE ELSE 2DROP THEN ELSE DROP THEN
    fname$
    ;


--- DIRECTORY STRUCTURE ---

\ #00    := @FNAME        '' File name
\ #08    := @FEXT        '' File extension
11    := @ATR        '' Attribute
\ #12    := @CASE	'' reserved - used for case info
\ #13    := @CMS        '' creation millisecond (2ms)
14    := @CTIME        '' creation time
16    := @CDATE        '' creation date
18    := @ADATE        '' access data
\ #20    := @FCLSTH        '' First cluster (high word)
22    := @FTIME        '' modification time
24    := @FDATE        '' modification date
\ #26    := @FCLST        '' First cluster of file (low word)
28    := @FSIZE        '' size of file


pri StartSector ( diradr -- sector )
--- = virtual memory address of file's directory entry
	DUP 26 + W@ SWAP 20 + W@ W>L
\ pub CLUST>SECT ( clust# -- sector )
	44 vbr+ @ - SC* @ROOT +
	;

--- return with the address of the 32-byte directory buffer  in RAM using current file index
pub @DIRBUF ( -- bufadr )	FILE# 5 << dirbuf + ;


{
--- Find the directory entry and return with its virtual address >>5, that is, aligned to 32 bytes = 64GB range
pub DIR?    ( str -- dirxptr>>5 | FALSE )
	?MOUNT
	mounted C@
	IF
	  cwdsect @ 9 << ( str dirxptr )
	  BEGIN ( str dirxptr )
	    DUP XADR					--- ensure correct sector is loaded
	    DUP C@					--- terminate on null entry
	  WHILE ( str dirxptr bufptr )
	    DUP #11 + C@ 4TH #11 + C!			--- just make our search string have the same attribute (extra zero term* on each anyway)
	    ( str dirxptr bufptr )
	    DUP 4TH COMPARE$ ( str dirxptr bufptr flg )
	    IF
              @DIRBUF BL CMOVE				--- save dir entry for FOPEN#
	      NIP EXIT                          	--- Found it, exit here with address
            THEN
	    DROP BL +					--- skip to next dir entry (32 bytes)
	  REPEAT
	  2DROP					--- failed to find it - discard parameters
	THEN
	DROP FALSE						--- Failed to find it
	;
}

12 bytes dir$
pub DIR?    ( str -- diraddr>>5 | FALSE )
	?MOUNT
	dir$ 11 + C~
	mounted C@
	IF
	  0 ( str offset )
	  BEGIN ( str dirptr )
	    DUP 9 >> cwdsect @ + SECTOR			--- ensure correct sector is loaded
	    DUP 9BITS SDBUF + DUP C@			--- terminate on null entry
	    3RD 0= OR					--- but not first one
	  WHILE ( str index bufptr )
	    DUP $E5 <>					--- skip deleted entries
	    IF
	    DUP @DIRBUF BL CMOVE			--- save in case it's successful so FOPEN# can access
	    dir$ 11 CMOVE				--- copy the name as a string
	    dir$ 3RD COMPARE$
	      IF NIP 5 >> cwdsect @ 4 << +  EXIT THEN	--- Found it, exit here with address
	    THEN
	    BL +					--- skip to next dir entry (32 bytes)
	  REPEAT
	  DROP 2DROP					--- failed to find it - discard parameters
	ELSE
	  DROP
	THEN
	FALSE						--- Failed to find it
	;




--- DIRECTORY ENTRY HANDLERS ---

--- update current directory entry from buffer
{
pub DIR!
	@DIRBUF diradr @FILE @ XADR BL CMOVE		--- copy that to the virtual address
	WRSECT DROP					--- Force an update
	;
}
pub DIR!
	@DIRBUF diradr @FILE @				--- diradr holds 64GB address>>5 for 32-byte aligned directory entries
	DUP 4 >> SECTOR >N 5 << SDBUF +
	BL CMOVE		--- copy that to the virtual address
	WRSECT DROP					--- Force an update
	;

--- split 6 digit decimal number into 3 two digit groups
pri DECS ( #xxyyzz -- zz yy xx )	100 U/MOD 100 U/MOD ;

--- write to directory entry as new date
pri +DIR! ( word field -- )		@DIRBUF + W! ;

--- update file modification/create date in dir buf
pri FDATE! ( #yymmdd field -- )                --- Date (7/4/5 bits, for year-since-1980/month/day)
	SWAP
	200000 +                     --- arrange as decimal YYMMDD from 1980 ( 2000.0000 + 1980.0000 - )
	DECS 9<< SWAP 5 << + +
	SWAP +DIR!
	;

--- update file modification/create time in dir buf
pri FTIME! ( #hhmmss field -- )                 --- Time (5/6/5 bits, for hour/minutes/doubleseconds)
	SWAP DECS 11 << SWAP 5 << + SWAP 2/ +
	SWAP +DIR!
	;

--- DATE TIME STAMPING ---

IFNDEF DATE@
150101    := DATE@
120000    := TIME@
}

{ HELP FSTAMP
Update the modified time and data of the current file
}
pub FSTAMP ( -- )
     DATE@ @FDATE FDATE! TIME@ @FTIME FTIME!              --- update file date and time with current
     DIR!
     ;

pri .FYEAR ( fdate -- )
     9>> 1980 + $250A PRINTNUM
     ;

IFNDEF .ASMONTH
pri .ASMONTH ( index -- )
     >N 1- 3 *
     " JanFebMarAprMayJunJulAugSepOctNovDec" + 3 CTYPE
     ;
}
--- print date in Unix format
pri .FDATE ( fdate -- )
--- 	extract day of the month to index into name string
	DUP 5 >> .ASMONTH
--- 	day of the month
	$1F AND $230A PRINTNUM
	;
pri .FTIME ( ftime -- )
      DUP 11 >> $20A PRINTNUM ':' EMIT
      5 >> 6 BITS $20A PRINTNUM
     ;



--- CLUSTER HANDLERS ---

{
--- display cluster usage from FAT
pub .FATMAP
     36 vbr+ @ 0 DO
       I $3F AND 0= IF CR I .WORD SPACE  THEN
       FAT1 I+ SECTOR
       sectcrc @FILE W@
       IF '*' ELSE '.' THEN EMIT
       lastkey C@ $1B = IF LEAVE THEN
     LOOP
     ;

}
pri NextFreeDir ( -- xadr )
     0
     cwdsect @ 9<< S/C 9<<
     ADO I XC@ 0= IF I+ LEAVE THEN 32 +LOOP
     ;


{ CLUSTER CHAIN CODES
If value => $0FFF.FFF8 then there are no more clusters in this chain.
$0FFF.FFF7 = bad
0 = free

}
pri @CLUSTER ( index -- xadr )
     4* FAT1 9<< +
    ;
pri CLUSTER@ ( index -- cluster )
      @CLUSTER X@
     ;


IFNDEF ROUNDUP/
pub ROUNDUP/ SWAP OVER /ROUND SWAP / ;
}

{ HELP CLUSTERS? ( size -- xadr )
Find free clusters for the file size in bytes - 0 = all
return with address of first free cluster
}
pri CLUSTERS? ( size -- xadr )
--- calculate clusters required
     9>> S/C ROUNDUP/ ( clusters )
      0
     BEGIN
---	find a free cluster
       BEGIN DUP @CLUSTER X@ WHILE 1+ REPEAT
       ( clusters index )
---	check for sufficient contiguous clusters (linear non-fragmented)
       0 OVER 4TH ADO I @CLUSTER X@ OR DUP IF NIP I SWAP LEAVE THEN LOOP
       ( clusters chain flag )
     WHILE
       1+
    REPEAT
     NIP
     ;


pub FSIZE@				@DIRBUF @FSIZE + @ ;

pub FSECT@ ( -- sect )			_file @FILE @ ;


--- VIRTUAL FILE ACCESS ---

pri FSADR! ( faddr -- addr )     	1 wrflg C!
pub FSADR ( faddr -- addr )		L>S FSECT@ + SECTOR SDBUF + ;


--- common FS store routines
pri ~!					FSECT@ IF 0 MAX FSIZE@ MIN FSADR! ELSE R> 3DROP THEN ;

pub FSC! ( byte faddr -- )		~! C! ;

pub FS! ( long faddr -- )		~! ! ;

--- 25.333us @96MHz  (26.5us)
pub FSC@ ( faddr --- byte )		FSADR C@ ;

pub FSW@				FSADR W@ ;

pub FS@					FSADR @ ;

pub FS					DUMP: FSC@ FSW@ FS@ ;


--- SEQUENTIAL FILE ACCESS ---

--- maintain read and write pointers for 4 files --- offsets into files
#files longs fread						--- access via @FILE for current file:   fread @FILE   or    @FREAD
#files longs fwrite						--- access via @FILE for current file:   fwrite @FILE  or    @FWRITE

byte _fstat						--- current status of file system
pub FSTAT	_fstat C! ;

pub @FREAD ( -- readptr )		fread @FILE ;
pub @FWRITE ( -- writeptr )		fwrite @FILE ;

--- return with remaining bytes in file
pub FREM ( --- rem )			@FWRITE @ DUP IF FSIZE@ SWAP - THEN ;


WORD fkey						--- backup for input device when input is switched to file

--- Read in the next character in the virtual buffer as part of the console input stream
pri FGET ( -- ch )
    @FREAD @ FSC@					--- Read a single character
    DUP 0=
       IF 'X' FSTAT! fkey W@ ukey W!			--- stop when null encountered and return to previous input device
       ELSE @FREAD ++					--- update index otherwise
       THEN
    ;

							--- ignore null characters (but will write nulls if another bit in long is set)
pub FPUTB ( byte -- )					--- write byte even if it is null
      FSECT@ 0<> RW? AND					--- check if file is opened and a valid write pointer is set (APPEND)
     IF							--- don't write if a file is not opened
      @FWRITE @ FSIZE@ BLKSIZ ALIGN =>			--- file full?
         IF DROP 'O' FSTAT! EXIT THEN			--- Don't write to beyond end of file - fstat = O for OVERFLOW
							--- still room in the file so just write it
      @FWRITE @ FSC!					--- write the character to the file
      @FWRITE @ FSIZE@ BLKSIZ ALIGN  1- =		--- last byte in file?
         IF 'F' FSTAT! EXIT THEN			--- Warn file is now full - fstat = F for FULL, exit now!

      @FWRITE ++
       0 @FWRITE @ FSC!					--- Insert a null terminator (overwritten by the next character)
     ELSE
       DROP 'N' FSTAT!				--- no file - fstat = N
     THEN
     ;

--- Write a character into the logical end of the file and update the write pointer
\ 280us typical - TF2 94us
pub FPUT ( ch -- )		?DUP IF FPUTB THEN ;


\ TAQOZ# $4.0000 $1.0000 LAP FREAD LAP .LAP 5911280 cycles = 73.891ms  ok
\ SPI>BUF w CALL	 $2.0000 256 KB LAP FREAD LAP .LAP 21455057 cycles = 268.188ms  ok
\ SPI>BUF inc SPIRD	$2.0000 256 KB LAP FREAD LAP .LAP 20415696 cycles = 255.196ms  ok
--- File Read to memory
pub FREAD ( dst size --- )     9>> FSECT@ -ROT SDRDS DROP ;




--- Redirect the console input to read the file sequentially
pub FILE>
pub FILEIN
    FSECT@ IF ukey W@ fkey W! ' FGET ukey W! THEN
     ;
\ ALIAS FILEIN FILE>

{ HELP >FILE ( -- )
Redirect character output via uemit to the open file using "fptr" which is set to the start of the file when opened
If the file is not opened and a valid write pointer set then output will be discarded
}

pub FILEOUT ( -- )
     FSECT@ IF ' FPUT uemit W! ELSE NULLOUT THEN
    ;
\ ALIAS FILEOUT >FILE

pub FCLOSE						--- Close the current file
    FLUSH						--- make sure that this file has any modifications written back.
     @sector ~~						--- clear sector (-1)
     _file @FILE ~					--- clear file pointer
     NULL$ FILE$ $!					--- blank out file name
     @DIRBUF BL ERASE					--- wipe dir entry
     ;

{ HELP FOPEN# ( diradr -- sector )
Open the file pointed to by the 64GB virtual directory entry address
aligned to 32 byte directory entries
}
pub FOPEN# ( xdiradr5 --- sector )
	diradr @FILE !					--- save 64GB address of directory entry
	@DIRBUF
	StartSector
	_file @FILE !					--- save starting sector of file
	@FREAD ~					--- Set  FREAD  to start of file sector
	@FWRITE ~
	RO FSECT@
	;

{ HELP FOPEN$ ( namestr -- sector )
Open the file with the 8.3 name and return with its sector or 0 if failed
The variable fstat can be checked for more information if there was an error
Execution time ~ 10ms sample:
" FIRMWARE.ROM" LAP FOPEN$ DROP LAP .LAP 2.887ms ok
Usage: " SYSLOG.TXT" FOPEN$ IF etc etc
}
pub FOPEN$ ( namestr -- sector )
     FCLOSE
     DUP C@
     IF							--- skip null name
       DUP C@ '/' = IF 1+ THEN				--- ignore leading / in file name
       DUP LEN$ 12 >
         IF '!' FSTAT! DROP FALSE EXIT THEN		--- abort with ! status if name is too long
       DUP FILE$ $!					--- set the name for this file
      >F83 DIR? DUP					--- find the dir entry
        IF FOPEN#    ( sector )				--- open the file from the dir entry
        ELSE '?' FSTAT!				--- else ? not found
	THEN
     ELSE
       DROP FALSE '?' FSTAT!
     THEN
    ;

{ HELP FOPEN ( <name> -- )
Open a file interactively with the name specified in the input stream
Report back to the console
}
pre FOPEN ( <name> -- )
    GETWORD
     FOPEN$ ?DUP
       IF ." ...opened at "  .LONG SPACE
       ELSE ."  not found "
       THEN
    ;


{ HELP FCREATE$ ( namestr -- flg )
--- Create a new file by name but if it already exists then delete the old one and reuse the dir entry.
--- preallocate 1M (hidden) per file in cluster table so only dir entry needs updating.
--- last file can increase beyond 1M if needed
}
pub FCREATE$ ( namestr -- flg )
     FCLOSE                            --- close any open file on this channel - clears dir entry buffer
    >F83 ( namestr -- f83str )                --- make sure it's ready in the correct 8.3 format
     @DIRBUF 11 CMOVE                    --- write the name of the file to the directory buffer
     $20 @DIRBUF @ATR + C!                --- set archive attribute
     DATE@ @CDATE FDATE! TIME@ @CTIME FTIME!        --- stamp create date and time
     CLUSTERS? ( -- xadr )
\     NextFreeDir ( -- xadr ) XADR


     ;







--- FILE APPEND OPERATIONS ---

--- APPEND TO TEXT FILES USING AN EOF MARKER


1         := RCDSZ        \ Minimum record increment, normally 1 for text files, needs to be 2^n, n>=0
RCDSZ >|    := >|RCDSZ

--- virtual memory fileaddress for rcd record number (for text files rcd = char pos)
pub @RCD    ( rcd -- fadr )	>|RCDSZ << ;

\ Erase the current file by overwriting with nulls
pub -FERASE
     FSECT@ 0EXIT
     0 FSIZE@ ADO 0 I FSC! LOOP FLUSH
     ;

byte eof            \ end of file character

pri APPEND.BLK ( -- relblk )
    FSECT@ FSIZE@ 9>> OVER + SWAP     ( maxsect minsect )
     BEGIN
      2DUP - 2/ OVER +        ( max min mid )     --- Find new mid point
        SECTOR                  ( max min )
     2DUP - 1 >
     WHILE
       SDBUF C@ eof C@ =        ( max min flg )     --- if true then too high
       IF 2DUP - 2/ OVER + ROT DROP SWAP
       ELSE 2DUP - 2/ OVER + NIP
       THEN
    REPEAT
      NIP
    ;

{ HELP APPEND ( eof -- xptr )
Find the EOF marker (normally a null) and set the write pointer and result to this ready to append
return with null if failed.
}
pub APPEND ( eof -- ptr )
     eof C!
    FSECT@ DUP 0EXIT DROP                    --- exit with false if there is no file opened
     APPEND.BLK ( -- relblk )                --- find the active block to use
     9<< SDBUF LEN$ BLKSIZ MIN +             --- add in offset allowing for a full block as well
     FSIZE@ OVER = IF DROP FALSE THEN
	DUP @FWRITE !
	;





--- FILE SHELL COMMANDS ---

pub RENAME$ ( new$ -- )
     FSECT@ IF
       >F83 @DIRBUF 11 CMOVE                 --- update local copy of directory entry
       DIR!
    THEN
      DROP
    ;

pre RENAME ( <oldname> <newname> )
    GETWORD FOPEN$ IF ."  to " GETWORD RENAME$ ELSE DROP ."  No file opened " THEN
    ;

pre DELETE ( <name> -- )
     GETWORD FOPEN$ IF  THEN
     ;

--- Load a file as console input - scripts or source code
pre FLOAD ( <name> -- )
    GETWORD FOPEN$ 0EXIT FILEIN
    ;

--- exception handler - if word not found then run from file - point unum to this code
pub FRUN        @WORD DUP C@ '.' = IF 1+ THEN FOPEN$ 0EXIT FILEIN ;


pub (cat) --- type out the currently open file else ignore
     FSECT@ 0EXIT
---  clear any preexisting console escape
     lastkey C~
     0
     BEGIN
---    null end of file or escape key?
       DUP FSC@ DUP lastkey C@ $1B <> AND
     WHILE
--- make sure all LFs are preceded by a CR
       DUP $0A = IF $0D EMIT THEN EMIT 1+
     REPEAT
     2DROP
     ;
pub FPRINT$ ( file$ -- ) --- Print the contents of the file specified by the string if it exists
     FOPEN$ 0EXIT (cat)
     ;


{ HELP cat <name>
List the contents of the specified file
}
pre cat ( <name> -- ) 		[COMPILE] FOPEN CR (cat) ;



--- DIRECTORY PATH CONTROL ---

NULL$ 11 STRING cwd$

pub cd$ ( dirstr -- )
     --- from root directory?
     DUP C@ '/' = IF ROOT NULL$ cwd$ $! 1+ THEN
     DUP FOPEN$
     IF
       $10 @DIRBUF @ATR + SET?
         IF cwd$ $! FSECT@ cwdsect ! EXIT THEN
     THEN
     DROP
    ;
pre cd
     GETWORD cd$
     ;

pub pwd     '/' EMIT cwd$ PRINT$ ;

pub .PATH      ." TAQOZ@" .SER pwd ."  $ " ;


{ HELP PROMPT ( on/off -- )
Turn on the path prompt and and suppress the ok response or revert back to normal Forth ok
}

pub PROMPT ( on/off -- )        DUP NOT OK ' .PATH AND prompt W! ;




--- DIRECTORY LISTING ---

{
DIRECTORY ENTRY

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

{
--- print the symbol(s) for each active directory name attribute
pri .ATR ( atr -- )
    " rhsvda" SWAP 6
     FOR
       DUP 1 AND IF OVER C@ EMIT ELSE ." ." THEN
       2/ SWAP 1+ SWAP
     NEXT 2DROP
    ;
}
pri .ATR ( atr -- )
    " rhsvda" 6
     FOR
       OVER 1 AND IF DUP C@ EMIT ELSE DOT THEN
       SWAP 2/ SWAP 1+
     NEXT 2DROP
    ;

pri .FSIZE	@FSIZE I+ @ $2A0A PRINTNUM ;

( FIRMWARE.ROM .....a 0000.620A    07/07/2014 11:58:14   5,536 )

pri .DIR ( addr -- )
     --- ignore blank entries as closed
     DUP C@
     IF
---	print the file name with spaces included (formatted listing)
      DUP 8 CTYPE DOT DUP 8 + 3 CTYPE
--- 	print attributes as alphas
       SPACE DUP @ATR + C@ .ATR SPACE
--- 	print sector number
      DUP StartSector .LONG
       4 SPACES DUP @FDATE + W@  DUP .FDATE
       SPACE .FYEAR
       SPACE @FTIME + W@ .FTIME
       SPACE .FSIZE
     ELSE
        DROP ." *CLOSED*"
     THEN
    ;

pri (.DIR) I CR .DIR ;


{
DIR     PBJTECH.SDL
------------------------------------------------------------------------------
NAME    .EXT ATRS   SECTOR     DATE       TIME       SIZE
CE1372  .JPG .....a 0000.7C17    20/06/2013 02:36:52   736,486
}

WORD udir

pub (SLIST) ( method -- )
    udir W!
     1 FILE FCLOSE                    	--- always use FILE#1 for directory and any temp read only
    cwdsect @ S/C            		--- scan and list rootdir by sector up to one cluster long
    ADO
       I SECTOR
       ACTIVE?
       IF
         SDBUF BLKSIZ                 	--- scan the buffer for dir entries
         ADO                    	--- up to 16 dir entries/sector
           @ATR I+ C@ $0F >            --- accept only valid entries
           IC@ $80 < AND            	--- but ignore if 1st character has 8th bit set
           IC@ '?' <> AND            	--- ignore "deleted" entries
            IF udir W@ CALL THEN        --- all good, list this one using the directed method
         BL +LOOP                    	--- next dir entry 32 bytes (assumes standard 8.3)
       ELSE
         LEAVE                    	--- no more dir sectors - leave loop
       THEN
    LOOP
    ;

pri (DIR) ( code -- )
    ?MOUNT
     CR drive$ PRINT$ pwd .VOL
     (SLIST)
     ;
pub DIR
---         CE1372  .JPG .....a 0000.7C17    20/06/2013 02:36:52   736,486
---  CR ." NAME    .EXT ATRS   SECTOR       DATE       TIME       SIZE "
    ' (.DIR) (DIR) --- use this method for listing the directory
    ;

--- Print the file name at the current loop index I
pub .FNAME ( --- )
     IC@ BL >                            --- skip invalid index/entry
     IF
       $10 @ATR I+ SET? IF '[' EMIT THEN
       11 0 DO
         J I+ C@ DUP BL > IF I 8 = IF '.' EMIT THEN DUP EMIT THEN DROP
       LOOP
       $10 @ATR I+ SET? IF ']' EMIT THEN
     THEN
;

--- print the Unix time or year if the file is older than 6 months
pri .UTIME (  -- )
---  print time
      2 SPACES I @FTIME + W@ .FTIME                    --- read file modification time
    ;


byte lscnt

{ directory list method for ls
D:/ SD64G
[HELP    ]     EASYFILE.FTH   EXTEND  .FTH   EASYNET .FTH   LIFE    .FTH
CALCDEMO.FTH   KJV     .TXT   SEE     .FTH   SPLAT-V4.FTH   WARPEACE.TXT
LOVE    .WAV   POPCORN .WAV   CVA9V26 .JIC   TF2     .OGV   WEBSTERS.TXT
ILIAD   .TXT   PRIDE   .TXT   MIDENG  .TXT   VULGAR  .TXT   ROUGES  .TXT
LEXICON .TXT   WARWORLD.TXT   VALIANT .WAD     ok
}
pri (ls)
--- 5 files per line
     lscnt C@ 5 MOD 0= IF CR THEN
--- format a directory name
     $10 @ATR I+ SET?
     IF
       '[' EMIT I 8 CTYPE ']' EMIT 5 SPACES             --- Use [ ] to enclose name
     ELSE
       I 8 CTYPE                             --- normal, print name and opt ext
       8 I+ C@ BL <>
         IF  DOT 8 I+ 3 CTYPE 3 SPACES ELSE 7 SPACES THEN
     THEN
     lscnt C++
    ;

--- List a single directory entry in FTP compatible format
pri (.LIST) ( <index> )
      ." -rwxrwxrwx 1 502     500"				// dummy permissions
      .FSIZE				// print file size "1048576"
      SPACE
      @FDATE I+ W@ .FDATE					// DATE "24"

--- most systems expect either the time or the year if it is older than 6 months
       .UTIME
       SPACE .FNAME CR						// FILE NAME "LOG0001.TXT"
    ;

pub .LIST        ' (.LIST) (SLIST) ;				// set list method


--- list the directory in wide and simple format
--- ls -l in long format

pre ls
     delim 1+ C@ BL =
     IF
       GETWORD " -l" $=
       IF CR .LIST EXIT THEN
     THEN
     lscnt C~ ' (ls) (DIR)
    ;


pub .FX				CR ." #" DUP PRINT SPACE FILE @DIRBUF .DIR ;
pub .FILE			FILE# .FX ;

pub .FILES			FILE# 4 0 DO I .FX LOOP FILE  ;


{ HELP QV ( <filename> -- )
Quick view of file header in ASCII dump format
QV<cr> will display current file if opened
}
pre QV  delim 1+ C@ BL = IF GETWORD DUP C@ IF FOPEN$ THEN DROP THEN FSECT@ 0EXIT 0 $400 FS DUMPA ;


{  SD BOOTLOADER

P2 SECTOR ZERO BOOT SIGNATURE

The proposed ROM bootloader would only need to init the raw SD card without regard to FAT32 or any format in fact
and reads the signature on sector 0 and if it is the P2BOOT.IMG file name it will
read the starting sector for the boot image from offset $20 in sector 0
then read in from there into memory for the image size specified in offset $24

DUMP OF THE FIRST 64 bytes OF SECTOR ZERO
00.0000: 50 32 42 4F 4F 54 20 20 49 4D 47 20 00 64 49 6C    P2BOOT  IMG .dIl
00.0010: 79 48 79 48 00 00 E6 73 58 44 CC 02 00 00 10 00    yHyH...sXD......
00.0020: 80 F2 00 00 00 00 10 00 2A 00 04 00 00 00 00 00    ........*.......
00.0030: 47 5B 02 00 69 73 02 00 00 00 00 00 00 00 00 00    G[..is.......... ok


Where
$00..$1F = Copy of directory entry for P2BOOT.IMG
$20..$23 = Starting sector of boot file in contiguous blocks
$24..$27 = Number of bytes to load
$28..$2B = Directory entry address encoded as sector<<4 + 4-bits as 1 of 16 directory entries/sector (64GB address range)
$30..$33 = HH:MM:SS time encoded as pure decimal (i.e. 3.45.12 PM is 34512 )
$34..$37 := YY:MM:DD date encoded as pure decimal

Checking this a little:
TF2# $20 $20 SD DUMPL
00.0020: 0000.F280 0010.0000 0004.002A 0000.0000    ........*.......
00.0030: 0002.5B47 0002.7369 0000.0000 0000.0000    G[..is.......... ok

TF2# $30 x@ . 154439 ok
TF2# $34 x@ . 160617 ok



}

--- backup memory into P2BOOT.IMG for the size specified in k and setup sector 0
--- takes around 7 seconds on CV-A9 at 80MHz for 1MB image ~= 3ms/blk or 0.5sec for 64k
pub SAVE
pub SDBACKUP ( kbytes -- )					--- size in kilobytes where 128 = 128k
	" P2BOOT.IMG" FOPEN$					--- try to open default boot image but exit if failed
	IF
	  1 MAX 1024 MIN 10 <<					--- limit between 1k and 1M and shift up kbytes to bytes
	  FSECT@ 0 3RD						--- use raw file's starting sector from start for size
	    ADO I OVER SDWR DROP 1+ SPINNER BLKSIZ +LOOP DROP	--- write the image with a little spinning progress symbol | / - \
	  @DIRBUF 0 XADR BL CMOVE				--- make a copy of the directory entry for reference and detection in sector 0
	  FSECT@ $20 X!                      			--- Setup a pointer to the raw file starting sector
	  DUP $24 X!						--- write the file size we are using
	  diradr @FILE @ $28 X!					--- save 64GB encoded pointer to the directory entry
	  TIME@ $30 X!						--- time and date stamp
	  DATE@ $34 X!
	  WRSECT                                          	--- write the sector to the card
	  SWAP .DECL ."  bytes written"		--- Confirmation
	THEN
	DROP							--- discard size or wrsect flag
	;
\ ALIAS SDBACKUP SAVE

{

WORD sdtask

pub SD.TASK
	!SP !FS NULLOUT
	BEGIN
	  !SP sdtask W@ ?DUP IF file$ SWAP CALL sdtask W~ THEN
	AGAIN
;

--- To run from another cog - ' FOPEN$ sdtask W!

--- To list inserted cards automatically
BEGIN CARD? IF E: lscnt C~ ' (ls) (DIR) BEGIN CARD? 50 ms CARD? OR 0= UNTIL THEN KEY UNTIL

171210
TAQOZ# $20000 256 KB LAP FREAD LAP .LAP 21642561 cycles = 270.532ms  ok
TAQOZ# LAP 0 SECTOR LAP .LAP 70594 cycles = 882.425us ok
TAQOZ# LAP 1 SECTOR LAP .LAP  69842 cycles = 873.25us ok



171122
TAQOZ# LAP 0 SECTOR LAP .LAP 83336 cycles = 1.41ms  ok
TAQOZ# LAP 1 SECTOR LAP .LAP 76552 cycles = 956.900us ok
TAQOZ# LAP 2 SECTOR LAP .LAP 76552 cycles = 956.900us ok

TAQOZ# LAP 0 SECTOR LAP .LAP 83120 cycles = 1.39ms  ok
TAQOZ# LAP 1 SECTOR LAP .LAP 76464 cycles = 955.800us ok
TAQOZ#

171123
TAQOZ# LAP 0 SECTOR LAP .LAP 89313 cycles = 1.116ms  ok
TAQOZ# LAP 1 SECTOR LAP .LAP 73745 cycles = 921.812us ok
}


\ SDATE@ build.date E! TIME@ build.time E!
]~
END
\ !FS
