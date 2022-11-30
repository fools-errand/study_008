*************************************************************************************
***
*** Program:       MSS.sas
*** Programmer:    Matt Becker
*** Date Created:  02Feb2010
***
*** Purpose:       Macro to create summary stats for tables
***
*** Comments:
***
*** Macro Parameters    : MSDATA   - Input dataset
***                      MSOUT    - Ouptut dataset
***                      MSVAR    - Variable to be summarized
***                      MSWHERE  - Subset condition, if required
***                      MSORDER  - Order variable in output dataset
***                      MSSTATS  - Summary stats required
***                      MSBY     - By variable
***                      MSPREC   - Precision of raw data (decimal places)
***                      MSORIENT - Specify L=landscape, P=portrait (determines
***                                 which summary statistics are required)
***
***
*** Modification History:
***
*** Date        Programmer              Description
*** ----------  ----------------------  ---------------------
***
***
*************************************************************************************;

%macro mss (msdata=,      /* INPUT DATASET                      */
             msout=,      /* OUTPUT DATASET                     */
             msvar=,      /* VARIABLE TO BE SUMMARIZED          */
			 mstrt=atrt,  /* TREATMENT VARIABLE                 */ 
           mswhere=,      /* ANY WHERE CONDITIONS ON INPUT DSET */
           msorder=1,     /* VALUE OF ORDER IN FINAL DATASET    */
           msstats=,      /* SUMMARY STATS (1)                  */
              msby=,      /* ADDITIONAL BY VARIABLES (2)        */
            msprec=,      /* PRECISION (3)                      */
			msorient=l,    /* ORIENTATION                        */
			msspace=&trtspace,  /* SPACE FOR SUMMARY STATS     */
			msprt=N);     /* SET TO Y TO HAVE THE OUTPUT PRINTED */  


** (1) - IF THIS IS LEFT BLANK, THE STANDARD STATS ARE
         PRODUCED WHICH ARE N, MEAN (SE), STD, MEDIAN
         Q1, Q3, MIN and MAX. NMISS AND SUM ARE AVAILABLE USING THE
         STATS OPTION ;

** (2) - EXTRA BY VARIABLES CAN BE ADDED IN THE BY OPTION ;

** (3) - IF THIS IS USED, IT STATES THE PRECISION OF THE
         DATA HELD ON THE DATASET. MEANS AND MEDIANS ARE
         THEN PRESENTED TO +1 DP AND STD TO +2 DP;

data ms0&msorder;
set &msdata;
  if index(upcase("&msstats"),"GMEAN") then do;
    if &msvar gt 0 then &msvar=log(&msvar);
	else if &msvar=0 then &msvar=0;
	call symput("GMEAN","YES");
  end;
  else call symput("GMEAN","NO");
run;

proc means data=ms0&msorder nway 
  %IF %UPCASE(&MSPRT) NE Y %THEN %DO;
    noprint
  %END;;
  var &msvar;
  %IF &MSBY NE or &MSTRT NE %THEN %DO;
    class &MSBY &MSTRT;
  %END;
  %IF &MSWHERE NE %THEN %DO;
    where &MSWHERE;
  %END;
  output out=ms&msorder    n=nn
                      mean=nmean
                       std=nstd
                    median=nmedian
                       min=nmin
                       max=nmax
                     nmiss=nnmiss
                       sum=nsum
				    stderr=nse
					    q1=nq1
						q3=nq3
                       var=nvar
					  uclm=nuclm
					  lclm=nlclm;
run;

data _null_;
  if 0 then set ms&msorder nobs=count;
  call symput("numobs",left(put(count,10.)));
  stop;
run;

%if &numobs>=1 %then %do;

%if &msprec ne %then %do;
  %if &msprec eq 0 %then %let acc=%eval(3+&msspace);
  %else %let acc=%eval(4+&msspace+&msprec);
%end;

  data ms2&msorder;
    set ms&msorder;

%IF &GMEAN=YES %THEN %DO;
  if nmean ne . then nmean=exp(nmean);
  if nuclm ne . then nuclm=exp(nuclm);
  if nlclm ne . then nlclm=exp(nlclm);
