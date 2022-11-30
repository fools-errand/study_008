%*** For in-text tables;

%macro  mtitle2 (progid=, type=rtf, orient=l, sasopt=nodate nonumber nobyline,
                 byvar=, bytxt=, tmname=Zgi_std, nopage=n);

%*** Set options ;
%if &sasopt ne %then options &sasopt;;
%global outputname  ;
options mprint;
%let mls=170;

%if %upcase(&orient)=P %then %do;
  %let oriento=Portrait;
  %let tmname=in_std;
  %let mls=108;
%end;
%else %let oriento=Landscape;

options orientation=&oriento;

%global tablno numtitle footn1 footn2 footn3 footn4 footn5 footn6 footn7 footn8 footn9 spageno sfootn1 sfootn2 sfootn3 sfootn8 sfootn9 sfootn10 sdata numfoot outputname
        tabnum title1 title2 title3 title4 title5 title6 outputf l_source /*footn10*/ footn11;

%let fstln = %str('\pn\li300 ');
%let chgln = %str('\pn\par\li0\brdrt\brdth0 ');
%let footbr = %str('\brdrt\brdrs ');

%*** Retrieve titles ;

data toc_prog;
  *set &derdata..toc_prog;
  set psmac.toc_prog;

  if compress(upcase(progid))=upcase("&progid");

  call symput('tabnum',trim(tabnum));

  if index(title1,'`{') then offset=9;

  else offset=0;

  call symput('title1',trim(title1)||repeat(" ",(&mls-length(title1)-length(tabnum)-21-4+offset))||"[Page_00000_of_99999]");

  call symput('title2',trim(title2));

  call symput('title3',trim(title3));

  call symput('title4',trim(title4));

  call symput('title5',trim(title5));

  call symput('title6',trim(title6));

  call symput('outputname',trim(outname));

  call symput('numtitle',compress(put(numtitle,3.)));

  call symput('footn1',trim(footn1));

  call symput('footn2',trim(footn2));

  call symput('footn3',trim(footn3));

  call symput('footn4',trim(footn4));

  call symput('footn5',trim(footn5));

  call symput('footn6',trim(footn6));

  call symput('footn7',trim(footn7));

  call symput('footn8',trim(footn8));

  call symput('progname',trim(progname));



  if l_source ne '' then footn11="PROGRAM: " || trim(progname) || ".sas, " || "SOURCE: " || trim(l_source) || ", (%upcase(&draft_final.)) &sysdate9 &systime";

  else footn11="PROGRAM: " || trim(progname) || ".sas, (%upcase(&draft_final.)) &sysdate9 &systime";

  footn11l=trim(footn11);

  call symput('footn11',trim(footn11l));



  call symput('numfoot',compress(put(numfoot,3.)));

  %IF &TYPE=LST or &TYPE=PS %THEN %DO;

    call symput('footnsl',repeat('_',&ls-1));

    call symput('ltitle1',"&ptitle1");

    call symput('ltitle2',"&ptitle2" || repeat(" ",(&ls-length("&ptitle2")-21-1))); ** || "[Page_00000_of_99999]");

    call symput('gtitle1',"&ptitle1" || repeat(" ",(&ls-length("&ptitle1")+65)) || "&sysdate9 &systime");

    call symput('gtitle2',"&ptitle2" || repeat(" ",(&ls-length("&ptitle2")+77)); ** || "Page 1 of 1");

    call symput('footn1',trim(footn1) || repeat(" ",&ls));

    call symput('footn2',trim(footn2) || repeat(" ",&ls));

    call symput('footn3',trim(footn3) || repeat(" ",&ls));

    call symput('footn4',trim(footn4) || repeat(" ",&ls));

    call symput('footn5',trim(footn5) || repeat(" ",&ls));

    call symput('footn6',trim(footn6) || repeat(" ",&ls));

    call symput('footn7',trim(footn7) || repeat(" ",&ls));

    call symput('footn8',trim(footn8) || repeat(" ",&ls));

  %END;

  %IF &BYVAR NE %THEN %DO;

    call symput('titleby',"&bytxt #byval(&byvar)" || repeat(" ",&ls));

  %END;

  if index(tabnum,'Table') then call symput('outputf','tables');

  else if index(tabnum,'Listing') then call symput('outputf','listings');

  else if index(tabnum,'Figure') then call symput('outputf','figures');

  else if index(tabnum,'Appendix') then call symput('outputf','statsapp');  ** for stat appendix listings.  kcm 17sept09 **;

  %IF %UPCASE(&ORIENT)=P %THEN %DO;

    call symput('outputf','in-text');

  %END;

run;



%*** Check if a title was found;

%let numobs=0;



proc sql noprint;

  select count(*) into: numobs

  from toc_prog;

quit;



%Global _outputname;

%Let _outputname=&output/&outputf/&outputname;



%*** If no titles or multiple titles found return error and abort;

%if &numobs=0 %then %do;

   %put WARNING: The PROGID &progid is not found;

%end;

%else %if &numobs>1 %then %do;

   %put WARNING: Multiple titles found with PROGID &progid;

%end;

%else %do;

  %if %upcase(&type)=RTF %then %do;

    ods listing close;

    ods path sashelp.tmplmst &derdata..tplate;

    ods &type file="&output/&outputf/&outputname..&type" style=&tmname headery=1700 footery=1190;

    ods escapechar='`';

  %end;

  %else %if %upcase(&type)=LST %then %do;

    proc printto print="&output/&outputf/&outputname..&type" new;

    options center formchar="|_----|+|---+=|-/\<>*" ps=&ps ls=&ls;

  %end;

  %else %if %upcase(&type)=PS %then %do;

	proc printto;

	filename grphout "&output/&outputf/&outputname..&type";



    goptions reset=goptions rotate=l htitle=1.2 htext=1.2

         horigin=1.0 vorigin=1.0 DEVICE=psll

         GSFNAME=grphout GSFMODE=replace

         hsize=8.5 in vsize=6.5 in ftitle=Courier ftext=Courier ;

   	options center formchar="|_----|+|---+=|-/\<>*" ps=&ps ls=&ls;

  %end;



  options linesize=160 pagesize=50;



/*

  title1 j=l "&ptitle1";

  title2 j=l "&ptitle2";

*/

  title1 j=l "&tabnum:  &title1";

  %do i=2 %to &numtitle;

    title%eval(&i+1) j=c "&&title&i" ;

  %end;

  %if &byvar ne %then %do;

    title%eval(&numtitle+4) ' ';

    title%eval(&numtitle+5) j=l "&titleby";

  %end;

%end;





%if %upcase(&type)=RTF %then %do;

   footnote1  j=left &footbr

%end;

%else %if %upcase(&type)=LST %then %do;

  footnote1 "&footnsl"

%end;



%if &numfoot ne 0 %then %do;

     %do i=1 %to &numfoot;

         "&&footn&i"

         %If &i ^= &numfoot %then %do;

             &chgln

         %end;

     %end;;

%End;

%Else %do;

;

%End;



footnote2 " ";

footnote3 j=l "&footn11";



%mend mtitle2;

