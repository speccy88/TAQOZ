TAQOZ



IFDEF EASYNET.fth
FORGET EASYNET.fth
}

pub EASYNET.fth		." WIZNET NETWORK SERVERS 160707.1500 " ;


: FILEIN	KEY: FGET ;
: FSIZE@	dirbuf 28 + @ ;
: FILE$		dirbuf ;
: RENAME$	2DROP ;
: RIGHT$	DUP LEN$ ROT - + ;
: (cat)		0 SD PRINT$ ;
: .LIST		 ;
: APPEND	DROP ;
: RW		;
: FSTAMP	;

long @FWRITE


pub READYLED		DROP ;
pub LANLED		DROP ;
pri LEDS		NOP ;


pub LOCATE$ ( ch str -- str \Locate the first ch in the string and return else null )
	0 SWAP DUP LEN$ ADO OVER I C@ = IF DROP I LEAVE THEN LOOP
	NIP
	;

pub COMPARE$ ( str1 str2 -- flg \ Compare two strings for equality )
	OVER LEN$ OVER LEN$ =
	IF
	DUP LEN$
	ADO C@++ I C@ <> IF DROP 0 LEAVE THEN LOOP
	0<>
	ELSE 2DROP FALSE
	THEN
	;


pri UNKNOWN
 	delim C@ 1+ $0D <> IF BEGIN KEY $0D <> WHILE DROP REPEAT THEN		\ if there is more than get it and discard
	LANCON ." 550 Unknown command " @WORD PRINT$ CRLF LANSEND
	;

word un
IFNDEF QUIET
\ Turn the Forth console into a quiet non-echoing/prompting command interpreter
pub QUIET
	IF
 	  OFF ECHO OFF OK				--- Non-interactive mode - just accept "commands"
	  ' NOP 					--- Disable auto space (added when the console processes a word)
	  ' UNKNOWN 					--- Respond with negative FTP style message for unknown
 	ELSE
 	  ON ECHO ON OK
 	  0 0						--- reset unum and prompt - default shell processing
 	THEN
 	unum W! DUP uprompt W! uprompt 2+ W!				--- set vector for further processing if not found or not number
	;
}


\ LANLED blink variables
byte ledcnt
byte ledon


( Console diagnostic message handler )
byte msgs
pub MSGS ( on/off -- ) msgs C! ;

long msgstk
pri <MSG ( level -- )				--- print message to console if message priority is => message setting with 0 being the highest
	uemit @ msgstk ! msgs C@ <=
 	  IF CON ELSE NULLOUT THEN
 	CR REVERSE .DT ."  #" SKT@ DUP PRINT SPACE 3 * skt$ + 3 CTYPE SPACE
 	;
pri MSG>	PLAIN CRLF msgstk @ uemit ! ;


pri FlushSkt				@WORD 1- BL ERASE ;		--- erase any garbage that has already been accumulated


{ HELP LANSKT ( -- )
Set console's socket backup to the current one - allows console processing of server commands
}
pub LANSKT				SKT@ skt2 C! LAN ;

{ HELP UpdateTXWR
Due to limitations of WIZnet read/write register access a copy is maintained and updated when possible
}
---					TXWRITE is now readable - buffer it
pri UpdateTXWR				TXWRITE LW@ @txwr W! ;


TIMER contd

---					ms 300 seconds = 5 MINS
pri KEEPALIVE				300,000 contd TIMEOUT ;


--- background timer cog can only request a disconnect
byte disreq
--- timeout sets disreq flag which is handled by main loop
pri DISCREQ				disreq C~~ ;

pub CONNECTED? ( -- flg )
---	Has CONNECT interrupt been set?
	sCONNECTED?
	DUP IF
---	Setup Tachyon to handle command/response mode
	  OFF ECHO UpdateTXWR
	  ( 1 <MSG ." CONNECT " MSG> )
---	let console know what is happening
	  CON SKT@ .SOCKET
---	discard any console input as well
 	    BEGIN BEGIN KEY 0= UNTIL 3 ms KEY 0= UNTIL
---	flush out anything already sitting there
 	  LAN KEEPALIVE ON LANLED FlushSkt
	  ' DISCREQ contd ALARM
	THEN
	;
{ HELP DISCONNECT
Disconnect socket (which may progress through DISCON WAIT) and flip the shell back to the console
Report the socket status
}
pub DISCONNECT				sDISCON CONIO SKT@ .SOCKET LAN ;

