
options noquotelenmax;

%macro run_batch(sas_prg=);

%let sas_path = %substr(&sas_prg,1,%sysfunc(find(&sas_prg,%str(/),-%length(&sas_prg)))-1);
%put sas_path = &sas_path;

%let prg_name = %scan(%scan(&sas_prg,-1,%str(/)),1,%str(.));
%put prg_name = &prg_name;


%AnalyzeIO (SASFile=%str(&sas_prg),
            worklib=%str(&sas_path./../../lineage/worklib),
            file_io=(Y),
            master_io=%str(&sas_path./../../lineage/master_io.sas7bdat)
            ); 
%mend run_batch;



