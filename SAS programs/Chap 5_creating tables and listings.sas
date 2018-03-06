
%let proj = U:\OCS\Certifications\SAS\01 SAS Clinical Trials\02 Exam attempts\sas_cerifications\SAS programs;

/* pp. 124 - ... */
/*proc format;*/
/*	value trtpn */
/*		1 = 'Active'*/
/*		0 = 'Placebo'*/
/*		;*/
/*run;*/
/**/
/*data class;*/
/*	set sashelp.class (rename = (sex=sexn));*/
/*	if _n_ <= 10 then trtpn=1;*/
/*	else              trtpn=0;*/
/*	format trtpn trtpn.;*/
/*run;*/

**** INPUT SAMPLE DEMOGRAPHICS DATA AS CDISC ADaM ADSL;
data ADSL;
	label USUBJID = "Unique Subject Identifier"
	TRTPN = "Planned Treatment (N)"
	SEXN = "Sex (N)"
	RACEN = "Race (N)"
	AGE = "Age";
	input USUBJID $ TRTPN SEXN RACEN AGE @@;
	datalines;
101 0 1 3 37 301 0 1 1 70 501 0 1 2 33 601 0 1 1 50 701 1 1 1 60
102 1 2 1 65 302 0 1 2 55 502 1 2 1 44 602 0 2 2 30 702 0 1 1 28
103 1 1 2 32 303 1 1 1 65 503 1 1 1 64 603 1 2 1 33 703 1 1 2 44
104 0 2 1 23 304 0 1 1 45 504 0 1 3 56 604 0 1 1 65 704 0 2 1 66
105 1 1 3 44 305 1 1 1 36 505 1 1 2 73 605 1 2 1 57 705 1 1 2 46
106 0 2 1 49 306 0 1 2 46 506 0 1 1 46 606 0 1 2 56 706 1 1 1 75
201 1 1 3 35 401 1 2 1 44 507 1 1 2 44 607 1 1 1 67 707 1 1 1 46
202 0 2 1 50 402 0 2 2 77 508 0 2 1 53 608 0 2 2 46 708 0 2 1 55
203 1 1 2 49 403 1 1 1 45 509 0 1 1 45 609 1 2 1 72 709 0 2 2 57
204 0 2 1 60 404 1 1 1 59 510 0 1 3 65 610 0 1 1 29 710 0 1 1 63
205 1 1 3 39 405 0 2 1 49 511 1 2 2 43 611 1 2 1 65 711 1 1 2 61
206 1 2 1 67 406 1 1 2 33 512 1 1 1 39 612 1 1 2 46 712 0 . 1 49
;
run;

**** DEFINE VARIABLE FORMATS NEEDED FOR TABLE;
proc format;
	value trtpn
	1 = "Active"
	0 = "Placebo";
	value sexn
	. = "Missing"
	1 = "Male"
	2 = "Female";
	value racen
	1 = "White"
	2 = "Black"
	3 = "Other*";
run;
**** DUPLICATE THE INCOMING DATASET FOR OVERALL COLUMN CALCULATIONS
**** SO NOW TRT HAS VALUES 0 = PLACEBO, 1 = ACTIVE, AND 2 = OVERALL.;
data adsl; 
	set adsl;
	output;
	trtpn = 2;
	output;
run;


**** AGE STATISTICS PROGRAMMING ************************************;
**** GET P VALUE FROM NON PARAMETRIC COMPARISON OF AGE MEANS.; 
proc npar1way
	data = adsl
	wilcoxon
	noprint;
	where trtpn in (0,1);
	class trtpn;
	var age;
	output out=pvalue wilcoxon;
run;

***** GET AGE DESCRIPTIVE STATISTICS N, MEAN, STD, MIN, AND MAX.;
proc sort
	data=adsl;
	by trtpn;
run;

proc univariate
	data = adsl noprint;
	by trtpn;
	var age;
	output out = age
	n = _n mean = _mean std = _std min = _min max = _max;
run;

**** FORMAT AGE DESCRIPTIVE STATISTICS FOR THE TABLE.;
data age;
	set age;
	format n mean std min max $14.;
	drop _n _mean _std _min _max;
	n = put(_n,5.);
	mean = put(_mean,7.1);
	std = put(_std,8.2);
	min = put(_min,7.1);
	max = put(_max,7.1);
run;

