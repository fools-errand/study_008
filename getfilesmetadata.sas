%macro getFilesMetadata();
data _null_;
  set list end=eof;
  where dir=0;
  retain cnt 0;
  cnt = cnt + 1;
  call symputx('sdd_File'||strip(put(cnt,best.)),file);
 
  if eof then call symputx('total',cnt);
  drop cnt;
run;   
%put total=&total;
 
%do i=1 %to &total;
   %put --->>> file&i = &&sdd_file&i;
   %if %sysfunc(fileexist(&&sdd_File&i)) %then %do;
      %get_FileAttributes(file_path=%str(&&sdd_file&i),sas_dsname=work.sddFileMeta&i.);
      *proc print data=sddfilemeta&i.;
      *run;
    %end;
%end;
  
data FilesMeta;
  set sddFileMeta:;
run;

data FilesMeta;
 set FilesMeta;
 format latest_dtm datetime18.;
 latest_dtm = input(last_modified,datetime18.);
run;
  
proc datasets library=work nolist;
  delete sddFileMeta:;
run;

%mend getFilesMetadata;
