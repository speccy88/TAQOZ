TAQOZ

FORGET C2PROG

pub C2PROG	." Silabs C8051F Microcontroller Flash Loader - 181119.0000 " ;


BUFFER	:= BUFFERS

: BDUMP		SWAP BUFFERS + SWAP DUMP ;
{
SILAB PPC Programmer for Tachyon Forth


   *** Flash Silabs micros via C2 interface ***
Peter Jakacki 2012

Rather than using dedicated chips for extra I/O and analog functions etc I use cheap micros in small packages for these tasks. I refer to them as PPCs or Propeller Peripheral Controllers. But what good is it to have a small micro when you still have to program somehow and the programming headers can take up a lot more room than the micro itself. With this particular series it only needs one extra pin from the host Propeller to program it and this pin can be dedicated to this or jumpered only during Flash programming.

Advantage of using Silabs C8051F parts:
Simple but efficient 8051 instruction set
Precision internal oscillator 24.5MHz
25 or 50 MIPS
8051 software tools are plentiful and many are free.
Easy C2 in-circuit Flash Programming

The C2 interface for Flash Programming of Silabs C8051F CPUs requires a data line plus a clock line which is connected to the CPU's reset pin. In my implementations I normally use I2C so the C2 data line is shared with the I2C SDA line. Both lines may be changed dynamically with the C2PINS word.
The C2CK could be shared with another pin via a jumper if resources are scarce.

No programming voltages or any other special requirements.

8051 code is compiled to an Intel Hex file and loaded or pasted in via the serial port as normal text. A HEXLOAD command with a buffer address is given first after which the same buffer address may be used to program the PPC. Multiple PPC chips may be used incircuit and automation words written to suit such as automatic assignment of I2C addresses to multiple chips.

CODE SIZE: 872 bytes ( including the Intel Hex loader )
NAME SIZE: 382 bytes

Notes:
This document can be copied and pasted as Forth source code directly into Forth via the serial terminal.

References:
AN127 Rev1.2

*	*


}



\ Default I/O pins

54	:= C2GND
53	:= C2VDD
52	:= C2CK	\ This is my default clock line to the PuppyProp's PPC
51	:= C2D	\ Propeller's SDA line

{
// C2 status return codes
#define  INVALID_COMMAND   0x00
#define  COMMAND_FAILED    0x02
#define  COMMAND_OK        0x0D

// C2 interface commands
#define  GET_VERSION       0x01
#define  BLOCK_READ        0x06
#define  BLOCK_WRITE       0x07
#define  PAGE_ERASE        0x08
#define  DEVICE_ERASE      0x03

// C2 Registers
#define  FPDAT             0xB4
#define  FPCTL             0x02
#define  DEVICEID          0x00
#define  REVID             0x01
}

\ C2 address constants
0	:=  =DEVID
2	:=  =FPCTL
$B4	:=  =FPDAT
6	:=  =BLKRD

\ Status bits
{
 7	CONSTANT  =busy
 6	CONSTANT  =eerror
 2	CONSTANT  =inbusy
 1	CONSTANT  =outready
}
long  faddr

pub C2PINS ( clkpin datpin -- \ Assign new pins for the C2 interface )
	' C2D :=!		\ Rewrite the constant
	' C2CK :=!
	;
pub C2RESET --- Generate a reset pulse
	C2GND LOW C2VDD HIGH
	C2CK LOW 20 us C2CK HIGH 5 us
	;
pri C2STOP
pri C2START ( -- ) \ Start or stop strobe
	C2D FLOAT
pri C2STROBE ( -- ) \ Strobe the C2 clock low then high
	C2CK LOW C2CK HIGH
	;
pri C2WAIT
	C2D FLOAT
	  10000 0 DO C2STROBE C2D PIN@ IF LEAVE THEN LOOP
	;
pri C2INS ( instr -- ) \ Send out the 2-bit C2 instruction
	2
pri C2WRITE ( data bits -- )
	FOR C2CK LOW DUP 1& IF C2D HIGH ELSE C2D LOW THEN C2CK HIGH 2/ NEXT
	DROP
	;
