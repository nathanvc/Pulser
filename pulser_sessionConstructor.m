% Start a 'Pulser' session.
%
% CAD 8/28/2012


%%  Daq Configure  (Configure DAQ 'tasks' for aOut, aIN etc.)

% Only run if the the daqToggle bit is flipped. The user does this explicitly in the configuration, but it could be flipped by certain GUI states.
%

if pulserSession.ni.daqToggle
	import dabs.ni.daqmx.*
  
	% I need to count channels.     
	%function chanObjs = createAOVoltageChan(obj,deviceNames,chanIDs,chanNames,minVal,maxVal,units,customScaleName)
	if numel(pulserSession.aOut.devIDs > 0)
		pulserSession.aOut.task=Task('pulserAO')  %Create a task object; needs a string identifier.
		pulserSession.aOut.task.createAOVoltageChan(pulserSession.ni.aOut.devIDs,pulserSession.ni.aOut.channels,pulserSession.ni.aOut.names,-10,10);
    end
    
    if numel(pulserSession.ni.aIn.names > 0)
        for i=1:numel(pulserSession.ni.aIn.names)
			pulserSession.aIn.task=Task('pulserAI')  %Create a task object; needs a string identifier.
			pulserSession.aIn.task.createAIVoltageChan(pulserSession.ni.aIn.devIDs,pulserSession.ni.aIn.channels,pulserSession.ni.aIn.names,-10,10);
        end
    end
	
	% function chanObj = createDOChan(obj,deviceNames,chanIDs,chanNames,lineGrouping)
    if numel(pulserSession.ni.digOut.names > 0)
        for i=1:numel(pulserSession.ni.digOut.names)
			pulserSession.digOut.task=Task('pulserDigOut')  %Create a task object; needs a string identifier.
			pulserSession.digOut.task.createDOChan(pulserSession.ni.digOut.devIDs,pulserSession.ni.digOut.channels,pulserSession.ni.digOut.names);
        end
    end
    
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