**** TRANSPOSE AGE DESCRIPTIVE STATISTICS INTO COLUMNS.;
proc transpose
	data = age
	out = age
	prefix = col;
	var n mean std min max;
	id trtpn;
run;

**** CREATE AGE FIRST ROW FOR THE TABLE.;
data label;
	set pvalue(keep = p2_wil rename = (p2_wil = pvalue));
	length label $ 85;
	label = "#S={font_weight=bold} Age (years)";
run;

**** APPEND AGE DESCRIPTIVE STATISTICS TO AGE P VALUE ROW AND
**** CREATE AGE DESCRIPTIVE STATISTIC ROW LABELS.;
data age;
	length label $ 85 col0 col1 col2 $ 25 ;
	set label age;
	keep label col0 col1 col2 pvalue ;

	if _n_ > 1 then
		select;
			when(_NAME_ = 'n')    label = "#{nbspace 6}N"; 
			when(_NAME_ = 'mean') label = "#{nbspace 6}Mean";
			when(_NAME_ = 'std')  label = "#{nbspace 6}Standard Deviation";
			when(_NAME_ = 'min')  label = "#{nbspace 6}Minimum";
			when(_NAME_ = 'max')  label = "#{nbspace 6}Maximum";
	otherwise;
	end;
run;
**** END OF AGE STATISTICS PROGRAMMING *****************************;

**** SEX STATISTICS PROGRAMMING ************************************;
**** GET SIMPLE FREQUENCY COUNTS FOR SEX.;
proc freq
data = adsl
noprint;
where trtpn ne .;
tables trtpn * sexn / missing outpct out = sexn;
run;
**** FORMAT SEX N(%) AS DESIRED.;
data sexn;
set sexn;
where sexn ne .;
length value $25;
value = put(count,4.) || ' (' || put(pct_row,5.1)||'%)';
run;
proc sort
data = sexn;
by sexn;
run;
**** TRANSPOSE THE SEX SUMMARY STATISTICS.;
proc transpose
data = sexn
out = sexn(drop = _name_)
prefix = col;
by sexn;
var value;
id trtpn;
run;

**** PERFORM A CHI-SQUARE TEST ON SEX COMPARING ACTIVE VS PLACEBO.;
proc freq
data = adsl
noprint;
where sexn ne . and trtpn not in (.,2);
table sexn * trtpn / chisq;
output out = pvalue pchi;
run;
**** CREATE SEX FIRST ROW FOR THE TABLE.;
data label;
set pvalue(keep = p_pchi rename = (p_pchi = pvalue));
length label $ 85;
label = "#S={font_weight=bold} Sex";
run;
**** APPEND SEX DESCRIPTIVE STATISTICS TO SEX P VALUE ROW AND
**** CREATE SEX DESCRIPTIVE STATISTIC ROW LABELS.;
data sexn;
length label $ 85 col0 col1 col2 $ 25 ;
set label sexn;
keep label col0 col1 col2 pvalue ;
if _n_ > 1 then
label= "#{nbspace 6}" || put(sexn,sexn.);
run;
**** END OF SEX STATISTICS PROGRAMMING *****************************;

**** RACE STATISTICS PROGRAMMING ***********************************;
**** GET SIMPLE FREQUENCY COUNTS FOR RACE;
proc freq
data = adsl
noprint;
where trtpn ne .;
tables trtpn * racen / missing outpct out = racen;
run;
**** FORMAT RACE N(%) AS DESIRED;
data racen;
set racen;
where racen ne .;
length value $25;
value = put(count,4.) || ' (' || put(pct_row,5.1)||'%)';
run;
proc sort
data = racen;
by racen;
run;

**** TRANSPOSE THE RACE SUMMARY STATISTICS;
proc transpose
data = racen
out = racen(drop = _name_)
prefix=col;
by racen;
var value;
id trtpn;
run;
**** PERFORM FISHER'S EXACT TEST ON RACE COMPARING ACTIVE & PLACEBO.;
proc freq 
data = adsl
noprint;
where racen ne . and trtpn not in (.,2);
table racen * trtpn / exact;
output out = pvalue exact;
run;
**** CREATE RACE FIRST ROW FOR THE TABLE.;
data label;
set pvalue(keep = xp2_fish rename = (xp2_fish = pvalue));
length label $ 85;
label = "#S={font_weight=bold} Race";
run;
**** APPEND RACE DESCRIPTIVE STATISTICS TO RACE P VALUE ROW AND
**** CREATE RACE DESCRIPTIVE STATISTIC ROW LABELS.;
data racen;
length label $ 85 col0 col1 col2 $ 25 ;
set label racen;
keep label col0 col1 col2 pvalue ;
if _n_ > 1 then
label= "#{nbspace 6}" || put(racen,racen.);
run;
**** END OF RACE STATISTICS PROGRAMMING
*******************************************************************;

