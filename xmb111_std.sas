*************************************************************************;
* Title: xmb111_std.sas								                    *;
* Author: MJB							                *;
* Date:	17 June 2003							                        *;
* SAS Version: 8.2							                            *;
* OS: Windows NT							                            *;
* Purpose:	create a standard template for zgi output via ods			*;
* Project: 								                                *;
* Files used:								                            *;
* Files created:							                            *;
* Validated by: xyz on ddMONyyyy 					                    *;
* Validation Method:							                        *;
* Comments:								                                *;
* Modifications:  02Feb2010 Matt Becker - updated to run on system      *;
*************************************************************************;
ods path
   psmac.tplate (update)
   sashelp.tmplmst (read) ;

proc template;                                                                
   define style xmb111_std / store =  &derdata..TPLATE (update);                            
      parent = styles.rtf; 
      style Body from Document /                                              
         marginleft = 1in                                                     
         marginright = 1in                                                    
         margintop = 1in                                                      
         marginbottom = 1in;                                                                                                     
      style table from output /                                               
         rules = groups                                                       
         frame = hsides                                                         
         borderspacing = 1                                                    
         padding = 0                                                          
         protectspecialchars = off;                                           
      style header from header /                                              
         backgroundcolor = _undef_;                                           
      style SystemFooter from TitlesAndFooters /                              
         font = Fonts('FootFont');                                            
      style headersAndFooters from cell /                                     
         color = colors('headerfg')                                           
         font = fonts('HeadingFont');                                         
      style fonts /                                                           
         'docFont' = ("Times New Roman",9pt)                                  
         'headingFont' = ("Times New Roman",9pt,bold)                         
         'FootFont' = ("Times New Roman",9pt)                                 
         'headingEmphasisFont' = ("Times New Roman",9pt,bold italic)          
         'FixedFont' = ("Times New Roman",9pt)                                
         'BatchFixedFont' = ("Times New Roman",9pt)                           
         'FixedHeadingFont' = ("Times New Roman",9pt,bold)                    
         'FixedStrongFont' = ("Times New Roman",9pt,bold)                     
         'FixedEmphasisFont' = ("Times New Roman",9pt,italic)                 
         'EmphasisFont' = ("Times New Roman",9pt,italic)                      
         'StrongFont' = ("Times New Roman",9pt,bold)                          
         'TitleFont' = ("Times New Roman",9pt,bold)                           
         'TitleFont2' = ("Times New Roman",9pt,bold);                         
    
   end;                                                                       
run;                         
