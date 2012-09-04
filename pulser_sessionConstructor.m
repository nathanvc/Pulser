% Start a 'Pulser' session.
%
% CAD 8/28/2012


%%  Daq Configure  (Configure DAQ 'tasks' for aOut, aIN etc.)

% Only run if the the daqToggle bit is flipped. The user does this explicitly in the configuration, but it could be flipped by certain GUI states.
%

if pulserSession.ni.daqToggle
	import dabs.ni.daqmx.*
    %########## Put This Shit Somewhere Else !!!!!  ##########
    trainLength=10;
    sampleRate=20000;
    possibleHandlingModes={'DAQmx_Val_FiniteSamps','DAQmx_Val_ContSamps','DAQmx_Val_HWTimedSinglePoint'};
    
    % Sometimes continuous (infinite acquistion) is desired. This will catch the mode to select. 
    if isfinite(trainLength)
        modeToUse=1;
    else
        modeToUse=2;
    end
    %############################################################

  
	if length(pulserSession.ni.aOut.channels) > 0;
		pulserSession.aOut.task=Task('analogOut');  %Create a task object; needs a string identifier.
		pulserSession.aOut.task.createAOVoltageChan(pulserSession.ni.aOut.devIDs,pulserSession.ni.aOut.channels,pulserSession.ni.aOut.names,-10,10);
        pulserSession.aIn.task.cfgSampClkTiming(sampleRate,possibleHandlingModes(modeToUse), trainLength*sampleRate);
    end
    
    if length(pulserSession.ni.aIn.channels) > 0;
        for i=1:numel(pulserSession.ni.aIn.names)
			pulserSession.aIn.task=Task('analogIn');  %Create a task object; needs a string identifier.
			pulserSession.aIn.task.createAIVoltageChan(pulserSession.ni.aIn.devIDs,pulserSession.ni.aIn.channels,pulserSession.ni.aIn.names,-10,10);
            pulserSession.aIn.task.cfgSampClkTiming(sampleRate,possibleHandlingModes(modeToUse), trainLength*sampleRate);
        end
    end
	
	% function chanObj = createDOChan(obj,deviceNames,chanIDs,chanNames,lineGrouping)
%     if length(pulserSession.ni.digOut.channels) > 0
%         for i=1:numel(pulserSession.ni.digOut.names)
% 			pulserSession.digOut.task=Task('pulserDigOut');  %Create a task object; needs a string identifier.
% 			pulserSession.digOut.task.createDOChan(pulserSession.ni.digOut.devIDs,pulserSession.ni.digOut.channels,pulserSession.ni.digOut.names);
%         end
%     end
    
%    if numel(pulserSession.ni.counterCount > 0)
%        for i=1,numel(pulserSession.ni.counterCount)
%            pulser_daq_session.addCounterInputChannel(pulserSession.ni.cards(i), 0:pulserSession.ni.counterCount(i)-1, pulserSession.ni.counterType(i));
%        end
%    end

else
end

%%  Arduino Optical Encoder Configuration

% Pre-allocate data containers for the encoders
if pulserSession.opticalEncoder.encoderToggle
    for i=1:pulserSession.opticalEncoder.count
        pulserSession.opticalEncoder.data{i}=[];
    end
else
end

%%
