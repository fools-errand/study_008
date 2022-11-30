
%macro get_FileAttributes(file_path=, sas_dsname=fileAttrs);

 data _file_attr(keep=file_seq infoname infoval);
   length infoname infoval $ 500;
   file_seq=1;
   rc=filename("afile", "&file_path");
   fid=fopen("afile");
   if (fid>0) then do;
      *return the number of system-dependent information items available for the external file;
      infonum=foptnum(fid);
      do i=1 to infonum;
        infoname=foptname(fid,i);
        infoval=finfo(fid,infoname);
        infoname = translate(trim(infoname),"_"," ()");
        infoname = translate(trim(infoname),"_"," ");

        if trim(upcase(infoname)) in ('FILENAME','OWNER_NAME','LAST_MODIFIED','FILE_SIZE__BYTES') then output;
        *output;
      end;
   end;
   else do;
     infoname="Filename"; infoval="&file_path"; output;
     infoname="Owner_Name";infoval=""; output;
     infoname="Last_Modified";infoval="";output;
     infoname="File_Size__bytes";infoval="";output;
   end;
   close=fclose(fid);
 run;
 

 /* transpose each information item into its own variable */
 proc transpose data=_file_attr out=file_attrs(drop=_:) ;
   by file_seq ;
   var infoval;
   id infoname;
 run;

data &sas_dsname;
 set file_attrs;
 drop file_seq;
run;

proc datasets library=work nolist;
 delete _file_attr file_attrs;
run;

%mend get_FileAttributes;

%*get_FileAttributes(file_path=/compute-landingzone/Projects/hlsdata/study_003/programs/dev/d0_dm.sas);
%*get_fileAttributes(file_path=PSMAC.TPLATE);
