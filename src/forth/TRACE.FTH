


word steppc

pri _lit	$3FF AND ;
pri _reg	$1FF AND REG ;


TABLE vec
	_lit _lit _lit _lit
	_ifx DROP _reg _reg

pub STEP
    	steppc W@ DUP
	CRLF .WORD ." : " W@ DUP .WORD 8 SPACES
	DUP $F800 < IF CALL ELSE 8>> $0F AND 8 - 2* vec + W@ CALL THEN
	.S
	2 steppc W+!
	;

pub RESUME	BEGIN STEP 100 ms KEY UNTIL ;
pub TRACE	steppc W! RESUME ;



{
w               =       $F800           ' wordcode offset for 10-bit literals
_IF             =       $FC00           ' IF relative forward branch 0 to 127 words
_UNTIL          =       $FC80           ' UNTIL relative reverse branch 0 to 127 words
opunused	= 	$FD00
rg		= 	$FE00          ' task/cog register 8-bit offset
fat		=	$FF00
registers       = 	rg                         'Variables used by kernel + general-purpose
tasks           = 	rg+$D0    	' 2 longs/task * 8 cogs
}
