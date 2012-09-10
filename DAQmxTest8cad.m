function DAQmxTest8cad()

global callbackStruct8
import dabs.ni.daqmx.*
import Devices.NI.DAQmx.*

deviceName = 'Dev1';
sampRate = 30000;
acqTimes = 10;
loopPeriods = 2;
numSignals = 5;
numIterations = 10;
numSamples = round(acqTimes*sampRate);

%% Create AI tasks/channels
hAI = Task('Rig 1 AI');
hAI.createAIVoltageChan(deviceName,0:1);

%% Create DO tasks/channels
hDO = Task('Rig 1 DO');
hDO.createDOChan(deviceName,'line1'); 
hDO.createDOChan(deviceName,'line2');

%% Create AO tasks/channels
hAO = Task('Rig 1 AO');
hAO.createAOVoltageChan(deviceName,0:1);

%% Create shared CTR task/channel
hCtr = Task('Rig1 Clock');
hCtr.createCOPulseChanFreq(deviceName,0,[],sampRate); %Ctr0

%% Create digital trigger tasks/channesl
hTrigs = Task('Rig 1 Trig');
hTrigs.createDOChan(deviceName,'/port2/line1'); %PFI9 (/port1/line0 is PFI0) double check the pinouts just to be sure.

%% Configure timing
hSys = System.getHandle();


hAI.cfgSampClkTiming(sampRate, 'DAQmx_Val_FiniteSamps', numSamples); %,['Ctr' num2str(i-1) 'InternalOutput']);
hAO.cfgSampClkTiming(sampRate, 'DAQmx_Val_FiniteSamps', numSamples); %,['Ctr' num2str(i-1) 'InternalOutput']);
hDO.cfgSampClkTiming(sampRate, 'DAQmx_Val_FiniteSamps', numSamples,['Ctr0InternalOutput']); 
hCtr.cfgImplicitTiming('DAQmx_Val_ContSamps');
    
%Create a double-sized buffer for the output tasks (ping-pong buffer like)   
hAO.cfgOutputBuffer(2*numSamples);
hDO.cfgOutputBuffer(2*numSamples);    
%hAO(i).set('writeRegenMode','DAQmx_Val_AllowRegen'); %Doesn't matter if this is set or not...we're /not/ regenerating, as fresh data is always available
%hDO(i).set('writeRegenMode','DAQmx_Val_AllowRegen'); %Doesn't matter if this is set or not...we're /not/ regenerating, as fresh data is always available
hAO.set('writeRelativeTo','DAQmx_Val_FirstSample');
hDO.set('writeRelativeTo','DAQmx_Val_FirstSample');



%% Configure triggering
hAI.cfgDigEdgeStartTrig('PFI9');
hAO.cfgDigEdgeStartTrig('PFI9'); 
hCtr.cfgDigEdgeStartTrig('PFI9'); 


%% Prepare output data
doSignals = cell(numSignals,1);
aoSignals = cell(numSignals,1);
pulseDelays = linspace(0,0.4*acqTimes,numSignals);
pulseWidths = linspace(.1*acqTimes,.5*acqTimes,numSignals);

timebase = linspace(0,acqTimes,numSamples); %Use same signals for 
for k=1:numSignals
    [doSignals{k}, aoSignals{k}] = deal(zeros(numSamples,2)); %There are 2 AO and DO channels each
    
    %Cycle through pulseDelays on AO channels, use fixed pulseWidth
    startIdx = find(timebase>=pulseDelays(k),1);
    endIdx = find(timebase>=(pulseDelays(k) + pulseWidths(1)),1);
    
    aoSignals{k}(startIdx:endIdx,1) = 1;
    aoSignals{k}(startIdx:endIdx,2) = 2; %second channel has 2x the amplitude wrt first
    
    %Cycle through pulseWidths on DO channels; use fixed pulseDelay
    startIdx = find(timebase>=pulseDelays(1),1);
    endIdx = find(timebase>=(pulseDelays(1) + pulseWidths(k)),1);
    
    doSignals{k}(startIdx:endIdx,1) = 1;
    doSignals{k}(:,2) = ~doSignals{k}(:,1); %second channel is inverted wrt first
end

%% Create data figure(s)
hFig = figure;
hlines = plot(timebase*1000, zeros(length(timebase),1),'r',timebase*1000, zeros(length(timebase),1),'b');
legend('Chan0','Chan1');
xlabel('Time (ms)');
ylabel('Volts');

%% Initialize and start 'loop'
callbackStruct8.iterationCounter = 0;
callbackStruct8.numIterations = numIterations;
callbackStruct8.numSignals = numSignals;
callbackStruct8.numSamples = numSamples;
callbackStruct8.hAO = hAO;
callbackStruct8.hDO = hDO;
callbackStruct8.hAI = hAI;
callbackStruct8.hCtr = hCtr;
callbackStruct8.hTrigs = hTrigs;
callbackStruct8.aoSignals = aoSignals;
callbackStruct8.doSignals = doSignals;
callbackStruct8.hFig = hFig;
callbackStruct8.hlines = hlines;
callbackStruct8.timebase = timebase;
callbackStruct8.cycleComplete = false;

%%%Remove excess tasks (for now)%%%%
% delete(hAI(2:end)); hAI(2:end) = [];
% delete(hAO(2:end)); hAO(2:end) = [];
% delete(hDO(2:end)); hDO(2:end) = [];
% delete(hCtr(2:end)); hCtr(2:end) = [];
% delete(hTrigs(2:end)); hTrigs(2:end) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%Register callbacks to execute at end of each iteration (for each rig)
hAI.registerDoneEvent(@test8Callback);

%Write data for first iteration, and initialize write iteration counter
iterationCounter = 0;
writeData();

%Create timer objects, responsible for triggering each iteration
hTimer = timer('ExecutionMode','fixedRate','Period',loopPeriods,'TimerFcn',@(obj,evntdata)timerFcn(obj,evntdata),'StopFcn',@stopFcn,'TasksToExecute',numIterations);

%Start Tasks
hTrigs.start(); %starts trigger tasks..but they still await samples
hAI.start();
hAO.start();
%hDO.start();
hCtr.start();

%Start timer objects, which sends triggers
start(hTimer); %starts both the timers

    function timerFcn(obj,eventdata)
        %Output trigger signal used by all other Tasks
        disp(['Timer count: ' num2str(get(obj,'TasksExecuted'))]);
        hTrigs.writeDigitalData(uint8([0;1;0])); %TODO: Support 'double' type data for writeDigitalData() method, even though it's less efficient
        writeData(); %Write data for next iteration
    end


    function stopFcn(obj,eventdata)
        pause(loopPeriods(1));
        hAI.clear();
        hAO.clear();
        hDO.clear();
        hCtr.clear();
        hTrigs.clear();
        close(callbackStruct8.hFig);
    end

    function writeData()
        
        if isempty(iterationCounter)
            iterationCounter = 0;
        end

        %Determine which signal to draw from during this iteration
        signalIdx = mod(iterationCounter,numSignals)+1;    

        %Write data!
        hAO.writeAnalogData(aoSignals{signalIdx});
        hDO.writeDigitalData(logical(doSignals{signalIdx})); %TODO: Support use of double data here
        
        %Increment write-specific iteration counter
        iterationCounter = iterationCounter + 1;
    end

end
















