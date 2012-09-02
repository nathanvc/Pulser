% Pulser Configuration
% Chris Deister 8/23/2012
% 
% Here you set the daq boards you have and what you want the channels to
% be. This is just a matter of convinence; you can set all this stuff in the
% GUI.

%% Ni Daqs

% Abandoned the DAQtoolbox. It's a great thing, but too limited. Nimex to the rescue?
pulserSession.ni.rate = 10000;

% Here we set the cards you want to use ('Dev1', 'Dev2', etc.). 
% In addition, you need to set how many analog inputs and outputs you want to use (not how many you could use) for each card. 
% Each block here needs a vector (syntax is  like cards=['Dev1' 'Dev2'] and count=[4 8]). 
pulserSession.ni.daqToggle=0;      % 0 means no daqs, 1 means use daqs

%% ----- Analog Out
%

pulserSession.ni.aOut.devIDs={'Dev1','Dev1','Dev1','Dev1'};  % I default to the cell array approach even for one card for maximum flexibility. 
pulserSession.ni.aOut.names={'Piezo','Blue Laser','Yellow Laser','output4'};
pulserSession.ni.aOut.channels={0 1 2 3};  % could be numeric arrays in the cells.
% This is the default scheme the @Task class wants the devIDs to be in.
% From Task Class:
%   deviceNames: String or string cell array specifying names of device on which channel(s) should be added, e.g. 'Dev1'. If a cell array, chanIDs must also be a cell array (of equal length).
%   chanIDs: A numeric array of channel IDs or, in the case of multiple deviceNames (a multi-device Task), a cell array of such numeric arrays
%   chanNames: (OPTIONAL) A string or string cell array specifying names to assign to each of the channels in chanIDs (if a single string, the chanID is appended for each channel) In the case of a multi-device Task, a cell array of such strings or string cell arrays. If omitted/empty, then default DAQmx channel name is used.

%% ----- Analog In
% 
pulserSession.ni.aIn.names={'Air','Land','Sea','input4'};
pulserSession.ni.aIn.devIDs={'Dev1','Dev1','Dev1','Dev1'}; 

%% ----- Digital Out
%
pulserSession.ni.digOut.Names={'Fiber Launch Shutter'};
pulserSession.ni.digOut.devIDs={'Dev1'};  

%   deviceNames: String or string cell array specifying names of device on which channel(s) should be added, e.g. 'Dev1'. If a cell array, chanIDs must also be a cell array (of equal length).
%   chanIDs: A string identifying port and/or line IDs for this Channel, e.g. 'port0','port0/line0:1', or 'line0:15'. In the case of multiple deviceNames (a multi-device Task), a cell array of such strings
%   chanNames: (OPTIONAL) A string or string cell array specifying names to assign to each of the channels in chanIDs (if a single string, the chanID is appended for each channel) In the case of a multi-device Task, a cell array of such strings or string cell arrays. If omitted/empty, then default DAQmx channel name is used.
%   lineGrouping: (OPTIONAL) One of {'DAQmx_Val_ChanPerLine', 'DAQmx_Val_ChanForAllLines'}. If empty/omitted, 'DAQmx_Val_ChanForAllLines' is used. Specifies whether to group digital lines into one or more virtual channels. If you specify one or more entire ports in chanIDs, you must set lineGrouping to DAQmx_Val_ChanForAllLines.

%% ----- Quadrature Encoding
%

% I haven't looked into nimex quadrature encoding, so I comment out for now.
% pulserSession.ni.counterCount=[0];
% pulserSession.ni.counterType=['position'];
% pulserSession.ni.CountertNames=['Rotary1']; 

%% ----- Optical Encoders  (optical mouse chips connected to arduinos; dx and dys are streamed over serial)
%

pulserSession.opticalEncoder.encoderToggle=1;
pulserSession.opticalEncoder.count=1;
pulserSession.opticalEncoder.baudRates=(38400);
pulserSession.opticalEncoder.serialPort=['/dev/tty.usbmodem1a161']  % You can get this from the arduino ide, if you have a tough time finding it.



