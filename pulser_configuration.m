% Pulser Configuration
% Chris Deister 8/23/2012
% 
% Here you set the daq boards you have and what you want the channels to
% be. This is just a matter of convinence; you can set all this stuff in the
% GUI.

%% Ni Daqs
% Keep in mind that with the session-based DAQ toolbox, you can have only
% one input/output rate ? every card has to obey (or be capable of this).
pulserSession.rate = 10000;

% Here we set the cards you want to use ('Dev1', 'Dev2', etc.). 
% In addition, you need to set how many analog inputs and outputs you want to use (not how many you could use) for each card. 
% Each block here needs a vector (syntax is  like cards=['Dev1' 'Dev2'] and count=[4 8]). 
pulserSession.ni.daqToggle=0;      % 0 means no daqs, 1 means use daqs
pulserSession.ni.cards=['Dev1'];
pulserSession.ni.AOutCount = [4];
pulserSession.ni.AInCount=[8];
pulserSession.ni.counterCount=[1];
pulserSession.ni.counterType=['position']

%% Optical Encoders

% Configure optical encoders if you want.
pulserSession.opticalEncoder.encoderToggle=1;
pulserSession.opticalEncoder.count=1;
pulserSession.opticalEncoder.baudRates=(38400);
pulserSession.opticalEncoder.serialPort=['/dev/tty.usbmodem1a161']



