function out = pulser_whale(amplitude,upTime,downTime,numPulses,interPulseFrequency,baselineTime,baselineValue,numReps,interTrainInterval,sRate,acquisitionTime)

% Pulser Whale (or Whale Train) 'Class'
% 
% Started by Chris Deister 11/24/2012 (kept Dom and Josh's up and down convention)
% 5 and 25ms have been the 'default' up and down.


% --- Create Train
dt=1/sRate;
interPulseInterval=1/interPulseFrequency;

% --- Make the kernel
up=linspace(pi, 2*pi, upTime*sRate);
down=linspace(0, pi, downTime*sRate);
whaleKern=((cos([up down])+1)/2)*amplitude;

% Preallocate (I figure this is useful, but is it?)
%totalSamplesInTrain=interPulseInterval*numPulses/dt;
%pulseTrain=zeros(totalSamplesInTrain,1);

if numPulses > 0
    for k=0:numPulses-1,
		% Make a vector of impulses
        pulseTrain(ceil(1 +(k*((interPulseInterval)/dt))):ceil((1 +(k*((interPulseInterval)/dt)))))=1
	end
end

% Then convolve with the whale kernel
pulseTrain=conv(whaleKern,pulseTrain);

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