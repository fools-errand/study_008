
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

      %*if %qupcase(%qscan(&name,-1,.)) = %upcase(&ext) %then %do;
        *FILE="&dir/&name";  *output;
      %*end;
      %*else %if %qscan(&name,2,.) = %then %do;        
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