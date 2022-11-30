/******************************************************************************\
* $Id: AnalyzeIO.sas 
*
* Copyright(c) 2016 by SAS Institute Inc., Cary, NC USA 27513
*
* Name          :  AnalyzeIO.sas
*
* Purpose       : This program analyzes Input(s)/Output(s) for specified SASFile
*
* Author        : Sandeep Juneja(SJ)
*
* Support       : SAS(r) Solutions OnDemand
*
* Input         : 
*
* Output        : 
*                 
*
* Parameters    : (if applicable)
*
* Dependencies/
* Assumptions   :
*
* Usage         :
*
* History:
*   CHGID  DATE       User   Comment
*   0001   22APR2016  SJ     Creation
/******************************************************************************/
/*----------------------------------------------------------------------
* SAMPLE code for parsing the output from SCAPROC and creating a  
* dataset with inputs and output.
* 
* Macro variables used:
* scaprocout - textual output of SCAPROC to be analyzed
*
* Librefs used:
* mywork - library where the output data set will be stored
*
* SAS INSTITUTE INC. IS PROVIDING YOU WITH THE COMPUTER SOFTWARE CODE
* INCLUDED WITH THIS AGREEMENT ("CODE") ON AN "AS IS" BASIS, AND
* AUTHORIZES YOU TO USE THE CODE SUBJECT TO THE TERMS HEREOF.  BY USING
* THE CODE, YOU AGREE TO THESE TERMS.  YOUR USE OF THE CODE IS AT YOUR
* OWN RISK.  SAS INSTITUTE INC. MAKES NO REPRESENTATION OR WARRANTY,
* EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NONINFRINGEMENT AND
* TITLE, WITH RESPECT TO THE CODE.
* 
* The Code is intended to be used solely as part of a product
* ("Software") you currently have licensed from SAS Institute Inc. or
* one of its subsidiaries or authorized agents ("SAS"). The Code is
* designed to either correct an error in the Software or to add
* functionality to the Software, but has not necessarily been tested. 
* Accordingly, SAS makes no representation or warranty that the Code
* will operate error-free.  SAS is under no obligation to maintain or
* support the Code.
* 
* Neither SAS nor its licensors shall be liable to you or any third
* party for any general, special, direct, indirect, consequential,
* incidental or other damages whatsoever arising out of or related to
* your use or inability to use the Code, even if SAS has been advised of
* the possibility of such damages.
* 
* Except as otherwise provided above, the Code is governed by the same
* agreement that governs the Software.  If you do not have an existing
* agreement with SAS governing the Software, you may not use the Code.
*
*----------------------------------------------------------------------*/

* http://support.sas.com/kb/24/671.html;
%macro nobs(ds);
    %let DSID=%sysfunc(OPEN(&ds.,IN));
    %let NOBS=%sysfunc(ATTRN(&DSID,NOBS));
    %let RC=%sysfunc(CLOSE(&DSID));
    &NOBS
%mend;

%macro AnalyzeIO (SASFile=, worklib=%str(), 
                  scafile=%str(), file_io=%str(Y),master_io=,);

* Define Variables based on OS - installation path;
******************************************;
* INITIALIZATION                         *;
******************************************;

%if &SYSSCP = WIN %then %do;
   %let dlm=%str(\);                                  
   %let install_path=%nrbquote(C:\WINDOWS);  * Required to ignore Font files;
   %let dlm=%str(/); 
   %let _sasws_=%str( );
%end;
%else %do;
  %let dlm=%str(/);
  %let install_path=%nrbquote(/SFW); * Required to ignore Font files;
%end;

%put OS=&SYSSCP DLM=&dlm  install_path=&install_path;
 
******************************************;
* ERROR HANDLING;                        *;
******************************************;

* Check if the SASFile is specified or not;
%if (%length(&SASFile)<=1) %then %do;
   %put ERROR: Please specify Input SASFile to Analyze its Inputs/Outputs;
   %goto prg_exit;
%end;
%else %do;
  * Convert \ to / for supplied parameter paths;
  %let SASFile = %sysfunc(translate(&SASFile,%str(/),%str(\)));
  %put SASFile=&SASFile;

  %if %sysfunc(fileexist(&SASFile)) %then %do;
     %let SASFile_Fldr=%substr(&SASFile,1,%sysfunc(findc(&SASFile,%str(/),-%length(&SASFile)))-1);
     %let SASFile_Name = %scan(%substr(&SASFile,%sysfunc(findc(&SASFile,%str(/),-%length(&SASFile)))+1),1,%str(.));
     %put SASFile_Fldr=&SASFile_Fldr   SASFile_Name=&SASFile_Name;
 %end;
 %else %do;
    %put ERROR: Please specify Input SASFile path: &SASFile;
    %goto prg_exit;
 %end;

