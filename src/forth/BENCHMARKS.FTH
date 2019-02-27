pub fibo ( n -- f )
     1- 0 1		( Setup initial calculations "0 1" )
     ROT FOR BOUNDS NEXT NIP
     ;

( fibonacci test - just a Q&D one liner )
47 6 DO CRLF ." fibo(" I . ." ) = " I  LAP fibo  LAP .LAP ."  result =" . 10 +LOOP


47 6 DO CRLF ." fibo(" I . ." ) = " I  LAP   1- 0 1 ROT FOR BOUNDS NEXT NIP  LAP .LAP ."  result =" . 10 +LOOP


: fibo ( n -- f )
  0 1  ROT FOR BOUNDS NEXT DROP
  ;


{
TAQOZ# : fibo ( n -- f )  0 1  ROT FOR BOUNDS NEXT DROP  ;  ok
TAQOZ# 47 6 DO CRLF ." fibo(" I . ." ) = " I  LAP fibo  LAP .LAP ."  result =" . 10 +LOOP
fibo(6) = 685 cycles = 8.562us  result =8
fibo(16) = 1245 cycles = 15.562us  result =987
fibo(26) = 1805 cycles = 22.562us  result =121393
fibo(36) = 2365 cycles = 29.562us  result =14930352
fibo(46) = 2925 cycles = 36.562us  result =1836311903 ok
}


#8190 == *SIZE
$3.0000 == *FLAGS

*FLAGS *SIZE + == EFLAGS

: PRIMES
	CRLF ." Primes = "
	LAP
	*FLAGS 8190d 1 FILL  0 3 EFLAGS *FLAGS
	DO I C@
         IF  DUP I + DUP EFLAGS <
           IF    EFLAGS SWAP
                 DO  0 I C! DUP  +LOOP
           ELSE  DROP  THEN  SWAP 1+ SWAP
           THEN  1+ 1+
       LOOP  2DROP
       LAP .LAP
       ;




#8190 == *SIZE
$3.0000 == *FLAGS
: SIEVE
	LAP
	   *FLAGS *SIZE 1 FILL
	   0 *SIZE 0
	   DO I *FLAGS + C@
	      IF 3 I + I + DUP I + *SIZE <
	         IF *SIZE *FLAGS + OVER I + *FLAGS +
	            DO 0 I C! DUP +LOOP
	         THEN
	      DROP 1+
	      THEN
	  LOOP
	LAP .LAP
;


0 16 ADO CRLF I .B SPACE I MODZ . LOOP