pri C2READ ( -- byte )
	C2D FLOAT
	0 8 FOR 2* C2STROBE C2D PIN@ 1& + NEXT
	REV 24 >>
	;
\ *************************** READ DATA REGISTER ***************************
pub C2DAT@ ( -- byte ) \ Read the C2 DATA regsiter
	C2START 0 C2INS 0 C2INS C2WAIT C2READ C2STOP
	;
\ ************************** WRITE DATA REGISTER ***************************
pub C2DAT! ( byte -- ) \ Write to the C2 DATA register
	C2START 1 C2INS 0 C2INS 8 C2WRITE C2WAIT C2STOP
	;
\ ************************* READ ADDRESS REGISTER **************************
pub C2ADR@ ( -- byte ) \ Read the C2 ADDRESS register
	C2START 2 C2INS C2READ C2STOP
	;

\ ****************************** WRITE ADDRESS REGISTER *************************
\ pub C2AddressWrite
pub C2ADR! ( byte -- ) \ Write to the C2 ADDRESS register
	C2START 3 C2INS 8 C2WRITE C2STOP
	;



pub C2REG@ ( adr -- byte )
	C2ADR! C2DAT@
	;

pub C2REGS	DUMP: C2REG@ C2REG@ C2REG@ ;




\ Diagnostic function - check ID of C2 device
pub .C2 ( -- \ Check to see if a C2 device responds and list it's identity codes  )
	C2RESET
	0 C2REG@ ." ID=" .BYTE ." r" 1 C2REG@ .BYTE
	;
pri C2OR ( -- \ Poll until Out Ready with a timeout )
	1000 BEGIN 1- C2ADR@ 1& OVER 0= OR UNTIL DROP
	;
pub C2DATW@ ( -- byte \ Poll until Out Ready and read DATA regsiter )
	C2OR C2DAT@
	;
pub C2CMD ( cmd -- ) \ This function writes a command to the PI
pub C2DATW! ( byte -- \ Write to DATA register and wait until not busy )
	C2DAT!
pri C2IB ( -- \ Poll Input Busy )
	1000 BEGIN 1- C2ADR@ 2 AND 0= OVER 0= OR UNTIL DROP
	;

\ pub C2WriteSFR   \ This function directly writes an SFR and consists of the following steps:
pub C2REG! ( dat reg -- )
	C2ADR! C2DATW!
	;
\ This function allows writes to SFRs on devices that have SFR Paging and ensures that the SFR page is managed correctly .
\ pub C2DIR!
pub C2DIR! ( data addr -- )
	=FPDAT C2ADR!
	$0A C2CMD					\ direct write command
	C2DATW@ $0D <> IF 2DROP EXIT THEN
 	C2CMD					\ write address
	1 C2CMD
	C2CMD					\ write data
	;

pub C2FLASH --- Place C2 device into Flash programming mode
	C2RESET
	5 us
	=FPCTL C2ADR!
	2 C2DATW!
 	4 C2DATW!		\ Halt the core	(AN127Rev1.2)
	1 C2DATW!
	20 ms			\ Charge-pump delay?
	;

\ C2 DEVICE ERASE
pub C2ERASE ( -- flg \ Erase all the memory on the C2 device )
\	C2FLASH
	=FPDAT C2ADR! 3 C2CMD	\ Write device erase command in Flash Programming data register
	C2DATW@ $0D <> IF FALSE EXIT THEN
	$DE C2DATW!			\ Arming sequence
	$AD C2DATW!
	$A5 C2DATW!			\ Erase commences after this
 	C2DATW@
	;
\ 512 BYTE PAGE ERASE
pub C2ERASEP ( addr -- flg \ Erase the page on the C2 device )
	C2FLASH
 	=FPDAT C2ADR! 8 C2DATW!		\ Page erase command
	C2DATW@ $0D <> IF FALSE EXIT THEN
	9>> C2DATW!		\ write target page
	C2DATW@ $0D <> IF FALSE EXIT THEN
	0 C2DATW!
	\ C2DATW@ $0D =
	C2DATW@
	;


pub C2ProgramBlock ( src addr -- flg  \ Program a 256 byte block )
	C2FLASH
 	=FPDAT C2ADR!
	7 C2DATW!						\ BLOCK WRITE COMMAND
	C2DATW@ $0D =
	  IF
	  W>B C2DATW! C2DATW! 0 C2DATW!		\ block sized address
	  C2DATW@ $0D =
	    IF
	    $100 ADO I C@ C2DATW! LOOP
	    C2OR  TRUE
	    ELSE  FALSE
	    THEN
	  ELSE  FALSE
	  THEN
	;
pub C2PROGRAM ( addr dst cnt -- \ Program the device and assume the count is in even 256 block sizes )
	C2RESET C2DAT@ $FF = IF CR ." NO DEVICE " EXIT 3DROP THEN
	C2FLASH C2ERASE
       IF
	  SWAP faddr !
	  ADO
	    I faddr @ C2ProgramBlock DROP
	    256 faddr +!
	  256 +LOOP
	  ELSE
	  ."  Erase Failed " 3DROP
	  THEN
	C2RESET
	;

( *** DEVICE SPECIFC *** )
{
pub F99x \ id=25
	C2FLASH
	0 $A7 C2DIR!		\ SFR page 0
 	$8F $B2 C2DIR!		\ OSCICN = enable int osc -
 	0 $A9 C2DIR!		\ CLKSEL = Int Osc - no divide
pri ForceVMON
	C2FLASH
	$A0 $FF C2REG!		\ Vdd supply monitor enable - VDDOK
 	2 $EF C2REG!			\ Enable the VDD Supply Monitor as a reset source.
	;
pub F41x \ id=0C
	C2FLASH
	$87 $B2 C2DIR!		\ Oscillator init
	$10 $B6 C2REG!		\ WriteSFR(0xB6, 0x10) Flash timing
	$10 $c9 C2REG!		\ WriteSFR(0xC9, 0x10) - Voltage regulator init
	ForceVMON
	;
}
{
\ Force a device to erase by setting it's VDD monitor bits etc.
\ Still testing
\ Usage: F99x C2ERASE!!
pub C2ERASE!!
\	C2FLASH F99x  \  2 $EF C2REG! $80 $FF C2REG!
 	\ 0 C2ERASEP DROP
	10 ms
	C2ERASE DROP
 	;
}


( *** C2 DEBUG COMMANDS *** )


{
\ ReadBlock type - could be passed to C2ReadBlock if enabled
BYTE c2cmd
pub FLASH 		6 c2cmd C! ;
pub RAM  		$0B c2cmd C! ;
pub CPUREG  	9 c2cmd C! ;
}
\ Read the registers into the buffers using the register block read command
pub C2RB
	C2FLASH
	=FPDAT C2ADR!
	9 C2DATW!
	C2DATW@ DROP
 	$80 C2DATW! $80 C2DATW!
  	BUFFERS $80 ADO C2DATW@ I C! LOOP
	;
pub C2RB?
	C2RB 0 80 BDUMP
	;

\ Write the buffer into the registers using the register block write command
pub C2WB
	C2FLASH
	=FPDAT C2ADR!
	$0A C2DATW!
	C2DATW@ DROP
 	$80 C2DATW! $80 C2DATW!
  	BUFFERS $80 ADO I C@ C2DATW! LOOP
 	;
\ Diagnostic - dump the C2 registers (don't know what they all are)
pub C2REGS
	C2RESET
	$100 0 DO I C2ADR! C2DAT@ I BUFFERS + C! LOOP
 	0 $100 BDUMP
 	;

pub C2READBLK ( addr dst -- \ Read a 256 byte block into the dst buffer )
	C2FLASH
	=FPDAT C2ADR!
	6 C2DATW!
	C2DATW@ $0D <> IF ."  REJECT ReadBlock " C2RESET EXIT THEN
	SWAP W>B C2DATW! C2DATW! 0 C2DATW!
	C2DATW@ $0D <> IF  ."  REJECT ReadBlock parameters " C2RESET DROP EXIT THEN
	$100 ADO C2DATW@ I C! LOOP
	;

{
To read a flash block:
--- 1. Perform an Address Write with a value of FPDAT.
	=FPDAT C2ADR!
--- 2. Perform a Data Write with the Block Read command.
	=BLKRD C2DAT!
--- 3. Poll on InBusy using Address Read until the bit clears.
	C2WAIT
--- 4. Poll on OutReady using Address Read until the bit set.
--- 5. Perform a Data Read instruction. A value of 0x0D is okay.
--- 6. Perform a Data Write with the high byte of the address.
--- 7. Poll on InBusy using Address Read until the bit clears.
--- 8. Perform a Data Write with the low byte of the address.
--- 9. Poll on InBusy using Address Read until the bit clears.
--- 10. Perform a Data Write with the length.
--- 11. Poll on InBusy using Address Read until the bit clears.
REPEAT
12. Poll on OutReady using Address Read until the bit set.
13. Perform a Data Read instruction. This will read the data from the flash.
 Repeat step 12 and 13 for each byte specified by the length field

}


( *** DEBUG & DIAGNOSTICS *** )
pub C2DUMP ( addr cnt -- )
	C2FLASH ADO I BUFFERS C2READBLK I $100 BDUMP $100 +LOOP C2RESET
 	;

\ Diagnostic only - displays C2 Flash status
pub C2?   C2ADR@ DUP .BYTE SPACE DUP 1& IF ." (Output Ready) " THEN 2 AND IF ." (Input Busy) " THEN ;

pub P2D2	52 51 C2PINS ;

{
pub C2LIST ( dat -- ) \ List all clock lines that have a common data line
	#28 0 DO I OVER C2PINS
	C2RESET 0 C2ADR! C2DAT@ DUP 1 $FE WITHIN
	IF CR ." CLK:" I .DEC2 SPACE ." DAT:" OVER .DEC2 ."  DEVID=" DUP .BYTE THEN DROP
	LOOP DROP
	;
}
{

( ***  INTEL HEX LOADER UTILITIES *** )

\ Will process character by character without any expectations - meaning it can terminate anytime

\ Allocate enough memory for typical 16 bytes/line + headers etc
32 TABLE hexbuf
long hexptr
long dst
long hexadr
byte hexflg
byte hex

\ Write bytes from hexbuf to dest
pri WRITEHEX
	hexbuf C@++ ( ptr cnt )				\ Process 1st byte = count
	SWAP C@++ 8 << ( cnt ptr adrh )		\ next 2 bytes are the destination address
	SWAP C@ +	( cnt addr )
	2DUP + hexadr !					\ Update last unwritten address pointer (external use)
	dst @ + ( cnt dst )				\ add in the offset
	hexbuf 4 + SWAP ROT ( src dst cnt )		\ and write this line to the destination
	CMOVE
	;
pri +HEX ( nibble -- )
	hex C@ 4 << + hex C!
	hexflg C@
	  IF hex C@ hexptr @ C! hexptr ++ hexflg C~
	  ELSE	1 hexflg C+!
	  THEN
	;
pri HEX: ( char -- \ Process Intel Hex input )
	DUP ":" = IF DROP hex C~ hexflg C~ hexbuf hexptr ! EXIT THEN
	DUP "0" "9" WITHIN IF "0" - +HEX EXIT THEN
	DUP "A" "F" WITHIN IF $37 - +HEX EXIT THEN
	$0D = IF hexptr @ hexbuf - 5 > 		\ terminate on an empty line else write a valid line
 	  IF WRITEHEX  ELSE R> DROP THEN  THEN
	;

pub HEXLOAD ( dst -- \ Load an Intel Hex file into the dst area )
	dst !
	BEGIN KEY HEX: AGAIN
	;

{ Quick hex load and program current C2 device
Usage: C2LOAD  Programming device ID=25r01 from 4000 to 0000 for 0400 bytes ok
}
pub C2LOAD
	$4000 HEXLOAD
	dst @ 0 hexadr @ #256 ALIGN
 	."  Programming device " .C2 ."  from " 3RD .WORD SPACE
 	." to 0000 for " DUP .WORD ."  bytes"
	C2PROGRAM
	;
}




END
