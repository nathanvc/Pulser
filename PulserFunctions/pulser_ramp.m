function out = pulser_ramp(amplitude,rampSpeed,baselineTime,baselineValue,numReps,interTrainInterval,sRate,acquisitionTime)

% Pulser Ramp 'Class'
% 
% Chris Deister 8/24/2012
%

% --- Make a ramp
dt=1/sRate;
rampTime= 0:dt:(amplitude-baselineValue)/rampSpeed;
rampValues = baselineValue:(amplitude-baselineValue)/(length(rampTime)-1):amplitude;


% --- Create Train
% Add a zero (or whatever baselineValue is) at the end of the ramp to ensure
% it always resets.
pulseTrain=[rampValues baselineValue]';

% Now we pad the pulse train with as many zeros to give us the right
% inter-train interval, then we replicate it n-times and shave off the last
% set of zeros.
if numReps > 1
    pulseTrain=padarray(pulseTrain,ceil(interTrainInterval/dt),baselineValue,'post');
    pulseTrain=repmat(pulseTrain,numReps,1); 
    pulseTrain=pulseTrain(1:length(pulseTrain)-interTrainInterval/dt);
else
end

% Lastly we need to add the baseline by padding ramp's begining and end with the baseline values for a length determined by the desired acquisition time.
pulseTrain=padarray(pulseTrain,ceil(baselineTime/dt),baselineValue,'pre');
pulseTrain=padarray(pulseTrain,ceil((acquisitionTime/dt)-length(pulseTrain)),baselineValue,'post');

out = pulseTrain;