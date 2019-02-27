
\ This file contains the functions to:
\
\ * manage a buffer, and write it to /dev/fb/0
\ * draw colored lines
\ * clear the screen
\
\
\ To set this up you must do the following:
\
\ * Set width to the width of your framebuffer (number of pixels)
\ * Set pixel to the number of bytes in a pixel
\ * Rewrite pixel! to store a pixel (it now works only on
\   Big-Endian machines in 15 or 16 bit color)
\ * make sure your forth system has enough memory. with gforth do:
\      gforth -m <number of bytes>
\
\ And will probably want to:
\
\ * Set height to the number of lines your pixel buffer will be
\   (this will be displayed at the top of the screen)
\ * Rewrite rgb to pack your pixel format if you want
\   (type fbset at the terminal and it tells you your pixel format)
\
\ EXAMPLE CODE
\
\ See the word "test" at the bottom for a good test and example.


1280 constant width  \ CHANGE THIS
1024 constant height \ CHANGE THIS

4 constant pixel \ Size (in bytes) of a pixel CHANGE THIS

: pixels
   4 * \ CHANGE THIS
;

( pixel addr --     store a pixel )
: pixel!
   !   \ CHANGE THIS
;

variable color -1 color !

( r g b --   set color from rgb )
: rgb
   swap 8 lshift + \ CHANGE THIS
   swap 16 lshift +
   color !
;




create buff width height * pixels dup allot
constant buff-size

: assert
   dup if . abort" <---file error" then drop
;

\ FIX: error detection etc.
s" /dev/fb/0" w/o open-file assert constant file

: write-buffer
   buff buff-size file write-file assert
   file flush-file assert 0 0 file reposition-file assert
;

: clear
   buff buff-size 4 / 0 do 0 over ! 4 + loop drop
;

clear

variable x 0 x !
variable y 0 y !

( x y -- addr   convert x,y to pixel address )
: c2a
   1+ height swap -  \ invert y
   width * + pixels buff +
;

( x y --   colors pixel at x,y )
: setpixel
   c2a color @ swap pixel!
;

: moveto
   y ! x !
;


width pixels constant linebytes

variable h
variable w
variable c
variable r
variable d
variable startx
variable starty

( x y -- )
: setxy
   x @ startx !
   y @ starty !
   y ! x !
;

: sethw
   x @ startx @ - w !
   y @ starty @ - h !
;

( x y -- )
: line-defaults
   setxy
   sethw
   pixel r !
   0 linebytes - d !
;

( --  change control variables for line if line is going right )
: r-l
   w @ 0 < if x @ startx ! y @ starty ! w @ -1 * w ! h @ -1 * h ! then
;

( --  change control variables for line if line is going up )
: u-d
   h @ 0 < if linebytes d ! h @ -1 * h ! then
;

( --  change control variables if line is predominantly verticle )
: h-v
   h @ w @ > if h @ w @ h ! w !  r @ d @ r ! d ! then
;

( x y --   setup variables for drawing line to x,y )
: pinit
   line-defaults r-l u-d h-v
;

( --   set c to w, then double w and h )
: cinit
   w @ 1+ 2 / c !
;

( x y -- addr "w"   setup everything for line )
: line-setup
   pinit
   startx @ starty @ c2a w @ cinit
;

( h+c --   decrement c by w )
: w-
   w @ - c !
;

( addr -- addr2  move the pixel address "right" )
: right
   r @ +
;

( addr -- addr2  move the pixel address "down" )
: down
   d @ +
;

: slant? ( -- h+c w>? )
   c @ h @ + dup w @ >
;

: colorit ( addr --   color the pixel at addr )
   color @ swap pixel!
;

( addr -- addr2  move addr to the next pixel in the line. use h, w, and c )
: nextp
   right slant? if w- down else c ! then
;

( x y )
: lineto
   line-setup over colorit 0 do nextp dup colorit loop drop
;


\ INTERACTIVE COMMANDS (Only useful for calling directly)
\ see also: rgb moveto clear

( x y -- draw a line to x,y )
: l
   lineto write-buffer
;

( spacing -- spacing=how far to spread the lines out. try 12 )
: test
   clear
   width height min 1 - over / over *
   \ stack: spacing width
   dup 1+ 0 do 0 i moveto dup i - 0 lineto over +loop
   dup 1+ 0 do i over moveto 0 i lineto over +loop
   dup 1+ 0 do dup dup i - moveto i over lineto over +loop
   2drop
   write-buffer
;