%END;
%IF &MSPREC NE %THEN %DO;
       if nn ne . then n=put(nn,7.);
   if nnmiss ne . then nmiss=put(nnmiss,7.);
    if nmean ne . then mean=put(nmean,%eval(9+&msprec).%eval(&msprec+1));
	 if nn>1 then std=put(nstd,%eval(10+&msprec).%eval(&msprec+1));
	 else if nn=1 then std=repeat(' ',5-&msprec)||'-';
	 if nn>1 then stderr=put(nse,%eval(10+&msprec).%eval(&msprec+1));
	 else if nn=1 then se=repeat(' ',5-&msprec)||' ';	
     /*if nmin ne . then min=put(nmin,&acc..&msprec);*/
     %if &msprec>0 %then if nmin ne . then min=put(nmin,%eval(8+&msprec).%eval(&msprec));;
	 %if &msprec=0 %then if nmin ne . then min=put(nmin,7.);;
     if nmedian ne . then median=put(nmedian,%eval(9+&msprec).%eval(&msprec+1));
     /*if nmax ne . then max=put(nmax,&acc..&msprec);*/
     %if &msprec>0 %then if nmax ne . then max=put(nmax,%eval(8+&msprec).%eval(&msprec));;
	 %if &msprec=0 %then if nmax ne . then max=put(nmax,7.);;
     if nq1 ne . then q1=put(nq1,%eval(9+&msprec).%eval(&msprec+1));
	 if nq3 ne . then q3=put(nq3,%eval(9+&msprec).%eval(&msprec+1));
     if nsum ne . then sum=put(nsum,7.);
	 if nn>1 and nuclm ne . then uclm=put(nuclm,%eval(14+&msprec).%eval(&msprec+1));
	 else if nn=1 then uclm=repeat(' ',5-&msprec)||' ';
	 if nn>1 and nlclm ne . then lclm=put(nlclm,%eval(14+&msprec).%eval(&msprec+1));
	 else if nn=1 then lclm=repeat(' ',5-&msprec)||' ';
%END;
%ELSE %DO;
       if nn ne . then n=put(nn,best9.);
   if nmiss ne . then nmiss=put(nnmiss,best9.);
     if nsum ne . then sum=put(nsum,best9.);
    if nmean ne . then mean=put(nmean,best9.);
     if nstd ne . then std=put(nstd,best9.);
  if nmedian ne . then median=put(nmedian,best9.);
     if nmin ne . then min=put(nmin,best9.);
     if nmax ne . then max=put(nmax,best9.);
	  if nse ne . then se=put(nse,best9.);
	  if nq1 ne . then q1=put(nq1,best9.);
	  if nq3 ne . then q3=put(nq3,best9.);
	  if nuclm ne . then uclm=put(nuclm,best9.);
	  if nlclm ne . then lclm=put(nlclm,best9.);
%END;
   gmean=mean;
   length meanse meansd quarts range ci95 $50 ;
   meanse=mean || ' (' || compress(se) || ')';
   meansd=mean || ' (' || compress(std) || ')';
   quarts=compress(q1) || ', ' || compress(q3);
   range=compress(min) || ', ' || compress(max);
   if n(nuclm,nlclm)=2 then ci95=compress(lclm) || ', ' || compress(uclm);
   else ci95=repeat(' ',5-&msprec)||' ';
   if nn lt 1 then ci95='';
run;

proc transpose data=ms2&msorder out=ms3&msorder
                         %IF &MSTRT NE %THEN %DO;
						   prefix=trt
						 %END;;
  %IF &MSBY NE %THEN %DO;
    by &MSBY;
  %END;
  %IF &MSTRT NE %THEN %DO;
    id &MSTRT;
  %END;
  %IF &MSSTATS NE %THEN %DO;
    var &msstats;
  %END;
  %ELSE %DO;
    %IF %UPCASE(&MSORIENT)=L %THEN 
    var n mean std median range ci95 quarts;
	%IF %UPCASE(&MSORIENT)=P %THEN
	var n mean std median range ci95 quarts;
	;
  %END;
run;

data &msout;
length 
%DO I=1 %TO &OVTRT;
  trt&i
%END; $100;
set ms3&msorder;
  order=&msorder;
  length text $70;
  _name_=upcase(_name_);
       if _name_='STD'   then text='SD';
  else if _name_='NMISS' then text='N Missing';
  else if _name_='MIN'   then text='Min';
  else if _name_='MAX'   then text='Max';
  else if _name_='CI95'  then text='95% CI';
  else if _name_='RANGE' then text='Min, Max';
  else if _name_='QUARTS' then text='Quartiles';
  else if _name_='MEANSE' then text='Mean (SE)';
  else if _name_='MEANSD' then text='Mean (SD)';
  else if _name_='N' then text='n';
  else if _name_='GMEAN' then text='Geometric Mean';
  else if _name_='LCLM' then text='95% CI: Lower';
  else if _name_='UCLM' then text='              Upper';
  else if _name_='Q1' then text='Quartiles: Q1';
  else if _name_='Q3' then text='                 Q3';
  else text=substr(_name_,1,1)||lowcase(substr(_name_,2));
  sorder=input(_name_,statord.);
  array medvrs _character_;
  do i=1 to dim(medvrs);
     if compress(medvrs(i))='.' then medvrs(i)='';
  end;
  drop i;
  array trtvars $ trt1-trt&tottrt;
  %DO I=1 %TO &OVTRT;
    if _name_='N' and trt&i='' then trt&i=put(0,7.);
    space&i=int((12+%eval(&msprec * 2) - length(trim(trt&i)))/2);
    if _name_='RANGE' and index(trt&i,',') and space&i gt 0 then trt&i=repeat(' ',space&i+1) || trim(trt&i);
	drop space&i;

	%IF %eval(&msspace) gt 4 %THEN %DO;
	  trt&i=repeat(' ',&msspace-5) || trt&i;
	%END;
  %END;
run;

proc sort data=&msout; by &msby order sorder; run;

%end;
%else %do;
data &msout;
run;
%end;

%MEND MSS;

