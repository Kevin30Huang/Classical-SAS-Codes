/*not recommend for qs and supp-- domain*/
%macro ValLevSht(dsn,lib);
proc sql;
	create table &dsn as
	select distinct "&dsn.TESTCD" as a, &dsn.TESTCD, &dsn.TEST, &dsn.TEST, 
	case when(&dsn.STRESN ne .) then "float" else "text" end as type
	from &lib..&dsn;
quit;

data &dsn.rank;
	set &dsn. end=eof;
	rank=_n_;
	if eof then	call symput("numrank",rank);
run;

proc sql;
	create table &dsn. as
	select a.*,b.rank
	from &lib..&dsn. as a
	left join &dsn.rank as b
	on a.&dsn.testcd=b.&dsn.testcd;
quit;

data a;
run;
%do i=1 %to &numrank;
data b;
	length type $7.;
	set &dsn.;
	where rank=&i;
	if &dsn.stresn ne . then 
		do;
		avalc =input(&dsn.stresn,best.);
		if index(avalc,".") then
			do; typen=2; type="float"; end;
		else 
			do; typen=1; type="integer"; end;
		end;
	proc sort;
	by typen;
run;

data c;
	set b end=eof;
	if eof;
	keep &dsn.testcd &dsn.test type ;
run;
data a;
	set a c;
	if &dsn.testcd ne "";
run;
%end;

proc print data=a;
	var &dsn.testcd &dsn.test type;
run;

%mend;

%ValLevSht(dsn=LB,lib=dataprot);
