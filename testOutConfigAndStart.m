%% Configure NI-DAQ Session

pulser_daq_session = daq.createSession('ni');
pulser_daq_session.Rate = pulser.ni.rate;
trialDuration=10; % in seconds

%% Analog Output

if numel(pulser.ni.aOut.channels) > 0,
    pulser.ni.aOut.aOutWrite=zeros(pulser.ni.rate*trialDuration,numel(pulser.ni.aOut.channels));
    for i=1:numel(pulser.ni.aOut.channels),
        if strcmp(pulser.ni.aOut.trains.types{i},'pulses'),
            pulser_daq_session.addAnalogOutputChannel(pulser.ni.aOut.devIDs{i}, pulser.ni.aOut.channels(i), 'Voltage');
	        pulser.ni.aOut.aOutWrite(:,i)=pulser_pulses(pulser.ni.aOut.trains.amplitudes(i),pulser.ni.aOut.trains.pulseWidths(i),pulser.ni.aOut.trains.numPulses(i),pulser.ni.aOut.trains.pulseInterval(i),pulser.ni.aOut.trains.baselineTimes(i),pulser.ni.aOut.trains.baselines(i),pulser.ni.aOut.trains.repetitions(i),pulser.ni.aOut.trains.interTrainInterval(i),pulser.ni.rate,trialDuration);
        elseif strcmp(pulser.ni.aOut.trains.types{i},'ramps'),
            pulser_daq_session.addAnalogOutputChannel(pulser.ni.aOut.devIDs{i}, pulser.ni.aOut.channels(i), 'Voltage');
	        pulser.ni.aOut.aOutWrite(:,i)=pulser_ramp(pulser.ni.aOut.trains.amplitudes(i),pulser.ni.aOut.trains.rampSpeeds(i),pulser.ni.aOut.trains.baselineTimes(i),pulser.ni.aOut.trains.baselines(i),pulser.ni.aOut.trains.repetitions(i),pulser.ni.aOut.trains.interTrainInterval(i),pulser.ni.rate,trialDuration);
        elseif strcmp(pulser.ni.aOut.trains.types{i},'ramps') || strcmp(pulser.ni.aOut.trains.types{i},'trains') ~= true,
          disp('unknown train type try again, valid choices are "ramps" and "pulses," contact Chris if you want help with other train types.')      
        end
    end
end
pulser_daq_session.addTriggerConnection('external','Dev1/PFI0','StartTrigger');
pulser_daq_session.Connections(1).TriggerCondition='FallingEdge';
%% Digital Output (just 'buffered' for now; shutters later)

% if numel(pulser.ni.dOut.channels) > 0,
%     pulser.ni.dOut.dOutWrte=zeros(pulser.ni.rate*trialDuration,numel(pulser.ni.dOut.channels));
%     for i=1:numel(pulser.ni.dOut.channels),
%         if strcmp(pulser.ni.dOut.trains.types{i},'pulses'),
%             pulser_daq_session.addDigitalChannel(pulser.ni.dOut.devIDs{i}, pulser.ni.dOut.channels{i}, 'OutputOnly');
% 	        pulser.ni.dOut.dOutWrte(:,i)=pulser_pulses(pulser.ni.dOut.trains.amplitudes(i),pulser.ni.dOut.trains.pulseWidths(i),pulser.ni.dOut.trains.numPulses(i),pulser.ni.dOut.trains.pulseInterval(i),pulser.ni.dOut.trains.baselineTimes(i),pulser.ni.dOut.trains.baselines(i),pulser.ni.dOut.trains.repetitions(i),pulser.ni.dOut.trains.interTrainInterval(i),pulser.ni.rate,trialDuration);
% %         elseif strcmp(pulser.ni.dOut.trains.types{i},'toggle'),
% %           pulser_daq_session.addAnalogOutputChannel(pulser.ni.dOut.devIDs{i}, pulser.ni.dOut.channels(i), 'Voltage');
% % 	        pulser.ni.dOut.aOutWrite(:,i)=pulser_ramp(pulser.ni.dOut.trains.amplitudes(i),pulser.ni.dOut.trains.rampSpeeds(i),pulser.ni.dOut.trains.baselineTimes(i),pulser.ni.dOut.trains.baselines(i),pulser.ni.dOut.trains.repetitions(i),pulser.ni.dOut.trains.interTrainInterval(i),pulser.ni.rate,trialDuration);
%         elseif strcmp(pulser.ni.dOut.trains.types{i},'pulses') || strcmp(pulser.ni.dOut.trains.types{i},'trains') ~= true,
%           disp('Digital Outs Can Only Be Pulses Or A Toggle [0 to 1]')      
%         end
%     end
% end

% s.addDigitalChannel('Dev1', 'Port0/Line0:1', 'OutputOnly')

%% Analog Input

% Not vectorized to allow for different devIDs.
if numel(pulser.ni.aOut.channels) > 0,
    for i=1:numel(pulser.ni.aOut.channels),
        pulser_daq_session.addAnalogInputChannel(pulser.ni.aOut.devIDs{i},pulser.ni.aOut.channels(i), 'Voltage');
    end
else
end

%% Start Doing Things
if pulser.opticalEncoder.encoderToggle
    for i=1:pulser.opticalEncoder.count
        session_configuration.opticalEncoder.data{i}=[];
        pulser.opticalEncoder.data{i}=pulser_opticalEncoder(20,pulser.opticalEncoder.serialPort,pulser.opticalEncoder.baudRates(i));
    end
else
end
pulser_daq_session.queueOutputData(pulser.ni.aOut.aOutWrite);
data = pulser_daq_session.startForeground();


%%  Arduino Optical Encoder Configuration

% Pre-allocate data containers for the encoders
% if session_configuration.opticalEncoder.encoderToggle
%     for i=1:session_configuration.opticalEncoder.count
%         session_configuration.opticalEncoder.data{i}=[];
%     end
% else
% end
