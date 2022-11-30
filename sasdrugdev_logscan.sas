/******************************************************************************************
* Copyright(c) 2017 SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
*
* NAME:      sasdrugdev_logscan.sas
*
* Purpose:   Check logs for issues, including (e)rror/(w)arning/(i)nvalid/(u)ninitialized messages.
*            In addition, allow user to INCLUDE/EXCLUDE messages to scan through .txt files.
*         
* Author:    Preetesh Parikh
*
* Input:         
*
* Output:  
*
* Parameters: (if applicable)
* 1. logpath(Required) - specify the full directory path where the logs are
* 2. include(Optional) - text file location containing additional messages to scan
* 3. exclude(Optional) - text file location containing messages to exclude
* 4. outpath(Required) - output directory location to store the sas datset with issues
* 5. maxissue(Optional)- parameter for maximum issues per log to be shown(default to 50)
*
* Dependencies/Assumptions:
*
*
*
* HISTORY:
* ChangeId   User                Date      Description
* 000        Preetesh Parikh   13FEB2017   Created   
********************************************************************************************/

%macro sasdrugdev_logscan(logpath=,include=,exclude=,outpath=,maxissue=50);
         
	/********************************************************************************************
	WINDOWS vs. LINUX(SDD/LSAF)
	*********************************************************************************************/

	%local dirdlm;
	%if (&sysscp=WIN) %then %do;   
	   %*let ws=;
	   %let dirdlm=\;
	%end;
	%else %do;
	   %*let ws=%str(&_sasws_/);
	   %let dirdlm=/;
	%end;

	/********************************************************************************************
	INTERNAL MACROs
	*********************************************************************************************/

	%macro DirExist(dir) ; 
	   %global return;
	   %local rc fileref; 
	   %let rc = %sysfunc(filename(fileref,&dir)) ; 
	   %if %sysfunc(fexist(&fileref))  %then %let return=1;    
	   %else %let return=0;
	%mend DirExist;

	%local incmsgcnt;
	%macro incmsg;
	data incmsg;
	  infile "&include." length=linelength lrecl=32767;
	  length inclist $1000;
	  input @01 inclist $varying1000. linelength;   
	  inclist=strip(inclist);

	  * PRXMATCH - removes comments like these /* ---- */;
	  if ^missing(inclist) and prxmatch('/\/*.\*\//',inclist)<=0;
	run;

	%let dsid=%sysfunc(open(work.incmsg,IN));
	%let incmsgcnt=%sysfunc(attrn(&dsid.,nobs));
	%if &dsid.>0 %then %let rc=%sysfunc(close(&dsid.));

	data _null_;
	   set work.incmsg;
	   call symputx("inclist"||strip(put(_N_,best.)),inclist,'G');          
	run;
	%mend;


	%local excmsgcnt;
	%macro excmsg;
	data excmsg;
	  infile "&EXCLUDE." length=linelength lrecl=32767;
	  length exclist $1000;
	  input @01 exclist $varying1000. linelength;   
	  exclist=strip(exclist);

	  * PRXMATCH - removes comments like these /* ---- */;
	  if ^missing(exclist) and prxmatch('/\/*.\*\//',exclist)<=0;
	run;

	%let dsid=%sysfunc(open(work.excmsg,IN));
	%let excmsgcnt=%sysfunc(attrn(&dsid.,nobs));
	%if &dsid.>0 %then %let rc=%sysfunc(close(&dsid.));

	data _null_;
	   set work.excmsg;
	   call symputx("exclist"||strip(put(_N_,best.)),exclist,'G');          
	run;
	%mend;


	/********************************************************************************************
	PARAMETER CHECKING 
	*********************************************************************************************/

	/*************************************
	LOGPATH PARAMETER CHECKING
	**************************************/
	%if %nrbquote(&logpath) ne %then %do;
	   %DirExist(&logpath.);
	%end;
	%else %do;
	   %put %str(E)RROR: PATH is required;
	   %goto exit;
	%end;

	%if &return=1 %then %do;
	   filename _dir_ "%bquote(&logpath.)";
	   data filenames(keep=memname location);
	      chkdir=dopen( '_dir_' );
	      count=dnum(chkdir);
	      do i=1 to count;
	         memname=dread(chkdir,i);
	         location="&logpath";
	         output filenames;
	      end;   
	      rc=dclose(chkdir);
	   run;
	%end;
	%else %do;
	   %put %str(E)RROR: PATH:<&logpath.> is not valid;
	   %goto exit;
	%end;

	/*************************************
	OUTPATH PARAMETER CHECKING
	**************************************/
	%if %nrbquote(&outpath) ne %then %do;   
	   %DirExist(&outpath.);
	%end;
	%else %do;
	   %put %str(E)RROR: PATH is required;
	   %goto exit;
	%end;

	%if &return ne 1 %then %do;
	   %put %str(E)RROR: PATH:<&outpath.> is not valid;
	   %goto exit;
	%end;

	/*************************************
	INCLUDE PARAMETER CHECKING
	**************************************/
	%let incfile=0;
	%local filrf rc fid;
	%if %nrbquote(&include) ne %then %do;
	   %if %scan(&include,-1,'.') ne txt %then %do;
	      %let incfile=0;
	      %put %str(E)RROR: PATH:<&include> is not valid;   
	      %goto exit;   
	   %end;   
	   %else %if %sysfunc(fileexist(&include)) %then %do;      
	      %let rc=%sysfunc(filename(filrf,&include));
	      %let fid=%sysfunc(fopen(&filrf));
	      %if &fid > 0 %then %do;
	         %let rc=%sysfunc(fread(&fid));
	         %let rc=%sysfunc(fget(&fid,mystring));
	         %if &rc = 0 %then %do;
	            %let incfile=1;   
	         %end;
	         %else %do;
	            %put %str(E)RROR: FILE:<&include> is empty;            
	            %goto exit;   
	         %end;
	         %let rc=%sysfunc(fclose(&fid));
	      %end;
	      %let rc=%sysfunc(filename(filrf));
	   %end;
	   %else %do;
	      %let incfile=0;
	      %put %str(E)RROR: PATH:<&include> is not valid;   
	      %goto exit;   
	   %end;
	%end;
	/*************************************
	EXCLUDE PARAMETER CHECKING
	**************************************/
	%let excfile=0;
	%local filrf rc fid;
	%if %nrbquote(&EXCLUDE) ne %then %do;
	   %if %scan(&EXCLUDE,-1,'.') ne txt %then %do;
	      %let excfile=0;
	      %put %str(E)RROR: PATH:<&exclude> is not valid;   
	      %goto exit;   
	   %end;   
	   %else %if %sysfunc(fileexist(&EXCLUDE)) %then %do;      
	      %let rc=%sysfunc(filename(filrf,&EXCLUDE));
	      %let fid=%sysfunc(fopen(&filrf));
	      %if &fid > 0 %then %do;
	         %let rc=%sysfunc(fread(&fid));
	         %let rc=%sysfunc(fget(&fid,mystring));
	         %if &rc = 0 %then %do;
	            %let excfile=1;   
	         %end;
	         %else %do;
	            %put %str(E)RROR: FILE:<&exclude> is empty;
	            %goto exit;
	         %end;
	         %let rc=%sysfunc(fclose(&fid));
	      %end;
	      %let rc=%sysfunc(filename(filrf));
	   %end;
	   %else %do;
	      %let excfile=0;
	      %put %str(E)RROR: PATH:<&exclude> is not valid;
	      %goto exit;   
	   %end;
	%end;

	/*************************************
	MAXISSUE PARAMETER CHECKING
	**************************************/
	%if &maxissue ne %then %do;
		%if %sysfunc(notdigit(&maxissue))>0 %then %do;
			%put %str(E)RROR: VALUE:<&maxissue> is not a valid number;
	      	%goto exit;  
		%end;
		%else %if &maxissue <=0 %then %do;
			%put %str(E)RROR: VALUE:<&maxissue> should be great than zero;
	      	%goto exit;  
		%end;
	%end;
	%else %do;
		%let maxissue=50;
	%end;

	/********************************************************************************************
	COLLECT LOG FILES
	*********************************************************************************************/

	data dirlist;
	   set filenames;
	   if upcase(strip(scan(memname,-1,'.')))='LOG';   
	   fpath="&logpath.&dirdlm."||memname;                    
	   keep fpath;   
	run;

	data dirlist;      
	   length name $200;
	   set dirlist;
	   name=strip(scan(strip(scan(fpath,-2,'.')),-1,"&dirdlm."));            
	   if _n_=1 then cnt=0;
	   cnt+1;
	run;

	/********************************************************************************************
	GET COUNT OF LOG FILES
	*********************************************************************************************/
	%let totfile=;

	data _NULL_;
	   if 0 then set dirlist nobs=n;
	   call symputx('totfile',n);
	   stop;
	run;

	%if &totfile=0 %then %do;
	   %put %str(E)RROR: PATH:<&logpath.> does not contain any files with .log extension;
	   %goto exit;
	%end;

	data _null_;
	   set dirlist;
	   call symputx("file"||strip(put(cnt,best.)),name,'G');       
	run;

	/********************************************************************************************
	CREATE A SHELL
	*********************************************************************************************/
	proc sql;
	create table sasdrugdev_logscan
	(
	   LogName char(200),LogLine num,Message char(1000),ErrCnt num
	);
	quit;

	/********************************************************************************************
	CREATE MACRO VARIABLES FOR EACH OF THE MESSAGES COMING FROM INCLUDE/EXCLUDE FILE PARAMETERS
	*********************************************************************************************/
	%if &incfile=1 %then %do;
	   %incmsg;
	%end;
	%if &excfile=1 %then %do;
	   %excmsg;
	%end;


	/********************************************************************************************
	SCAN EACH OF THE LOG FILES FOR APPROPRIATE MESSAGES
	*********************************************************************************************/
	%do i=1 %to &totfile;   
	   data files;   
	      length Message $1000. LogName $200;
	      infile "&logpath.&dirdlm.&&file&i...log" length=linelength lrecl=32767;
	      input @01 line $varying1000. linelength;         
	      LogName="&logpath.&dirdlm.&&file&i...log";
	      logline=_n_;

	      * Default messages to check;
	      if    index(upcase(line),'E'||'RROR:') 
	      OR    index(upcase(line),'W'||'ARNING:') 
	      OR index(upcase(line),'I'||'NVALID') 
	      OR index(upcase(line),'U'||'NINITIALIZED')
	      OR prxmatch('/E\RROR\s\d+-\d+:/',upcase(line))>0
	      OR prxmatch('/W\ARNING\s\d+-\d+:/',upcase(line))>0
	      then do;
	         Message=compbl(strip(line));
	         flag=1;
	      end;


	      * Scan for messages to be flagged from the supplied message file;      
	      %if &incfile=1 %then %do;         
	         %do j=1 %to &incmsgcnt;
	            if index(upcase(line),upcase("&&inclist&j")) then do;               
	               Message=compbl(strip(line));                        
	               flag=1;
	            end;
	         %end;
	      %end;      
	      
	      * Reset flag value for exclusion Cases;
	      %if &excfile=1 %then %do;
	         %do k=1 %to &excmsgcnt;
	            if index(upcase(line),upcase("&&exclist&k")) then flag=.;            
	         %end;
	      %end;
	      
	      if flag=1;
	   run;

	   %let dsid = %sysfunc( open(files) ); 
	   %let nobs = %sysfunc( attrn(&dsid,nobs) ); 
	   %let rc = %sysfunc( close(&dsid) ); 
	   %if &nobs = 0 %then %do;
	      data files;
	         length Message $1000. LogName $200;
	         LogName="&logpath.&dirdlm.&&file&i...log";
	         LogLine=.;
	         Message='***************LOG IS CLEAN*****************';
	         ErrCnt=0;
	      run;
	   %end;
	   %else %do;      
	      data files(drop=flag line);      
	         retain LogName LogLine Message;
	         retain ErrCnt 0;
	         set files;   
	         ErrCnt=ErrCnt+1;
	         if ErrCnt<=&maxissue.;         
	      run;
	   %end;

		proc append data=files out=sasdrugdev_logscan; 
		run;
	   
	%end;

		libname out "&outpath.";
		data _null_;	
            cdate =  strip(put(date(),date.));
			ctime = strip(put(time(),time.));
			dt = cdate||"_"||translate(ctime, "_", ":");
			call symputx('cdt', dt);
		run;

		data out.sdd_logscan_&cdt.;
			set sasdrugdev_logscan;
		run;


	/********************************************************************************************
	CLEAN UP
	*********************************************************************************************/

	/*** CLEAN UP ALL FILENAME REFERENCES ***/
	filename _all_ clear;
	

	/*** DELETE GLOBAL MACRO VARIABLES ***/
	data delmac(keep=name);
	   set sashelp.vmacro;
	   if scope='GLOBAL'  and (index(name,'EXCLIST') or index(name,'INCLIST') or index(name,'RETURN') or index(name,'FILE'));
	run;
	data _null_;
	   set delmac;
	   call symdel(name);
	run;

	/*** CLEAR WORK AREA ***/
	proc datasets lib=work nolist kill;
	quit;
	run;


%exit:

%mend;
%*sasdrugdev_logscan(logpath=%str(&_SASWS_/SAS/ProjectPreet/Files),include=%str(&_SASWS_/SAS/ProjectPreet/Files/include.txt),exclude=%str(&_SASWS_/SAS/ProjectPreet/Files/exclude.txt),outpath=%str(&_SASWS_/SAS/ProjectPreet/Files));
%*sasdrugdev_logscan(logpath=%str(C:\logcheck),include=%str(C:\logcheck\include.txt),exclude=%str(C:\logcheck\exclude.txt),outpath=%str(C:\logcheck));
%*sasdrugdev_logscan(logpath=%str(C:\logcheck),include=%str(C:\logcheck\messages.txt));
%*sasdrugdev_logscan(logpath=%str(C:\logcheck),include=%str(C:\logcheck\include.txt),exclude=%str(C:\logcheck\exclude.txt),outpath=%str(C:\logcheck),maxissue=300);
