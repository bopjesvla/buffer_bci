call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../../utilities/initPaths.m;startSigProcBuffer('epochEventType','stimulus.target','testepochEventType','stimulus.image','freqband',[.1 1 10 12],'clsfr_type','erp','trlen_ms',1300);quit();" %matopts%
) else (
  echo run ../../utilities/initPaths.m;startSigProcBuffer('epochEventType','stimulus.target','testepochEventType','stimulus.image','freqband',[.1 1 10 12],'clsfr_type','erp','trlen_ms',1300); | %matexe% %matopts%
)