function setPixelLocation(hObj,newLocation)
%SETLOCATION Set new location of HG objec in pixel units, without resizing it
%
%   hObj: A handle-graphics object with 'position' property
%   newLocation: 1x2 array specifying new [left bottom] values for 'position', in pixel units

validateattributes(newLocation,{'numeric'},{'size' [1 2]});
assert(ishandle(hObj),'Supplied hObj is not a valid HG handle');

setpixelposition(hObj,getpixelposition(hObj) .* [0 0 1 1] + [newLocation 0 0]);


end

