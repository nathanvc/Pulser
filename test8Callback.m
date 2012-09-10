function test8Callback()
%   Function called at end of each iteration

global callbackStruct8


%Increment iteration counter
callbackStruct8.iterationCounter = callbackStruct8.iterationCounter + 1; %Incremented count reflects the iteration that's about to run

%Prepare the data for the next iteration, and start the tasks
if callbackStruct8.iterationCounter <= callbackStruct8.numIterations
    
    %Read & plot AI data
    [numSamps,inputData] = callbackStruct8.hAI.readAnalogData(callbackStruct8.numSamples, callbackStruct8.numSamples, 'scaled',1);
    
    set(callbackStruct8.hlines(1),'YData',inputData(:,1));
    set(callbackStruct8.hlines(2),'YData',inputData(:,2));
    drawnow expose;    
    
    %Stop the tasks -- this is needed so they can be restarted
    callbackStruct8.hCtr.stop()
    callbackStruct8.hAI.stop();
    callbackStruct8.hAO.stop();
    callbackStruct8.hDO.stop()
    pause(.5);
end

%Prepare the data for the next iteration, and start the tasks
if callbackStruct8.iterationCounter < callbackStruct8.numIterations       
    
    %Start the tasks so they can await trigger. Note these methods are vectorized.
    callbackStruct8.hAI.start();
    callbackStruct8.hAO.start();
    callbackStruct8.hDO.start();
    callbackStruct8.hCtr.start();
end

end



