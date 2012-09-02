function out = pulser_opticalEncoder(trialLength,serialPort,baudRate)

% Pulser Optical Encoder 'Class'
% 
% Chris Deister 8/28/2012
%
% Streams dx and dy from an optical mouse sensor/arduino combo (the arduino prints to serial).
% Modified from RobotGrrl's Arduino2Serial example


numSec=trialLength;
t=[];
x=[];
y=[];

s1 = serial(serialPort);            % define your serial port (just get it from the arduino ide)
s1.BaudRate=baudRate;               % Baud rate of 38400 works well in testing, I haven't tried anything else
set(s1, 'terminator', 'LF');        % define the terminator for println
fopen(s1);

try                             % use try catch to ensure fclose
                                % signal the arduino to start collection
w=fscanf(s1,'%s');              % must define the input % d or %s, etc.
if (w=='A')
    %display(['Collecting data']);
    fprintf(s1,'%s\n','A');     % establishContact just wants 
                                % something in the buffer
end

i=0;
t0=tic;
while (toc(t0)<=numSec)
    i=i+1;
    t(i)=fscanf(s1,'%f')/1000.;
    x(i)=fscanf(s1,'%d');       % must define the input % d, %f, %s, etc.
    y(i)=fscanf(s1,'%d');       % must define the input % d, %f, %s, etc.
end
fclose(s1);

catch exception
    fclose(s1);                 % always, always want to close s1
    throw (exception);
end

mouseTrackData.t=t;
mouseTrackData.x=x;
mouseTrackData.y=y;

out = mouseTrackData;