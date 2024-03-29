function [outData]=pulser_startPulserWithConfig(config)
% Takes a config file as it's argument. Spits out analog input data that
% should be captured in an output variable.

%% Create Tasks
import dabs.ni.daqmx.*

%%%%% Set up and queue tasks
% I've set everything to 'queue' before a rising-edge trigger on PFI0. Matlab can not execute the tasks simultaneously, so a trigger is the only way to sync up the i/o.  To do this everything is clocked to counter0, which is triggered by rising-edge of PFI0.  TODO: create software input to PFI0 and toggle in GUI.

% Note: I'm not looping trials for now, but it will require a trigger to
% advance each.
for k=1:config.numTrials,  % I don't wan't to indent the program, so I'll point out the closers at the end for the 'main loop'
    
%Counter For Timing Tasks
pCntrTask=Task('Counter Task');
pCntrTask.createCOPulseChanFreq(config.DODevice,0,'',config.sampleRate); 
pCntrTask.cfgImplicitTiming('DAQmx_Val_ContSamps',config.acqTime*config.sampleRate);
pCntrTask.cfgDigEdgeStartTrig('PFI0');
pCntrTask.start();

%Counter For Camera  (Could be used for something else)
if config.useCam==1,
    pCamTask=Task('Camera Task');
    pCamTask.createCOPulseChanFreq(config.DODevice,1,'',config.camFrameRate); 
    pCamTask.cfgImplicitTiming('DAQmx_Val_ContSamps',config.acqTime*config.sampleRate);
    pCamTask.cfgDigEdgeStartTrig('PFI0');
    pCamTask.start();
else
end

% Analog Output
if numel(config.AOChans) > 0,
    pOutputTask = Task('pulser out');
    pOutputTask.createAOVoltageChan(config.AODevice,config.AOChans);
    pOutputTask.cfgSampClkTiming(config.sampleRate,'DAQmx_Val_ContSamps',config.sampleRate*config.acqTime,'Ctr0InternalOutput');
    % pOutputTask.set('writeRegenMode','DAQmx_Val_AllowRegen');
    
    % Now construct pulse trains and ramps seperatley for analog output. This will be expanded for different types (noise etc.)
	% Pre-Allocate output vectors (because it's Matlab)
	% Each column represents a channel.
	aOutWrte=zeros(config.sampleRate*config.acqTime,numel(config.AOChans));
	for i=1:numel(config.AOChans),
	    if config.trainTypes(i)==1,
	        aOutWrte(:,i)=pulser_pulses(config.trainAmplitudes(i),config.pulseWidths(i),config.numPulses(i),config.pulseInterval(i),config.baselineTimes(i),config.baselineValues(i),config.numTrains(i),config.interTrainInterval(i),config.sampleRate,config.acqTime);
	    elseif config.trainTypes(i)==2,
	        aOutWrte(:,i)=pulser_ramp(config.trainAmplitudes(i),config.rampSpeeds(i),config.baselineTimes(i),config.baselineValues(i),config.numTrains(i),config.interTrainInterval(i),config.sampleRate,config.acqTime);
	    end
	end
	pOutputTask.writeAnalogData(aOutWrte,inf,true);
	aOutFlag=1;
else
	aOutFlag=0;
end

% Digital Output
if config.DOChanCount > 0,
    pDigOutputTask = Task('pulser digout');
    pDigOutputTask.createDOChan(config.DODevice,config.DOChans);
    pDigOutputTask.cfgSampClkTiming(config.sampleRate,'DAQmx_Val_ContSamps',config.sampleRate*config.acqTime,'Ctr0InternalOutput');
    % pDigOutputTask.set('writeRegenMode','DAQmx_Val_AllowRegen');
	
    % Now contruct digital outputs
	% these are always pulse trains (I will support unbuffered 'toggles' soon, but they will be configured differently).
	% Pre-Allocate output vectors (because it's Matlab)
	% Each column represents a channel.
	dOutWrte=zeros(config.sampleRate*config.acqTime,numel(config.DOChans));
	for i=1:config.DOChanCount,
		dOutWrte(:,i)=pulser_pulses(config.stepDigValue(i),config.pulseDigWidths(i),config.numDigPulses(i),config.pulseDigInterval(i),config.baselineDigTimes(i),config.baselineDigValues(i),config.numDigTrains(i),config.interDigTrainInterval(i),config.sampleRate,config.acqTime);
	end
	pDigOutputTask.writeDigitalData(dOutWrte,inf,true);
	digOutFlag=1;
else
	digOutFlag=0;
end

% Analog Input  (The outputs have to be higher than me on the 'stack'!)
if numel(config.AIChans) > 0,
    pInputTask = Task('pulser in');
    pInputTask.createAIVoltageChan(config.AIDevice,config.AIChans);
    pInputTask.cfgSampClkTiming(config.sampleRate,'DAQmx_Val_ContSamps',config.sampleRate*config.acqTime,'Ctr0InternalOutput');
    % pInputTask.cfgDigEdgeStartTrig('PFI0');  %Not needed becuse the clock
    % is triggered.
	outData=pInputTask.readAnalogData(config.acqTime*config.sampleRate,'scaled',inf);
	aInFlag=1;
else
	aInFlag=0;
end


% Maybe I should just query the task map instead of this flag non-sense?
pCntrTask.clear();
% hTrig.clear();
if aInFlag,
	pInputTask.clear();
else
end
if aOutFlag,
	pOutputTask.clear();
else
end
if digOutFlag,
	pDigOutputTask.clear();
else
end
if config.useCam==1,
	pCamTask.clear();
else
end
pause(config.interTrialInterval);  % For the main loop
end							% Also, for the main loop.