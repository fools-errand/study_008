**************************************************************************************;
** macro msdtmdt - creates the dates for SDTM domains (yyyy-mm-dd)
** must be called from INSIDE a data step
** parameters:
**    datepart (required)   date prefix
**    datevar (required) output date var name
** mjb 20mar2010
** mods:
**
**************************************************************************************;
%macro msdtmdt (datepart=, datevar=);

 %if &datepart= | &datevar= %then %do;
  put 'missing parameters - aborting...'
 %end;

 %else %do;
  &datevar= trim(left(substr(&datepart.yy,1,4)))||'-'||trim(left(substr(put(&datepart.mm,$textm.),1,2)))||'-'||trim(left(substr(&datepart.dd,1,2)));
  if compress(&datevar)='--' then &datevar='';
 %end;

%mend msdtmdt;

