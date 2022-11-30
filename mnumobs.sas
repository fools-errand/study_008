**************************************************************************************;
** macro mnumobs - calculates number of observations in a SAS dataset
** must be called from OUTSIDE a data step
** parameters:
**    inds (required)  input dataset
** mjb 13apr2010
** mods:
**
**************************************************************************************;
%macro mnumobs (inds=);
 %global nobs;

 %if &inds= %then %do;
  put 'missing parameters - aborting...'
 %end;

 %else %do;
   proc sql noprint;
	  select nobs into :nobs separated by ' '
      from dictionary.tables
	  where libname='WORK' and memname="%upcase(&inds)";
   quit;
%end;

%mend mnumobs;

