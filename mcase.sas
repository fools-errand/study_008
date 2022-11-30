**************************************************************************************;
** macro mcase - mixes the case of all character variables of an input dataset
** must be called from OUTSIDE a data step
** parameters:
**    inds (required)  input dataset
** mjb 13apr2010
** mods:
**
**************************************************************************************;
%macro mcase(inds=, exceptl=%str('USUBJID'), fix_id=Y);
 %if &inds= %then %do;
  put 'missing parameters - aborting...'
 %end;

 %else %do;
   proc sql noprint;
     select distinct name into :varlist separated by ' '
     from dictionary.columns
     where libname='WORK' and memname="%upcase(&inds)" and upcase(type)="CHAR" and upcase(name) not in(&exceptl);
   quit;

   %if "&varlist" ne "" %then %do;
     data &inds;
       set &inds;
	   %if %upcase(&fix_id)=Y %then %do;
	     usubjid=substr(usubjid,8);
	   %end;
       %let num=1;
	   %let myval=%scan(&varlist,1);
	   %put &myval;
       %do %while(&myval ne);
	     &myval=propcase(&myval);
		 &myval=tranwrd(&myval,'s:','S:');
		 &myval=tranwrd(&myval,'p:','P:');
		 &myval=tranwrd(&myval,'v:','V:');
		 &myval=tranwrd(&myval,'a:','A:');
		 &myval=tranwrd(&myval,'w:','W:');
		 &myval=tranwrd(&myval,'ongoing','Ongoing');
         %let num=%eval(&num+1);
  	     %let myval=%scan(&varlist,&num);
       %end;
     run;
   %end;
 %end;

%mend mcase;

