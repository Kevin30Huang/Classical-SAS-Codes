%macro linuxcommand(dir);
Filename filelist pipe "dir &dir./*.sas"; 
                                                                                   
Data filelist;
               format filename $200.;                                        
               Infile filelist;
               Input filename $ @@;
               FILENAME2=SCAN(filename,-1,"/");
               Core=scan(FILENAME2,1,".");
               put "sas94 " Core +(-1) ".sas -log ../logs/" Core +(-1) 
               ".log -print ../output/" Core +(-1) ".lst;";
Run;
%mend;

%linuxcommand(dir=%str(/Volumes/app/cdars/prod/sites/groton/prjB349/nda1_cdisc/B3491017/saseng/cdisc3_0/analysis/QC/program));
/*copy log output to notepad++ and then replace \r\n with " " */
