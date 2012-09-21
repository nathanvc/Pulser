Pulser
======

Pulser is a pulse generator designed to replace trigger-sync in the 2p.  
It runs in 32 or 64-bit Matlab, can use any daqmx compatible NiDAQ board, and does not use the Matlab daqtoolbox.
Because it does not use the daqtool box, digital i/o (buffered and unbuffered) works just fine no matter what platform you use.

The daq engine is the daqmx C driver via the matlab nimex library developed and maintained by the Svoboda lab at Janelia Farm.  The nimex library is compiled against version 9.3 of daqmx, which is therefore required to use Pulser. 

The nimex library is part of the internal distribution of Pulser. Please do not distribute the nimex library outside of the lab.

Questions: cdeister at brown dot edu

Use:
Load a configuration and pass it to the pulser_startPulser function and run.

Soon:
Auto-save, GUI (I am not experienced with MATLAB GUI programming, so this will take a while)