function pulser_startPulserOld(ainTaskName)

% Execute all 'committed' tasks.
% sampleRate is the niDaq task rate desired.
% trainLength is the length of the output/input
% toGraph is a boolean

% TODO: I need to figure out how to set all the tasks off at once, even though there may not always be Ains etc.


%% ----- Local Calculations

import dabs.ni.daqmx.*
% 
% possibleHandlingModes={'DAQmx_Val_FiniteSamps','DAQmx_Val_ContSamps','DAQmx_Val_HWTimedSinglePoint'};
% possibleHandlingModes(modeToUse(1))
% 
% Sometimes continuous (infinite acquistion) is desired. This will catch the mode to select. 
if isfinite(trainLength)
	modeToUse=1;
else
	modeToUse=2;
end
	

ainTaskName.start
%ainTaskName.registerDoneEvent(disp('Acquisition Done!'));
