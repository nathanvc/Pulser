% Pulser Configuration
% Chris Deister 8/23/2012
% 
% Here you set the daq boards you have and what you want the channels to
% be. This is just a matter of convinence; you can set all this stuff in the
% GUI.

%% Ni Daqs

% Abandoned the toolbox. It's a great thing, but too limited. Nimex to the rescue?
pulserSession.ni.rate = 10000;

% Here we set the cards you want to use ('Dev1', 'Dev2', etc.). 
% In addition, you need to set how many analog inputs and outputs you want to use (not how many you could use) for each card. 
% Each block here needs a vector (syntax is  like cards=['Dev1' 'Dev2'] and count=[4 8]). 
pulserSession.ni.daqToggle=0;      % 0 means no daqs, 1 means use daqs

pulserSession.ni.AOut.names=['Piezo','Blue Laser','Yellow Laser','output4'];
pulserSession.ni.AOut.devIDs=['Dev1','Dev1','Dev1','Dev1'];  % I've thought about different/better ways to do this, but the user has to make choices at some point, might as well be at the earliest point.
 
% Name of connected object(s) (for your own sake)
pulserSession.ni.AIn.names=['Air','Land','Sea','input4'];
pulserSession.ni.AOut.devIDs=['Dev1','Dev1','Dev1','Dev1']; 
pulserSession.ni.DigOut.Names=['Fiber Launch Shutter'];
pulserSession.ni.DigOut.devIDs=['Dev1'];  

% I haven't looked into nimex quadrature encoding, so I comment out for now.
% pulserSession.ni.counterCount=[0];
% pulserSession.ni.counterType=['position'];
% pulserSession.ni.CountertNames=['Rotary1']; 

%% Optical Encoders  (optical mouse chips connected to arduinos; dx and dys are streamed over serial)

% Configure arduino-based optical encoders if you want.
pulserSession.opticalEncoder.encoderToggle=1;
pulserSession.opticalEncoder.count=1;
pulserSession.opticalEncoder.baudRates=(38400);
pulserSession.opticalEncoder.serialPort=['/dev/tty.usbmodem1a161']  % You can get this from the arduino ide, if you have a tough time finding it.



