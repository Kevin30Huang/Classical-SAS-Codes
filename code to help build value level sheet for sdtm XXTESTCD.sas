/*not recommend for qs and supp-- domain*/
proc sql;
	create table LB as
	select distinct "LBTESTCD" as a, LBTESTCD, LBTEST, LBTEST, 
	case when(LBSTRESN ne .) then "float" else "text" end as type
	from sdtm.LB;
quit;

data LBrank;
	set LB end=eof;
	rank=_n_;
	if eof then	call symput("numrank",rank);
run;

proc sql;
	create table LB as
	select a.*,b.rank
	from sdtm.LB as a
	left join LBrank as b
	on a.LBtestcd=b.LBtestcd;
quit;

%macro a;
	data a;
	run;
	%do i=1 %to &numrank;
	data b;
		length type $7.;
		set LB;
		where rank=&i;
		if LBstresn ne . then 
			do;
			avalc =input(LBstresn,best.);
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
		keep LBtestcd lbtest type ;
	run;
	data a;
		set a c;
	run;
	%end;

%mend;
%a;

proc print data=a;
run;
