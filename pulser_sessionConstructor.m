% Start a 'Pulser' session.
%
% CAD 8/28/2012


%%  Daq Configure  (nidaqs can do analog out, analog in, and often counters. Matlab session does not allow digital outs.)

if pulserSession.ni.daqToggle
	import dabs.ni.daqmx.*

% You might want multiple analog input and output cards so we have to loop
% the adds to span through all the cards in the configuration file. 
    if numel(pulserSession.AOutCount > 0)
        for i=1,numel(pulserSession.ni.AOutCount)
            pulser_daq_session.addAnalogOutputChannel(pulserSession.ni.cards(i), 0:pulserSession.ni.AOutCount(i)-1, 'Voltage');
        end
    end
    
    if numel(pulserSession.ni.AInCount > 0)
        for i=1,numel(pulserSession.ni.AInCount)
            pulser_daq_session.addAnalogInputChannel(pulserSession.ni.cards(i), 0:pulserSession.ni.AInCount(i)-1, 'Voltage');
        end
    end
    
    if numel(pulserSession.ni.counterCount > 0)
        for i=1,numel(pulserSession.ni.counterCount)
            pulser_daq_session.addCounterInputChannel(pulserSession.ni.cards(i), 0:pulserSession.ni.counterCount(i)-1, pulserSession.ni.counterType(i));
        end
    end

else
end

%%  Arduino Optical Encoder Configuration

% Pre-allocate data containers for the encoders
if pulserSession.opticalEncoder.encoderToggle
    for i=1:pulserSession.opticalEncoder.count
        pulserSession.opticalEncoder.data{i}=[];
    end
else
end

%%
