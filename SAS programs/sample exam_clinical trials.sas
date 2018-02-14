
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

