
%let proj = U:\OCS\Certifications\SAS\01 SAS Clinical Trials\02 Exam attempts\sas_cerifications\SAS programs;


data class;
	set sashelp.class;
run;

/* 2-sample ttest */
ods output Equality = variancetest;
ods output TTests = pvalue;

proc ttest data=class;
	class sex;
	var age;
run;

ods output close;

**** CHECK VARIANCES AND SELECT PROPER P-VALUE;
data pvalue2;
	if _n_ = 1 then
		set variancetest(keep = probf);
	set pvalue(keep = variances probt);
	keep probt;
	if (probf <= .05 and variances = "Unequal") or
	   (probf > .05 and variances = "Equal");
run;

***** TRACE ON/OFF;
ods trace on;

	proc ttest data=class;
		class sex;
		var age;
	run;

ods trace off;