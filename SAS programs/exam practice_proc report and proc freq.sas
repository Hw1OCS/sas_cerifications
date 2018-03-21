


proc format;
	value agefmt 
		low-13 = '<=13'
		13-high = '> 13';
	value wtfmt
		low-100 = '<=100'
		100-high = '>100';
run;


data class;
	set sashelp.class;

	age_cls = age;
	format age_cls agefmt.;

	weight_cls = weight;
	format weight_cls wtfmt.;
/**/
/*	if _n_=5 then do;*/
/*		age = .;*/
/*		age_cls = '';*/
/*	end;*/
run;

proc freq data=class;
/*	tables sex*age_cls / norow;*/
/*	tables sex*age_cls / nocol;*/
/*	tables age_cls*sex / norow nocol nopercent;*/
	tables sex*age_cls / norow nocol nopercent;
/*	tables sex*age_cls / norow nocol nopercent missing;*/
run;

/*ods output ChiSq = pvalues (where = (statistic eq 'Chi-Square'));*/
ods output ChiSq (match_all) = pvalues_opt (where = (statistic eq 'Chi-Square'));

/*ods trace on;*/
	proc freq data=class;
		tables sex*age_cls / chisq;
		tables sex*weight_cls / chisq;
	run;
/*ods trace off;*/
ods output close;

/* qn. 47 */
proc format;
	value aesevfmt
		1='Mild'
		2='Moderate'
		3='Severe'
		;
run;

data teae;
	subjid=1; aebodsys='nervous system'; aedecod='dizziness'; aesev=1; output;
	subjid=1; aebodsys='nervous system'; aedecod='headache'; aesev=2; output;
	subjid=1; aebodsys='nervous system'; aedecod='headache'; aesev=3; output;
	subjid=1; aebodsys='nervous system'; aedecod='dizziness'; aesev=2; output;
	subjid=1; aebodsys='nervous system'; aedecod='lethargy'; aesev=3; output;

	subjid=2; aebodsys='nervous system'; aedecod='dizziness'; aesev=1; output;
	subjid=2; aebodsys='nervous system'; aedecod='dizziness'; aesev=2; output;

	subjid=3; aebodsys='nervous system'; aedecod='headache'; aesev=3; output;
	subjid=3; aebodsys='nervous system'; aedecod='headache'; aesev=3; output;
	subjid=3; aebodsys='nervous system'; aedecod='lethargy'; aesev=2; output;

	subjid=4; aebodsys='nervous system'; aedecod='lethargy'; aesev=2; output;

	format aesev aesevfmt.;
run;


proc report data=class split="*" headline headskip
	out=report_class;
	column sex age height;
	define sex / order "gender*latest";
/*	define sex / order noprint;*/
/*	define sex / noprint order ;*/
/*	define sex /  noprint;*/
/*	define age_num / "Age";*/
	define age / order format=agefmt. "Age group";
/*	define age / display style(header)={'my age'};*/
/*	define age / display style(header)=[foreground=green background=red] 'xyz';*/
	define height / analysis n mean;

	break after sex / page;
run;


/* Qn #52. */
data work.sum;
	num1=1;
	num2=' ';
	num3=.;

/*	num3=num1+num2;*/

	num4=num1+num3;
run;

/* Qn #1. */
data demo;
	set sashelp.class;
run;

* A.;
proc sort data=WORK.DEMO out=out;
by sex;
run;
proc print data= out (obs=5);
run;	

* B.;
proc print data=WORK.DEMO(obs=5);
where Sex='M';
run;

* C.;
proc print data=WORK.DEMO(where=(sex='M'));
where obs<=5;
run;

* D.;
proc sort data=WORK.DEMO out=out;
/*by sex descending;*/
by descending sex;
run;
proc print data= out (obs=5);
run;

/* Qn #60. */
data class;
	set sashelp.class;
run;

%macro prt(dsn =, version =);

	%if %upcase(&dsn.) NE DIARY %then %do;
		proc print data=&dsn.;
			title "Print of WORK.&dsn. data set";
			footnote "Version Date: &version.";
		run;
	%end;
%mend prt;

* Test mprint;
options mprint nomlogic nosymbolgen;
%prt(dsn=class, version=2018);

options nomprint mlogic nosymbolgen;
%prt(dsn=class, version=2018);

options nomprint nomlogic symbolgen;
%prt(dsn=class, version=2018);

/* Qn. #34. */
data class;
	set sashelp.class;

	if   _n_ <= 8 then day = age - 11;
	if   _n_ = 9  then day = 7;
	else               day = age - 1;
run;


* A.;
data a;
	set class;
	if day > 14 then week = 3 ; 
	else if day > 7 then week = 2 ; 
	else if day > 0 then week = 1 ;
run;

* B.;
* DANGEROUS;
data b;
	set class;
	if day > 0 then week = 1 ; 
	else if day > 7 then week = 2 ; 
	else if day > 14 then week = 3 ;
run;

* C.;
* DANGEROUS;
data c;
	set class;
	select;
		when (day > 0) week = 1 ;
		when (day > 7) week = 2 ;
		otherwise week = 3 ;
	end;
