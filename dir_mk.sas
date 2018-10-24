%let original_des=%str(/export/project13/app1/CLIN/studies/mig);
%let project_new=%str(b3741002);
/*x "cd &original_des.";
x "mkdir &project_new.";*/

%let file_des=&original_des./&project_new.;

/*x "cd &file_des.";
x "mkdir data derived document eSub import listing macro stat";
x "chmod 775 data derived document eSub import listing macro stat";*/

***Derived/...; 
x "cd &file_des./derived";
x "mkdir ADaM SDTM";
x "chmod 775 ADaM SDTM";

***eSub/...;
x "cd &file_des./eSub";
x "mkdir analysis archived programs report tabulations util";
x "chmod 775 analysis archived programs report tabulations util";

	****eSub/analysis/....;
	x "cd &file_des./eSub/analysis";
	x "mkdir adam legacy";
	x "chmod 775 adam legacy";
	
		****eSub/analysis/adam/....;
		x "cd &file_des./eSub/analysis/adam";
		x "mkdir datasets programs";
		x "chmod 775 datasets programs";

	***eSub/tabulations/...;
	x "cd &file_des./eSub/tabulations";
	x "mkdir legacy programs sdtm";
	x "chmod 775 legacy programs sdtm";

***import/...;
x "cd &file_des./import";
x "mkdir ADaM data derived raw SDTM";
x "chmod 775 ADaM data derived raw SDTM";

***listing/...;
x "cd &file_des./listing";
x "mkdir archived";
x "chmod 775 archived";

***macro/...;


***stat/...;
x "cd &file_des./stat";
x "mkdir background crtdata efficacy safety";
x "chmod 775 background crtdata efficacy safety";

