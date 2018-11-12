%macro reorder_var_alpha(lib=,domain=,output=);
proc sql noprint;
    select distinct name into: varlst separated by ' '
    from dictionary.columns
    where upcase(libname) eq upcase("&lib") and upcase(memname) eq upcase("&domain") and upcase(memtype)=upcase("DATA");
quit;

data &output;
	retain &varlst;
	set &lib..&domain;
	rank=_n_;
run;
%mend;

%macro findrecord(dsin,where);
title1 j=l "Source Data : &dsin";
title2 j=l "Condition: &where";
title4 j=l "Records are displayed horizontally";
title5 j=l "Variables are listed in alphabetical order";
%if %index(&dsin,.) %then
	%do;
	%let lib=%scan(&dsin,1,".");
	%let domain=%scan(&dsin,2,".");
	%end;
%else
	%do;
	%let lib=work;
	%let domain=&dsin;	
	%end;

%reorder_var_alpha(lib=&lib,domain=&domain,output=a);
data a;
	set a;
	where &where;
	count=_n_;
	proc print;
run;

Data rank;
	set a(where=(&where)) end=eof;
	keep rank;
/* 	if _N_=1 then call symput("first",strip(rank)); */
	if eof then 
		do;
		call symput("count",_n_);
/* 		call symput("last",strip(rank)); */
		end;
run;

data _null_;
	set rank;
	%do i=1 %to &count;
		if _N_=&i then call symput("rank&i",strip(rank));
	%end;
run;


proc transpose data=a out=tmp prefix=OBS;
	where &where;
	var _all_;
	ID RANK;
run;

data tmp2;
	retain Var_Name Var_Label;
	array col[&count] $200. 
		%do i=1 %to &count;
			obs&&rank&i
		%end;;
	set tmp(rename=(_NAME_=Var_Name _LABEL_=Var_Label));
	%if &count ne 1 %then
		%do;
		if
		%do i=2 %to &count;
			%if &i=2 %then %str(col[1] ne col[2]);
			%else  %str(or col[1] ne col[&i]);
		%end;
		;
		%end;
	;
	
run;

title4 j=l "Records are displayed vertically";
title5 j=l "e.g. col1 stands for first record in dataset by condition";
title6 j=l "Only variables have different values in any two records would be displayed";
option nocenter;
proc print data=tmp2;
run;
%mend;

%findrecord(dsin=qcdatv.qc_tmm_r, where=%str(SID like '%10041001%'));

%findrecord(dsin=datvprot.tmm_r, where=%str(SID like '%10011001%' and DISBLFLG=1));