run;

* D.;
data d;
	set class;
	select;
		when (day > 14) week = 3 ;
		when (day > 7) week = 2 ;
		otherwise week = 1 ;
	end ;
run;

* compare A vs D;
proc sql noprint;
	create table ad as
	select A.name, A.day, A.week as week_a,
		                  D.week as week_d
	from work.a A inner join work.d D
	on   A.name = D.name
	;
quit;
		   

/* Qn. #11. */
data class;
	set sashelp.class;
run;

proc univariate data=class;
	class sex;
	var age height;

	* C.;
/*	output out=results mean=m1 m2 std=s1 s2;*/

	* D.;
	ods output out=results2 mean=m1 m2 std=s1 s2;
run;

* correction for Answer D.;
* - This approach does not works!!!;
ods trace on;
/*ods output out=results2 mean=m1 m2 std=s1 s2;*/
	proc univariate data=class;
		class sex;
		var age height;
	run;
/*ods output close;*/
ods trace off;

/* Qn. #57. */
/*proc print data=class (obs=10);*/
/*run;*/
/**/
/*proc print data=class all;*/
/*run;*/

/* Qn. #21. */
data class1;
	set sashelp.class;
run;

data class2 
	(drop = _age)
	;
	set class1 (rename = (age=_age));
	if   _n_>8 then age = _age + 5;
	else            age = _age;
run;

proc compare base=class1 compare=class2;
run;

* A.;
proc compare base=class1 compare=class2 listall;
run;

* B.;
proc compare base=class1 compare=class2 out=compare outall;
run;

* C.;
proc compare base=class1 compare=class2 allobs;
run;

* D.;
proc compare base=class1 compare=class2 out=compare2 outdiff;
run;

/* Qn. #53. */
data vs1;
	subject=101; name='SBP'; v1=160; v2=150; v3=.; v4=130; v5=120;
run;

data vs2;
	set vs1;
	total=mean(of v:);
run;

/* Qn. #99. */
data one;
	input subjid 1-2 trt $ 4-5 result $ 6-7 dtime 9-10 age 11-12;
	datalines;
01   CR 0 56
02 A PD 1 52
03 B PR 1 47
05 1 SD 1 39
06 C SD 3 21
;
run;

data a b c d;
	set one;

	* A.;
	if indexc(TRT, 'ABC') eq 0 then output a;

	* B.;
	if index(TRT, 'ABC') eq 0 then output b;

	* C.;
	if find(TRT, 'ABC') eq 0 then output c;

	* D.;
	if indexw(TRT, 'ABC') eq 0 then output d;
run;

data test;
	s='asdf adog dog';
	p='dog  ';
	x=indexw(s,p);
	put x;
	y=index(s,p);
	put y;
run;

/* Qn. #78. */
data bp;
	id=1; sbp=145; dbp=92; output;
	id=2; sbp=130; dbp=87; output;
	id=3; sbp=117; dbp=78; output;
	id=4; sbp=135; dbp=85; output;
	id=5; sbp=145; dbp=79; output;
run;

data 
	work.highbp
	work.normbp
	work.investbp;

	set work.bp;

	if sbp gt 140 and dbp gt 90 then output work.highbp;
/*	if sbp lt 120 and dbp lt 80 then output work.normbp;*/
	else if sbp lt 120 and dbp lt 80 then output work.normbp;
	else output work.investbp;
run;






/* - source: https://www.lexjansen.com/nesug/nesug01/bt/bt3002.pdf*/
DATA EXAMPLE1;
 INPUT GROUP $ @10 STRING $3.;
 LEFT = 'X '; *X AND 4 BLANKS;
 RIGHT = ' X'; *4 BLANKS AND X;
 C1 = SUBSTR(GROUP,1,2);
 C2 = REPEAT(GROUP,1);
 LGROUP = LENGTH(GROUP);
 LSTRING = LENGTH(STRING);
 LLEFT = LENGTH(LEFT);
 LRIGHT = LENGTH(RIGHT);
 LC1 = LENGTH(C1);
 LC2 = LENGTH(C2);
DATALINES;
ABCDEFGH 123
XXX 4
Y 5
; 
run;

DATA EXAMPLE3;
 INPUT PHONE $ 1-15;
 PHONE1 = COMPRESS(PHONE);
 PHONE2 = COMPRESS(PHONE,'(-) ');
DATALINES;
(908)235-4490
(201) 555-77 99
; 
run;

DATA EX_10;
 INPUT STRING $ 1-10;
 FIRST = INDEX(STRING,'XYZ');
 FIRST_C =INDEXC(STRING,'X','Y','Z');
DATALINES;
ABCXYZ1234
1234567890
ABCX1Y2Z39
ABCD1Y2Z39
ABCZZZXYZ3
; 
run;
	



%macro donotrun;

/*proc univariate data=class ;*/
/*	class sex;*/
/*	var age height;*/
/*run;*/
/**/
proc means data=class;
	class sex;
	var height weight;
run;


%mend donotrun;
