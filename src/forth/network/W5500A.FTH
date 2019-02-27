TAQOZ

FORGET W5500.fth

pub W5500.fth		." WIZNET W5500 driver for TAQOZ " ;


--- some default IP settings that are only loaded in on a new pcb and if storage locations in upper eeprom is blank
&192.168.0.1		:= myGW
&192.168.0.150		:= myIP
&255.255.255.0		:= mySN



( HARDWARE DEFINITIONS )


{ W5500 SPI frame format
ADDRH ADDRL CONTROL <DATA>
7..5	SKT
4,3	X,REG,TX,RX
2	R/W
1,0	00 = VARIABLE LEN DATA
}

IFNDEF @wizpins
&20.23.22.21	:= @wizpins
}
pub WIZPINS	' @wizpins 2+ ! ;

--- Write and update CONTROL byte
pri RDWIZ						0
---							ctl byte
pri WIZADR ( wr -- )					SWAP @wizpins SPIPINS SPIWW
--- entry point only for reference by SWC!33
pri SWC							0_0 OR SPIWB ;
pri WRWIZ						4 WIZADR ;

pub @COMMON ( 6.8us )					0 $F8
--- write directly to the control byte literal embedded in SWC
pri SWC! ( or andn -- )					' SWC C@ SWAP ANDN OR ' SWC C! ;
pub @RX							$18 $18 SWC! ;
pub @TX							$10 $18 SWC! ;
pub @SOCKET						8 $18 SWC! ;

\ BYTE skt1
byte skt2
---							socket constant
pub SKT@						0_0 ;
---		Set the socket number ( calculates address and sets as a SOCKET constant )
pub SKT
pub SOCKET ( skt -- )					DUP ' SKT@ C! 5 << $E0 SWC! ;

--- READ/WRITE METHODS ---
pub LC! ( byte wizadr -- ) ( 17.5us )			WRWIZ SPIWB SPICE ;
pub LW! ( word wizadr -- ) ( 18.8us )			WRWIZ SPIWW SPICE ;
pub L! ( long wizadr -- ) ( 21.1us )			WRWIZ SPIWL SPICE ;

pub LC@ ( wizadr -- byte ) ( 16.8us )			RDWIZ 0 SPIRD SPICE ;
pub LW@ ( wizadr -- word ) ( 18.0us )			RDWIZ 0 SPIRD SPIRD SPICE ;
pub L@ ( wizadr -- long ) ( 20.3us )			RDWIZ 0 SPIRDL SPICE ;

--- BLOCK TRANSFER METHODS ---
--- Read a block of memory from the WIZnet
pub LREAD ( src dst cnt -- )				ROT RDWIZ SPIRX DROP SPICE ;

--- Write a block to the WIZnet - 558us/512 bytes
pub LWRITE ( src dst cnt -- )				SWAP WRWIZ SPITX SPICE ;



( ----------------------------------- REGISTER LEVEL INTERFACE -------------------------------- )

--- EEPROM CONFIG BACKUP ---
--- Use the top part of the 64K EEPROM to save IP settings

$FFC0	:= @gateway
$FFC4	:= @sip
$FFC8	:= @subnet
$FFCC	:= @mac
$FFD0	:= @wcold
$FFE0	:= @ports

\ common registers

--- Access common registers
pub wMODE ( mask -- )			0 @COMMON LC! ;
pub GATEWAY ( addr -- )			DUP @gateway EE! 1 @COMMON L! ;
pub SUBNET ( mask -- )			DUP @subnet EE! 5 @COMMON L! ;
pub MAC ( high low  -- )		DUP @mac EE! $0B @COMMON L! 9 LW! ;
pub SIP ( long -- )			DUP @sip EE! $0F @COMMON L! ;


pri INTS@ ( -- ints )			$15 @COMMON LC@ ;
pri INTMASK ( mask -- )			$16 @COMMON LC! ;


pri @RTR ( -- adr )			$19 @COMMON ;
pri @RCR ( -- adr )			$1B @COMMON ;

pri UIP ( ip -- )			$28 @COMMON L! ;
pri UPORT ( port -- )			$2C @COMMON LW! ;



