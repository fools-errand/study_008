/********************************************************************

* Program:   mpageof.sas                                            *

* Created:   Matt Becker 02/02/2010                                 *

* Purpose:   Paginate ODS output                                    *

*                                                                   *

* Parameters:                                                       *

*    infile:   input file generated from ODS                        *

*    outfile:  output file name (must differ from infile)           *

*    type:     input file type (RTF, PDF)                           *

*    text:     pagination placeholder text                          *

*                                                                   *

* Modified:                                                         *

*********************************************************************/

%macro mpageof(infile="&output/&outputf/&outputname..&type",

                outfile="&output/&outputf/&outputname..&type",

                type=rtf,

                text=[Page_00000_of_99999],

               );



%if %upcase(&type)^=LST %then %do;

  ods &type close;



%*** scan file to determine the number of pages ;

data _null_;

  infile &infile lrecl=32767 end=_eof;

  input;

  if index(_infile_,"&text") then pageno + 1;

  if _eof then call symput('NUMPAGES',compress(put(pageno,14.)));

run;



%*** determine text length needed for Page X of X ;

%local numpagel lpageof;

%let numpagel=%length(&numpages);

%let lpageof=%length(&text);



%*** paginate ;

data _null_;

  infile &infile lrecl=32767 end=_eof;

  length pageof $ &lpageof;

  input ;

  if index(_infile_,"&text") then do;

    pageno + 1;

    pageof = 'Page '|| put(pageno,&numpagel..) ||" of &numpages";

    pageof = compbl(pageof);

    pageof = right(pageof);

    pad="";

    _infile_ = tranwrd(_infile_,"&text",pageof);

  end;

  file &outfile noprint lrecl=32767;

  put _infile_;

  %if &type=PDF %then %do;

    if index(_infile_, "/BaseFont") then do;

      put @1 "/Encoding /WinAnsiEncoding";

    end;

  %end;

run;

%end;

%mend mpageof;

