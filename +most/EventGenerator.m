classdef EventGenerator < handle
    %EVENTGENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    %% EVENTS    
    events
        dummyEvent; %Used to initialize persistent data store
    end
    
    %% CONSTRUCTOR/DESTRUCTOR
    methods
        
        function obj = EventGenerator()
            %Ensure persistent var gets initialized
            obj.notify('dummyEvent');
        end
    end
    
    %% PUBLIC METHODS
    
    methods
        function notify(obj,eventName,eventData)
            %Event notification method that appends supplied eventData var/struct to the event's data var, which is supplied to the event listener(s)
            
            persistent hEventData
            
            if isempty(hEventData)
                hEventData = most.EventData();
            end
            
            if nargin < 3
                hEventData.DEventData = [];
            else
                hEventData.DEventData = eventData;
            end
            
            notify@handle(obj,eventName,hEventData);
        end
    end
    
end