**** CONCATENATE AGE, SEX, AND RACE STATISTICS AND CREATE GROUPING
**** GROUP VARIABLE FOR LINE SKIPPING IN PROC REPORT.;
data forreport;
set age(in = in1)
sexn(in = in2)
racen(in = in3);
group = sum(in1 * 1, in2 * 2, in3 * 3);
run;
**** DEFINE THREE MACRO VARIABLES &N0, &N1, AND &NT THAT ARE USED IN
**** THE COLUMN HEADERS FOR "PLACEBO," "ACTIVE" AND "OVERALL" THERAPY
**** GROUPS.; 
data _null_;
set adsl end=eof;
**** CREATE COUNTER FOR N0 = PLACEBO, N1 = ACTIVE.;
if trtpn = 0 then
n0 + 1;
else if trtpn = 1 then
n1 + 1;
**** CREATE OVERALL COUNTER NT.;
nt + 1;
**** CREATE MACRO VARIABLES &N0, &N1, AND &NT.;
if eof then
do;
call symput("n0",compress('(N='||put(n0,4.) || ')'));
call symput("n1",compress('(N='||put(n1,4.) || ')'));
call symput("nt",compress('(N='||put(nt,4.) || ')'));
end;
run;

/*%put _all_;*/

**** USE PROC REPORT TO WRITE THE DEMOGRAPHICS TABLE TO FILE.;


options nodate nonumber missing = ' ';
ods escapechar='#';
ods pdf style=htmlblue file="&proj.\program5.3.pdf";
proc report
	data=forreport
	nowindows
	spacing=1
	headline
	headskip
	split = "|"
	;
/*	columns (group label col1 col0 col2 pvalue);*/
	columns group label col1 col0 col2 pvalue;

	define group /order order = internal noprint;
	define label /display " ";
	define col0 /display style(column)=[asis=on] "Placebo|&n0";
	define col1 /display style(column)=[asis=on] "Active|&n1";
	define col2 /display style(column)=[asis=on] "Overall|&nt";
	define pvalue /display center " |P-value**" f = pvalue6.4;

	compute after group;
		line '#{newline}';
	endcomp;

	title1 j=l 'Company/Trial Name'
		   j=r 'Page #{thispage} of #{lastpage}';
	title2 j=c 'Table 5.3';
	title3 j=c 'Demographics and Baseline Characteristics';

	footnote1 j=l '* Other includes Asian, Native American, and other'
	' races.';
	footnote2 j=l
	"** P-values: Age = Wilcoxon rank-sum, Sex = Pearson's"
	" chi-square, Race = Fisher's exact test.";
	footnote3 j=l
	"Created by %sysfunc(getoption(sysin)) on &sysdate9..";
run;
ods pdf close;

/*******************************************************************************
    Creating Adverse Event Summaries
*******************************************************************************/
**** INPUT SAMPLE TREATMENT DATA.;
**** INPUT TREATMENT CODE DATA AS ADAM ADSL DATA.; 
data ADSL;
length USUBJID $ 3;
label USUBJID = "Unique Subject Identifier"
TRTPN = "Planned Treatment (N)";
input USUBJID $ TRTPN @@;
datalines;
101	1 102 0 103 0 104 1 105 0 106 0 107 1 108 1 109 0 110 1
111 0 112 0 113 0 114 1 115 0 116 1 117 0 118 1 119 1 120 1
121 1 122 0 123 1 124 0 125 1 126 1 127 0 128 1 129 1 130 1
131 1 132 0 133 1 134 0 135 1 136 1 137 0 138 1 139 1 140 1
141 1 142 0 143 1 144 0 145 1 146 1 147 0 148 1 149 1 150 1
151 1 152 0 153 1 154 0 155 1 156 1 157 0 158 1 159 1 160 1
161 1 162 0 163 1 164 0 165 1 166 1 167 0 168 1 169 1 170 1
;
run;
**** INPUT ADVERSE EVENT DATA AS SDTM AE DOMAIN.;
%macro donotrun;

