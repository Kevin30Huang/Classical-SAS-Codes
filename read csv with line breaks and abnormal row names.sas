*Deal with line breaks in csv file and convert to sas dataset;
data _null_;
  infile '/home/huanj126/MBMA_Data_Definition_2015-11-10.csv' recfm=n lrecl=50000;
  file '/home/huanj126/testout.csv' recfm=n;
  input a $char1.;
  *make indicator;
  if a = '"' then do;
    d+1;
    if d = 2 then d = 0;
  end;
  if a = "," and d = 0 then do;
    c+1;
  end;
  *line end indicator;
  if a='0D'x and d=0 then lineind+1;
  *deal with special character in first row;
  if lineind=0 then
  	do;
  	a=translate(a,"__________"," ()[]:'/?#");
  	a=translate(a,"_",'0A'x);
  	a=translate(a,"_",'0D'x);
  	end;
  *output file to csv;
  *ignore '0A'x in cell;
  if a = '0A'x then do;
    if c = 2 then do;
      c = 0;
      checkpoint=1;
      put '0A'x;
    end;
  end;
  *add '0A'x in the each line end;
  else 
  	if a='0D'x and d=0 then
  		do;
  		put '0D'x;
  		put '0A'x;
  		end;
  	else 
  		put a $char1.;
/*   	rank=_n_; */
run;

proc import datafile="/home/huanj126/testout.csv"
	out=temp
	replace;
	getnames=yes;
	guessingrows=max;
run;
