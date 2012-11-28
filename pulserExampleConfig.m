%% Pulser Configuration

% Note: Pulser uses counter0 to time digital i/o. The other counters are free to use.
% This will spit out a variable called pulser, but you can make this anything as long as you end up with a struct to pass to Pulser.

%% Hardware Configuration  
pulser.sampleRate = 10000;         	% In Hz applies to all tasks for now, but you could (theoretically) create a rate for each task.
pulser.acqTime=20;					% Total acquisition time for a trial.
pulser.numTrials=1;					% Number of times your pulserured tasks will repeat. This works, but each run has to be triggered.
pulser.interTrialInterval=0;		% Dead-time in between trials, if you want any. Since I have to trigger each trial, this might be redundant.

pulser.AIDevice = 'Dev1';			% You can pass multiple devices via a cell-array {'Dev1','Dev2'}.
pulser.AIChans = [0 1 3];			% Numerical row vector. Arguments are just the channel number on the board so 0 is valid.
pulser.AIChanLabels = {'Whisker Stim','Blue Laser','2p frame trigger'};  % Optional Labels

pulser.AODevice = 'Dev1';			% Again, you can span devices with a cell-array.
pulser.AOChans = [0 1]; 				% Numerical row vector.
pulser.AOChanLabels = {'Whisker Stim','blue laser'};  % Optional Labels

pulser.DODevice='Dev1';			% Multiple devices with a cell-array (be carefull because digital i/o is implemented differently on dif boards: clocks etc.)
pulser.DOChans='line2';            % (use = 'line2:n')The arguments for API digital channel creation are one string if one daq board is used or a cell-array if multiple boards, this is unlike analog.
pulser.DOChanCount=1;              % You must specify how many digital channels you want (see note just above for my reasoning).

pulser.useCam=false;				% Boolean for toggling frame triggereing on a connected camera. If true, a counter task (counter1 by default) will be created at the frame rate of choice.
pulser.camFrameRate=10;			% Rate you want to drive your camera at.

%% Waveform Configuration (again I'd like to move this elsewhere)
% Note: This is set up to take the arguments needed for pulse train, or ramp construction.  Analog and digital are pulserured seperately. 

% Analog Out
% assignments are row-vectors that are assumed to go in order of the specified channels 
% if an argument doesn't apply like ramp-speed for pulse trains, just put a zero in anyway (not ideal) Pulser will sort it out.
% Amplitudes in Volts and Times in Seconds.
pulser.trainTypes=[1 1];			% 1 for pulse-train, 2 for ramp, 3 for whale
pulser.trainAmplitudes=[-8 0];		% Peak amplitude your output will reach. Pulse height, ramp peak etc. (In Volts)		
pulser.rampSpeeds=[0 0];			% Speed (V/sec) at which your ramp will climb from baseline to peak.
pulser.baselineValues=[0 0];		% Baseline from which to operate around. Note you can have a dc input by calling a pulse train of any type with no amplitude.
pulser.baselineTimes=[0 60];		% Time to hold at baseline before any patterned output starts. This has to be smaller than the acquisition time.
pulser.numTrains=[0 6];				% How many times do you want your train or ramp to repeat?
pulser.interTrainInterval=[60 60];	% Time between train (or ramp, or whatever) repetitions.
pulser.pulseWidths=[.010 .006];		% How wide should your pulses be? (in seconds)
pulser.numPulses=[15 20];			% How many pulses in a given repetition will you give?
pulser.pulseRate=[15 30];			% How much time in between your pulses.  TODO: I should have a toggle that lets the user put this is rate or time.
pulser.upTimes=[0.005 0.005];		% For whale stimuli up stroke time.
pulser.downTimes=[0.02 0.02];		% For whale stimuli down stroke time.

% Digital Out
% assignments are row-vectors that are assumed to go in order of the specified channels 
% pulses only of course (and amplitude is always 1 or 5)
% Amplitudes in Volts and Times in Seconds.	
pulser.stepDigValue=[1];			% Equivalent to analog's amplitude (do you want your trains to be high=1 or low=0?)
pulser.baselineDigValues=[0];		% Can only be 0 or 5. I trust the user won't mess that up here, but will enforce in GUI.
pulser.baselineDigTimes=[0];		% Time to hold at baseline before any patterned output starts.
pulser.numDigTrains=[1];			% How many times do you want your train or ramp to repeat?
pulser.interDigTrainInterval=[10];	% Time between train (or ramp, or whatever) repetitions.
pulser.pulseDigWidths=[.010];		% How wide should your pulses be? (in seconds)
pulser.numDigPulses=[50];			% How many pulses in a given repetition will you give?
pulser.pulseDigFrequency=[5];	% How much time in between your pulses.  TODO: I should have a toggle that lets the user put this is rate or time.		

% Shutters
pulser.shutterLines=[7];
pulser.shutterPause=1;  %Time to wait (in sec) after toggling shutters. I didn't see a scenario have multiples, one will always rate limit - right?
pulser.shutterToggles=[1];  %What to write 1: High 0: Low
pulser.shutterDevice='dev1';
