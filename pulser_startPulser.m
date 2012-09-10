function [outData]=pulser_startPulser()

%% Hardware Configuration  (ideally this would be done elsewhere using a rig and/or user specific configuration file)
% Note: Pulser uses counter0 to time digital i/o. 
% TODO: Add channel labels, for GUI/book keeping purposes.
% TODO: Should add a save/load funtion.
AIDevice = 'Dev1';			% You can pass multiple devices via a cell-array {'Dev1','Dev2'}.
AIChans = [0 1 3 4];		% Numerical row vector. Arguments are just the channel number on the board so 0 is valid. 
AODevice = 'Dev1';			% Again, you can span devices with a cell-array.
AOChans = 0:1; 				% Numerical row vector.
DODevice='Dev1';			% Multiple devices with a cell-array (be carefull because digital i/o is implemented differently on dif boards: clocks etc.)
DOChans='line2';            % (use = 'line2:n')The arguments for API digital channel creation are one string if one daq board is used or a cell-array if multiple boards, this is unlike analog.
DOChanCount=1;              % You must specify how many digital channels you want (see note just above for my reasoning).
useCam=true;				% Boolean for toggling frame triggereing on a connected camera. If true, a counter task (counter1 by default) will be created at the frame rate of choice.
camFrameRate=10;			% Rate you want to drive your camera at.

sampleRate = 50000;         % In Hz applies to all tasks for now, but you could (theoretically) create a rate for each task.
acqTime=10;					% Total acquisition time for a trial.
numTrials=1;				% Number of times your configured tasks will repeat. This works, but each run has to be triggered.
interTrialInterval=0;		% Dead-time in between trials, if you want any. Since I have to trigger each trial, this might be redundant.

