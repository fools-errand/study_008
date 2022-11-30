/******************************************************************************************
* Copyright(c) 2021 SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
*
* NAME:      sas_all_util.sas
*
* Purpose:   create a SAS utility to batch submit all SAS programs in a folder
*         
* Author:    
*
* Input:         
*
* Output:  
*
* Parameters: (if applicable)
* 1. codepath (Required) - specify the full directory path where the logs are

* Dependencies/Assumptions:
*
*
*
* HISTORY:
* ChangeId   User                Date      Description
* 000                          14JUN2021    Created   
********************************************************************************************/

%global base_path;

%let base_path2 = %str(/compute-landingzone/Projects/hlsdata);
%let study_path = %str(/study_003/programs/dev);


%macro list_files(dir,ext);
  %local filrf rc did memcnt name i;
  %let rc=%sysfunc(filename(filrf,&dir));
  %let did=%sysfunc(dopen(&filrf));      

   %if &did eq 0 %then %do; 
    %put Directory &dir cannot be open or does not exist;
    %return;
  %end;

   %do i = 1 %to %sysfunc(dnum(&did));   

   %let name=%qsysfunc(dread(&did,&i));
      
	  %if %qscan(&name,2,.) = %then %do;        
        FILE="&dir/&name";  dir=1; output;
        %list_files(&dir/&name,&ext)
      %end;
	  %else %do;
         FILE="&dir/&name";  dir=0; output;
	  %end;

   %end;
   %let rc=%sysfunc(dclose(&did));
   %let rc=%sysfunc(filename(filrf));     

%mend list_files;

data list;
  length FILE $500 dir 8;
  %list_files(&base_path2.&study_path,sas)
run;

data list;
 set list;
 where dir=0 and scan(strip(file), -1) = "sas" 
             and index (file,'all_sas_files') = 0
             and index (file,'_run_batch.sas') = 0
            ;
 length file_path $300;
 file_path = tranwrd(file,"&base_path2"," ");
 run;

proc sort data=list;
  by file;
run;

data work._null_;
   attrib workpath length=$400;
   workpath=pathname("work");
   call symput("workPath", trim(left(workpath)));
   stop;
 run;

%put <&workpath>;

data _null_;
 set list end=eof;
 call symputx("file"||strip(put(_n_,best.)),kstrip(file));
 call symputx("file_path"||strip(put(_n_,best.)),kstrip(file_path));
 if eof then call symputx('totfiles',strip(put(_n_,best.)));
run;


%macro test;

%put <<&base_path2>>;

%include "&base_path2/study_003/macros/sasdrugdev_logscan.sas";

*filename tmp catalog "work.temp.s3files.source";
*filename test "&workpath/all_sas_files.sas";
filename test "/compute-landingzone/Projects/hlsdata/study_003/programs/dev/all_sas_files.sas";


data _null_;
    file test;
    put '%include "/compute-landingzone/Projects/hlsdata/study_003/macros/analyzeio.sas";'; 
    put '%include "/compute-landingzone/Projects/hlsdata/study_003/macros/run_batch_.sas";'; 
run;

data _null_;
    file test mod;
    %*do i=1 %to &totfiles;
    %do i=1 %to 3;

        put  '%run_batch(sas_prg='"%str(&&file&i));";

    %end;

run;

%include test;

%mend test;

%test;
  

%sasdrugdev_logscan(logpath=%str(/compute-landingzone/Projects/hlsdata/study_003/programs/dev/logs),
include=%str(/compute-landingzone/Projects/hlsdata/study_003/macros/include.txt),
exclude=%str(/compute-landingzone/Projects/hlsdata/study_003/macros/exclude.txt),
outpath=%str(/compute-landingzone/Projects/hlsdata/study_003/programs/dev/logs));


%symdel base_path2/nowarn;