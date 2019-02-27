TAQOZ

( ********************************* SERIAL FLASH ******************************* )
{
BeMicroCV-A9            SW1
41	CLK     CLK  	60
40	CMD 	DI      58
36	D0      DO      59
37	D1
38	D2
39	D3	CS  	61
}

( WINBOND 25Q80 )

{
#P61	== sfcs
#P60	== sfck
#P59	== sfdi
#P58	== sfdo
}
{
#P39	== sfcs
#P41	== sfck
#P36	== sfdi
#P40	== sfdo
}

pub FLASH.fth			." Serial Flash routines 171219.0000 " ;

\ long @sfpins

0 == @sfpins

pub SFPINS ( &cs.so.si.ck -- )	' @sfpins ==! ;
\ &61.58.59.60 SFPINS
\ &39.36.40.41 SFPINS
\ &39.40.36.41 SFPINS
&41.40.36.57 SFPINS

pub SFWD			4
--- ensure correct pins are used for serial flash at the start of each new transaction (4.6us)
pub SFINS ( byte -- )		@sfpins SPIPINS SPICE SPIWB DROP ;

pub SFWE			6 SFINS ;

--- 935.8us/1kB = 914ns/byte
--- read block from SF to RAM		ins + addr       read block end
pub SFRDBLK ( sfadr dst cnt -- )	ROT 3 SFINS SPIWS SPIRX SPICE	;

( Read multiple bytes and assemble them into a long )
\ pub SFRDS ( cnt -- long )	0 SWAP FOR 8<< 0 SPIRD + NEXT ;

( Read serial Flash serial number )
\ pub SFSID			$4B SFINS 8 SFRDS 4 SFRDS SPICE ;
pub SFSID			$4B SFINS 0 SPIRDL SPIRDL 0 SPIRDL SPICE ;
( Read serial Flash Jedec ID )
pub SFJID			$9F SFINS 0 SPIRD SPICE ;

pub SFERSEC ( addr -- )		SFWE $20 SFINS SPIWS SPICE ;
pub SFER32K ( addr -- )		SFWE $52 SFINS SPIWS SPICE ;
pub SFER64K ( addr -- )		SFWE $D8 SFINS SPIWS SPICE ;
pub SFERCHIP			SFWE $C7 SFINS SPICE ;

pub SFWRPAGE ( src dst -- )	SFWE $02 SFINS SPIWS #256 SPITX SPICE ;

pub BACKUP			0 SFER64K 1 s 0 0 64 KB
pub SFWRBLK ( src dst cnt -- )  ROT SWAP ADO I OVER SFWRPAGE 3 ms SPIN #256 + #256 +LOOP DROP ;

--- backup the first 64K of memory into flash

pri SFW				0 SPIRD 0 SPIRD 8<< OR ;
--- 14.6us
pub SFC@			3 SFINS SPIWS 0 SPIRD SPICE ;
--- 15.9us
pub SFW@			3 SFINS SPIWS SFW SPICE ;
--- 18.1us
pub SF@ ( addr -- long )	3 SFINS SPIWS SFW SFW 16 << OR SPICE ;

--- Select Serial Flash as memory for DUMP words
pub SF				DUMP: SFC@ SFW@ SF@ ;

	--- extras ---

pub DP@				$5A SFINS SPIWS 0 SPIRD SPICE ;
pub SFDP			DUMP: DP@ DP@ DP@ ;
pub .SF				SFJID .B SPACE SFSID <D> U. ;

END
