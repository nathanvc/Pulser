function out = pulser_pulses(amplitude,pulseWidth,numPulses,interPulseFrequency,baselineTime,baselineValue,numReps,interTrainInterval,sRate,acquisitionTime)

% Pulser Pulse (or Pulse Train) 'Class'
% 
% Started by Chris Deister 8/24/2012
% 9/3/2004 - rounded all padarray calls that divide by dt, because sample rates that were multiples of 5 were causing errors.

% --- Create Train
dt=1/sRate;
interPulseInterval=1/interPulseFrequency;


% Preallocate (I figure this is useful, but is it?)
%totalSamplesInTrain=interPulseInterval*numPulses/dt;
%pulseTrain=zeros(totalSamplesInTrain,1);
	
if numPulses > 0
    for k=0:numPulses-1,
        pulseTrain(ceil(1 +(k*((interPulseInterval)/dt))):ceil((1 +(k*((interPulseInterval)/dt)))+(pulseWidth/dt)))=amplitude;
    end
end
% Now we pad the pulse train with as many zeros to give us the right
% inter-train interval, then we replicate it n-times and shave off the last
% set of zeros.
if numReps > 1
    pulseTrain=padarray(pulseTrain',ceil(interTrainInterval/dt),baselineValue,'post');
    pulseTrain=repmat(pulseTrain,numReps,1); 
    pulseTrain=pulseTrain(1:length(pulseTrain)-interTrainInterval/dt);
else
    pulseTrain=pulseTrain';  %TODO: This is stupid.
end

% Lastly we need to add the baseline by padding train's begining and end with the baseline values for a length determined by the desired acquisition time.
pulseTrain=padarray(pulseTrain,ceil(baselineTime/dt),baselineValue,'pre');
pulseTrain=padarray(pulseTrain,ceil((acquisitionTime/dt)-length(pulseTrain)),baselineValue,'post');

out = pulseTrain;