*please change the base and compare datasets;
proc compare base=orig compare=qc out=check outbase outcomp outnoequal outdif noprint;
run;