%end;

* Check if Work Library path is specified;
%if (%length(&worklib)<=1) %then %do;
   %*let worklib=%str();
   %*put ERROR: Please specify Work Library Folder;
   %*goto prg_exit;
   %let worklib = %sysfunc(getoption(work));
   %put worklib=&worklib;
%end;
%else %do;
  options dlcreatedir;
  %let worklib = %sysfunc(translate(&worklib,%str(/),%str(\)));
  %put worklib=&worklib;

%end;

* Check if SCAFile is specified or not - Intialize SCAFILE filename;
%if %length(&scafile)>0 %then %do;
   %let scafile = %sysfunc(translate(&scafile,%str(/),%str(\)));
   %put scafile = &scafile;
   filename scafile "&scafile";
%end;
%else %do;
   %let scafile=%str();
   filename scafile catalog 'work.scaproc.scafile.source';
%end;

%if %length(&master_io)>0 %then %do;
   %let master_io = %sysfunc(translate(&master_io,%str(/),%str(\)));
   %put master_io=&master_io;

   %let master_io_Fldr=%substr(&master_io,1,%sysfunc(findc(&master_io,%str(/),-%length(&master_io)))-1);
   %let master_io_Name = %scan(%substr(&master_io,%sysfunc(findc(&master_io,%str(/),-%length(&master_io)))+1),1,%str(.));
   %put master_io_Fldr=&master_io_Fldr   master_io_Name=&master_io_Name;
%end;

* Identify the SAS Temp directory path;
%let sas_tmp = %sysfunc(getoption(work));
%put sas_tmp=&sas_tmp;


******************************************;
* LIBRARY STATEMENTS                     *;
******************************************;

libname worklib "&worklib";  * Work Library;
libname saslib "&SASFile_Fldr"; * SAS Program Location Library;
libname MIOlib "&master_io_Fldr"; * Master IO Library;

******************************************;
* SCAPROC ANALYSIS                       *;
******************************************;

* Run the SCAPROC to Analyze Inputs/Outputs for the specified SAS Program by executing it;
proc scaproc; write; run;
proc scaproc; record scafile EXPANDMACROS; run;

%if %length(&SASFile.)>0 %then %do;

%let sas_path = %substr(&SASFile,1,%sysfunc(find(&SASFile,%str(/),-%length(&SASFile)))-1);
%put sas_path = &sas_path;

%let prg_name = %scan(%scan(&SASFile,-1,%str(/)),1,%str(.));
%put prg_name = &prg_name;

* Note: Below line is required since batch run call is from macros folder ;
* which is overwriting path to macros folder;
%*let _sasprogramfile = %str(&SASFile);
%*put _sasprogramfile = &_sasprogramfile;

   proc printto log="&sas_path/logs/&prg_name..log";
   run;
     %include "&SASFile";
   proc printto;
   run;
%end;

proc scaproc; write; run; 

*******************************************************;
*** PARSE SCAPROC OUTPUT                            ***;
*******************************************************;

data worklib.scadata;
  infile scafile lrecl=1000 length=linelength end=eof;
  input scaline $varying1000. linelength;
run;

data worklib.scadata1;
  infile scafile lrecl=1000 length=linelength end=eof;
  input scaline $varying1000. linelength;

  * Ignoring SASTemp outputs and Global Macro Variables;
  if index(scaline,"JOBSPLIT")>0 and (index(scaline,"&sas_tmp")= 0 and index(scaline,"SYMBOL")=0) then output;
run;