( SOCKET INTERRUPTS )
4	|< := 	&SENDOK
3	|< := 	&TIMEOUT
2	|< := 	&RECV
1	|< := 	&DISCON
0	|< := 	&CON
{
( SOCKET STATUS CODES )
$00	:=	SOCK_CLOSED
$13	:=	SOCK_INIT
$14	:=	SOCK_LISTEN
$17	:=	SOCK_ESTABLISHED
$1C	:=	SOCK_CLOSE_WAIT
$22	:=	SOCK_UDP
$32	:=	SOCK_IPRAW
$42	:=	SOCK_MACRAW
$5F	:=	SOCK_PPOE

( SOCKET TRANSIENT STATUS CODES )
$15	:=	SOCK_SYNSENT
$16	:=	SOCK_SYNRECV
$18	:=	SOCK_FIN_WAIT
$1A	:=	SOCK_CLOSING
$1B	:=	SOCK_TIME_WAIT
$1D	:=	SOCK_LAST_ACK
$11	:=	SOCK_ARP
$21	:=	SOCK_ARP1
$31	:=	SOCK_ARP2
}


\ Socket registers ( -- addr )
pri sMODE		0 @SOCKET ;		--- mode
pri sCMD!		1 @SOCKET LC! ;		--- command
pri sINTS		2 @SOCKET ;		--- interrupts
pri sSTAT@		3 @SOCKET LC@ ;		--- status
pri sPORT		4 @SOCKET ;		--- 2 byte src port
pri sDHAR		6 @SOCKET ;		--- 6 byte dest hardware address
pri sDIP		$0C @SOCKET ;		--- 4 byte dest IP address
pri sDPORT		$10 @SOCKET ;		--- 2 byte dest port
pri sSSIZE		$12 @SOCKET ;		--- 2 byte dest max seg size
pri sPRO		$14 @SOCKET ;		--- protocol in IP raw mode

pri sRXMEM		$1E @SOCKET ;
pri sTXMEM		$1F @SOCKET ;
pri TXFREE@		$20 @SOCKET LW@ ;
pri TXREAD		$22 @SOCKET ;
pri TXWRITE		$24 @SOCKET ;
pri RXSIZE@		$26 @SOCKET LW@ ;
pri RXREAD		$28 @SOCKET ;
pri RXWRITE		$2A @SOCKET ;
pri KEEPTMR		$2D @SOCKET ;	--- keep alive timer

\ Protocol modes
pri CLOSED		0 sMODE LC! ;
pub TCP			1 sMODE LC! ;
pub UDP			2 sMODE LC! ;
pri IPRAW		3 sMODE LC! ;
pri MACRAW		4 sMODE LC! ;
pri PPPoE		5 sMODE LC! ;





( SOCKET COMMANDS - use currently select socket )

pub sOPEN		1 sCMD! ;
pub sLISTEN		2 sCMD! ;
pub sCONNECT		4 sCMD! ;
pub sDISCON		8 sCMD! ;
pub sCLOSE		$10 sCMD! ;
pub sSEND		$20 sCMD! ;
pub sSENDMAC		$21 sCMD! ;
pub sSENDKEEP		$22 sCMD! ;
pub sRECV		$40 sCMD! ;


pri sCLOSED? 		sSTAT@ 0= ;
pri sINACTIVE?		sSTAT@ $17 < ;
pri sESTAB?		sSTAT@ $17 = ;
pri sCLOSING?		sSTAT@ $18 $1B WITHIN ;	--- closing or wait closing
pri sCONNECTED?		sINTS LC@ &CON AND DUP IF &CON sINTS LC! THEN ; --- Test and reset the connection interrupt;
pri sDISCON?		sINTS LC@ &DISCON AND DUP IF -1 sINTS LC! THEN ;





pub SetPORT
 	sPORT LW!
 	;
pub PORT! ( srcport -- ) --- save port config and set port
 	DUP SKT@ 4* @ports + EE!
	SetPORT
	;

( Set the factory defaults on very first run - generate a random MAC in the 01.FF.xx.xx.xx.xx range )
pub WCOLD
	CRLF ." Setting default IP configuration "
 	myGW @gateway EE!
 	myIP @sip EE!
 	mySN @subnet EE!
 	RND @mac EE! 				\ random MAC at first run, Need to have a unique ID
 	8 0 DO 0 I 4* @ports + EE! LOOP
 	$A55A @wcold EE!
 	;

\ Init the SPI for the WIZnet chip
pub !WIZIO
	@wizpins SPIPINS				\ Use SPI
	@COMMON
	;

$02FF := oui2

pub !WIZIP
 	@wcold EE@ $A55A <> IF WCOLD THEN
	@gateway EE@ GATEWAY			\ Assign a default gateway
	@subnet EE@ SUBNET
	@sip EE@ SIP
	oui2 @mac EE@ MAC
  	8 0 DO I 4* @ports + EE@ I SOCKET SetPORT LOOP
	;

