
/* Environment setting. */
/*%global proj_dir rawdata analdata programs output;*/

%let proj_dir = C:\Users\hw1\Desktop\_workuhm\OCS\certifications\sas\Exam attempts\sas_cerifications;
%let rawdata  = &proj_dir.\raw dataset;
%let programs = &proj_dir.\SAS programs;
/*%let output   = &proj_dir.\04 Output;*/

/*******************************************************************************
    Qn#40. What is the value of the variable day when the data step completes?
	Answer: day = 8
*******************************************************************************/
data WORK.DATE;
  day = 1;
  do while(day LE 7);
    day + 1;
  end;
run;

/*******************************************************************************
    Qn#45. LOCF 
*******************************************************************************/
%let dsin = raw_qn45.csv;

filename rawf "&rawdata.\&dsin.";
proc import datafile  =rawf
            out       =work.raw_qn45
            dbms      =csv replace;
	        guessingrows=4;
	        getnames=YES;
	        datarow=2;     
            delimiter =','; 
            getnames  =YES;
run;
filename rawf;

/* Choice A. */
data choiceA;
  set work.raw_qn45;
  by subject visitn;
/*  <insert code here>*/
  locf = lag(score);
  if first.subject then locf = .;
  if score ^= . then locf = score;
run;

/* Choice B. */
data choiceB;
  set work.raw_qn45;
  by subject visitn;
/*  <insert code here>*/
  if first.subject then locf = .;
  if score = . then locf = lag(score);
	
  /* MY OWN VERSION */
  /* [NOTE, 05-jan-2018]. Because of an independent IF condition (see above), all LOCF values are missing. */
  if first.subject then locf = .;
  else locf = lag(score);
run;

/* Choice C. */
data choiceC;
  set work.raw_qn45;
  by subject visitn;
/*  <insert code here>*/
  retain locf;
  if first.subject then locf = .;
  if score ^= . then locf = score;
run;

/*******************************************************************************
    PROC TRANSPOSE + ARRAY
*******************************************************************************/
/* Qn#28. Array */
data qn28 /*(keep = sex2{4} )*/;
  set sashelp.class (obs=4);

  array sex2{4};
  do i=1 to 4;
	sex2{i} = sex;
  end;
run;

/* Qn#55. PROC TRANSPOSE */
filename rwqn55 "U:\OCS\Certifications\SAS\01 SAS Clinical Trials\02 Exam attempts\sas_cerifications\SAS programs\qn55.csv";

proc import datafile=rwqn55 out=vitals
  dbms=csv;
run;

/* Option A. */
proc transpose data=vitals; 
  var pulse sysbp diabp;
run;

/* Option B. */
proc transpose data=vitals; 
  by patid visit;
run;