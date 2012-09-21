function session=pulser_sessionConstructor(session_configuration)
%
% Start a Pulser session.
% Takes a pre-loaded configuration as an argument (I use pulser.).
% Returns a nidaq session (named whatever you like, I suggest pulser.daqSession).
%
% CAD 9/16/2012


%%  Daq Configure  (Configure DAQ 'tasks' for aOut, aIN etc.)

% Only run if the the daqToggle bit is flipped. The user does this explicitly in the configuration, but it could be flipped by certain GUI states.
%

if session_configuration.ni.daqToggle
    session = daq.createSession('ni');
    session.Rate = session_configuration.ni.rate;

% You might want multiple analog input and output cards so we have to loop
% the adds to span through all the cards in the configuration file. 
    if numel(session_configuration.ni.aOut.channels) > 0
        for i=1:numel(session_configuration.ni.aOut.devIDs)
            session.addAnalogOutputChannel(session_configuration.ni.aOut.devIDs{i}, session_configuration.ni.aOut.channels(i), 'Voltage');
        end
    end
    
    if numel(session_configuration.ni.aIn.channels) > 0
        for i=1:numel(session_configuration.ni.aIn.devIDs);
            session.addAnalogInputChannel(session_configuration.ni.aIn.devIDs{i}, session_configuration.ni.aIn.channels(i), 'Voltage');
        end
    end

    if numel(session_configuration.ni.counter.channels) > 0
        for i=1:numel(session_configuration.ni.counter.channels);
            session.addCounterInputChannel(session_configuration.ni.counter.devIDs{i},session_configuration.ni.counter.channels(i), session_configuration.ni.counter.type{i});
        end
    end

else
end

%%  Arduino Optical Encoder Configuration

% Pre-allocate data containers for the encoders
if session_configuration.opticalEncoder.encoderToggle
    for i=1:session_configuration.opticalEncoder.count
        session_configuration.opticalEncoder.data{i}=[];
    end
else
end

%%
