options mprint;

%macro sas_all(path=);

%let sas_path = %substr(&path,1,%sysfunc(find(&path,%str(/),-%length(&path)))-1);
%put sas_path = &sas_path;

%if %index(%nrbquote(&path),%str(\*))>0 %then %do;
  %let path = %sysfunc(tranwrd(%nrbquote(&path),%str(\),%str(*)));
  %put path=%sysfunc(trim(&path));
%end;


%*let prg_name = %scan(%scan(&path,-1,%str(/)),1,%str(.));
%*put prg_name = &prg_name;


*filename oscmd pipe "ls -mlR --full-time -1 '&path' 2>&1";
*filename oscmd pipe "ls '&path' 2>&1";
filename oscmd pipe "ls &path ";

data files;
 infile oscmd truncover;
 input filename $200.;
 *put _infile_;
run;

data files;
 set files end=eof;
 where index(filename,'.sas')>0 and index(filename,'_run')=0;
 length file_path $500;
 if index(filename,"&sas_path")>0 then 
    file_path = strip(filename);
 else
    file_path = trim("&sas_path") || "/" || strip(filename);
 call symputx("file_path"||strip(put(_n_,best.)),kstrip(file_path));
 if eof then call symputx('totfiles',strip(put(_n_,best.)));
run;

%let work_path=%sysfunc(pathname(work));

*filename tmp "&work_path";
filename tmp "&sas_path/_run_sas.sas";

data _null_;
  file tmp;
  put '%global base_path;';
  put '%macro get_basepath();';
  put '  %if %symexist(_sasprogramfile) %then %do;';
  put '    %let base_path = %substr(&_sasprogramfile,1,%sysfunc(find(&_sasprogramfile,%str(/),-%length(&_sasprogramfile)))-1);';
  put '  %end;';
  put '  %else %do;';
  put '    %let base_path = %substr(&SYSPROCESSNAME,1,%sysfunc(find(&SYSPROCESSNAME,%str(/),-%length(&SYSPROCESSNAME)))-1);';
  put '    %let base_path = %substr(&base_path,8);';
  put '  %end;';
  put '  %put &base_path;';
  put '%mend get_basepath;';
  put '%get_basepath();';
  put "%include " """&sas_path/../../macros/autoexec_viya.sas""" ";";
run;

data _null_;
  file tmp mod;
  %do i=1 %to &totfiles;
     put  '%run_batch(sas_prg='"%str(&&file_path&i));";
  %end;
run;

%include tmp;
/**
data _null_;
 rc = fdelete('tmp');
 put rc=;
run;
**/
%mend sas_all;

%*sas_all(path=%str(/compute-landingzone/Projects/hlsdata/study_003/programs/dev/\*.sas));
%*sas_all(path=%str(/compute-landingzone/Projects/hlsdata/study_003/programs/dev/a*.sas));
%*sas_all(path=%str(/compute-landingzone/Projects/hlsdata/study_003/programs/dev/l*.sas));
%*sas_all(path=%str(/compute-landingzone/Projects/hlsdata/study_003/programs/dev/t*.sas));
%*sas_all(path=%str(/compute-landingzone/Projects/hlsdata/study_003/programs/dev/adam_d0*.sas));