data worklib.scadata2;
  set worklib.scadata1;
  retain obj_type_pattern type_pattern lib_path_pattern xpt_libname_pattern ttf_pattern time_pattern;
  length type obj_type $200;
  
  *Define patterns to extract different information;
  if _n_=1 then do;
     type_pattern = prxparse("/(INPUT|OUTPUT|UPDATE|LIBNAME|JOBSTARTTIME|JOBENDTIME)/i");
     obj_type_pattern = prxparse("/:\s*\w+\s/i");
     * Change pattern to include all characters and spaces between quotes;
     lib_path_pattern = prxparse("/(\'|\"")+.*(\'|\"")+/i");
     xpt_libname_pattern = prxparse("/LIBNAME .* XPORT .*.xpt/i");
     ttf_pattern = "/.*\.ttf/";
     * Start with digit 1 or more , followed by any characters till we '*' is encountered;
     time_pattern = prxparse("/\d+.*\*/i");
  end;
  
  if prxmatch(type_pattern,scaline)>0 and prxmatch(ttf_pattern,scaline)=0 then do;
     
     * IDENTIFY TYPE;
     call prxsubstr(type_pattern,scaline,type_start,type_len);
     if type_start>0 then TYPE=strip(substrn(scaline,type_start,type_len));
     
     * IDENTIFY OBJECT TYPE;
     call prxsubstr(obj_type_pattern,scaline,obj_type_start,obj_type_len);
     if obj_type_start>0 then OBJ_TYPE=strip(compress(strip(substrn(scaline,obj_type_start,obj_type_len)),":"));
     
     * LIB_PATH;
     call prxsubstr(lib_path_pattern,scaline,lp_start,lp_len);
     if lp_start>0 then lib_path=compress(strip(substrn(scaline,lp_start,lp_len)),"'""");
     *put lib_path=;

     * LIB name and xport engine;
     call prxsubstr(xpt_libname_pattern,scaline,lp_start,lp_len);
     if lp_start>0 then lib_engine="XPORT";

     * TIME Info;
    if (obj_type in ("JOBSTARTTIME","JOBENDTIME")) then do;
    call prxsubstr(time_pattern,scaline,time_start,time_len);
    if time_start>0 then TimeInfo=strip(substrn(scaline,time_start,time_len-1));
  end;
     
  * IDENTIFY OBJECT;
  *put type=;
  if type in ("INPUT") then obj=substr(scaline,type_start + 5); * 5 represents length of INPUT ;
  else if type in ("OUTPUT","UPDATE") then obj=substr(scaline,type_start + 6); * 6 represents length of OUTPUT;
  else if type in ("LIBNAME") then obj = scan(strip(substr(scaline,type_start + 7)),1," "); * 7 represents length of LIBNAME;
  else if type in ("JOBSTARTTIME","JOBENDTIME") then obj = TimeInfo;
        
  * Suppress extra characters;
  * put obj=;
  obj = strip(compress(obj,"*"));
     
  * Strip the extra / from the obj name;
  len = length(obj);
  loc = find(obj,"/",-length(obj));
  * put len= loc=;
  if len = loc then obj = substr(obj,1,length(obj)-1);
     
     * Suppress EXTRA LIB WORDS - SEQ, MULTI;
     if indexw(obj,"SEQ")>0 then obj = tranwrd(obj,"SEQ","");
     if indexw(obj,"MULTI")>0 then obj = tranwrd(obj,"MULTI","");
     
     * Parse DATASET DATA and LIBNAME;
     if obj_type in ("DATASET","CATALOG","ITEMSTORE") then do;
        lib_name= scan(obj,1,".");
        if obj_type in ("DATASET","CATALOG") then obj_name = scan(obj,2,".");
        else if obj_type in ("ITEMSTORE") then obj_name=scan(obj,-1,".");
     end;
     else if obj_type in ("LIBNAME") then do;
        * Ignore any libnames with no path. This fixes the issue where a libname references a
          second libname i.e. libname a (b) *;
        if not missing( lib_path ); 
        lib_name = obj;
     end;
     
     * CONVERT obj_name to LOWERCASE;
     if strip(type)^="FILE" then obj_name=lowcase(obj_name);
     
     sec_order_id = _n_;

     * OUTPUT ONLY JOBSPLIT RECORDS WITH I/O/U DEFINITIONS;       
     output;
  end;
  
  * DROP EXTRA VARIABLES;
  drop type_pattern type_start type_len;
  drop obj_type_pattern obj_type_start obj_type_len;
  drop lib_path_pattern lp_start lp_len xpt_libname_pattern ttf_pattern;
   drop time_start time_len;* timeinfo;
run;
     
proc sql;
 * Parse Lib Paths;
 create table worklib.lib_info as
    select distinct lib_name, lib_engine, lib_path
       from worklib.scadata2
          where obj_type="LIBNAME"
          order by lib_name;
 
 * Merge Lib Path information back with data;
 * Drop any data objects used by a transport libname *;
 create table worklib.io_info as
    select a.type, a.obj_type, a.lib_name, a.obj_name, b.lib_path, a.obj, a.sec_order_id,a.timeinfo
       from worklib.scadata2 a LEFT JOIN worklib.lib_info b
          ON strip(a.lib_name) = strip(b.lib_name)
          where a.obj_type ^= "LIBNAME"
                and b.lib_engine ^= "XPORT" 
          order by a.type, a.obj_type;
quit;

* Remove all the input references that were outputs from this JOB *;
proc sql;
   create table worklib.firstRecord as
      select * from worklib.io_info a
         where strip(type) = "OUTPUT"
         and sec_order_id = 
              ( select min(sec_order_id) from worklib.io_info b
                    where a.obj_name = b.obj_name
                     and a.lib_path = b.lib_path );


   delete from worklib.io_info a
      where strip(type) = "INPUT"
      and exists 
         ( select 1 from worklib.firstRecord b
              where a.obj_name = b.obj_name
               and a.lib_path = b.lib_path );

quit;

* Remove the sca proc output file *;
proc sql;
   delete from worklib.io_info a
      where strip(type) = "OUTPUT"
      and strip(obj) = "&scafile";
quit;

* Exclude MYWORK, WORK, SASHELP and SASUSER content from the job;
data worklib.io_info2;
  retain order_id sec_order_id;
  set worklib.io_info;
  * upcase and change / to \ for windows;
  where strip(upcase(lib_name)) not in ("MYWORK","WORK","SASHELP","SASUSER") and index(lib_path,'&dlm.sashelp')=0 ;
  length file_path $500;

  * change / to \ for windows;
  if obj_type="DATASET" then file_path=strip(lib_path) || "&dlm." || strip(obj_name) || ".sas7bdat";
  else if obj_type="FILE" then file_path=strip(obj);
  * KIA 03/21/2016 change / to \ for windows;
  else if obj_type="CATALOG" then file_path=strip(lib_path) || "&dlm." || strip(obj_name) || ".sas7bcat";
  else if obj_type in ("JOBSTARTTIME","JOBENDTIME") then file_path="";
  else file_path = strip(obj);

  * For Output files captured as output from scaproc change the \ to /; 
  file_path = translate(file_path,"/","\");

  if strip(type) in ("JOBSTARTTIME") then order_id=1;
  else if strip(type) in ("JOBENDTIME") then order_id=2;
  else if strip(type)="INPUT" then order_id=3;
  else if strip(type)="OUTPUT" then order_id=4;
  
  keep order_id sec_order_id obj_type type file_path timeinfo;
run;
      
proc sort data=worklib.io_info2 out=worklib.io_info2 nodupkey;
 by order_id sec_order_id type obj_type file_path;
 where length(strip(file_path))>1 or length(strip(timeinfo))>1;
run;
      
     
* Exclude Font files and any other content located in install_path location;
data worklib.io_info3;
 set worklib.io_info2;
 by order_id sec_order_id type obj_type file_path;
 where index(upcase(file_path),"&install_path.")=0 ; * Exclude list from the output job;
 
 * SINCE INPUT CAN BE FILE OR CONTAINER, BUT PARSER IDENTIFY EXACT FILES, SO ONLY FILES;
 * OUTPUT CAN ONLY BE CONTAINER;
 if strip(type) in ("INPUT","OUTPUT") then obj_type="FILE";
 * For PC SAS OUTPUTS should be FILE not CONTAINER
 * else if strip(type)="OUTPUT" then obj_type="CONTAINER";

 if index(file_path,"&dlm&dlm")>0 then file_path=tranwrd(file_path,"&dlm&dlm","&dlm");
 file_path=strip(file_path);

 * [Sandeep] 21JUN2021 NOTE: REPLACE PSMAC.TPLATE with full path;
 if (strip(lowcase(file_path))="psmac.tplate") then do;
    file_path = substr("&sas_path",1,find("&sas_path","/",-length("&sas_path"))-1);
    file_path = substr(file_path,1,find(file_path,"/",-length(file_path))-1);
    file_path = trim(file_path) || "/macros/tplate.sas7bitm";
 end;

run;

* Collect all the required IO information;
data worklib.job_info(drop=sec_order_id);
  retain sas_task order_id type obj_type file_path timeinfo;
  set worklib.io_info3;
  *set worklib.job_info worklib.task worklib.io_info4;
  *set worklib.job_info worklib.io_info2;
  by order_id sec_order_id;
  length sas_task $500;
  sas_task = "&SASFile";
  sas_task=tranwrd(sas_task,"&_sasws_","");
run;


proc sort data= worklib.job_info out = worklib.job_info nodupkey;
  by sas_task order_id type obj_type file_path timeinfo;
  where sas_task^=file_path; * ignore file itself as input;
run; 

/**
*http://support.sas.com/kb/37/581.html;
proc summary data=worklib.job_info nway;
 class sas_task order_id type obj_type file_path timeinfo;
 output out=worklib.job_info2(drop=_type_);
run; 
 **/

*******************************************************;
*** CAPTURE FILES METADATA                          ***;
*******************************************************;

*proc print data=worklib.job_info width=min;
*run;

%if &SYSSCP = WIN %then %do;
  data worklib.job_info2;
    set worklib.job_info;
    length file_path $500;

    if obj_type^="FILE" then file_path=kstrip(sas_task);

    * identify Metadata;
    call execute('%FileAttribs('||strip(put(_n_,best.))||','||file_path||')');

	createdDate=symget("CRDT"||strip(put(_n_,best.)));
    modifiedDate=symget("LMDT"||strip(put(_n_,best.)));
	fileSize = symget("fileSize"||strip(put(_n_,best.)));
  
  run;
%end;
%else %do;

  data worklib.job_info;
    set worklib.job_info end=eof;
    retain cnt 0;
    length file_path $500;
    
    * If Object is FILE, identify its Metadata;
    if obj_type="FILE" then file_path=tranwrd(file_path,"&_sasws_","");
    else file_path = tranwrd(sas_task,"&_sasws_","");
    cnt = cnt + 1;
    call symputx('sdd_File'||strip(put(cnt,best.)),file_path);
 
    if eof then call symputx('total',cnt);
    drop cnt;
  run;   
  %put total=&total;
 
  * Please Contact SAS Tech Support for sdd_getfilemeta.sas macro;
  * Only Applicable if Running in LSAF Environment;
 
  %do i=1 %to &total;
      %put --->>> file&i = &&sdd_file&i;
      %put %sysfunc(fileexist(&SASFile));
      %if %sysfunc(fileexist(&SASFile)) %then %do;
        %get_FileAttributes(file_path=%str(&&sdd_file&i),sas_dsname=work.sddFileMeta&i.);
        *proc print data=sddfilemeta&i.;
        *run;
      %end;
  %end;
  
  data sddFilesMeta;
    set sddFileMeta:;
  run;
  
  proc datasets library=work nolist;
    delete sddFileMeta:;
  run;

 
 proc sql;
  create table worklib.job_info2 as
  select distinct a.*, 
         b.owner_name,b.last_modified,b.file_size__bytes
  from worklib.job_info a LEFT JOIN sddFilesMeta b
  ON kstrip(a.file_path)=kstrip(b.filename)
  order by a.sas_task, a.order_id,a.file_path;
 quit;
 
%end;


*******************************************************;
*** GENERATE FILE IO                                ***;
*******************************************************;

* if file_IO=Y then generate IO dataset for specified SASFile;
%if (&file_io=%str(Y)) %then %do;
  *data saslib.&SASFile_Name;
  data worklib.&SASFile_Name;
     set worklib.job_info2;
  run;
%end;

*******************************************************;
*** APPEND TO MASTER IO                             ***;
*******************************************************;
%if (%sysfunc(exist(MIOlib.&master_io_Name)))%then %do;

  %if %eval(%nobs(MIOlib.&master_io_Name)>0) %then %do;
     %*put SASFile=&SASFile.;
     %let SASFile=%sysfunc(tranwrd(&SASFile,%str(&_sasws_),%str()));
     %*put SASFile=&SASFile.;
     
     proc sql;
       delete from MIOlib.&master_io_Name
       where kstrip(sas_task)="&SASFile";
     quit;

     proc append base=MIOLib.&master_io_Name data=worklib.&SASFile_Name FORCE;
     run;
  %end;
  %else %do;
      data MIOlib.&master_io_Name;
       set worklib.&SASFile_Name;
      run;
  %end;
%end;
%else %do;
  data MIOlib.&master_io_Name;
    set worklib.&SASFile_Name;
  run;
%end;

%let MacVars=%str();
PROC SQL noprint;
  select name into :MacVars separated by " "
  from Dictionary.Macros 
  where  (upcase(Name) like "%upcase(LMDT)%") or (upcase(Name) like "%upcase(CRDT)%") or (upcase(Name) like "%upcase(fileSize)%")
  and  scope eq 'GLOBAL';
quit;
%put MacVars -> &MacVars;
%symdel &MacVars /NOWARN;


%prg_exit:

*******************************************************;
*** CLEANUP                                         ***;
*******************************************************;
/*
proc datasets library=work kill nolist nowarn;
run;
quit;
*/

  %if %length(&worklib)>0 %then %do;
     proc datasets library=worklib kill nolist nowarn;
     run;
    quit;
  %end;

%mend AnalyzeIO;

