function [session pulseTrains]=pulser_outputGenerator(session_configuration)
%
% Pulser's Output Generator
%
% Takes pre-configured pulse train paramaters, defined by the GUI or a configuration file (argument for the function).
% Returns a set of pulse trains that can be queue'd as the Pulser session's output.
%
% Chris Deister 9/16/2012