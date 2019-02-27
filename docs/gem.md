# GEMS from TAQOZ Thread

## Explanations

TAQOS is different than other FORTHs

Normally when you type an interactive line (not within a definition) such as &quot;123 456 + .&quot; the TIB text input buffer simply builds up this text until you hit the enter. Then it will go through finding each &quot;word&quot; delimited by whitespace and try to find it in the dictionary. If found it will simply execute it right then and there while it is still parsing the TIB. Numbers will fail the dictionary search and so the &quot;word&quot; will then be tested to see if it is a valid number depending upon the current number base. If it is then it will be converted and pushed onto the stack. In our example therefore 123 and 456 are processed in order as numbers after the enter is hit followed by + which executes, adds the two numbers, pushes the result followed by . which prints the number from the stack.

TAQOZ is different. It does not have a TIB but rather it does have a word buffer that once it encounters a delimiter it will check first if it is a number and convert and compile it (not push it). If it is not a number it will search the dictionary and when found it will compile it unless of course it is an immediate execution word such as IF THEN etc. So after compiling + and . it encounters the enter key as the end of line it will execute this temporary code at full speed. The code that was executed was only temporarily allocated so the next line starts compiling at the same start point again. One of the reasons for handling each word and number as it comes in is compilation speed and the reason for compiling it is also so that we can run it the exact same way it would within a definition and at full speed. This also allows use to use the DO LOOP IF THEN etc that you just cannot use in other Forths. So much better I&#39;m sure you&#39;d agree.

This you can type into TAQOZ but have no hope of typing into most Forths interactively.

10 FOR CRLF .&quot; HELLO WORLD!&quot; NEXT

: pub pri pre

NOTE: TAQOZ like Tachyon in addition to the : colon symbol to define words also uses these words:

**pub** Create a header that is public (normal header like : does )

**pri** Create a header that is marked private so a RECLAIM can strip them as directed.

**pre** Create a header that has the &quot;immediate&quot; attribute set so that it executes immediately (words like IF ELSE THEN etc)

further explanations

2) Write a driver in TAQOZ itself rather than using the optimized assembly code in the kernel. It is very very simple to do, just bash some bits out.

3) TAQOZ uses wordcode which is either a cog or hubexec address plain and simple, or it is a high level call to more threaded code, or if it is usually \&gt;$F800 then it is further decoded as a short 10-bit literal, or a conditional branch etc. Since wordcode is exactly 16-bits long then any call to word aligned (purposely) threaded code always falls on an even address so TAQOZ uses the lsb to indicate a jump instead of a call which is also very useful for ELSE AGAIN REPEAT type unconditional branches etc.

What does that have to do with creating a table of bytes? It just means we can never have the current code compilation pointer on an odd address since all code, even interactive code, is normally compiled and then executed. The only difference with interactive code is that the code space is reused again but compiles at code&#39;s end the same as a definition etc.

That&#39;s why TABLE is now preallocated using a byte count value as in 128 7 \* TABLE FONT5X7 although you are quoting an early structure that was created manually but does the same thing (but hides the details). I then create a compiler helper word (that is later forgotten and removed) that scans a string and value to write the bit pattern into that table. None of this affects the word alignment since it has been preallocated.

[C] is an immediate to force the compilation of another immediate word GRAB which forces any interactive code to execute thus leaving their values on the stack. Actually, I&#39;m sure I could make that simpler now, it&#39;s more of a leftover.

I just checked the table structure I use now and it doesn&#39;t use [C] GRAB so that must have been the transitional version I used when I changed over to preallocating tables and filling them in later. But you can still create a table the old way that builds up, in fact have a look at TAQOZ2V0.FTH and you will see this:

0 TABLE ma
 000 001 005 010 ,,
 025 035 060 100 ,,
 001 005 010 025 ,,
 035 045 080 200 ,,

It was easy enough to create the ,, word to read 4 bytes and compile them in one shot to keep word alignment. The reason that the ,, uses the [C] GRAB is because the exact place that the temporary code is compiled is the exact place that the table has to be built, so it has to GRAB all the code that is temporarily compiled there and execute it which in this case results in permanent compilation of constants. The code pointers are then advanced after each line and by changing the TAQOZ prompt to reveal the code pointer we can watch it unfold (see if you can grok this).

btw - this version of TAQOZ is inserting a --- between the user input and its response so that it easier to see what is what.

