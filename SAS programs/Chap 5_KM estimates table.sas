
%let proj = U:\OCS\Certifications\SAS\01 SAS Clinical Trials\02 Exam attempts\sas_cerifications\SAS programs;

**** INPUT SAMPLE TREATMENT AND TIME TO DEATH DATA AS A SMALL 
**** PART OF AN ADAM ADTTE ANALYSIS DATASET.;
data ADTTE;
label TRTA = "Actual Treatment"
AVAL = "Analysis Value"
CNSR = "Censor";
input TRTA $ AVAL CNSR @@;
datalines;
A 52 0 A 825 1 C 693 1 C 981 1
B 279 0 B 826 1 B 531 1 B 15 1
C 1057 1 C 793 1 B 1048 1 A 925 1
C 470 1 A 251 0 C 830 1 B 668 0
B 350 1 B 746 1 A 122 0 B 825 1
A 163 0 C 735 1 B 699 1 B 771 0
C 889 1 C 932 1 C 773 0 C 767 1
A 155 1 A 708 1 A 547 1 A 462 0
B 114 0 B 704 1 C 1044 1 A 702 0
A 816 1 A 100 0 C 953 1 C 632 1
C 959 1 C 675 1 C 960 0 A 51 1
B 33 0 B 645 1 A 56 0 A 980 0
C 150 1 A 638 1 B 905 1 B 341 0
B 686 1 B 638 1 A 872 0 C 1347 1
A 659 1 A 133 0 C 360 1 A 907 0
C 70 1 A 592 1 B 112 1 B 882 0
A 1007 1 C 594 1 C 7 1 B 361 1
B 964 1 C 582 1 B 1024 0 A 540 0
C 962 1 B 282 1 C 873 1 C 1294 1
B 961 1 C 521 1 A 268 0 A 657 1
C 1000 1 B 9 0 A 678 1 C 989 0
A 910 1 C 1107 1 C 1071 0 A 971 1
C 89 1 A 1111 1 C 701 1 B 364 0
B 442 0 B 92 0 B 1079 1 A 93 1
B 532 0 A 1062 1 A 903 1 C 792 1
C 136 1 C 154 1 C 845 1 B 52 1
A 839 1 B 1076 1 A 834 0 A 589 1
A 815 1 A 1037 1 B 832 1 C 1120 1
C 803 1 C 16 0 A 630 1 B 546 1
A 28 0 A 1004 1 B 1020 1 A 75 1
C 1299 1 B 79 1 C 170 1 B 945 1
B 1056 1 B 947 1 A 1015 1 A 190 0
B 1026 1 C 128 0 B 940 1 C 1270 1
A 1022 0 A 915 1 A 427 0 A 177 0
C 127 1 B 745 0 C 834 1 B 752 1
A 1209 1 C 154 1 B 723 1 C 1244 1
C 5 1 A 833 1 A 705 1 B 49 1
B 954 1 B 60 0 C 705 1 A 528 1
A 952 1 C 776 1 B 680 1 C 88 1
C 23 1 B 776 1 A 667 1 C 155 1
B 946 1 A 752 1 C 1076 1 A 380 0
B 945 1 C 722 1 A 630 1 B 61 0
C 931 1 B 2 1 B 583 1 A 282 0
A 103 0 C 1036 1 C 599 1 C 17 1
C 910 1 A 760 1 B 563 1 B 347 0
B 907 1 B 896 1 A 544 1 A 404 0
A 8 0 A 895 1 C 525 1 C 740 1
C 11 1 C 446 0 C 522 1 C 254 1
A 868 1 B 774 1 A 500 1 A 27 1
B 842 1 A 268 0 B 505 1 B 505 0
;
run;

**** PERFORM LIFETEST AND EXPORT SURVIVAL ESTIMATES TO
**** SURVEST DATA SET.;
ods listing close;
ods output ProductLimitEstimates = survivalest;
	proc lifetest
	data=adtte;
		time aval * cnsr(1);
		strata trta;
	run;
ods output close;
ods listing;

data survivalest;
	set survivalest;
	**** CALCULATE VISIT WINDOW (MONTHS);
	if aval = 0 then
	visit = 0; **** Baseline;
	else if 1 <= aval <= 91 then
	visit = 91; **** 3 Months;
	else if 92 <= aval <= 183 then
	visit = 183; **** 6 Months;
	else if 184 <= aval <= 365 then
	visit = 365; **** 1 Year;
	else if 366 <= aval <= 731 then
	visit = 731; **** 2 Years;
	else if 732 <= aval <= 1096 then
	visit = 1096; **** 3 Years;
	else if 1097 <= aval <= 1461 then
	visit = 1461; **** 4 Years;
	else
	put "ERR" "OR: event data beyond visit mapping "
	aval = ;
