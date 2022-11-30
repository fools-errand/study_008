********************************************************************************;
***
*** Program:        HLS Pharma autoexec.sas
*** Programmer:     Matt Becker
*** Date Created:   02FEB2014
***
*** Input :         none
***
*** Output:         none
***
*** Purpose:        Assign project definitions, options, libnames and macro vars
***
*** Comments:
***
*** Software:       SDD 4.x
***
*** Modifications:
***
*** Date       Programmer        Description
*** ---------  ----------------  --------------
***  16FEB2017  JB                  Update
********************************************************************************;
*** Adding new comment;

options nofmterr;

%let pathname=%str(&base_path./../..);
%let rootdir=%str(&base_path./../..);

%let ptitle1=%str(PharmaCo);
%let ptitle2=%str(PharmaCo - Compound2 - CONFIDENTIAL);

%*let ddt=&pathname./Study Documents/ddt.xls;
%*let sdtm=&pathname./Study Documents/sdtm.xls;

options mprint;

%macro chklibs;

%if %sysfunc(libref(raw)) >0 %then %do;
  libname raw "&pathname./data/rawdata";
%end;

%if %sysfunc(libref(sdtm)) >0 %then %do;
  libname sdtm "&pathname./data/sdtm";
%end;

%if %sysfunc(libref(derived)) >0 %then %do;
  libname derived "&pathname./data/adam";
%end;

%if %sysfunc(libref(psmac)) >0 %then %do;
  libname psmac   "&pathname./macros" access=read;
%end;

%if %sysfunc(libref(fmtdata)) >0 %then %do;
  libname fmtdata "&pathname./formats";
%end;

%mend chklibs;

%chklibs;


%global rawdata derdata suppkeep;
%let rawdata=raw;
%let derdata=derived;
%let suppkeep=%str(studyid rdomain usubjid idvar idvarval qnam qlabel qval qorig qeval);

%let output =&pathname./outputs;
%let program=&pathname./programs;

%*** set treatment variables used in MSS, MFREQ;
%global ovtrt tottrt;
%let ovtrt=6;
%let tottrt=6;

*** set global macro vars;
%global study studynum keepdemo draft_final trtspace demovars ps ls;
%let study=;
%let studynum=;
%let keepdemo=;
%let draft_final=FINAL;
%let trtspace=4;
%let demovars=%str(usubjid age atrt rfendtc rfendtn rfstdtn rfstdtc cnstdtn q_safeas q_immuas race sex tbsa);
%let ps=50;
%let ls=130;

options linesize=136 pagesize=50 formchar="|----|+|---+=|-/\<>*";

options mautosource mrecall missing='';
options sasautos=("&pathname/macros" sasautos) fmtsearch=(fmtdata WORK);

ods path sashelp.tmplmst(read) psmac.tplate;

%let options=mprint center ps=45 ls=132;
%let moptions=macrogen symbolgen /* mlogic */;
%let topdatef=date9.;

%let fpgfln=%str(put '\b0\f4\fs16\pard\par '; );
%let border=%str(\brdrb\brdrs);

%let ori=l;     *** landscape;

data _null_;
   daytim=put("&sysdate"d,date9.)||" "||put("&systime"t,time8.);
   call symput("nowdate", daytim);
run;