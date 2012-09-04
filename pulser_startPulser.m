function [outData]=pulser_startPulser()

%%%%These Should Be Arguments Passed From a Config File%%%%
AIDevice = 'Dev1';
AIChans = [0 1 4];
AODevice = 'Dev1';
AOChan = 0:1; %Must be 1 channel

sampleRate = 80000; %Hz
acqTime=10;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Shit that I will move elsewhere
%%%%% Temporary home for values needed to make output trains.
%%% Place the argument value you want for each analog output channel.
trainTypes=[1 2 1]; % 1 for pulses, 2 for ramp
trainAmplitudes=[5 7 6];
rampSpeeds=[0 3.5 0];
baselineTimes=[3 5 3];
numTrains=[1 1 1];
interTrainInterval=[1 1 1];
baselineValues=[0 0 0];
pulseWidths=[.010 0 .010];
numPulses=[10 0 10];
pulseInterval=[.025 0 .025];
%%%%%%%%%%%%%%%%%%%%%%

%% Pulser Function
%
% Creates analog output trains, and configures input/output.
import dabs.ni.daqmx.*

%%%%% Set up the tasks. 
pInputTask = Task('pulser in');
pOutputTask = Task('pulser out');

%%%%% Construct Output Data
% Each Column Will Be A Channel
aOutData=zeros(sampleRate*acqTime,numel(AOChan));

% Now construct pulse trains and ramps seperatley.
for i=1:numel(AOChan),
    if trainTypes(i)==1,
        aOutData(:,i)=pulser_pulses(trainAmplitudes(i),pulseWidths(i),numPulses(i),pulseInterval(i),baselineTimes(i),baselineValues(i),numTrains(i),interTrainInterval(i),sampleRate,acqTime);
    elseif trainTypes(i)==2,
        aOutData(:,i)=pulser_ramp(trainAmplitudes(i),rampSpeeds(i),baselineTimes(i),baselineValues(i),numTrains(i),interTrainInterval(i),sampleRate,acqTime);
    end
end

% pulser_ramp(amplitude,rampSpeed,baselineTime,baselineValue,numReps,interTrainInterval,sRate,acquisitionTime)
% pulser_pulses(amplitude,pulseWidth,numPulses,interPulseInterval,baselineTime,baselineValue,numReps,interTrainInterval,sRate,acquisitionTime)
outData=zeros(sampleRate*acqTime,1);

pInputTask.createAIVoltageChan(AIDevice,AIChans);
pOutputTask.createAOVoltageChan(AODevice,AOChan);

% Do I have to buffer both aIn and aOut?
pInputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps',acqTime*sampleRate);
pOutputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps',acqTime*sampleRate);
% pOutputTask.writeAnalogData(aOutData, 0.2,true);

tic
pOutputTask.writeAnalogData(aOutData, inf,true);,toc,
[outData,~]=pInputTask.readAnalogData(acqTime*sampleRate,'scaled',inf);,toc

pInputTask.clear();
pOutputTask.clear();