options minoperator mindelimiter=',';
%macro ln(dt=, var=);
   data &dt;
      set &dt;
      temp=length(strip(&var));
      rename &var.=&var.2;
   run;
   
   proc means data=&dt noprint;
      var temp;
      output out=tt max=max;
   run; 

   data null;
      set tt;
      max1=max;
      call symput ('N', trim(left(put(max1, 8.))));
   run;

   data &dt;
      length &var $&n;
      format &var $&n..;
      set &dt;
      &var.=strip(&var.2);
      drop &var.2; 
   run;
%mend;

%macro lnall (dsin=,varlist =&charlst) ; 
    proc contents data = &dsin out = ck noprint;
    run;
    quit;
    proc sql noprint;
        select distinct Name into : charlst SEPARATED  by " " 
        from ck (where= (type=2)) ;
    quit ;
    
    %if %symexist(varlist) = 0 %then  %let varlist = &charlst ;

    %let numchr=0;
    %do %while(%scan(&varlist, &numchr + 1, %str( ))^=);
        %let numchr=%eval(&numchr + 1);
        %let tempvar=%scan(&varlist, &numchr, %str( ));
        %ln(dt=&dsin , var=&tempvar);
    %end;
%mend ; 

%macro list_val(dsin=,varlist =&charlst) ; 
title "Source Dataset: &dsin";
data intermediate;
    set &dsin;
run;
%lnall(dsin=intermediate);
data intermediate;
    set intermediate;
    drop temp;
run;

proc contents data = intermediate out = ck noprint;
run;
quit ;
 
proc sql noprint;
    select Name into : charlst   SEPARATED  by " " from ck ;
quit ;

proc sql NOPRINT;
    select Type into: typelst SEPARATED BY " " FROM CK;
QUIT;

%if %symexist(varlist) = 0 %then  %let varlist = &charlst ;
ods escapechar="~";
%let numchr=0;
%let maxlen=200;
%let len_flag=N;
%let numcheck=N;
%let datecheck=N;
%let timecheck=N;
%do %while(%scan(&varlist, &numchr + 1, %str( ))^=);
    %let numchr=%eval(&numchr + 1);
    %let tempvar=%scan(&varlist, &numchr, %str( ));
    %IF %SCAN(&TYPELST,&NUMCHR,%STR( ))=1 %THEN
        %DO;
        data _null_;
            set &dsin;
            where prxmatch('/^\d+\.?\d*$/',left(strip(PUT(&tempvar,BEST.))));
            if _N_ then 
                do; 
                call symput("numcheck","Y");
                stop;
                end;
        run;
        
        proc sql noprint;
            select count(distinct &tempvar) into : val_num&numchr
            from &dsin
            where &tempvar ne .;
        quit;
        
        %if &numcheck=Y and %eval(&&val_num&numchr>10)  %then
            %let val_lst&numchr=%str(Number list greater than 10 and Value satisfied regular expression '/^\d+\.?\d*$/') ;
         %else
            %do;
            proc sql noprint;
                select distinct left(strip(PUT(&tempvar,BEST.)))  into : val_lst&numchr SEPARATED  by "  ~{newline}" 
                from &dsin
                where &tempvar ne .;
            quit;
            %end;
        %let numcheck=N;
         
        %END;
    %ELSE  
        %DO;
        %if %length(&tempvar)>=3 and %substr(&tempvar,%length(&tempvar)-2,3) in (DAT  ,    DTC   ) %then
            %do;
            data _null_;
                set &dsin;
                where prxmatch('/^\d{4}(-\d{2}){0,2}$/',left(strip(&tempvar)));
                if _N_ then 
                    do; 
                    call symput("Datecheck","Y");
                    stop;
                    end;
            run;
            %end;
        %if %length(&tempvar)>=3 and %substr(&tempvar,%length(&tempvar)-2,3)=TIM %then
            %do;
            data _null_;
                set &dsin;
                where prxmatch('/^\d{2}(:\d{2}){0,2}$/',left(strip(&tempvar)));
                if _N_ then 
                    do; 
                    call symput("timecheck","Y");
                    stop;
                    end;
            run;
            %end;
        
        proc sql noprint;
            select count(distinct &tempvar) into : val_num&numchr
                from &dsin
                where &tempvar ne "";
        quit ;
        %if (&datecheck=Y or &timecheck=Y) and %eval(&&val_num&numchr>10)  %then
            %do;
            %if &datecheck=Y %then
                %let val_lst&numchr=%str(Date list greater than 10 and Value satisfied regular expression '/^\d{4}(-\d{2}){0,2}$/') ;
            %else
                %let val_lst&numchr=%str(Time list greater than 10 and Value satisfied regular expression '/^\d{2}(:\d{2}){0,2}$/') ; 
            %end;
        %else
            %do;
            proc sql noprint;
                select distinct left(strip(&tempvar))  into : val_lst&numchr SEPARATED  by "  ~{newline}" 
                from &dsin
                where &tempvar ne "";
            quit;
            %end;
        %let datecheck=N;
        %let timecheck=N;
             
        %END;
        
    proc sql noprint;
        select distinct LENGTH into : var_len&numchr
        from ck
        where NAME="&tempvar";
    quit;
    %let maxlen=%sysfunc(max(%eval(&&var_len&numchr*&&val_num&numchr),&maxlen));
        
    %if %eval(32767<&&var_len&numchr*&&val_num&numchr) %then
        %let len_flag=Y;
        
    %put maxlen=&maxlen;
    
    data var&numchr;
        _NAME_="&tempvar";
        Val_numb="&&val_num&numchr";
        %if %symexist(val_lst&numchr) %then VAL_LST="&&val_lst&numchr";;
        len_exceed="&len_flag";
    run;
    %let len_flag=N;
    
%end;

%if &maxlen>32767 %then 
    %do;
    %let maxlen=%sysfunc(min(&maxlen,32767));
    data _null_;
        file print;
        put _page_;
        put "Value list total lenght may exceed 32767, display would be truncated";
    run;
    %end;

data all_val;
    length _NAME_ $20. Val_numb $8. VAL_LST $&maxlen..;
    set var1-var&numchr;
    proc sort;
    BY _NAME_;
run;

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

PROC SORT DATA=CK(RENAME=(NAME=_NAME_ TYPE=_TYPE) KEEP=NAME LENGTH LABEL TYPE FORMAT);
    BY _NAME_;
RUN;

data all;
    retain _NAME_ type Val_numb val_lst miss1 LABEL format;  
    length Type $4.;
    MERGE all_val MISS2 CK;
    BY _NAME_;
    
    if _n_ ne 1;
    if _TYPE=1 then Type="Num";
    else if _TYPE=2 then Type="Char";
    drop _Type;
    rename _NAME_=Var_Name max1=MaxValue min1=MinValueExcptMiss miss1=If_Missing LABEL=Var_Label;
    proc print;
run;

title "order by value list count";
proc sort data=all;
    by val_numb var_name;
    proc print;
run;

%mend;  

%list_val(dsin=raw.clab);