data AE;
label USUBJID = "Unique Subject Identifier"
AEBODSYS = "Body System or Organ Class"
AEDECOD = "Dictionary-Derived Term"
AEREL = "Causality"
AESEV = "Severity/Intensity";
input USUBJID $ 1-3 AEBODSYS $ 5-30 AEDECOD $ 34-50
AEREL $ 52-67 AESEV $ 70-77;
/*input USUBJID $ AEBODSYS $ AEDECOD $ */
/*AEREL $  AESEV $ @@;*/
datalines;
101	Cardiac disorders Atrial flutter NOT RELATED MILD
101 Gastrointestinal disorders Constipation POSSIBLY RELATED MILD
102 Cardiac disorders Cardiac failure POSSIBLY RELATED MODERATE
102 Psychiatric disorders Delirium NOT RELATED MILD
103 Cardiac disorders Palpitations NOT RELATED MILD
103 Cardiac disorders Palpitations NOT RELATED MODERATE
103 Cardiac disorders Tachycardia POSSIBLY RELATED MODERATE
115 Gastrointestinal disorders Abdominal pain RELATED MODERATE
115 Gastrointestinal disorders Anal ulcer RELATED MILD
116 Gastrointestinal disorders Constipation POSSIBLY RELATED MILD
117 Gastrointestinal disorders Dyspepsia POSSIBLY RELATED MODERATE
118 Gastrointestinal disorders Flatulence RELATED SEVERE
119 Gastrointestinal disorders Hiatus hernia NOT RELATED SEVERE
130 Nervous system disorders Convulsion NOT RELATED MILD
131 Nervous system disorders Dizziness POSSIBLY RELATED MODERATE
132 Nervous system disorders Essential tremor NOT RELATED MILD
135 Psychiatric disorders Confusional state NOT RELATED SEVERE
140 Psychiatric disorders Delirium NOT RELATED MILD
140 Psychiatric disorders Sleep disorder POSSIBLY RELATED MILD
141 Cardiac disorders Palpitations NOT RELATED SEVERE
;
run;

%mend donotrun;

filename pp132 "&proj.\ae_pp132.csv";

proc import datafile=pp132 out=ae 
	dbms=csv
	replace;
	getnames=yes;
run;

data ae (drop = _usubjid);
	length usubjid $ 3;
	set ae (rename = (usubjid=_usubjid));
	usubjid = put(_usubjid, 3.);
run;

**** CREATE ADAE ADAM DATASET TO MAKE HELPFUL COUNTING FLAGS FOR 
**** SUMMARIZATION. THIS WOULD TYPICALLY BE DONE AS A SEPARATE
**** PROGRAM OUTSIDE OF AN AE SUMMARY.;
data adae;
	merge ae(in=inae) adsl;
	by usubjid;
	if inae;

	select (aesev);
		when('MILD') aesevn = 1;
		when('MODERATE') aesevn = 2;
		when('SEVERE') aesevn = 3;
		otherwise;
	end;
	label aesevn = "Severity/Intensity (N)";
run;
proc sort
	data=adae;
	by usubjid aesevn;
run;

data adae;
	set adae;
	by usubjid aesevn;
	if last.usubjid then
	aoccifl = 'Y';
	label aoccifl = "1st Max Sev./Int. Occurrence Flag";
run;
proc sort
data=adae;
by usubjid aebodsys aesevn;
run;
data adae;
set adae;
by usubjid aebodsys aesevn;
if last.aebodsys then
aoccsifl = 'Y';
label aoccsifl = "1st Max Sev./Int. Occur Within SOC Flag";
run;
proc sort
data=adae;
by usubjid aedecod aesevn;
run;
data adae;
set adae;
by usubjid aedecod aesevn;
if last.aedecod then
aoccpifl = 'Y';
label aoccpifl = "1st Max Sev./Int. Occur Within PT Flag";
run;
**** END OF ADAM ADAE ADAM DATASET DERIVATIONS;

**** PUT COUNTS OF TREATMENT POPULATIONS INTO MACRO VARIABLES; 
proc sql noprint;
	select count(unique usubjid) format = 3.
	into :n0 from adsl where trtpn=0;
	select count(unique usubjid) format = 3.
	into :n1 from adsl where trtpn=1;
	select count(unique usubjid) format = 3.
	into :n2 from adsl;
