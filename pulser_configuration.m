% Pulser Configuration Model
%
% 
% Here you set the daq boards you have, and what you want the channels to
% be. This is just a matter of convinence; you can (should be able to) set all this stuff in the
% GUI.

%% Ni Daqs

% Set the Session's Rate (note that all cards have to obey)
pulser.ni.rate = 20000;
pulser.ni.daqToggle=1;      % 0 means no daqs, 1 means use daqs (debug purposes, you probably want 1 here)

%% ----- Analog Out
%
pulser.ni.aOut.devIDs={'Dev1','Dev1','Dev1','Dev1'};  % I default to the cell array approach even for one card for maximum flexibility. 
pulser.ni.aOut.names={'Blue Laser','Yellow Laser','Piezo','Output 4'};
pulser.ni.aOut.channels=[0 1];  % The NI board number.

% ** Optional: You can configure your experiment here instead of the GUI.
pulser.ni.aOut.trains.types={'pulses' 'ramps'};  % Cell array containing strings 'pulses' for pulse train, 'ramps' for ramp. These need to be in order of your output channel vector.
pulser.ni.aOut.trains.baselines=[0 0];			% Row vector continaing the baselines (in volts) at which to give your pulses relative to.
pulser.ni.aOut.trains.baselineTimes=[3 5];		% Time to hold at baseline before any patterned output starts.
pulser.ni.aOut.trains.amplitudes=[5 8];			% Row vector containing the peak command voltage(s) you want.
pulser.ni.aOut.trains.repetitions=[1 1];		% How many times do you want your train or ramp to repeat?
pulser.ni.aOut.trains.interTrainInterval=[1 1];	% Time between train (or ramp, or whatever) repetitions.
pulser.ni.aOut.trains.pulseWidths=[.010 0];		% How wide should your pulses be? (in seconds)
pulser.ni.aOut.trains.numPulses=[10 0];			% How many pulses in a given repetition will you give?
pulser.ni.aOut.trains.pulseInterval=[.025 0];	% How much time to spend in between pulses (Note: this should ignore pulse width, TODO: I need to check). Does not apply to ramps, so just put a zero or something.
pulser.ni.aOut.trains.rampSpeeds=[0 3];			% Speed (V/sec) at which your ramp will climb from baseline to peak.

	
%% ----- Analog In
% 
pulser.ni.aIn.devIDs={'Dev1','Dev1','Dev1','Dev1'}; 
pulser.ni.aIn.names={'Blue Laser Copy','Yellow Laser Copy','Piezo Copy','input4'};
pulser.ni.aIn.channels=[0 1 2 3];  % could be numeric arrays in the cells.

%% ----- Digital Out  (TODO: Test Digital Out)
%
% pulser.ni.dOut.Names={'Test'};
% pulser.ni.dOut.devIDs={'Dev1'}; 
% pulser.ni.dOut.channels={'port0/line1'};  %Needs to be a cell array.  
% 
% % ** Optional: You can configure your experiment here instead of the GUI.
% pulser.ni.aOut.trains.types={'pulses'};         % Cell array containing strings 'pulses' for pulse train, 'toggles' for shutters, etc. These need to be in order of your output channel vector.
% pulser.ni.aOut.trains.baselines=[0];			% Row vector continaing the baselines (in volts) at which to give your pulses relative to.
% pulser.ni.aOut.trains.baselineTimes=[3];		% Time to hold at baseline before any patterned output starts.
% pulser.ni.aOut.trains.amplitudes=[5];			% Row vector containing the peak command voltage(s) you want.
% pulser.ni.aOut.trains.repetitions=[1];		% How many times do you want your train or ramp to repeat?
% pulser.ni.aOut.trains.interTrainInterval=[1];	% Time between train (or ramp, or whatever) repetitions.
% pulser.ni.aOut.trains.pulseWidths=[.010];		% How wide should your pulses be? (in seconds)
% pulser.ni.aOut.trains.numPulses=[10];			% How many pulses in a given repetition will you give?
% pulser.ni.aOut.trains.pulseInterval=[.025];	% How much time to spend in between pulses (Note: this should ignore pulse width, TODO: I need to check). Does not apply to ramps, so just put a zero or something.

%% ----- Quadrature Encoding
%
pulser.ni.counter.devIDs={'Dev1'};
pulser.ni.counter.channels=[0];
pulser.ni.counter.type={'position'};
pulser.ni.counter.names={'Rotary1'}; 

%% ----- Optical Encoders  (optical mouse chips connected to arduinos; dx and dys are streamed over serial)
% These function outside of the session.
%
pulser.opticalEncoder.encoderToggle=1;
pulser.opticalEncoder.count=1;
pulser.opticalEncoder.baudRates=(38400);
pulser.opticalEncoder.serialPort=['COM3'];  % Typically 'COM3' on Windows. You can get this from the arduino ide, if you have a tough time finding it.

