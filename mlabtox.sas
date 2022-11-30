**************************************************************************************;
** macro mlabtox - calculates lab toxicity grades (baseline, worst grade post dose, 
**                  shift to worst grade post dose, end of study grade, shift to end
**                  of study grade)
** mjb 30jan2010
** mods:
**
**************************************************************************************;
%macro mlabtox;

data lb;
  set &derdata..lb(where=(q_safeas='Y'));
  &tcond;
  output;
  if atrt in(2,3,4) then do;
    atrt=5;
	output;
  end;
  atrt=6;
  output;
run;

%* Create baseline grade record;
data basegr(keep=atrt usubjid lbtestcd basegr_l basegr_h x_grdl x_grdh);
  set lb;
  where visitnum=0;
  basegr_l=x_toxgrl;
  basegr_h=x_toxgrh;
run;

%* Get worst grade post dose for each LOW parameter by subject;
proc sort data=lb out=worstgr_l;
  by atrt usubjid lbtestcd x_toxgrl;
  where visitnum>0;

data worstgr_l(keep=atrt usubjid lbtestcd worstgr_l);
  set worstgr_l;
  by atrt usubjid lbtestcd x_toxgrl;
  if last.lbtestcd;
  worstgr_l=x_toxgrl;
run;

%* Get worst grade post dose for each HIGH parameter by subject;
proc sort data=lb out=worstgr_h;
  by atrt usubjid lbtestcd x_toxgrh;
  where visitnum>0;

data worstgr_h(keep=atrt usubjid lbtestcd worstgr_h);
  set worstgr_h;
  by atrt usubjid lbtestcd x_toxgrh;
  if last.lbtestcd;
  worstgr_h=x_toxgrh;
run;

%* Get end of study grade for each parameter by subject;
data endgr(keep=atrt usubjid lbtestcd endgr_l endgr_h);
  set lb;
  where visitnum=29;
  endgr_l=x_toxgrl;
  endgr_h=x_toxgrh;
run;

proc sort data=basegr;
  by atrt usubjid lbtestcd;
proc sort data=worstgr_l;
  by atrt usubjid lbtestcd;
proc sort data=worstgr_h;
  by atrt usubjid lbtestcd;
proc sort data=endgr;
  by atrt usubjid lbtestcd;

data final;
  merge basegr worstgr_l worstgr_h endgr;
  by atrt usubjid lbtestcd;
  wshift_l=worstgr_l-basegr_l;
  wshift_h=worstgr_h-basegr_h;
  eshift_l=endgr_l-basegr_l;
  eshift_h=endgr_h-basegr_h;
run;

proc sort data=final;
  by atrt usubjid lbtestcd x_grdl x_grdh;

proc transpose data=final out=ftran;
  by atrt usubjid lbtestcd x_grdl x_grdh;
  var basegr_l basegr_h worstgr_l worstgr_h wshift_l wshift_h endgr_l endgr_h eshift_l eshift_h;
run;

data ftran(rename=(_name_=grade col1=result));
  set ftran;
  select (upcase(_name_));
    when ("BASEGR_L") tpt=1;
    when ("BASEGR_H") tpt=1;
    when ("WORSTGR_L") tpt=2;
    when ("WORSTGR_H") tpt=2;
    when ("WSHIFT_L") tpt=3;
    when ("WSHIFT_H") tpt=3;
    when ("ENDGR_L") tpt=4;
    when ("ENDGR_H") tpt=4;
    when ("ESHIFT_L") tpt=5;
    when ("ESHIFT_H") tpt=5;
  end;
  output;
  if col1>. then do;
    col1=-99;
	output;
  end;
run;

data ftran;
  set ftran;
  if x_grdl='Y' and x_grdh ne 'Y' and upcase(grade) in('BASEGR_H','WORSTGR_H','WSHIFT_H','ENDGR_H','ESHIFT_H') then delete;
  else if x_grdh='Y' and x_grdl ne 'Y' and upcase(grade) in('BASEGR_L','WORSTGR_L','WSHIFT_L','ENDGR_L','ESHIFT_L') then delete;
run;
%mend mlabtox;;