pri !TXBUFS	8 FOR I SOCKET BUFFER $800 ERASE @TX BUFFER 0 $800 LWRITE @RX BUFFER 0 $800 LWRITE NEXT ;

pub !WIZ 	!WIZIO !TXBUFS !WIZIP ;


{ Since the W5500??? read and write index registers are unreadable until a connection has been established
or cannot be written incrementally until a send then these are buffered for when they become readable
}

16 bytes txwr 						--- tx write buffers for 8 sockets

pub @txwr ( -- addr )   	txwr SKT@ 2* + ;

pub !TXWR		txwr 16 $FF FILL ;				--- invalidate all txwr pointers (W5500 workaround)

long txtime
long txsize

byte autosend							--- Flag to control whether LANSEND sends when it receives a LF or not
$0A autosend C!							--- preset to autosend

\ TIMER sendtimer
pri WAITSEND
 	txsize @ 0EXIT 						--- don't bother if it's empty
	1000
 	FOR
 	  sINTS LC@ &SENDOK AND 				--- until sent
 	  TXREAD LW@ TXWRITE LW@ = AND
 	?NEXT DROP
 	&SENDOK sINTS LC!					--- reset the sent interrupt flag
 	;

\ Request WIZnet to send off current transmit data in buffer
pub LANSEND
 	&SENDOK sINTS LC!					--- Clear send interrupt
 	@txwr W@ TXWRITE LW! sSEND				--- update TXWRITE register and command WIZnet to SEND
	WAITSEND
  	txsize ~ 						--- reset txsize (buffer empty)
 	;
pub ?SEND							--- check to see if anything still needs to be sent
 	txsize @ 0EXIT						--- Exit if buffer empty
	LANSEND
	;
pub ?SENDPOLL
	txtime @ CNT@ - ABS CLKFREQ 7 >> >			--- 1/128 sec timeout since last
 	0EXIT ?SEND
	;


--- send out a character through the WIZnet - either block mode or autosend
pub LANEMIT ( ch -- )
 	@txwr W@
	OVER SWAP ( ch ch index ) @TX LC!			\ write character to buffer
  	@txwr W++ CNT@ txtime !
 	txsize ++
	$0A = autosend C@ AND					\ SEND if this is an CRLF end of line and autosend is active
 	txsize @ $3F0 > OR 					\ AUTOSEND if buffer size is large enough already
	  IF LANSEND THEN
	;


pub LANKEY ( -- ch )
 	RXSIZE@
 	IF
 	  RXREAD LW@ DUP @RX LC@ 				--- read a character from the receive buffer
 	  SWAP 1+ RXREAD LW! sRECV				--- update read index
 	ELSE
 	  keypoll W@ ?DUP IF CALL THEN				--- implement a keypoll for when LANKEY is doing nothing
 	  0							--- return with a null character
 	THEN
	;

( Redirect console output to the LAN )
pub LAN
	' LANEMIT uemit W!
 	' LANKEY ukey W!
	@txwr @ -1 = IF TXWRITE LW@ @txwr ! THEN		--- force an update (assumed valid) if the index is "invalid"
	;

( diagnostic to the terminal to reflect what is begin typed to the LAN )
pub LANCONEMIT
 	DUP CONEMIT LANEMIT
 	;

( allow input from both the serial console and the LAN socket )
pub LANCONKEY ( -- ch )
 	LANKEY KEY OR
 	;

--- use both LAN and CON for output
pub LANCON
	CON CRLF LAN
 	' LANCONEMIT uemit W!
	;




--- set WIZnet chip as source for any DUMP type operations
pub WIZ    DUMP: LC@ LW@ L@ ;

$800	:= WBUFSZ


pri LSEND 		DUP @txwr W+! TXWRITE LW@ SWAP @TX LWRITE LANSEND ;

long vread
long vwrite --- maintain a read/write pointer for any virtual memory writes


---  Read from WIZnet buffer into file until buffer is exhausted
--- Used by FTP STOR
pri LREADSKT ( dst --- )
	vwrite !
	BEGIN
	  RXSIZE@ ?DUP
	WHILE ( cnt )
	  RXREAD LW@ ( cnt index ) 			--- fetch receive read index for this socket
 	  SWAP
	  vwrite @ SWAP ( wizptr filedst cnt )
	  DUP >R
	  @RX LREAD vwrite ++ 				--- read WIZnet buffer directly into file and update vwrite+1
	  R> RXREAD LW@ + RXREAD LW! 			--- update read index in advance
	  sRECV 						--- signal that buffer up to READ index has been read
	  10 ms
	REPEAT
	;


