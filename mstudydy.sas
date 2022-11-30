**************************************************************************************;
** macro mstudydy - calculates study day
** should be called from within a data step
** parameters:
**    todate (required)   to date variable name
**    basedate (required) baseline date variable name
**    studyday (optional) output studyday var name
**                        (defaults to 'studyday')
** mjb 30jan2010
** mods:
**
**************************************************************************************;
%macro mstudydy (todate=, basedate=, studyday=studyday);

 %if &todate= |&basedate= %then %do;
  put 'missing parameters - aborting...'
 %end;

 %else %do;
  &studyday=&todate-&basedate+(&todate ge &basedate);
 %end;

%mend mstudydy;

