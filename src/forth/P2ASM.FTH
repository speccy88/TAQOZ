TACHYON [~
{ TF2 P2 ASSEMBLER 

 TF2 ASM format is the same as PASM
     if_z  ROR tos1,tos  wc,wz  
 
 when it is complete that is :)

151027 updated for new FPGA

}
IFDEF P2ASM.fth
P2ASM.dat DATORG
FORGET P2ASM.fth
}
pub P2ASM.fth	." Tachyon Forth inline assembler for the P2 151022-0000 " ;

DATPTR	== P2ASM.dat

long opcode
long pc
long aflags
1	== _s
2	== _#
4	== _,
8	== _r9
16	== _w		--- wide source so any I must go to L instead

: aflags?	aflags SET? ;

long postop

( Forth kernel registers - find them and name them  )
' NIP COG@ 9BITS	== tos
tos			== 1st
tos 1+			== 2nd
tos 2+			== 3rd
tos 3 +			== 4th

' 0EXIT 1+ COG@ 9 SHR 9BITS == x
x 1-			== acc
x 1+			== r0
r0 1+			== r1
r1 1+			== r2
' DROP			== drop

' -1 1+			== pushacc
pushacc 1+		== pushx
' DUP 1+ COG@ 9BITS	== pushx

' 0EXIT COG@ $FFFFF AND == popx

pub s			opcode SET _s aflags SET ;
pub d			9 SHL opcode SET ;

	
pub EFF!		MASK opcode SET ;
pub wc			#20 EFF! ;
pub wz			#19 EFF! ;

pub #d			#19 EFF! ;
pub #s			#18 EFF! ;

pub #			_# aflags SET ;

pub ,			d _, aflags SET _# aflags? IF #d _# aflags CLR THEN ;



LONG xpc
pub org			DUP pc ! xpc ! ;
pub orgh		pc ! ;