TAQOZ# : CODEPROMPT HERE .W .&quot; : &quot; ; ---  ok
TAQOZ# &#39; CODEPROMPT uprompt W! ---  ok
$511A: 0 TABLE atable ---  ok
$511C: 12 34 + . --- 46 ok
$511C: 12 34 56 78 ,, ---  ok
$5120: $511C QD ---
0511C: 0C 22 38 4E  41 01 1C 51  BC 16 4E 00  4E 00 C8 15     &#39;.&quot;8NA..Q..N.N...&#39;
0512C: 0A FC B9 FE  D5 00 85 00  70 00 D5 00  01 F8 94 00     &#39;........p.......&#39; ok
$5120: HERE QD ---
05120: A8 14 BC 16  4E 00 4E 00  4E 00 C8 15  0A FC B9 FE     &#39;....N.N.N.......&#39;
05130: D5 00 85 00  70 00 D5 00  01 F8 94 00  7B 00 DD 00     &#39;....p.......{...&#39; ok
$5120: &#39; HERE .W --- $14A8 ok
$5120: &#39; QD .W --- $16BC ok
$5120: HERE $10 DUMPW ---
05120: 14A8 F810 16DE 004E  004E 15C8 FC0A FEB9     &#39;......N.N.......&#39; ok
$5120:

It was kinda useful to create a word that would print the code pointer and revector the TAQOZ prompt by storing the code address of that routine into the uprompt vector. Straight away the prompt is exactly what I wanted. When I create an empty TABLE we can see how that used up a single wordcode which is in fact the code that returns the address following it by popping the return stack and pushing it onto the data stack, and never returning back there again but instead leaving a pointer to any structure that we may create.

When I typed in some temporary interactive code with 12 34 + . it never permanently allocated code memory but the pointer stayed the same at $511C. However when I now type the same numbers plus a couple more then use the immediate ,, word it grabbed and built up the 4 bytes into a long that was compiled with the , word.

pre ,, [C] GRAB 3 FOR 8\&lt;\&lt; + NEXT [C] , ;

The last few lines in my test was just to reveal the termporary code that is compiled so the code address of HERE is $14A8 and the last line I dumped you can see that at $5120 followed by a wordcode that encodes $10 as a short 10-bit literal, then DUMPW and then $004E which is EXIT so that the code can return to the console. Then the code pointer is restored back to $5120.

Welcome to &quot;Fudge the TAQOZ compiler on the go&quot; 101



## EXAMPLES

Putting machine code into a definition and running it

: ASM   R\&gt; SWAP COGINIT ;
: BLINKER ( pin cog -- )
 SWAP 2\* $6400 OR &#39; BLINKER 27 + W!
 ASM [
 $FCDC0600 ,
 $FD64005F ,
 $FF809896 ,
 $FD66001F ,



To run this BLINKER for pin 3 in cog 7:

3 7 BLINKER

EMIT: to many devices simultaneously

Normally uemit is zeroed and this selects the default serial console but you can always reference this device as CONEMIT. Therefore all you need to do is create a new hybrid device:

: BOTH   EMIT: DUP CONEMIT EMIT\_N5110 ;

If you can use the latest image on SD then please do that as that supports EMIT: so this simplifies creating character I/O devices.

## WORDS

[

The [ is an immediate word that simply tells the compiler that it is no longer building up a definition but now in interactive mode again. This is necessary since the definition is essentially finished but we don&#39;t need to EXIT since when ASM was implicitly called it popped the return address with R\&gt; which points to the assembly code we compiled after the ASM [ . So at that point the stack has the cog number and now the pointer to the assembly code which we now SWAP so that it is in the right order for a COGINIT which requires ( codeptr cog# -- ) . After the COGINIT it returns using the previous return address, not the one that called ASM.

R\&gt;

pop the return address from return stack with R\&gt;

,

The comma symbol , will simply store a long from the stack into the first code position and allocate those 4 bytes as if it were part of a definition and not to be confused with any code we are executing in interactive mode. Perhaps a bit of explanation is needed here since traditional Forths work very differently.

FOPEN  FLOAD FOPENS FLOADS

V1.1 uses FOPENS ( sector -- ) whereas FOPEN is defined as an interactive word which looks for a filename following FOPEN. The same for FLOAD.

So FLOAD \&lt;filename\&gt; should work but V1.1 boot image already has the EXTEND loaded as well as VGA on P0..P4

So in V1.1 FOPEN and FLOAD are defined using pre so that when they are encountered they execute immediately and wait for a filename.