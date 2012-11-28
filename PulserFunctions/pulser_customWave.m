function out = pulser_customWave(originalRate,sRate,acquisitionTime,numReps,interTrainInterval,baselineValue,baselineTime,scaleFactor,baseFolder,fileBase,numID,normToggle,baselineSub)

% Pulser Custom Waveform 'Class'
% 
% Started by Chris Deister 11/24/2012 
%
% Put files into a folder called 'baseFolder'
% Files need to be named 'fileBase_numID.txt'
% I kept the numID convention Josh used for their natural stim, because that seemed reasonable.  I don't love it because it doesn't generalize.
% normToggle is a boolean that tells the function you WANT it to internally SCALE your custom trace to its PEAK value before applying the scaleFactor.
% baselineSub is a boolean that tells the function to subtract the mean from the waveform before applying scaleFactor

dt=1/sRate;

fileName=[baseFolder filesep fileBase int2str(numID) '.txt'];
waveform = load(fileName)

custWave=resample(waveform,sRate,originalRate);

if baselineSub,
	custWave=custWave-mean(waveform);
else
end

if normToggle,
	custWave=(custWave/max(waveform))*scaleFactor;
else
	custWave=custWave*scaleFactor;
end

% Now we pad the pulse train with as many zeros to give us the right
% inter-train interval, then we replicate it n-times and shave off the last
% set of zeros.
if numReps > 1
    custWave=padarray(custWave',ceil(interTrainInterval/dt),baselineValue,'post');
    custWave=repmat(custWave,numReps,1); 
    custWave=custWave(1:length(custWave)-interTrainInterval/dt);
else
    custWave=custWave';  %TODO: This is stupid.
end

% Lastly we need to add the baseline by padding train's begining and end with the baseline values for a length determined by the desired acquisition time.
custWave=padarray(custWave,ceil(baselineTime/dt),baselineValue,'pre');
custWave=padarray(custWave,ceil((acquisitionTime/dt)-length(custWave)),baselineValue,'post');

out = custWave;
	
	
	
