********************************************************************************
*** Program:        MTOTTRT.sas
*** Programmer:     Matt Becker
*** Date Created:   02FEB2010
***
*** Purpose:        Macro to create population totals from age groups
***
*** Comments:       for Zymogenetics 499H01
***
***
*** Modification History:
***
*** Date       Programmer         Description
*** ---------  ----------------   --------------
*** 
********************************************************************************;
%macro mtottrt (cond=, poptrt=atrt, mprintem=N, indata=&derdata..dm);

%global pop1 pop2 pop3 pop4 pop5 pop6;
%let pop1=0;
%let pop2=0;
%let pop3=0;
%let pop4=0;
%let pop5=0;
%let pop6=0;

data _ftmp1a;
  set &indata;
  &cond;
  __trt=&poptrt;
  if __trt>.;
run;

data _ftmp1;
  set _ftmp1a;
  output;
  if __trt in(2,3,4) then do;
    __trt=5;
    output;
  end;
  __trt=6; *** Total ***;
  output;
run;

proc freq data=_ftmp1 noprint;
  tables __trt / out=_ftmp2;
run;

%if &mprintem=Y %then %do;
  proc print; run;
%end;

data _null_;
  set _ftmp2;
  call symput(compress('pop'||put(__trt,3.)),compress(put(count,4.)));
run;

%put pop1 = &pop1;
%put pop2 = &pop2;
%put pop3 = &pop3;
%put pop4 = &pop4;
%put pop5 = &pop5;
%put pop6 = &pop6;

%mend mtottrt;