pub CC!			#28 SHL opcode @ $0FFF.FFFF AND OR opcode ! ;
pub if_c		%1100 CC! ;
pub if_z		%1010 CC! ;
pub if_nc		%0011 CC! ;
pub if_nz		%0101 CC! ;
pub if_c_and_z		%1000 CC! ; ( c&z )
pub if_c_and_nz		%0100 CC! ;
pub if_c_or_z		%1110 CC! ;
pub if_c_or_nz		%1101 CC! ;
pub if_nc_or_z		%1011 CC! ;
pub if_nc_or_nz		%0111 CC! ;
pub if_c=z		%1001 CC! ; ( !(c^z)
pub if_c<>z		%0110 CC! ; ( c^z )
pub always		%1111 CC! ;
pub never		%0000 CC! ;

ALIAS if_c		c
ALIAS if_z		z
ALIAS if_nc		nc
ALIAS if_nz		nz
ALIAS if_c_and_z	c&z
ALIAS if_c_and_nz	c&nz
ALIAS if_c_or_z		c|z
ALIAS if_c_or_nz	c|nz
ALIAS if_nc_or_z	nc|z
ALIAS if_nc_or_nz	nc|nz
ALIAS if_c=z		c=z
ALIAS if_c<>z		c<>z


--- OPCODE CLASS with D and S operands
--- ror d,s {wc,wz}
--- Write opcode 7+3-bit opcode field and set default conditions etc

pub OPC		#18 SHL opcode @ OR opcode ! ;
pub ror         %0000000.000 OPC ;
pub rol         %0000001.000 OPC ;
pub shr         %0000010.000 OPC ;
pub shl         %0000011.000 OPC ;
pub rcr         %0000100.000 OPC ;
pub rcl         %0000101.000 OPC ;
pub sar         %0000110.000 OPC ;
pub sal         %0000111.000 OPC ;
pub add         %0001000.000 OPC ;
pub addx        %0001001.000 OPC ;
pub adds        %0001010.000 OPC ;
pub addzx       %0001011.000 OPC ;
pub sub         %0001100.000 OPC ;
pub subx        %0001101.000 OPC ;
pub subs        %0001110.000 OPC ;
pub subsx       %0001111.000 OPC ;
pub cmp         %0010000.000 OPC ;
pub cmpx        %0010001.000 OPC ;
pub cmps        %0010010.000 OPC ;
pub cmpsx       %0010011.000 OPC ;
pub cmpr        %0010100.000 OPC ;
pub cmpm        %0010101.000 OPC ;
pub subr        %0010110.000 OPC ;
pub cmpsub      %0010111.000 OPC ;
pub min         %0011000.000 OPC ;
pub max         %0011001.000 OPC ;
pub mins        %0011010.000 OPC ;
pub maxs        %0011011.000 OPC ;
pub sumc        %0011100.000 OPC ;
pub sumnc       %0011101.000 OPC ;
pub sumz        %0011110.000 OPC ;
pub sumnz       %0011111.000 OPC ;
pub isob        %0100000.000 OPC ;
pub notb        %0100001.000 OPC ;
pub clrb        %0100010.000 OPC ;	\ CCCC 0100010 CZI DDDDDDDDD SSSSSSSSS        CLRB    D,S/#       {WC,WZ} 
pub setb        %0100011.000 OPC ;
pub setbc       %0100100.000 OPC ;
pub setbnc      %0100101.000 OPC ;
pub setbz       %0100110.000 OPC ;
pub setbnz      %0100111.000 OPC ;
pub andn        %0101000.000 OPC ;
pub and         %0101001.000 OPC ;
pub or          %0101010.000 OPC ;
pub xor         %0101011.000 OPC ;
pub muxc        %0101100.000 OPC ;
pub muxnc       %0101101.000 OPC ;
pub muxz        %0101110.000 OPC ;
pub muxnz       %0101111.000 OPC ;
pub mov         %0110000.000 OPC ;
pub not         %0110001.000 OPC ;
pub abs         %0110010.000 OPC ;
pub neg         %0110011.000 OPC ;
pub negc        %0110100.000 OPC ;
pub negnc       %0110101.000 OPC ;
pub negz        %0110110.000 OPC ;
pub negnz       %0110111.000 OPC ;
pub altds       %0111000.000 OPC ;
pub decod       %0111001.000 OPC ;
pub topone      %0111010.000 OPC ;
pub botone      %0111011.000 OPC ;
pub incmod      %0111100.000 OPC ;
pub decmod      %0111101.000 OPC ;
pub mul         %0111110.000 OPC ;
pub muls        %0111111.000 OPC ;

pub OPCR9	_r9 aflags SET OPC ;
pub djz		%1001110.000 OPCR9 ;	( D,S/#rel9 )
pub djnz	%1001110.010 OPCR9 ;
pub djs		%1001110.100 OPCR9 ;
pub djns	%1001110.110 OPCR9 ;

( TESTN   D,S/#       {WC,WZ} )
pub testn	%1010000.000 OPC ;
pub test	%1010001.000 OPC ;
pub anyb	%1010010.000 OPC ;
pub testb	%1010011.000 OPC ;

( SETBYTS D,S/# )
pub setbyts	%1001010.100 OPC ;
pub movbyts	%1001010.110 OPC ;
pub splitb	%1001011.000 OPC ;
pub mergeb	%1001011.010 OPC ;
pub splitw	%1001011.100 OPC ;
pub mergew	%1001011.110 OPC ;

pub seussf	%1001100.000 OPC ;
pub seussr	%1001100.010 OPC ;
pub rev		%1001100.100 OPC ;
pub seti	%1001100.110 OPC ;

pub setd	%1001101.000 OPC ;
pub getd	%1001101.010 OPC ;
pub sets	%1001101.100 OPC ;
pub gets	%1001101.110 OPC ;




pub rdbyte	%1011000.000 OPC ;	(  RDBYTE  D,S/#/PTRx  {WC,WZ} )
pub rdword	%1011001.000 OPC ;
pub rdlong	%1011010.000 OPC ;

(                         LI )
pub wrbyte	%1100010.000 OPC ; ---  WRBYTE  D/#,S/#/PTRx
pub wrword	%1100010.100 OPC ; --- WRBYTE  D/#,S/#/PTRx
pub wrlong	%1100011.000 OPC ; --- WRBYTE  D/#,S/#/PTRx



pub rdfast	%1100011.100 OPC ; --- RDFAST  D/#,S/#
pub wrfast	%1100100.000 OPC ; --- WRFAST  D/#,S/#
pub fblock	%1100100.100 OPC ; --- FBLOCK  D/#,S/#

pub xinit	%1100101.000 OPC ; --- XINIT   D/#,S/# 
pub xzero	%1100101.100 OPC ;
pub xcont	%1100110.000 OPC ;
pub rep		%1100110.100 OPC ; ( REP     D/#,S/# )

--- CORDIC OPS
( CCCC 1100111 CLI DDDDDDDDD SSSSSSSSS        COGINIT D/#,S/#     {WC} )
pub coginit	%1100111.000 OPC ; ( COGINIT D/#,S/#     {WC} ) 
pub qmul	%1101000.000 OPC ; ( QMUL    D/#,S/# )
pub qdiv	%1101000.100 OPC ;
pub qfrac	%1101001.000 OPC ;
pub qsqrt	%1101001.100 OPC ;
pub qrotate	%1101010.000 OPC ;
pub qvector	%1101010.100 OPC ;

(                100000n nnI )
pub setnib	%1000000.000 OPC ;	--- SETNIB  D,S/#,#n
pub getnib	%1000010.000 OPC ;
pub rolnib	%1000100.000 OPC ;
pub nn		#19 SHL $0038.00000 opcode CLR opcode SET ;

(                        nnI )
pub setbyte	%1000110.000 OPC ; (  SETBYTE D,S/#,#n )
pub getbyte	%1000111.000 OPC ;
pub rolbyte	%1001000.000 OPC ;

(                        nI )
pub setword	%1001001.000 OPC ; (  SETBYTE D,S/#,#n )
pub getword	%1001001.100 OPC ;
pub rolword	%1001010.000 OPC ;

pub tjz		%1001111.000 OPC ; ( TJZ     D,S/#rel9 )
pub tjnz	%1001111.010 OPC ;
pub tjs		%1001111.100 OPC ;
pub tjns	%1001111.110 OPC ;


pub addct1	%1010100.000 OPC ;	--- ADDCT1  D,S/#
pub addct2	%1010100.010 OPC ;	--- ADDCT2  D,S/#
pub addct3	%1010100.100 OPC ;	--- ADDCT3  D,S/#
pub wmlong	%1010100.110 OPC ;	--- WMLONG  D,S/#/PTRx

pub calld	%1010101.000 OPC ; ( CALLD   D,S/#rel9   {WC,WZ} )
pub msgin	%1010110.000 OPC ;
pub rdlut	%1010111.000 OPC ;

pub setpae	%1011110.000 OPC ; (  SETPAE  D/#,S/# )
pub setpan	%1011110.100 OPC ;
pub setpbe	%1011111.000 OPC ;
pub setpbn	%1011111.100 OPC ;

(                         LI )
pub jp		%1100000.000 OPC ; (  JP      D/#,S/#rel9 )
pub jnp		%1100000.100 OPC ;
pub msgout	%1100001.000 OPC ; (  MSGOUT  D/#,S/# )
pub wrlut	%1100001.100 OPC ;



--- OPCODE CLASS with single D parameter ---
--- SETCZ D/#

pub OPCd        %1101011.000 OPC s ' d postop ! ;

pub setcz	%000101001 OPCd ; --- SETCZ   D/#  {WC,WZ}
pub setbrk	%000110100 OPCd ; --- SETBRK   D/#

pub rfbyte	%000010000 OPCd ; --- RFBYTE  D           {WC,WZ}
pub rfword	%000010001 OPCd ;
pub rflong	%000010010 OPCd ;

pub wfbyte	%000010011 OPCd ; --- WFBYTE  D/#
pub wfword	%000010100 OPCd ;
pub wflong	%000010101 OPCd ;


pub clkset      %000000000 OPCd ;
pub cogid       %000000001 OPCd ;
pub cogstop     %000000011 OPCd ;
pub locknew     %000000100 OPCd ;
pub lockret     %000000101 OPCd ;
pub lockclr     %000000110 OPCd ;
pub lockset     %000000111 OPCd ;
pub qlog        %000001110 OPCd ;
pub qexp        %000001111 OPCd ;

--- CORDIC OPS
pub setq        %000010110 OPCd ; ( SETQ    D/# )
pub setq2       %000010111 OPCd ;
pub getqx       %000011000 OPCd ;
pub getqy       %000011001 OPCd ;

pub getcnt      %000011010 OPCd ;
pub getrnd      %000011011 OPCd ;

pub setxdac     %000011100 OPCd ;
pub setxfrq     %000011101 OPCd ;
pub getxcos     %000011110 OPCd ;
pub getxsin     %000011111 OPCd ;


--- EVENTS & INTERRUPTS

pub setedg      %000100000 OPCd ;
pub setrdl      %000100001 OPCd ;
pub setwrl      %000100010 OPCd ;

pub sethlk	%000100011 OPCd ;	--- SETHLK  D/#

pub setint1	%000100101 OPCd ;	--- SETINT1 D/#
pub setint2	%000100110 OPCd ;
pub setint3	%000100111 OPCd ;

pub waitx	%000101000 OPCd ;

pub push        %000101010 OPCd ;	--- PUSH    D/#
pub pop         %000101011 OPCd ;	--- POP     D           {WC,WZ}

pub jmpcog	%000101100 OPCd ;	--- JMP 
pub call	%000101101 OPCd ;
pub calla	%000101110 OPCd ;
pub callb	%000101111 OPCd ;


pub jmprel	%000110000 OPCd ;





--- Opcode class: no parameters {wc} only
pub OPCnp        %1101011.000 OPC %000100100 s d ;

pub pollint	0 OPCnp ;	--- POLLINT             {WC}
pub pollct1	1 OPCnp ;	--- POLLCT1             {WC}
pub pollct2	2 OPCnp ;
pub pollct3	3 OPCnp ;

pub pollpat	4 OPCnp ;
pub polledg	5 OPCnp ;
pub pollrdl	6 OPCnp ;
pub pollwrl	7 OPCnp ;
pub pollhlk	8 OPCnp ;
pub pollxro	9 OPCnp ;
pub pollfbw	#10 OPCnp ;
pub pollrle	#11 OPCnp ;
pub pollwle	#12 OPCnp ;

pub waitint	#16 OPCnp ;
pub waitct1	#17 OPCnp ;
pub waitct2	#18 OPCnp ;
pub waitct3	#19 OPCnp ;
pub waitpat	#20 OPCnp ;
pub waitedg	#21 OPCnp ;
pub waitrdl	#22 OPCnp ;
pub waitwrl	#23 OPCnp ;
pub waithlk	#24 OPCnp ;
pub waitxro	#25 OPCnp ;
pub waitfbw	#26 OPCnp ;
pub waitrle	#27 OPCnp ;

pub allowi	%000100000 OPCnp ;
pub stalli	%000100001 OPCnp ;





pub OPCs	%1101011.000 OPC s  ;

--- treat these as if they have a wide S field
pub ret         %000110001 OPCs ;	--- CCCC 1101011 CZ0 000000000 000110001 RET  {WC,WZ}
pub reta        %000110010 OPCs ;
pub retb        %000110011 OPCs ;


pub OPCw	OPC _w aflags SET ;

pub call        %1101101.000 OPCw ;     --- CALL    #abs/#rel
pub calla       %1101110.000 OPCw ;     --- CALLA    #abs/#rel
pub callb       %1101111.000 OPCw ;     --- CALLB    #abs/#rel


---                    R abs(20)
pub jmp		%1101100.000 OPCw ;


( CCCC 11100ww Rnn nnnnnnnnn nnnnnnnnn        CALLD   reg,#abs/#rel )
pub calld       %11100.00.000 OPCw ;    --- CALLD   reg,#abs20/#rel  - CALLD PTRA,#LABEL
pub loc         %11101.00.000 OPCw ;    --- LOC     reg,#abs/#rel


\ pub jmp?	DUP $1FF > IF jmpabs ELSE jmpcog d THEN ;
\ pub jmp		%1101000.000 OPC ' jmp? postop ! ;

pub FIX23	_# aflags CLR 9 SHR s ; ( disable # processing and use top 23 bits of argument )
pub OPC23	' FIX23 postop ! ; ( Disable # processing  )

( CCCC 11110nn nnn nnnnnnnnn nnnnnnnnn        AUGS    #23bits )
pub augs        %11110.00.000 OPC23 ;    --- augment the next instruction by extending it's source field by 23 bits (+9=32)
pub augd        %11111.00.001 OPC23 ;    --- AUGD #LABEL 

{ ALIASES
PUSHA   reg/#                   =       WRLONG  reg/#,PTRA++
PUSHB   reg/#                   =       WRLONG  reg/#,PTRB++
POPA    reg                     =       RDLONG  reg,--PTRA
POPB    reg                     =       RDLONG  reg,--PTRB

RETI0                           =       CALLD   INB,INB     WC,WZ
RETI1                           =       CALLD   INB,$1F5    WC,WZ
RETI2                           =       CALLD   INB,$1F3    WC,WZ
RETI3                           =       CALLD   INB,$1F1    WC,WZ
}



pub APROMPT
	pc @ .ADDR  #13 SPACES
	opcode ~
	aflags ~
	postop ~ 
	always
	;

pub AEVAL
	SPACE opcode @ 4 SHL IF ( skip non-asm lines but ignore CCCC )
	  postop @ ?DUP IF CALL THEN
	  _r9 aflags? IF pc @ 4 + - 2/ 2/ 9BITS THEN
	  _s aflags? 0= IF s THEN ( do auto s if necessary )	
	  _# aflags? IF _w  aflags? NOT IF #s THEN THEN
	  $0D EMIT pc @ .ADDR SPACE opcode @ .LONG
	  opcode @ pc @ !
	  pc @ HERE = 4 pc +! IF pc @ DUP @HERE ! @HERE 4 + ! 0 ALLOT THEN
	THEN
	CR
	;

0	== l0
0	== l1
0	== l2
0	== l3
0	== l4
{
pub label IMMEDIATE
	[C] ' [C] GRAB pc @ SWAP 4 + !
	;
}

BYTE asmx

pub ANUM
	
	;

pub ASMKEY
	CONKEY 
	DUP $0D = IF asmx C~ EXIT THEN
	asmx C++
	DUP "#" = IF BL KEY! EXIT THEN
	DUP "," = IF $202C KEY! BL EXIT THEN 
	DUP "." = asmx C@ 2 < AND IF DROP [C] '  ?DUP IF pc @ SWAP 4 + ! THEN BL EXIT THEN
	;

pub ASM
	!SP
	' APROMPT prompt W!
	' AEVAL accept W!
	opcode ~ aflags ~
	' ASMKEY ukey W!
	$2.0000 org
	;

pub ENDCODE		prompt ~ keypoll W~ ukey W~ !SP ;

pub EXEC		xpc @ CALL .S ;
pub EXECS		FOR CR .S xpc @ CALL NEXT CR .S ;


pub CODE IMMEDIATE
	[C] CREATE$
	ASM HERE org
	; 



{ sample code file 

code (SDRD) ( dst  --  )
decod	r1,#9			'' 512 bytes $200
:l1				'' main loop
rep	#4,#8			'' 4+1 instructions for 8 times
andn	outa,sck		'' clock low 
test	miso,ina wc		'' read data from card
rcl	x,#1			'' shift in msb first
or  	outa,sck		'' clock high
andn	outa,sck		'' clock low
wrbyte	x,tos			'' write byte to buffer
add	tos,#1
djnz	r1,#l1			'' for 512 bytes
jmp	# ' DROP
endcode

TF2# code (SDRD) ( dst  --  )
 00.45D4 F727.3E09   decod       r1 , # 9                        ''
 00.45D8             l1                          ''
 00.45D8 FCDC.0808   rep         # 4 , # 8                       ''
 00.45DC F503.F994   andn        outa , sck              ''
 00.45E0 FA33.2DFE   test        miso , ina wc           ''
 00.45E4 F0A7.3A01   rcl         x , # 1                         ''
 00.45E8 F543.F994   or          outa , sck              ''
 00.45EC F503.F994   andn        outa , sck              ''
 00.45F0 FC43.3B8B   wrbyte      x , tos                         ''
 00.45F4 F107.1601   add         tos , # 1
 00.45F8 F9CF.3E81   djnz        r1 , # l1                       ''
 00.45FC FD80.001A   jmp         #  ' DROP
 00.4600             endcode ok


}

END

