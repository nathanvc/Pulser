classdef EventData < event.EventData
    %EVENTDATA  DEventGenerator event data class -- contains additional property with DEventData variable supplied by DEventGenerator event notifiers
    %
    % NOTES
    %   DEventData can be a structure, e.g. for cases where event notification includes 2 or more values to pass to listeners
    
    properties
        DEventData; %Event data specified using the DEventGenerator.notify() method
    end
    
    methods
        function obj = EventData(DEventData) 
            if nargin
                obj.DEventData = DEventData;
            end
        end        
    end
   
end