16 longs sktbuf						--- holding buffer for socket registers

pri @SKTBUF 		sktbuf + ;

pri .IPX	DUP >B .AS" ###" 8>> ;

pub .IP1
	 @SKTBUF @
	.IPX "." EMIT .IPX "." EMIT .IPX "." EMIT .IPX DROP
	;

pri .IP ( off -- )		3 SPACES .IP1 ;



pri .PTR  		C@++ 8<< SWAP C@ + ( $7FF AND ) .WORD "." EMIT ;

pri .@SKTBUF		@SKTBUF .PTR ;

IFNDEF SWAPB
pri SWAPB ( word -- word2 	\ Swap the bytes in a 16-bit word )
 	DUP 8>> SWAP >B 8<< OR
 	;
}


{
SKT HH:MM:SS MODE  PORT DEST  TXRD TXWR RXRD RXWR RXSZ  IR STATUS        	IP ADDR
#1  00:00:00 TCP 	21 52775 967F.967F.	.	.	. 00 17 ESTABLISHED	192.168.016.002.
}
pub .SKTHD		CRLF BOLD ." SKT HH:MM:SS MODE  PORT  DEST TXRD TXWR RXRD RXWR RXSZ  IR STATUS            IP ADDR" PLAIN ;

 pub .SKT
	DUP SOCKET 0 sktbuf $30 @SOCKET LREAD					--- read in registers
	0 @SKTBUF C@ IF CRLF "#" EMIT . 2 SPACES .TIME ELSE DROP BREAK
 	0  @SKTBUF C@ SPACE
	4* " CLSDTCP UDP IPRWMACRPPP !06!!07!" + 4 CTYPE SPACE
	4 @SKTBUF W@ SWAPB 5 U.R SPACE					--- PORT
 	16 @SKTBUF W@ SWAPB 5 U.R SPACE 				--- DPORT
	$22 .@SKTBUF $24 .@SKTBUF						--- TXRD TXWR
 	$28 .@SKTBUF $2A .@SKTBUF						--- RXRD RXWR
 	$26 .@SKTBUF SPACE							--- RX SIZE
  	2 @SKTBUF C@ .BYTE SPACE						--- INT REG
 	3 @SKTBUF C@ DUP .BYTE							--- STATUS REG
\	pri .SSTAT ( byte -- )							--- STATUS DESCRIPTION
 	SWITCH SPACE
 	  0 CASE ." closed      " BREAK
 	$13 CASE ." INIT        " BREAK
 	$14 CASE ." LISTEN      " BREAK
	$16 CASE ." SYNRECV     "  $0C .IP BREAK
   	$17 CASE ." ESTABLISHED "  $0C .IP BREAK
  	$18 CASE ." FIN WAIT    "  $0C .IP BREAK
 	$1C CASE ." closed wait " $0C .IP BREAK
 	$22 CASE ." UDP OPEN    " BREAK
 	$32 CASE ." IPRAW OPEN  " BREAK
 	;

pub .SOCKET ( n -- )	.SKTHD .SKT ;

pub .SOCKETS
	.SKTHD 8 0 DO I .SKT LOOP CRLF
	;
pub ifconfig
	0 sktbuf $40 @COMMON LREAD	\ read in common registers
 	BOLD
	CRLF ." NETWORK STATUS:" PLAIN
 	CRLF ." LINK " 		1 $2E @SKTBUF SET? IF ." *UP*" ELSE ." DOWN" THEN
	CRLF ." HARDWARE: " PCB$ PRINT$ ."  using WIZnet W5500 V" $39 @SKTBUF C@ .
 	CRLF ." SRC IP "	$0F .IP
 	CRLF ." MASK   "	5 .IP
 	CRLF ." GATEWAY"	1 .IP
	CRLF ." MAC       "	9 @SKTBUF 6 ADO I C@ .BYTE ." ." LOOP
	.SOCKETS
	;

\ SOCKETS - W5500 has 8 sockets - define 4 of them
0	:= NETMAN --- network management
1	:= FTP
2	:= FTPDAT
3	:= TELNET
4	:= HTTP --- uses sockets 4..7
32 bytes skt$ " NETFTPDATTELWEBWEBWEBWEB" skt$ $!

END
