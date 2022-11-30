**************************************************************************************;
** macro msdtmdy - calculates study day for SDTM domains
** must be called from OUTSIDE a data step
** parameters:
**    inds (required)  input dataset
**    todate (required)   to date variable name
**    studyday (optional) output studyday var name
**                        (defaults to 'studyday')
** mjb 20mar2010
** mods:
**
**************************************************************************************;
%macro msdtmdy (inds=, todate=, studyday=studyday);

 %if &todate= | &inds= %then %do;
  put 'missing parameters - aborting...'
 %end;

 %else %do;
  proc sort data=sdtm.dm out=dm(keep=usubjid rfstdtc);
    by usubjid;

  proc sort data=&inds;
    by usubjid;

  data &inds;
    merge &inds(in=x) dm(in=y);
    by usubjid;
    if x;
    if length(compress(&todate,'UN'))=10 AND length(compress(&todate))=10 then &studyday = input(&todate,yymmdd10.) - input(rfstdtc,yymmdd10.);
    if &studyday>=0 then &studyday=&studyday+1;
    drop rfstdtc;
  run;
 %end;

%mend msdtmdy;

