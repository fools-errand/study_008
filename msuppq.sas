********************************************************************************;
***
*** macro suppq - generates suppqual files containing vars that do not fit in
***               any sdtm domain
** should called from within a data step
** parameters:
**    outfile=output file name (format: <library name>."supp"||2char source domain name)
**    rdomain=original domain
**    idvar=id variable (see suppqual domain definition)
**    qnam=input variable
**    qlabel=suppqual variable label
**    qorig=raw or derived
**    qeval=evaluated (see suppqual domain definition)
**    filter=to filter input data
**
** mjb 20mar2010
**
** mods:
***
********************************************************************************;

%macro msuppq (outfile=, rdomain=, idvar=, qnam=, qlabel=, qorig=, qeval=, filter=);

   RDOMAIN=upcase("&rdomain");
   label rdomain='Related Domain Abbreviation';
   IDVAR=upcase("&idvar");
   %if &idvar^=  %then %do; IDVARVAL=&idvar; idvarval=left(idvarval); %end;
   QNAM=upcase("&qnam");
   QLABEL=upcase("&qlabel");
   QVAL=left(upcase(&qnam));
   QORIG=upcase("&qorig");
   QEVAL=upcase("&qeval");
   &filter output &outfile;

%mend msuppq;
