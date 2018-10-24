%macro max_min(dsin=,varlist =&charlst) ; 
proc contents data = &dsin out = ck noprint;
run;
quit ;
 
proc sql noprint;
	select Name into : charlst   SEPARATED  by " " from ck ;
quit ;

proc sql NOPRINT;
	select Type into: typelst SEPARATED BY " " FROM CK;
QUIT;

%if %symexist(varlist) = 0 %then  %let varlist = &charlst ;

proc sql;
	create table max as
	select distinct "Max" as AAcol1,
		%let numchr=0;
		%do %while(%scan(&varlist, &numchr + 1, %str( ))^=);
			%let numchr=%eval(&numchr + 1);
			%let tempvar=%scan(&varlist, &numchr, %str( ));
			%IF %SCAN(&TYPELST,&NUMCHR,%STR( ))=1 %THEN
				%DO; PUT(max(&tempvar),BEST.) as &tempvar %END;
 			%ELSE  %DO; max(&tempvar) as &tempvar %END;
 			%if %scan(&varlist, &numchr + 1, %str( ))^= %then %do; , %end; 	       
		%end;
	from &dsin;
quit;

proc transpose data=max out=max2 prefix=max;
	VAR _ALL_;
run;

PROC SORT DATA=MAX2;
	BY _NAME_;
RUN;

proc sql;
	create table min as 
	select distinct "Min" as AAcol1,
		%let numchr=0;
		%do %while(%scan(&varlist, &numchr + 1, %str( ))^=);
			%let numchr=%eval(&numchr + 1);
			%let tempvar=%scan(&varlist, &numchr, %str( ));
			%IF %SCAN(&TYPELST,&NUMCHR,%STR( ))=1 %THEN
				%DO; PUT(min(&tempvar),BEST.) as &tempvar %END;
 			%ELSE  %DO; min(&tempvar) as &tempvar %END;
 			%if %scan(&varlist, &numchr + 1, %str( ))^= %then %do; , %end; 	       
		%end;
	from &dsin;
quit;

proc transpose data=min out=min2 prefix=min;
	VAR _ALL_;
run;

PROC SORT DATA=MIN2;
	BY _NAME_;
RUN;

proc sql;
	create table miss as 
	select distinct "Missing" as AAcol1,
		%let numchr=0;
		%do %while(%scan(&varlist, &numchr + 1, %str( ))^=);
			%let numchr=%eval(&numchr + 1);
			%let tempvar=%scan(&varlist, &numchr, %str( ));
 			max(missing(&tempvar)) as &tempvar
 			%if %scan(&varlist, &numchr + 1, %str( ))^= %then %do; , %end; 	       
		%end;
	from &dsin;
quit;

proc transpose data=miss out=miss2 prefix=miss;
	VAR _ALL_;
run;

PROC SORT DATA=MISS2;
	BY _NAME_;
RUN;

PROC SORT DATA=CK(RENAME=(NAME=_NAME_) KEEP=NAME LABEL);
	BY _NAME_;
RUN;

data all;
	MERGE max2 min2 MISS2 CK;
	BY _NAME_;
	IF MAX1=MIN1 THEN MIN1="---SAME AS LEFT---";
run;

proc print data=all;
run;
%mend; 
%max_min(dsin=data.mh1qg2);