run;

proc sort
	data = survivalest;
	by trta visit aval;
run;

**** CREATE 95% CONFIDENCE INTERVAL AROUND THE ESTIMATE
**** AND RETAIN PROPER SURVIVAL ESTIMATE FOR TABLE.;
data survivalest;
	set survivalest;
	by trta visit aval;
	keep trta visit count left survprob lcl ucl;

	retain count survprob lcl ucl;

	**** INITIALIZE VARIABLES TO MISSING FOR EACH TREATMENT.;
	if first.trta then
	do;
		survprob = .;
		count = .;
		lcl = .;
		ucl = .;
	end;
	**** CARRY FORWARD OBSERVATIONS WITH AN ESTIMATE.;
	if survival ne . then
	do;
		count = failed;
		survprob = survival;
		**** SUPPRESS CONFIDENCE INTERVALS AT BASELINE.;
		if visit ne 0 and stderr ne . then
		do;
			lcl = survival - (stderr*1.96);
			ucl = survival + (stderr*1.96);
		end;
	end;
	**** KEEP ONE RECORD PER VISIT WINDOW.;
	if last.visit;
run;

proc sort
data = survivalest;
by visit;
run;

**** COLLAPSE TABLE BY TREATMENT. THIS IS DONE BY MERGING THE 
**** SURVIVALEST DATA SET AGAINST ITSELF 3 TIMES.;
data table;
merge survivalest
	(where=(trta="A")
	rename =(count=count_a left=left_a
	survprob=survprob_a lcl=lcl_a ucl=ucl_a))
	survivalest
	(where=(trta="B")
	rename =(count=count_b left=left_b
	survprob=survprob_b lcl=lcl_b ucl=ucl_b))
	survivalest
	(where=(trta="C")
	rename =(count=count_c left=left_c));
	by visit;
run;

**** CREATE VISIT FORMAT USED IN TABLE.;
proc format;
value visit
0 = "Baseline"
91 = "3 Months"
183 = "6 Months"
365 = "1 Year"
731 = "2 Years"
1096 = "3 Years"
1461 = "4 Years";
run;

**** CREATE SUMMARY WITH PROC REPORT;
options nodate nonumber missing = ' ';
ods escapechar='#';
ods pdf style=htmlblue file="&proj.\program5.7.pdf";
proc report
	data = table
	nowindows
	split = "|";
	columns (visit
	("Placebo" count_a left_a survprob_a
	("95% CIs" lcl_a ucl_a))
	("Old Drug" count_b left_b survprob_b
	("95% CIs" lcl_b ucl_b))
	("New Drug" count_c left_c survprob_c
	("95% CIs" lcl_c ucl_c)) );

	define visit /order order = internal "Visit" left
	format = visit.;
	define count_a /display "Cum. Deaths" width = 6
	format = 3. center;
	define left_a /display "Remain at Risk" width = 6
	format = 3. center spacing = 0;
	define survprob_a /display "Surv- ival Prob." center
	format = pvalue5.3;
	define lcl_a /display "Lower" format = 5.3;
	define ucl_a /display "Upper" format = 5.3;
	define count_b /display "Cum. Deaths" width = 6
	format = 3. center;
	define left_b /display "Remain at Risk" width = 6
	format = 3. center spacing = 0;
	define survprob_b /display "Surv- ival Prob." center
	format = pvalue5.3;
	define lcl_b /display "Lower" format = 5.3;
	define ucl_b /display "Upper" format = 5.3;
	define count_c /display "Cum. Deaths" width = 6
	format = 3. center;
	define left_c /display "Remain at Risk" width = 6
	format = 3. center spacing = 0;
	define survprob_c /display "Surv- ival Prob." center
	format = pvalue5.3;
	define lcl_c /display "Lower" format = 5.3;
	define ucl_c /display "Upper" format = 5.3;

	break after visit / skip;

	title1 j=l 'Company/Trial Name'
	j=r 'Page #{thispage} of #{lastpage}';
	title2 j=c 'Table 5.7';
	title3 j=c 'Kaplan-Meier Survival Estimates for Death Over Time';
	footnote1 "Created by %sysfunc(getoption(sysin)) on &sysdate9..";
run;
ods pdf close;