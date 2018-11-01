%macro sortuni(source=,varlst=);
proc sort data=&source out=tmp dupout=tmp2 nodupkey;
	by &varlst;
run;

data _null_;
	call symput('obscnt',0);
	set tmp2;
	call symput('obscnt',_n_);
	stop;
run;

%if %sysfunc(exist(tmp2)) ne 0 and &obscnt ne 0 %then 
	%do;
	title "Duplicated values were found in Source Data &source as following";
	proc print data=tmp2 (obs=10);
	run;
	%end;
%else 
	%do;
/* 	data info; */
/* 		Info="Dataset can be sorted by varlst without duplicated record"; */
/* 	run; */
/* 	proc print data=info; */
/* 	run; */
	data _null_;
		title "Dataset &source can be sorted by varlst without duplicated record";
		file print;
		put _page_;
		put "Variables (&varlst) Sort dataset successfully";
	run;
	%end;
%mend;
%sortuni(source=dataprot.tmm_p, varlst=%str(pt cpevent actevent repeatsn));