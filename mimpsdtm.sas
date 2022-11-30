**********************************************************************
*** Program:        \biometrics\499\499H01\analyses_mjb\CSR\macros\prod\mimpsdtm.sas
*** Programmer:     Matt Becker
*** Date Created:   09Apr2010
***
*** Input :         User-specified XLS from \499H01\analyses_mjb\CSR\doc\*.xls
***
*** Output:         User-specified
***
*** Purpose:        Retrieve SDTM specs and merge with SDTM files
***
*** Comments:
***
*** Software:       SAS 9 (Windows)
***
*** Modifications:
***
*** Date       Programmer        Description
*** ---------  ----------------  --------------
***
**********************************************************************;
%macro mimpsdtm (micsv=, miin=, miout=, mikeep=Y, mlbl=) ;

%let popyn=N ;

***  get XLS file  *** ;
proc import out=oddt
    datafile="&sdtm"
    dbms=xls replace;
    sheet='SDTM Variable Metadata' ;
run ;

***  define attribute variables  *** ;
data xls(keep=varname varlabel type clength fmtname) ;
   length varname $8 varlabel $40 type clength fmtname $15 ;
   set oddt(where=(filename=upcase("&micsv"))) ;

   *varname=studyid;
   *varlabel=study_identifier;
   *type=char ; ;
   clength=put(length,best4.);
   *fmtname=_9_ ;

   if varname='Domain' then delete ;

run ;

%let mikeep=%upcase(&mikeep) ;

*** Use ATTRIB statements to set the type, length and label *** ;
data ce ;
   set xls (rename=(clength=length)) end=last ;
   retain allvars ;
   length allvars $1000 ;

   if _n_=1 then allvars=trim(varname) ;
   else allvars=trim(allvars) || ' ' || trim(varname) ;

   if _n_=1 then call execute("data &miout (label='" || trim(varlabel) || "');") ;
   if _n_ ge 2 then
     do ;
        if upcase(type)='CHAR' then varlen=compress("$"||length) ;
           else varlen=compress(length) ;
        if fmtname="" then do ;
           call execute("attrib " || varname || " label='" || trim(varlabel) ||"' length=" || trim(varlen) || ";") ;
        end ;
        else do;
           call execute("attrib " || varname || " label='" || trim(varlabel) ||"' length=" || trim(varlen) || " format=" || trim(fmtname) || ";") ;
        end;
     end;

   if last then do;
      call symput('allvars',allvars) ;
      call execute("set &miin;");
      %IF &MIKEEP=Y %THEN %DO;
          call execute("keep " || allvars || ";");
     %END;
      call execute ("run;") ;
   end ;

run ;

data &miout(label=&mlbl) ;
   retain &allvars ;
   set &miout ;
run ;

%mend mimpsdtm ;

