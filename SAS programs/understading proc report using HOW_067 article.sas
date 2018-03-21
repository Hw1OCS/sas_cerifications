
%let proj_fld = U:\OCS\Certifications\SAS\01 SAS Clinical Trials\02 Exam attempts\sas_cerifications\SAS programs;

filename diab "&proj_fld\diabetes.csv";

/* read diabetes dataset */
proc import datafile=diab out=diabetes_raw
	dbms=csv
	replace;
	getnames=yes;
run;

/* understanding proc report. */
data diabetes;
	set work.diabetes_raw;
	if mod(_n_,2)=0 then trt='B';
	else trt='A';
run;

proc contents data=diabetes;
run;
