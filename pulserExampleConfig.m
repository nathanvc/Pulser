%% Hardware Configuration
% Note: Pulser uses counter0 to time digital i/o. 
% TODO: Add channel labels, for GUI/book keeping purposes.
% TODO: Should add a save/load funtion.
pulser.AIDevice = 'Dev1';			% You can pass multiple devices via a cell-array {'Dev1','Dev2'}.
pulser.AIChans = [0 1 3 4];		% Numerical row vector. Arguments are just the channel number on the board so 0 is valid. 
pulser.AODevice = 'Dev1';			% Again, you can span devices with a cell-array.
pulser.AOChans = 0:1; 				% Numerical row vector.
pulser.DODevice='Dev1';			% Multiple devices with a cell-array (be carefull because digital i/o is implemented differently on dif boards: clocks etc.)
pulser.DOChans='line2';            % (use = 'line2:n')The arguments for API digital channel creation are one string if one daq board is used or a cell-array if multiple boards, this is unlike analog.
pulser.DOChanCount=1;              % You must specify how many digital channels you want (see note just above for my reasoning).
pulser.useCam=true;				% Boolean for toggling frame triggereing on a connected camera. If true, a counter task (counter1 by default) will be created at the frame rate of choice.
pulser.camFrameRate=10;			% Rate you want to drive your camera at.

pulser.sampleRate = 50000;         % In Hz applies to all tasks for now, but you could (theoretically) create a rate for each task.
pulser.acqTime=10;					% Total acquisition time for a trial.
pulser.numTrials=1;				% Number of times your configured tasks will repeat. This works, but each run has to be triggered.
pulser.interTrialInterval=0;		% Dead-time in between trials, if you want any. Since I have to trigger each trial, this might be redundant.

%% Waveform Configureation
% Note: This is set up to take the arguments needed for pulse train, or ramp construction.  Analog and digital are configured seperatly. 

% Analog Out
% assignments are row-vectors that are assumed to go in order of the specified channels 
% if an argument doesn't apply, like ramp-speed for pulse trains, just put a zero in (not ideal) Pulser will sort it out.
% Amplitudes in Volts and Times in Seconds.
pulser.trainTypes=[1 2];			% 1 for pulse-train, 2 for ramp
pulser.trainAmplitudes=[5 7];		% Peak amplitude your output will reach. Pulse height, ramp peak etc. (In Volts)		
pulser.rampSpeeds=[0 3.5];			% Speed (V/sec) at which your ramp will climb from baseline to peak.
pulser.baselineValues=[0 0];		% Baseline from which to operate around. Note you can have a dc input by calling a pulse train of any type with no amplitude.
pulser.baselineTimes=[3 5];		% Time to hold at baseline before any patterned output starts.
pulser.numTrains=[1 1];			% How many times do you want your train or ramp to repeat?
pulser.interTrainInterval=[10 10];	% Time between train (or ramp, or whatever) repetitions.
pulser.pulseWidths=[.010 0];		% How wide should your pulses be? (in seconds)
pulser.numPulses=[10 0];			% How many pulses in a given repetition will you give?
pulser.pulseInterval=[.025 0];		% How much time in between your pulses.  TODO: I should have a toggle that lets the user put this is rate or time.

% Digital Out
% assignments are row-vectors that are assumed to go in order of the specified channels 
% pulses only of course (and amplitude is always 1 or 5)
% Amplitudes in Volts and Times in Seconds.	
pulser.stepDigValue=[1];			% Equivalent to analog's amplitude (do you want your trains to be high=1 or low=0?)
pulser.baselineDigValues=[0];		% Can only be 0 or 5. I trust the user won't mess that up here, but will enforce in GUI.
pulser.baselineDigTimes=[3];		% Time to hold at baseline before any patterned output starts.
pulser.numDigTrains=[1];			% How many times do you want your train or ramp to repeat?
pulser.interDigTrainInterval=[10];	% Time between train (or ramp, or whatever) repetitions.
pulser.pulseDigWidths=[.010];		% How wide should your pulses be? (in seconds)
pulser.numDigPulses=[10];			% How many pulses in a given repetition will you give?
pulser.pulseDigInterval=[.025];	% How much time in between your pulses.  TODO: I should have a toggle that lets the user put this is rate or time.		
%%%%%%%%%%%%%%%%%%%%%%