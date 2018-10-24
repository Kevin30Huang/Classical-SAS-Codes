data aa;
  infile '/home/huanj126/MBMA_Data_Definition_2015-11-10.csv' recfm=n lrecl=50000;
  file '/home/huanj126/testout.csv' recfm=n;
  input a $char1.;
  rank=_n_;
  if a = '"' then do;
    d+1;
    if d = 2 then d = 0;
  end;
  if a = "," and d = 0 then do;
    c+1;
  end;
  if a = '0A'x then do;
    if c = 2 then do;
      c = 0;
      checkpoint=1;
      put '0A'x;
    end;
  end;
  else 
  	if a='0D'x and d=0 then
  		do;
  		put '0D'x;
  		put '0A'x;
  		end;
  	else 
  		put a $char1.;
run;

proc import datafile="/home/huanj126/testout3.csv"
	out=temp
	replace;
	getnames=no;
	guessingrows=max;
run;