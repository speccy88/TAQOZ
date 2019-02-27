P2 TACHYON [~
IFDEF EEPROM.fth
FORGET EEPROM.fth
}

pub EEPROM.fth    PRINT" EEPROM UTILIES - 160625.0000 " ;

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

( EEPROM )
BYTE eeadr
--- EEPROM addressing - select default device and write 16-bit address
--- Updated to take an address >64K and automatically select the next device

pub @EE ( addr -- flg ) --- use full 32-bit address to select a device and issue the lower 16-bit address to it
    I2CSTOP
    L>W 2* $A0 + DUP eeadr C!                --- calculate the device address with base $A0 (8-bits)
    I2CSTART I2C!?                           --- send the device address
    OVER 8>> I2C!?                         --- send the 16-bit memory address (msb)
    OR SWAP I2C!? OR                         --- send the lsb and return with a combined ack flag.
    ;

--- Switch EEPROM to read mode
pub EERD ( -- flg  )
	I2CSTART eeadr C@ 1+ I2C!?
	;
--- revision 140602 - Added timeout loop counter to prevent hanging
pub @EEWAIT ( adr --  )
  	#200 BEGIN 1- OVER @EE 0= OVER 0= OR UNTIL 2DROP
	;
--- Store byte to EEPROM
pub EEC! ( byte addr -- )
 	@EEWAIT I2C! I2CSTOP
 	;
--- Fetch byte from EEPROM
pub EEC@ ( addr -- byte )
 	@EEWAIT EERD DROP
 	1 I2C@ I2CSTOP
 	;
pub EEW! ( word addr -- ) \ Store a non-aligned word in EEPROM
 	@EEWAIT W>B SWAP I2C! I2C! I2CSTOP
  	;
--- Fetch a word from EEPROM
pub EEW@ ( addr -- word )
 	@EEWAIT EERD DROP
 	0 I2C@ 1 I2C@ B>W I2CSTOP
	;

--- Fetch a long from EEPROM
pub EE@ ( addr -- long )
 	@EEWAIT EERD DROP
 	0 I2C@ 0 I2C@ B>W 0 I2C@ 1 I2C@ B>W I2CSTOP
 	W>L
 	;
pub EE! ( long addr -- ) \ Store a non-aligned long in EEPROM - 395us
 	@EEWAIT L>W SWAP W>B SWAP I2C! I2C!
 	W>B SWAP I2C! I2C! I2CSTOP
  	;

pri ENDRD ( --  \ read last byte [no ack] and stop )
 	1 I2C@ DROP I2CSTOP
 	;
pub EESAVEB ( ram eeprom cnt -- \ byte by byte method - safer for non-page aligned addresses and counts )
 	ADO C@++ I EEC! 5 ms SPINNER LOOP DROP
 	;


--- calculate and set EEPROM page size at compile time
0 $8000 EE! $8000 EE@ 0 EE@ <> IF 128 ELSE 64 THEN		== ep

IFNDEF FI2C@
ALIAS I2C@ FI2C@
}

--- Save a block of RAM to EEPROM. Will backup 32K to EEPROM in 4.963 seconds
pub EESAVE ( ram eeprom cnt -- )
	ep ALIGN                        				--- round up to nearest 64 byte page
	ROT SWAP                         				--- use ram address for loop index, leave eeprom addr on stack
   	ADO
   	( eeprom )
   	  DUP @EEWAIT                    				--- Wait for the EEPROM write cycle
{
          EERD DROP 0 I ep
 	    ADO FI2C@ I C@ <> OR DUP IF LEAVE THEN LOOP
          1 I2C@ DROP
}
\     	  IF
 	    DUP @EE DROP 0 I ep ADO I C@ I2C!? OR LOOP I2CSTOP 1 ms		--- Write 64 bytes and check acks
         	IF CR EMIT ." FAIL @" DUP .WORD THEN
 \       THEN
    	  SPINNER                      					--- console spinner to show it's busy
    	  ep +
  	ep +LOOP DROP
 	;

--- Load a block of EEPROM to RAM
pub EELOAD ( eeprom ram cnt -- )
	ROT  @EEWAIT EERD DROP				--- select the device - might have to wait
	  ADO FI2C@ I C! LOOP				--- sequential reading from EEPROM into RAM
	ENDRD						--- signal last byte read
 	;

pub ?BACKUP
 	errors C@ ?EXIT
--- Backup the current Tachyon Forth session
pub EEBACKUP
\	EEPROM
	0 0 $1.0000 EESAVE
	;


pub EE				' EEC@ dmpvec W! ' EEW@ dmpvec 2+ W! ' EE@ dmpvec 4 + W! ;

]~ END
