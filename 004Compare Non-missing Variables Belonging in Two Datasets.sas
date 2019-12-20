%macro Dataprocess(dsin1=,dsin2=,j=1);
title "&&dsin&j";
proc contents data = &&dsin&j out = ck&j noprint;
run;
quit ;
 
proc sql noprint;
	select Name into : charlst&j   SEPARATED  by " " from ck&j ;
quit ;

proc sql NOPRINT;
	select Type into: typelst&j SEPARATED BY " " FROM CK&j;
QUIT;

%if %symexist(varlist&j) = 0 %then  %let varlist&j = &&charlst&j ;

proc sql;
	create table D&j._max as
	select distinct "Max" as AAcol1,
		%let numchr&j=0;
		%do %while(%scan(&&varlist&j, &&numchr&j + 1, %str( ))^=);
			%let numchr&j=%eval(&&numchr&j + 1);
			%let tempvar&j=%scan(&&varlist&j, &&numchr&j, %str( ));
			%IF %SCAN(&&TYPELST&j,&&NUMCHR&j,%STR( ))=1 %THEN
				%DO; PUT(max(&&tempvar&j),BEST.) as &&tempvar&j %END;
 			%ELSE  %DO; max(&&tempvar&j) as &&tempvar&j %END;
 			%if %scan(&&varlist&j, &&numchr&j + 1, %str( ))^= %then %do; , %end; 	       
		%end;
	from &&dsin&j;
quit;

proc transpose data=D&j._max out=D&j._max2 prefix=max;
	VAR _ALL_;
run;

PROC SORT DATA=D&j._MAX2;
	BY _NAME_;
RUN;

PROC SORT DATA=CK&j(RENAME=(NAME=_NAME_) KEEP=NAME LABEL);
	BY _NAME_;
RUN;

data D&j.Info1;
	MERGE D&j._max2 CK&j;
	BY _NAME_;
	Var_Name=upcase(_NAME_);
	if Var_NAME ne "AACOL1";
	Rename Label=Var_Label;
	proc sort;
	BY Var_Name;
run;

data D&j.Info2;
	set D&j.info1;
	if not(strip(max1)="" or strip(max1)=".") ;
run;
%mend;

%macro ProduceOut(j,sort_id);
%if &j=2 %then
	%str(title1 "Compare Non-missing Varibel Names and Labels in &dsin1 and &dsin2 Dataset";);
%else 
	%str(title1 "Compare All Varibel Names and Labels in &dsin1 and &dsin2 Dataset";);
title2 "SourceA: &dsin1 | SourceB:&dsin2";	
data bothData&j;
	retain INCLUSION Var_NAME Var_Label;
	length INCLUSION $6.;
	merge D1Info&j(in=a Keep=Var_Name Var_Label) 
		  D2Info&j(in=b Keep=Var_Name Var_Label);
/* 	by _NAME_ LABEL; */
	by Var_Name;
	if A and not B then INCLUSION="A Only";
	if B and not A then INCLUSION="B Only";
	if A and B then INCLUSION="Both";
	proc sort;
	by INCLUSION;
	%if %trim(&sort_id) eq %then
		%do;
		proc print;		
		%end;
run;

%mend;

%macro SameVar_diffValue(j,sort_id);
	%if %trim(&sort_id) ne %then
		%do;
		proc sql noprint;
			select distinct var_name into: varlst separated by " "
			from bothData&j
			where inclusion="Both";
		quit;
		
		%let small_sort_id=%sysfunc(tranwrd(&sort_id,%str( ),%str(,)));
		%if &varlst ne %then
			%do;
			data diff_sum_all;
			length var_name $32.;
			run;
			%do k=1 %to %sysfunc(countw(&varlst));
				%let var_&k=%sysfunc(scan(&varlst, &k," "));
				proc sql;
					create table disout1_&k as 
					select distinct &small_sort_id , &&var_&k
					from &dsin1;
					
					create table disout2_&k as 
					select distinct &small_sort_id , &&var_&k
					from &dsin2;
				quit;
				
				proc compare base=disout1_&k compare=disout2_&k out=diff&k outnoequal noprint;
				run;		

				data _null_;
					set diff&k end=eof;
					if eof then	call symput("diff&k", _n_);
				run;
				
				%if %symexist(diff&k) %then 
					%do;
					data diff_sum_&k;
						var_name="&&var_&k";
						diff_value="Y";
					run;
					
					data diff_sum_all;
						set diff_sum_all diff_sum_&k;
					run;
					%end;
			%end;
			%end;
		
		data _null_;
			set diff_sum_all end=eof;
			if eof then	call symput("diff_sum_all", _n_);
		run;
		
		%if %symexist(diff_sum_all) %then
			%do;
			proc sql;
				create table bothData_add&j as 
				select a.*, b.diff_value
				from bothData&j as a 
				left join diff_sum_all as b on a.var_name=b.var_name
				order by inclusion, diff_value;
			quit;
			proc print;
			run;
			%end;
		
		%end;
%mend;


%macro TwoDataNonMisVarComp(dsin1=,dsin2=,sort_id=) ; 
	%Dataprocess(dsin1=&dsin1,dsin2=,j=1);
	
	%Dataprocess(dsin1=,dsin2=&dsin2,j=2);
	
	%ProduceOut(j=2,sort_id=&sort_id);
	%SameVar_diffValue(j=2,sort_id=&sort_id);	
	
	%ProduceOut(j=1,sort_id=&sort_id);
	%SameVar_diffValue(j=1,sort_id=&sort_id);	
	
%mend;

%TwoDataNonMisVarComp(dsin1=viewprot.pkct001_1,dsin2=viewprot.pkct001_1_sctpk1qg1_1_02, sort_id=%str(SUBJECTNUMBERSTR)) ;
