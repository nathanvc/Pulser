function varargout = reportError(ME)
%REPORTERROR Display, or return, report of error to command-line in error color (i.e. red), without throwing error
%% SYNTAX
%   function reportError(ME)
%   function errString = reportError(ME)%
%       errString: 'Safe' error report string, suited for use in fprintf statements by caller
%
%% NOTES
%   Generally suited as a safe-in-all-cases display of the string generated by the MException getReport() method
%   Particularly suited for:
%       Use in callback functions which cannot generate true exceptions
%       Error messages/reports that contan filenames/paths which can confuse frintf
%

errString = ME.getReport('extended','hyperlinks','off');
errString = strrep(errString,'\','\\'); %Don't recognize any escape characters
errString = strrep(errString,'%','%%'); %Don't recognize any formatting characters

if nargout
    varargout = {errString};
else
    fprintf(2,errString);
    fprintf(1,'\n');
end

end

