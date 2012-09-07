function [outData]=pulser_startPulser()

%%%%These Should Be Arguments Passed From a Config File%%%%
AIDevice = 'Dev2';
AIChans = [0 1 3 4];
AODevice = 'Dev2';
AOChan = 0:1; 
DODevice='Dev2';
DOChans='line2';

% writeDigitalData(task, writeData, timeout, autoStart, numSampsPerChan)

sampleRate = 50000; %Hz
acqTime=10;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Shit that I will move elsewhere
%%%%% Temporary home for values needed to make output trains.
%%% Place the argument value you want for each analog output channel.
trainTypes=[1 2]; % 1 for pulses, 2 for ramp
trainAmplitudes=[5 7];
rampSpeeds=[0 3.5];
baselineTimes=[3 5];
numTrains=[1 1];
interTrainInterval=[1 1];
baselineValues=[0 0];
pulseWidths=[.010 0];
numPulses=[10 0];
pulseInterval=[.025 0];
%%%%%%%%%%%%%%%%%%%%%%

%% Pulser Function
%
%% Creates analog output trains, and configures input/output.
import dabs.ni.daqmx.*

%%%%% Set up the tasks. 
pInputTask = Task('pulser in');
pOutputTask = Task('pulser out');
pDigOutputTask = Task('pulser digout');


%%%%% Construct Output Data
% Each Column Will Be A Channel
aOutData=zeros(sampleRate*acqTime,numel(AOChan));

% Now construct pulse trains and ramps seperatley.
for i=1:numel(AOChan),
    if trainTypes(i)==1,
        aOutData(:,i)=pulser_pulses(trainAmplitudes(i),pulseWidths(i),numPulses(i),pulseInterval(i),baselineTimes(i),baselineValues(i),numTrains(i),interTrainInterval(i),sampleRate,acqTime);
        dOutData(:,i)=pulser_pulses(1,pulseWidths(i),numPulses(i),pulseInterval(i),baselineTimes(i),baselineValues(i),numTrains(i),interTrainInterval(i),sampleRate,acqTime);
    elseif trainTypes(i)==2,
        aOutData(:,i)=pulser_ramp(trainAmplitudes(i),rampSpeeds(i),baselineTimes(i),baselineValues(i),numTrains(i),interTrainInterval(i),sampleRate,acqTime);
    end
end


outData=zeros(sampleRate*acqTime,1);

%Counter
pCntrTask=Task('Counter Task');
pCntrTask.createCOPulseChanFreq(DODevice,0,'',sampleRate); 
pCntrTask.cfgImplicitTiming('DAQmx_Val_ContSamps',acqTime*sampleRate);
pCntrTask.start();

pInputTask.createAIVoltageChan(AIDevice,AIChans);
pOutputTask.createAOVoltageChan(AODevice,AOChan);
pDigOutputTask.createDOChan(DODevice,DOChans);

pInputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps');
pOutputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps');
%pDigOutputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps');


% pInputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps',acqTime*sampleRate,'Ctr0InternalOutput');
% pOutputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps',acqTime*sampleRate,'Ctr0InternalOutput');
% %pDigOutputTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps',acqTime*sampleRate,'Ctr0InternalOutput');

% pInputTask.cfgAnlgEdgeStartTrig('PFI0',3,'DAQmx_Val_Rising');
% pOutputTask.cfgAnlgEdgeStartTrig('PFI0',3, 'DAQmx_Val_Rising');
% pDigOutputTask.cfgAnlgEdgeStartTrig('PFI0',3, 'DAQmx_Val_Rising');

%% ----- Optical Encoders  (optical mouse chips connected to arduinos; dx and dys are streamed over serial)
%

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

%% GO 

%(Either the output is a couple of ms early because of matlab execution delays (but they both finish at the same time) or the cpu timing is crudy, using a self trigger would be a good test.

tic
pOutputTask.writeAnalogData(aOutData,inf,true);
pDigOutputTask.writeDigitalData(dOutData,inf,true);
[outData,~]=pInputTask.readAnalogData(acqTime*sampleRate,'scaled',inf);


pInputTask.clear();
pOutputTask.clear();
pDigOutputTask.clear();
pCntrTask.clear();