pub DSCTD? ( -- flg )
	disreq C@ sESTAB? AND
---	process disconnect req if active
 	  IF DISCONNECT disreq C~ 0 contd ALARM THEN
---	or if it's closed OR closing or $1C? (gets stuck on CLOSE WAIT??)
 	sCLOSED? sCLOSING? OR sSTAT@ $1C = OR
---	disconnect interrupt? OR closed - ok
 	sDISCON? OR DUP
 	IF
	( 1 <MSG ."   LISTENING " MSG> )
	  sCLOSE sOPEN sLISTEN
 	  OFF QUIET
	  OFF LANLED
 	  FlushSkt CONIO
 	  SKT@ .SOCKET
	THEN
	;
{
pri DISCONNECTED? ( -- flg )
	disreq C@ sESTAB? AND
 	  IF DISCONNECT disreq C~ 0 contd ALARM THEN 			--- process disconnect req if active

 	sCLOSED? sCLOSING? OR 						--- or if it's closed OR closing or $1C?
 	sSTAT@ $1C = OR						--- CLOSE WAIT - check this out - gets stuck on this
( #2  22:09:58 TCP 	80 39416 EE08.EE08.  83.  83.	. 00 1C closed wait	150.070XXXX )
 	sDISCON? OR DUP 							--- disconnect interrupt? OR closed - ok
 	IF
	( 1 <MSG ."   LISTENING " MSG> )
	  sCLOSE sOPEN sLISTEN
 	  OFF QUIET
	  OFF LANLED
 	  FlushSkt CONIO
 	  SKT@ .SOCKET
	THEN
	;
}
pri CONNECT
	( 1 <MSG ." CONNECTING " )
	3000 contd TIMEOUT							--- allow up to 3 seconds to connect
	  BEGIN sESTAB? contd TIMEOUT? OR UNTIL 				--- Wait for it to be established (WIZNET regsiter quirks)
 	KEEPALIVE
	TXWRITE LW@ @txwr W! 						--- refresh txwrite (treat as new connection)
	( ." ---  CONNECTED " MSG> )
	;

byte constat 									--- relay connection status to application
pri STAT!		constat C! ;

{ TELNET IACs
pri /DO		253
pri IAC ( cmd -- ) 255 EMIT EMIT ;
pri /SB		250 IAC ;
pri /SE		240 IAC ;
pri /WILL		251 IAC ;
pri /WONT		252 IAC ;
pri /DONT		254 IAC ;

pri /NAWS		31 EMIT ;
pri /LINEMODE 	34 EMIT ;
pri /ECHO		1 EMIT ;
}


--- define a "bye" especially for telnet sessions.

: BYE	DISCONNECT ;
: QUIT	DISCONNECT ;

pri ?TELNET
---	check telnet socket new connection?
	TELNET SOCKET CONNECTED?
	IF
---	indicate connection status active as Telnet
 	  "T" STAT!
---	be interactive but not reset etc with certain controls
  	  1 flags 1+ SET
	  ledcnt C~
\ 	  CON CR LAN
---		let 1/128 timeout handle characters or blocks
	  LAN  autosend C~
---	execute IAC script to setup remote telnet client
	  " TELNET.INI" FOPEN$ IF FILEIN THEN
 	  WAITSEND 	  " WELCOME.TEL" FOPEN$
 	    IF (cat)
---	default Welcome banner
 	    ELSE ." WELCOME TO THE TACHYON WIZNET TELNET SESSION!" CRLF
 	    THEN
---	Reset rx buffer and receive --- redirect console to this LAN socket
	  FlushSkt LANSKT
 	  OFF QUIET OFF ECHO
	  KEEPALIVE
	THEN
---	Process disconnection
	DSCTD? IF
 	  ( 0 <MSG ." SESSION ENDED " CR MSG> )
 	  "t" STAT! CONIO
 	  1 flags 1+ CLR
 	THEN
	;


pub RESOLVE ( namestr -- ip )
 	HTTP SOCKET
 	;
{
HTTP/1.0 302 Found
Cache-Control: private
Content-Type: text/html; charset=UTF-8
Location: http://www.google.com.au/?gfe_rd=cr&ei=UH_EVO24O63u8wfd74GYAQ
Content-Length: 262
Date: Sun, 25 Jan 2015 05:29:52 GMT
Server: GFE/2.0
Alternate-Protocol: 80:quic,p=0.02

<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>302 Moved</TITLE></HEAD><BODY>
<H1>302 Moved</H1>
The document has moved
<A HREF="http://www.google.com.au/?gfe_rd=cr&amp;ei=UH_EVO24O63u8wfd74GYAQ">here</A>.
</BODY></HTML>
}
pub GETTIME
 	HTTP SOCKET
 	" google.com" RESOLVE HTTP SOCKET $0C L!			--- contact google.com and set dest IP
 	LAN ." GET /" CRLF						--- issue GET request

 	--- Date: Sun, 25 Jan 2015 05:29:52 GMT


 	;


\ Print the byte as a decimal number
pri .BYTEDEC ( byte -- )		>B .DEC ;

pri COMMA				"," EMIT  ;

pri .IPD ( long -- ) 	DUP 24 >> .BYTEDEC COMMA DUP 16>> .BYTEDEC COMMA DUP 8>> .BYTEDEC COMMA .BYTEDEC ;


16 bytes user$ " user" user$ $!

16 bytes pass$ " pass" pass$ $!

word dataport

20 dataport W!			\ Default FTP data port


pri GETFNAME
	GET$ DUP C@ "/" = IF 1+ THEN						--- adjust name if / is used
 	DUP LEN$ 1- OVER  + C@ "." = IF 0 OVER DUP LEN$ 1- + C! THEN 		--- remove final period
 	;


pri ECHOREQ
 	CON CRLF BEGIN LANKEY DUP EMIT 0= UNTIL					--- Just echo the request to the console for now
 	;

( FTP COMMANDS )
( FTP COMMANDS LINK )


{ HELP USER
FTP COMMAND
Syntax: USER username
Send this command to begin the login process. username should be a valid username on the system, or "anonymous" to initiate an anonymous login.
}
pre USER
	ON LANLED
	GET$ user$ $!
	." 331 User admin OK. Password required" CRLF
	;

pre PASS
	ON LANLED
	GET$ pass$ $!
	." 230 OK. Current restricted directory is /" CRLF
	;

long type

{ HELP TYPE
FTP COMMAND
Syntax: TYPE 	type-character [second-type-character]
Sets the type of file to be transferred. type-character can be any of:
A - ASCII text
E - EBCDIC text
I - image (binary data)
L - local format
For A and E, the second-type-character specifies how the text should be interpreted. It can be:
N - Non-print (not destined for printing). This is the default if 	second-type-character is omitted.
T - Telnet format control (<CR>, 	<FF>, etc.)
C - ASA Carriage Control
For L, the second-type-character specifies the number of bits per byte on the local system, and may not be omitted.
}
pre TYPE
	ON LANLED
	GET$ type 4 CMOVE
	LAN ." 200 TYPE is now " type C@ EMIT CRLF
	;

{ HELP PORT
FTP COMMAND
Syntax: PORT 	a1,a2,a3,a4,p1,p2
Specifies the host and port to which the server should connect for the next file transfer.
This is interpreted as IP address a1.a2.a3.a4, port p1*256+p2.
}
pre PORT 	\ accept port number
	ON LANLED
	GET$ NUMBER dataport W!
	LAN ." 200 Port is now " dataport W@ .DEC CRLF
	;

\ Define min and max for FTP passive ports
40,000 	:= #ftpmin
50,000 	:= #ftpmax

\ 227 Entering Passive Mode (192,168,16,106,248,252)
{ HELP PASV
FTP COMMAND
Syntax: PASV
Tells the server to enter "passive mode". In passive mode, the server will wait for the client to establish a connection with it rather than attempting to connect to a client-specified port. The server will respond with the address of the port it is listening on, with a message like:
227 Entering Passive Mode 	(a1,a2,a3,a4,p1,p2)
where a1.a2.a3.a4 is the IP address and p1*256+p2 is the port number.
}
pre PASV
	ON LANLED
	#ftpmax #ftpmin GETRND dataport W!						\ pick a random port in the specified range
	FTPDAT SOCKET sCLOSE 								\ Prep the data port socket
	TCP dataport W@ SetPORT sOPEN sLISTEN   					\ Set the port and open listen for connection
 	( 1 <MSG ." FTPDAT CONNECT " MSG> )
	\ respond that all is accepted
	FTP SOCKET LAN									\ switch back to FTP socket
	." 227 Entering Passive Mode with port " \ dataport W@ .DEC		\ Response with msg and port
	." (" @sip EE@ .IPD COMMA dataport 1+ C@ .BYTEDEC COMMA dataport C@ .BYTEDEC ." )" CRLF
	;

{ HELP SYST
FTP COMMAND
Syntax: SYST
Returns a word identifying the system, the word "Type:", and the default transfer type (as would be set by the TYPE command).
For example: UNIX Type: L8
}
pre SYST
	ON LANLED
	." 215 Unix Type: L8" CRLF
	;




pre FEAT
	ON LANLED
	." 211 no Features supported" CRLF
{	." 211-no Features supported" CRLF
 	."  yet to be implemented" CRLF
 	." 211 End" CRLF
}
	;

{ HELP MDTM
FTP COMMAND
  The server-PI will respond to the MDTM command with a 213 reply
   giving the last modification time of the file whose pathname was
   supplied, or a 550 reply if the file does not exist, the modification
   time is unavailable, or some other error has occurred.

      mdtm-response = "213" SP time-val CRLF /
                      error-response
Example response:
213 19980615100045.014
}
pre MDTM
 	ON LANLED
  	GETFNAME FOPEN$ DROP
 	autosend C~~
	." 550 Modification time not available" CRLF
	;


{ HELP CDUP
FTP COMMAND
Syntax: CDUP
Makes the parent of the current directory be the current directory.
}
pre CDUP
	  ON LANLED
	." 250 Directory successfully changed" CRLF
	;


16 bytes cwd$ " FILENAME.TXT " cwd$ $!

{ HELP CWD
Syntax: CWD remote-directory
Makes the given directory be the current directory on the remote host
}
pre CWD ( <name> )
	ON LANLED
	GET$ DUP cwd$ $! DUP " /" $= SWAP LEN$ 0= OR
 	IF
 	  ." 250 okay"
	ELSE
	  ." 550 Not a directory"
	THEN
 	CRLF
	;

{ HELP PWD
Syntax: PWD
Returns the name of the current directory on the remote host.
}
pre PWD
	ON LANLED
	." 257 " $22 EMIT "/" EMIT $22 EMIT ."  is your current location" CRLF
	;



pub ?DISCONNECT   	300 ms DISCONNECT ;

{ HELP LIST
FTP COMMAND
Syntax: LIST [remote-filespec]
If remote-filespec refers to a file, sends information about that file. If remote-filespec refers to a directory, sends information about each file in that directory. remote-filespec defaults to the current directory. This command must be preceded by a PORT or PASV command.
}
pre LIST
 	delim 1+ C@ BL = IF GET$ DROP THEN                 --- ignore a remote-filespec
 	uemit W@ --- allow this to be dumped to the console in interactive mode
 	IF
	  KEEPALIVE
	  ON LANLED LANCON	." 150 Here comes the directory listing" CRLF LANSEND
	  ( 1 <MSG ." LIST REQUEST " MSG> )
	  FTPDAT SOCKET CONNECT
 	  autosend C~
	  LAN .LIST							--- Send off the directory listing in compatible format
	  LANSEND WAITSEND
 	  50 ms
	  FTPDAT SOCKET DISCONNECT
	  autosend C~~
	  FTP SOCKET LANCON ." 226 Directory send OK" CRLF LANSEND
	  ( 1 <MSG ." LIST SENT " MSG> )
	  ?DISCONNECT
 	ELSE
	  CRLF .LIST
	THEN
	;

{ This is how most UNIX, Novell, and MacOS ftp servers send their time
                                  Jul 06 12:57 or Jul  6  1999
-rwxrwxrwx	1 502  	500 	674 Sep  4  2014 HELP.TXT
-rwxrwxrwx	1 502  	500   65536 Sep  4  2014 FIRMWARE.ROM
}
{ Feature list from NAS FTP
211-Extensions supported:
 EPRT
 IDLE
 MDTM
 SIZE
 REST STREAM
 MLST type*;size*;sizd*;modify*;UNIX.mode*;UNIX.uid*;UNIX.gid*;unique*;
 MLSD
 TVFS
 ESTP
 PASV
 EPSV
 SPSV
 ESTA
 AUTH TLS
 PBSZ
 PROT
 UTF8
211 End.
}


long blkpoll
$200 := BUFSIZ

--- BLKSEND will send a file sector by sector
pri BLKSEND ( xaddr cnt -- )							\ send chunks of up to one complete sector at buffer address
	?DUP 0= IF DROP EXIT THEN
	BEGIN
	  OVER SDADR OVER BUFSIZ MIN ( xaddr cnt bufadr bufcnt )		\ grab it a sector at a time
	  DUP >R LSEND									\ copy source buffer directly to socket tx buffer
         blkpoll W@ ?DUP IF CALL THEN						\ callback hook used by applications
	  ( src cnt )
	 R> DUP >R - SWAP R> + SWAP ( xaddr cnt )					\ update source parameters block by block
	  DUP 0=									\ until the source buffer is exhausted (cnt=0)
 	  sCLOSED? OR									\ or if closed
	UNTIL
	2DROP
	;

--- Send the currently open file in block mode
pub SENDFILE ( offset -- )	FSIZE@ OVER - BLKSEND ;

{ HELP SIZE
FTP COMMAND
Syntax: SIZE remote-filename
Returns the size of the remote file as a decimal number.
}
pre SIZE
	ON LANLED
  	GETFNAME FOPEN$
 	( 1 <MSG ." SIZE " FILE$ PRINT$ MSG> )
 	LANCON
	IF
	  ." 213 "  FSIZE@ .DEC
	ELSE
 	  ." 550 Could not get file size."
 	THEN
 	CRLF LANSEND
	;
{

0000_C800:   55 53 45 52  20 61 6E 6F   6E 79 6D 6F  75 73 0D 0A   USER anonymous..
0000_C810:   50 41 53 53  20 63 68 72   6F 6D 65 40  65 78 61 6D   PASS chrome@exam
0000_C820:   70 6C 65 2E  63 6F 6D 0D   0A 53 59 53  54 0D 0A 50   ple.com..SYST..P
0000_C830:   57 44 0D 0A  54 59 50 45   20 49 0D 0A  50 41 53 56   WD..TYPE I..PASV
0000_C840:   0D 0A 53 49  5A 45 20 2F   0D 0A 50 41  53 56 0D 0A   ..SIZE /..PASV..
0000_C850:   43 57 44 20  2F 0D 0A 4C   49 53 54 20  2D 6C 0D 0A   CWD /..LIST -l..

550 Could not get the file size
}

--- send accepted or rejected message to FTP client
pri FTPMSG ( flg -- )
 	FTP SOCKET LANCON
	IF
	  ON LANLED
	  ." 150 Accepted data connection for " FILE$ PRINT$ CRLF LANSEND
	  FTPDAT SOCKET CONNECT LAN
 	ELSE
	  ." 550 File not available" CRLF LANSEND
	THEN
 	;

--- FTP rename file request ---

16 bytes RNFR$ " FILENAME.EXT" RNFR$ $!    \ place for source string for rename (PBJ: 0 STRING or #12 > req for null term.)

{ HELP RNFR
FTP COMMAND
Syntax: RNFR from-filename
Used when renaming a file. Use this command to specify the file to be renamed; follow it with an RNTO command to specify the new name for the file.
}
pre RNFR
 	GETFNAME RNFR$ $!
 	FTP SOCKET LANCON ." 350 Waiting for RNTO" CRLF LANSEND
 	;

{ HELP RNTO
FTP COMMAND
Syntax: RNTO to-filename
Used when renaming a file. After sending an RNFR command to specify the file to rename, send this command to specify the new name for the file.
}
pre RNTO
 	RNFR$ FOPEN$ DROP GETFNAME RENAME$
 	FTP SOCKET LANCON ." 250 Rename done" CRLF LANSEND
 	;


{
Command:	RETR PREVIOUS.ROM
Response:	150 Accepted data connection for PREVIOUS.ROM
Response:	226 File successfully transferred
Status:	File transfer successful, transferred 65,536 bytes in 1 second
}

--- FTP Retrieve a file i.e. RETR /LOG0001.TXT ---
{ HELP RETR
FTP COMMAND
Syntax: RETR remote-filename
Begins transmission of a file from the remote host. Must be preceded by either a PORT command or a PASV command to indicate where the server should send data.
}
pri (RETR) ( position flg/addr -- )
 	DUP FTPMSG
 	IF ( position )
	  FILE$ 3 RIGHT$ " LOG" $=
  	  IF										\ If it's a log file then just send up to EOF marker
 	    DROP 0 APPEND
 	      IF @FWRITE @ OVER - 16 MAX ELSE FSIZE@ THEN
 	    BLKSEND 									\ Just send all the text up to the EOF or at least 16
 	  ELSE 									\ else send the whole file
 	    SENDFILE
 	  THEN
	  100 ms
	  ?SEND
  	  DISCONNECT --- close the data connection
	  FTP SOCKET
 	  LANCON ." 226 File successfully transferred" CRLF LANSEND 	\ Announce successful transfer
 	ELSE
 	  DROP
	THEN
 	FTP SOCKET ?DISCONNECT
	;

pre RETR
	KEEPALIVE
	GETFNAME FOPEN$ 								\ get the file name and try to open it
 	0 SWAP (RETR)
	;


{ HELP STOR
FTP COMMAND
Syntax: STOR remote-filename
Begins transmission of a file to the remote site. Must be preceded by either a PORT command or a PASV command so the server knows where to accept data from.
Usage
Command:	STOR PREVIOUS.ROM
Response:	150 Accepted data connection for PREVIOUS.ROM
Response:	250 File rcvd PREVIOUS.ROM
Status:	File transfer successful, transferred 65,536 bytes in 5 seconds
}
pre STOR
	KEEPALIVE
	GETFNAME 							--- get file name to store
	FOPEN$ RW 							--- try to open it for overwrite
	DUP FTPMSG 							--- send appropriate FTP message if accepted or not, connect to FTPDAT if accepted
 	?SEND
 	IF
 	  ( 1 <MSG ." STOR " FILE$ PRINT$ MSG> )
	  FTPDAT SOCKET
	  BEGIN
	    @FWRITE @
	    LREADSKT ( dst --- )
 	    vwrite @ @FWRITE !							--- update file write index
 	    DSCTD?
 	  UNTIL
	  FTP SOCKET LANCON ." 250 File rcvd " FILE$ PRINT$ CRLF LANSEND
 	  FSTAMP
 	  ( 1 <MSG ." FILE RCVD"  MSG>)
	THEN
    	FTPDAT SOCKET ?DISCONNECT
 	FTP SOCKET ?DISCONNECT
	;




{ HELP REST
FTP COMMAND
Syntax: REST position
Sets the point at which a file transfer should start; useful for resuming interrupted transfers. For nonstructured files, this is simply a decimal number. This command must immediately precede a data transfer command (RETR or STOR only); i.e. it must come after any PORT or PASV command.
}
pre REST ( <position> )
	GET$ NUMBER 				--- read the offset specified
 	(RETR)						--- retrieve as usual from this offset
	;




{                   Tachyon FTP session
Status:	Connecting to 192.168.16.151:21...
Status:	Connection established, waiting for welcome message...
Response:	220 WELCOME TO THE TACHYON WIZNET FTP SESSION!
Command:	USER admin
Response:	331 User admin OK. Password required
Command:	PASS *****
Response:	230 OK. Current restricted directory is /
Status:	Server does not support non-ASCII characters.
Status:	Connected
Status:	Retrieving directory listing...
Command:	CWD /
Response:	250 Directory successfully changed
Command:	TYPE I
Response:	200 TYPE is now I
Command:	PASV
Response:	227 Entering Passive Mode with port (192,168,16,151,173,118)
Command:	LIST
Response:	150 Here comes the directory listing
Response:	226 Directory send OK
Status:	Directory listing successful

}



( *** FTP SERVER 	- relies on the Forth console to interpret FTP commands directly *** )

pri ?FTP
	FTP SOCKET
	CONNECTED? 						--- examine interrupt register for a new connection etc
	IF
 	  "F" STAT!
\	  CON CRLF LAN
	  LAN ON QUIET
{
	  " WELCOME.FTP" FOPEN$
	  IF
 	    LAN (cat)
 	  ELSE
}
 	autosend C~~

	    LANCON ." 220 WELCOME TO THE TACHYON WIZNET FTP SESSION!" CRLF --- Welcome banner
\  	  THEN
	  KEEPALIVE 						--- Give FTP a maximum 5 min session
	  LANSKT 						--- makes sure the console uses this connection and socket
	THEN
	DSCTD? IF "f" STAT! CONIO THEN
	;



( HTTP COMMANDS )

--- some WIP here while I sort out my webpage files and content formatting etc


\ Sample content header - just for testing
pri CONTENT ( str -- )
	1 <MSG ." CONTENT = " DUP PRINT$  MSG>
	LANCON autosend C~
	." HTTP/1.1 200 OK" CRLF
	." Date: Tue, 03 Dec 2013 04:19:05 GMT" CRLF
	." Server: Tachyon Forth " CRLF
	." Last Modified: Tue, 01 Jan 2014 12:00:00 GMT" CRLF
	." Accept-Ranges: bytes" CRLF
	." Content-Length: " FSIZE@ .DEC CRLF
	." Connection: close" CRLF
	." Content-Type: " PRINT$ CRLF
	autosend C~~ CRLF
	;








48 bytes GET$

48 	:= getsz	--- limited in size by GET$ = 39 or implement new GETPARS to place string directly into GET$

pri ?CONTENT     \  MJB maybe later move to a table based approach
	 \ GET$ 3 RIGHT$
	"." GET$ LOCATE$ 1+   \ MJB prepare for other extensions like "JS"

	DUP " JPG" COMPARE$ IF DROP " image/jpg" CONTENT EXIT THEN		\ Send header for JPG files
	DUP " ICO" COMPARE$ OVER " PNG" COMPARE$ OR
	  IF DROP " image/png" CONTENT EXIT THEN					\ Send header for ICO/PNG files
	DUP " HTM" COMPARE$ IF DROP " text/html" CONTENT EXIT THEN		\ Send header for TEXT/HTML files
	DROP
	;

IFNDEF >UPPER
pri >UPPER  ( str1 --  ) --- Convert lower-case letters to upper-case
	DUP LEN$ ADO I C@ "a" "z" WITHIN IF I C@ BL XOR I C! THEN LOOP
	;
}

pri GETTXT
 	0 APPEND DROP @FWRITE @ OVER - 16 MAX BLKSEND			\ Just send all the text up to the EOF or at least 16
 	;
pri GETHTX --- temp def
	GETTXT
	;



--- Send the requested page to the web client ---
pri GETPAGE
	GET$ " /" COMPARE$ 								\ null GET / (root dir)
	  IF " HOME.HTM" DUP GET$ $!						\ Default request - open HOME.HTM
	  ELSE GET$ 1+ DUP >UPPER 							\ otherwise convert requested file name to uppercase
	  THEN
 	FOPEN$ NOT IF " HTTP404.HTM" FOPEN$ DROP THEN 				\ on file not found - use default 404 file
	LAN										\ Direct all output to the selected socket
	?CONTENT									\ Handle content headers
	1 <MSG ."  --> " FILE$ PRINT$ MSG>				\ echo name of actual file served
	UpdateTXWR @txwr W@ TXREAD LW!

	FILE$ 3 RIGHT$
  	DUP " TXT" $= IF DROP GETTXT ?SEND EXIT THEN				\ plain text file  ( only uppercase ?? or is >upper used somewhere?)
 	" HTX" $= IF GETHTX ?SEND EXIT THEN 					\ we have a html template file HTX with embedded FORTH

	0 FSIZE@ BLKSEND								\ or just send the whole file
	?SEND
	;

{ HELP HEAD
HTTP COMMAND
The HEAD method is identical to GET except that the server MUST NOT return a message-body in the response. The metainformation contained in the HTTP headers in response to a HEAD request SHOULD be identical to the information sent in response to a GET request. This method can be used for obtaining metainformation about the entity implied by the request without transferring the entity-body itself. This method is often used for testing hypertext links for validity, accessibility, and recent modification.
The response to a HEAD request MAY be cacheable in the sense that the information contained in the response MAY be used to update a previously cached entity from that resource. If the new field values indicate that the cached entity differs from the current entity (as would be indicated by a change in Content-Length, Content-MD5, ETag or Last-Modified), then the cache MUST treat the cache entry as stale.
}
pre HEAD  --- just repond back with the same head
	ECHOREQ
	;



{ HELP GET
HTTP COMMAND
The GET method means retrieve whatever information (in the form of an entity) is identified by the Request-URI. If the Request-URI refers to a data-producing process, it is the produced data which shall be returned as the entity in the response and not the source text of the process, unless that text happens to be the output of the process.
The semantics of the GET method change to a "conditional GET" if the request message includes an If-Modified-Since, If-Unmodified-Since, If-Match, If-None-Match, or If-Range header field. A conditional GET method requests that the entity be transferred only under the circumstances described by the conditional header field(s). The conditional GET method is intended to reduce unnecessary network usage by allowing cached entities to be refreshed without requiring multiple requests or transferring data already held by the client.
The semantics of the GET method change to a "partial GET" if the request message includes a Range header field. A partial GET requests that only part of the entity be transferred, as described in section 14.35. The partial GET method is intended to reduce unnecessary network usage by allowing partially-retrieved entities to be completed without transferring data already held by the client.
The response to a GET request is cacheable if and only if it meets the requirements for HTTP caching described in section 13.
}
pre GET ( <name> -- \ Open up the file name and send it ) 		--- /index.htm HTTP/1.1
	KEEPALIVE
	LAN GET$ DUP LEN$ getsz => IF DROP " GET$ to long" THEN
 	GET$ $! 									--- get the name and store in GET$  \ GET$
	1 <MSG ." GET " GET$ PRINT$ MSG>					--- Let me know about a request
	ECHOREQ
	GETPAGE
	;

1	:= #hskts							--- select from 1 to 4 sockets for HTTP processing

{ HELP ?HTTP
Service the HTTP server socket
}
pri ?HTTP
	HTTP #hskts ADO
 	I SOCKET
	CONNECTED?
	  IF
 	    "H" STAT!
	    ON QUIET 							--- Disable interactive mode prompts
	    KEEPALIVE
	    LANSKT 							--- Let the same socket talk to the foreground Forth console when it switches back
	  THEN
 	  DSCTD? IF "h" STAT! CONIO THEN
 	LOOP
	;


\ ----------------------------------------------------------------------------------------------------------- \
{
\ Check for control keys - this does not read the input buffer
pri ?CTRLS
	lastkey C@ SWITCH lastkey C~
 	^A CASE CONIO DISCARD OFF QUIET ."   ENQ " PLAIN CONSOLE BREAK
	^W CASE [CON DISCARD ifconfig CON] BREAK
 	^K CASE keypoll W~ OFF QUIET CONIO BREAK 					--- kill background key poll (servers)
	^S CASE [CON DISCARD .SOCKETS CON] BREAK
	^Q CASE CON DISCARD 8 0 DO I SOCKET DISCONNECT LOOP BREAK
 	^C CASE CON OFF QUIET DEBUG BREAK
       SWITCH@ IF CONIO OFF QUIET PLAIN THEN
	;
}
pri ?LED
 	--- the LED should be blinking very briefly when it's idle but alive
	1 ledcnt C+! ledcnt C@ ledon C@ < LANLED LEDS
	--- reflect current connection status as a long or short blink
	constat C@ $61 < IF constat C@ ELSE 1 THEN ledon C!
 	;

byte fsave
byte netflgs
--- 1	inhibit console shortcuts

( Main server loop - checks and services sockets - 1.3ms when idle )
pub ?EASYNET
	?LED
	SKT@ skt2 C! 							--- swap current socket between foreground and background
\ 	FILE# fsave C! 0 FILE 						--- use foreground file
	?TELNET 								--- Poll the TELNET server
	?SENDPOLL
	?FTP 									--- Poll the FTP server
	?HTTP 									--- Poll the WEB server
\	?SDCARD
  	TRUE 8 0 DO I SOCKET sCLOSED? AND LOOP IF CONIO THEN			--- force console back to serial if not busy
 	skt2 C@ SOCKET								--- restore foreground socket
\ 	fsave C@ FILE								--- restore foreground file
  	DEPTH 8 > IF !SP THEN							--- clean up abnormal stack
	1 netflgs SET? ?EXIT							--- skip controls if flag is set
\	?CTRLS									--- process console shortcuts
	;

pub RESTART		CON PLAIN ifconfig CRLF CRLF REBOOT ;



pub EASYNET
	!SP !WIZ 5000 @RTR LW! 16 @RCR LC!						--- setup retry counters
	CRLF ." *** TAQOZ EASYNET Network Servers and EASYFILE File Server *** " CRLF CRLF
\	RND fboot !
	4 ledon C! 								--- just setup an LED blink time
	ON READYLED 								---  Now init the IP addresses (stored in high 64K EEPROM)
	TELNET SOCKET sCLOSE TCP 10001 PORT!  sOPEN sLISTEN 			--- Setup TELNET but on port 10001
	FTP SOCKET sCLOSE TCP 21 PORT! sOPEN sLISTEN 				--- Setup FTP
	HTTP #hskts ADO I SOCKET sCLOSE TCP 81 PORT! sOPEN sLISTEN LOOP
	."  ... ready! " CRLF
	ifconfig 								--- report WIZnet status
  	0 STAT!
	' ?EASYNET keypoll W!  \ +POLL 						--- Poll the server in the background
	CRLF ." * WEB, FTP, and TELNET servers running * "
	CRLF
 	;


\ AUTORUN EASYNET

\ : MYLED		IF $40 ELSE $100000 THEN LED! ;
\ ' MYLED ' LANLED W!

END