quit;
**** OUTPUT A SUMMARY TREATMENT SET OF RECORDS. TRTPN=2; 
data adae;
set adae;
output;
trtpn=2;
output;
run;
**** BY SEVERITY ONLY COUNTS; 
proc sql noprint;
create table All as
select trtpn,
sum(aoccifl='Y') as frequency from adae
group by trtpn;
quit;
proc sql noprint;
create table AllBySev as
select aesev, trtpn,
sum(aoccifl='Y') as frequency from adae
group by aesev, trtpn;
quit;
**** BY BODY SYSTEM AND SEVERITY COUNTS;
proc sql noprint;
create table AllBodysys as
select trtpn, aebodsys,
sum(aoccsifl='Y') as frequency from adae
group by trtpn, aebodsys;
quit;
proc sql noprint;
create table AllBodysysBysev as
select aesev, trtpn, aebodsys,
sum(aoccsifl='Y') as frequency from adae
group by aesev, trtpn, aebodsys;
quit;
**** BY PREFERRED TERM AND SEVERITY COUNTS;
proc sql noprint;
create table AllPT as
select trtpn, aebodsys, aedecod,
sum(aoccpifl='Y') as frequency from adae
group by trtpn, aebodsys, aedecod;
quit;
proc sql noprint;
create table AllPTBySev as
select aesev, trtpn, aebodsys, aedecod,
sum(aoccpifl='Y') as frequency from adae
group by aesev, trtpn, aebodsys, aedecod;
quit;
**** PUT ALL COUNT DATA TOGETHER; 
data all;
set All(in=in1)
AllBySev(in=in2)
AllBodysys(in=in3)
AllBodysysBysev(in=in4)
AllPT(in=in5)
AllPTBySev(in=in6);
length description $ 40 sorter $ 200;
if in1 then
description = 'Any Event';
else if in2 or in4 or in6 then
description = '#{nbspace 6} ' || propcase(aesev);
else if in3 then
description = aebodsys;
else if in5 then
description = '#{nbspace 3}' || aedecod;
sorter = aebodsys || aedecod || aesev;
run;
proc sort
data=all;
by sorter aebodsys aedecod description;
run;

**** TRANSPOSE THE FREQUENCY COUNTS;
proc transpose
	data=all
	out=flat
	prefix=count;
	by sorter aebodsys aedecod description;
	id trtpn;
	var frequency;
run;

proc sort
data=flat;
by aebodsys aedecod sorter;
run;
**** CREATE A SECTION BREAK VARIABLE AND FORMATTED COLUMNS;
data flat;
	set flat;
	by aebodsys aedecod sorter;

	retain section 1;

	length col0 col1 col2 $ 20;
	if count0 not in (.,0) then
	col0 = put(count0,3.) || " (" || put(count0/&n0*100,5.1) || "%)";
	if count1 not in (.,0) then
	col1 = put(count1,3.) || " (" || put(count1/&n1*100,5.1) || "%)";
	if count2 not in (.,0) then
	col2 = put(count2,3.) || " (" || put(count2/&n2*100,5.1) || "%)";
	if sum(count1,count2,count3)>0 then
	output;
	if last.aedecod then
	section + 1;
run;

/*%put _all_;*/

**** USE PROC REPORT TO WRITE THE AE TABLE TO FILE.;
options nodate nonumber missing = ' ';
ods escapechar='#';
ods pdf style=htmlblue file="&proj.\program5.4.pdf";
proc report
	data=flat
	nowindows
	split = "|";
	columns section description col1 col0 col2;

	define section /order order = internal noprint;
	define description /display style(header)=[just=left]
	"Body System|#{nbspace 3} Preferred Term|#{nbspace 6} Severity";
	define col0 /display "Placebo|N=&n0";
	define col1 /display "Active|N=&n1";
	define col2 /display "Overall|N=&n2";

	compute after section;
		line '#{newline}';
	endcomp;

	title1 j=l 'Company/Trial Name'
		   j=r 'Page #{thispage} of #{lastpage}';
	title2 j=c 'Table 5.4';
	title3 j=c 'Adverse Events';
	title4 j=c "By Body System, Preferred Term, and Greatest Severity";
run;
ods pdf close;