%% Waveform Configureation (again I'd like to move this elsewhere)
% Note: This is set up to take the arguments needed for pulse train, or ramp construction.  Analog and digital are configured seperatly. 

% Analog Out
% assignments are row-vectors that are assumed to go in order of the specified channels 
% if an argument doesn't apply, like ramp-speed for pulse trains, just put a zero in (not ideal) Pulser will sort it out.
% Amplitudes in Volts and Times in Seconds.
trainTypes=[1 2];			% 1 for pulse-train, 2 for ramp
trainAmplitudes=[5 7];		% Peak amplitude your output will reach. Pulse height, ramp peak etc. (In Volts)		
rampSpeeds=[0 3.5];			% Speed (V/sec) at which your ramp will climb from baseline to peak.
baselineValues=[0 0];		% Baseline from which to operate around. Note you can have a dc input by calling a pulse train of any type with no amplitude.
baselineTimes=[3 5];		% Time to hold at baseline before any patterned output starts.
numTrains=[1 1];			% How many times do you want your train or ramp to repeat?
interTrainInterval=[10 10];	% Time between train (or ramp, or whatever) repetitions.
pulseWidths=[.010 0];		% How wide should your pulses be? (in seconds)
numPulses=[10 0];			% How many pulses in a given repetition will you give?
pulseInterval=[.025 0];		% How much time in between your pulses.  TODO: I should have a toggle that lets the user put this is rate or time.

% Digital Out
% assignments are row-vectors that are assumed to go in order of the specified channels 
% pulses only of course (and amplitude is always 1 or 5)
% Amplitudes in Volts and Times in Seconds.	
stepDigValue=[1];			% Equivalent to analog's amplitude (do you want your trains to be high=1 or low=0?)
baselineDigValues=[0];		% Can only be 0 or 5. I trust the user won't mess that up here, but will enforce in GUI.
baselineDigTimes=[3];		% Time to hold at baseline before any patterned output starts.
numDigTrains=[1];			% How many times do you want your train or ramp to repeat?
interDigTrainInterval=[10];	% Time between train (or ramp, or whatever) repetitions.
pulseDigWidths=[.010];		% How wide should your pulses be? (in seconds)
numDigPulses=[10];			% How many pulses in a given repetition will you give?
pulseDigInterval=[.025];	% How much time in between your pulses.  TODO: I should have a toggle that lets the user put this is rate or time.		
%%%%%%%%%%%%%%%%%%%%%%
shutterLines=[7 6];
shutterPause=1;  %Time to wait (in sec) after toggling shutters. I didn't see a scenario have multiples, one will always rate limit - right?
shutterToggles=[1 1];  %What to write 1: High 0: Low
shutterDevice='dev1';


%% Create Tasks
import dabs.ni.daqmx.*

%%%%% Set up and queue tasks
% I've set everything to 'queue' before a rising-edge trigger on PFI0. Matlab can not execute the tasks simultaneously, so a trigger is the only way to sync up the i/o.  To do this everything is clocked to counter0, which is triggered by rising-edge of PFI0.  TODO: create software input to PFI0 and toggle in GUI.

% Note: I'm not looping trials for now, but it will require a trigger to
% advance each.
for k=1:numTrials,  % I don't wan't to indent the program, so I'll point out the closers at the end for the 'main loop'
    
% Toggle Shutters Etc. (Non-buffered Digital I/O. Straight From Meng Demo)
if numel(shutterLines) > 1,
    pShutterTask = dabs.ni.daqmx.Task.empty();
    for i=1:numel(shutterLines),
        pShutterTask(i) = dabs.ni.daqmx.Task(sprintf('Shutter %d Control',i));
        pShutterTask(i).createDOChan(shutterDevice,sprintf('line%d',shutterLines(i)));
        pShutterTask(i).writeDigitalData(shutterToggles(i));
    end
    shutterFlag=1;
    pause(shutterPause)
else
    shutterFlag=0;
end

%Counter For Timing Tasks
pCntrTask=Task('Counter Task');
pCntrTask.createCOPulseChanFreq(DODevice,0,'',sampleRate); 
pCntrTask.cfgImplicitTiming('DAQmx_Val_ContSamps',acqTime*sampleRate);
pCntrTask.cfgDigEdgeStartTrig('PFI0');
pCntrTask.start();

%Counter For Camera  (Could be used for something else)
if useCam==1,
    pCamTask=Task('Camera Task');
    pCamTask.createCOPulseChanFreq(DODevice,1,'',camFrameRate); 
    pCamTask.cfgImplicitTiming('DAQmx_Val_ContSamps',acqTime*sampleRate);
    pCamTask.cfgDigEdgeStartTrig('PFI0');
    pCamTask.start();
else
end

% Analog Output
if numel(AOChans) > 0,
    pOutputTask = Task('pulser out');
    pOutputTask.createAOVoltageChan(AODevice,AOChans);
    pOutputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps',sampleRate*acqTime,'Ctr0InternalOutput');
    % pOutputTask.set('writeRegenMode','DAQmx_Val_AllowRegen');
    
    % Now construct pulse trains and ramps seperatley for analog output. This will be expanded for different types (noise etc.)
	% Pre-Allocate output vectors (because it's Matlab)
	% Each column represents a channel.
	aOutWrte=zeros(sampleRate*acqTime,numel(AOChans));
	for i=1:numel(AOChans),
	    if trainTypes(i)==1,
	        aOutWrte(:,i)=pulser_pulses(trainAmplitudes(i),pulseWidths(i),numPulses(i),pulseInterval(i),baselineTimes(i),baselineValues(i),numTrains(i),interTrainInterval(i),sampleRate,acqTime);
	    elseif trainTypes(i)==2,
	        aOutWrte(:,i)=pulser_ramp(trainAmplitudes(i),rampSpeeds(i),baselineTimes(i),baselineValues(i),numTrains(i),interTrainInterval(i),sampleRate,acqTime);
	    end
	end
	pOutputTask.writeAnalogData(aOutWrte,inf,true);
	aOutFlag=1;
else
	aOutFlag=0;
end

% Digital Output (Buffered)
if DOChanCount > 0,
    pDigOutputTask = Task('pulser digout');
    pDigOutputTask.createDOChan(DODevice,DOChans);
    pDigOutputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps',sampleRate*acqTime,'Ctr0InternalOutput');
    % pDigOutputTask.set('writeRegenMode','DAQmx_Val_AllowRegen');
	
    % Now contruct digital outputs
	% these are always pulse trains (I will support unbuffered 'toggles' soon, but they will be configured differently).
	% Pre-Allocate output vectors (because it's Matlab)
	% Each column represents a channel.
	dOutWrte=zeros(sampleRate*acqTime,numel(DOChans));
	for i=1:DOChanCount,
		dOutWrte(:,i)=pulser_pulses(stepDigValue(i),pulseDigWidths(i),numDigPulses(i),pulseDigInterval(i),baselineDigTimes(i),baselineDigValues(i),numDigTrains(i),interDigTrainInterval(i),sampleRate,acqTime);
	end
	pDigOutputTask.writeDigitalData(dOutWrte,inf,true);
	digOutFlag=1;
else
	digOutFlag=0;
end

% Analog Input  (The outputs have to be higher than me on the 'stack'!)
if numel(AIChans) > 0,
    pInputTask = Task('pulser in');
    pInputTask.createAIVoltageChan(AIDevice,AIChans);
    pInputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps',sampleRate*acqTime,'Ctr0InternalOutput');
    % pInputTask.cfgDigEdgeStartTrig('PFI0');  %Not needed becuse the clock
    % is triggered.
	outData=pInputTask.readAnalogData(acqTime*sampleRate,'scaled',inf);
	aInFlag=1;
else
	aInFlag=0;
end


% Maybe I should just query the task map instead of this flag non-sense?
pCntrTask.clear();
if shutterFlag,   %Toggle shutters back before a new run or exit. It would be wise to give user control of this. 
    for i=1:numel(shutterLines),
        pShutterTask(i).writeDigitalData(abs(shutterToggles(i)-1));  % This was to toggle back without another paramater. abs(0-1)=1 and abs(1-1)=0
    end
    pShutterTask.clear();
else
end
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
if useCam==1,
	pCamTask.clear();
else
end
pause(interTrialInterval);  % For the main loop
end							% Also, for the main loop.


% Place holder until I implement a a way to do this simultaneously:
%% ----- Optical Encoders  (optical mouse chips connected to arduinos; dx and dys are streamed over serial)
%  I need to rig up a way for this to execute at the same time the tasks do
%  (PFI0 trigger)

% encoderToggle=1;
% encoderCount=1;
% ecoderBaudRates=38400;
% encoderSerialPort={'COM3'};
% 
% % Pre-allocate data containers for the encoders
% if encoderToggle
%     for i=1:encoderCount
%         encoderData{i}=[];
%     end
% else
% end