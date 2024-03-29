classdef VClassic < hgsetget
    %VCLASSIC  Original version of a 'standard' most class (provisional name for most library was Vivo)
     %
    %% NOTES
    %   ALL code still using this should aim to eventually use most.DClass instead, as well as other classes, e.g. PDepProp, which separate functionality out into discrete classes
    %   This class will soon be DEPRECATED
    %
    %   The 'pseudo-dependent' property feature is intended to address following issues:
    %       * Allows abstract superclass to define and document concrete properties, while subclasses simply implement pseudo property-access methods. Avoids copy&paste of properties to preserve documentation strings. %TMW: Abstract property documentation inheritance would reduce some need for this. (WF: Similar restriction in JavaDoc)
    %       * Allows for inheritance/overriding of property-access methods, e.g. subclasses can override property access for each individual property and can likewise defer to superclass logic  %TMW: Current property-access methods do not support inheritance
    %       * Allows for a single switch-yard get/set methods to be defined at each subclass, which can decide between individuated, grouped, or default (this or superclass) handling of each property     %TMW: Some mechanism for get.(tag) or set.(tag) property-access methods might obviate this need
    %       * Allows supeurclass to (additionally) define property-specific set-access methods which can do error/type-checking without pushing that into subclass logic
    %       * Subclasses can make Hidden properties that are defined in a higher-level subclass, but this requires property be Abstract in the higher-level. %TMW: Would be nice to have ability to make subclass properties Hidden, without being an Abstract property (or, otherwise, preserving documentation)
    %   Many of these features are particularly valueable for situations where class properties are connected to a hardware device's properties
    %   There are some weaknesses of 'pseudo-dependent' properties:
    %       * Error conditions generated during set/get occur in callbacks (property access listeners) and do not generate an exception interrupting program flow (just a warning)
    %       * (Related) The variable still has a value even when in an error condition, so it becomes decoupled from device
    %    
    %   TODO: Cache the 'classNameShort' property on object construction, rather than computing every time property is needed
    %   TODO: Consider subclassing MException, to make VException -- instead of packing utility functions here. But how to make this available to all VClass instances?
    %
    %% ************************************************************************    
       
    properties (SetAccess=private, Dependent)
       errorCondition; %Logical value indicating if class is in an error condition. Messages for all errors causing this condition can be queried using errorConditionMessages. 
       errorConditionMessages; %Cell array of error messages that have been stored to this class via errorConditionSet()
       errorConditionIdentifiers; %Cell array of error identifiers that have been been stored to this class via errorConditionSet()       
    end
    
    properties (SetAccess=protected,Hidden)
        %errorConditionMessages={}; %Cell array of error messages that have been generated by this class, in sequential order. When empty, the class is considered not in an error condition. Class users can reset this property using errorConditionClear()
        errorConditionArray; %Array of MException objects that have been stored to this class via errorConditionSet()
    end      
    
    properties (Hidden)
        errorConditionVerbose=false; %Logical value indicating, if true, to display information to command line every time errorConditionSet() adds new message
    end
    
    properties (Hidden)
        %%%%%%%Support for 'pseudo-dependent' properties        
       
        %Locks are used so that get/set listener methods do not invoke their counterpart listener method in process of surreptitiously getting/setting method
        pdepPropGlobalLock=false; 
        pdepPropLockMap;
        
        %Following properties should be added to subclasses, sans 'Raw', to override these defaults
        pdepPropGetListRaw = {}; %Itemized list of properties which will use psuedo-dependent get access. If empty, /all/ GetObservable properties will be presumed. 
        pdepPropSetListRaw = {}; %Itemized list of properties which will use psuedo-dependent set access. If empty, /all/ SetObservable properties will be presumed. 
    end    
    
    properties (Dependent,Access=protected)
        classNameShort; %Short version of object's class name, i.e. class name with all package information stripped.
        
        classPath; %Path of this object's class definition
        classPrivatePath; %Path of private folder associated with this object's class definition        
    end
    
    properties (Hidden,Access=protected)
        
        customDisplayPropertyList = {};
        restoreCachedPropertyValue;
        
    end
    
    %TODO: Reconsider use of Abstract Constant for this...should probably factor out pseudo-dependent properties into their own mixin, and this would be
    properties(GetAccess=protected,Abstract,Constant)
       setErrorStrategy; %One of {'setEmpty','restoreCached','setErrorHookFcn'}. setEmpty: stored property value becomes empty when driver set error occurs. restoreCached: restore value from prior to the set action generating error. setErrorHookFcn: The subclass implements its own setErrorHookFcn() to handle set errors in subclass-specific manner.  
    end
      
    %% EVENTS
    events (NotifyAccess=protected)
        errorCondSet;
        errorCondReset;
    end
    
    %% CONSTRUCTOR/DESTRUCTOR
    methods
        function obj = VClassic()
            
            %TMW: This silly two-step construction (req'd to set value type to logical) is avoided with new containers.Map constructor in R2010a
            obj.pdepPropLockMap = containers.Map({'dummy'},{false});
            obj.pdepPropLockMap.remove('dummy');
            
            obj.pdepPropInitialize(); %Initialize pseudo-dependent properties
        end
    end
    
     %% PROPERTY ACCESS METHODS
    
    methods
        function classNameShort = get.classNameShort(obj)            
            classNameShort = getClassNameShort(class(obj));
        end               
        
        function classPath = get.classPath(obj)
            classPath = fileparts(which(class(obj)));
        end
        
        function classPath = get.classPrivatePath(obj)
            classPath = fullfile(obj.classPath,'private');        
        end
        
        function set.errorConditionVerbose(obj,val)
            assert(islogical(val),'Value of ''errorConditionVerbose'' must be a logical (true, false, 0, 1)');
        end
        
        function tf = get.errorCondition(obj)
            tf = ~isempty(obj.errorConditionArray);            
        end
        
        function val = get.errorConditionMessages(obj)
            errorCondArray = obj.errorConditionArray;
            if isempty(errorCondArray) 
                val = {};
            else
                val = {errorCondArray.message};
            end
        end
        
        function val = get.errorConditionIdentifiers(obj)
            errorCondArray = obj.errorConditionArray;
            if isempty(errorCondArray)
                val = {};
            else
                val = {errorCondArray.identifier};
            end
        end

    end
    
    %% PUBLIC METHODS
    methods
        function errorConditionReset(obj)
            %Clears (all) error conditions on object            
            obj.errorConditionArray(:) = [];
            notify(obj,'errorCondReset');
        end
        
        function errorConditionSet(obj,ME)
            assert(isa(ME,'MException'),'Supplied value must be of class MException');
            if ~isempty(ME)
                if obj.errorConditionVerbose
                    fprintf(2,'Error condition for object of class %s has been set: \n\t%s\n',class(obj),ME.message);
                end
                  
                if isempty(obj.errorConditionArray)
                    obj.errorConditionArray = ME; %Actually set the value
                    notify(obj,'errorCondSet');
                else
                    obj.errorConditionArray(end+1) = ME; %Appends the MException object, but does not signal new errorCondition for class
                end                      
            end
        end        
        
    end
        
    
    %% ABSTRACT METHODS (including SEMI-ABSTRACT)
    methods (Hidden, Access=protected)
        
        %Subclasses with pseudo-dependent properties should implement these as switch-yard to dispatch to appropriate get/set methods implemented by that subclass
        function pdepPropHandleGet(obj,src,evnt)
        end
        
        function pdepPropHandleSet(obj,src,evnt)
        end
        
        %A typical pdepPropHandleGet/Set method appears as:
        %
        %     function pdepPropHandleGet(obj,src,evnt)
        %             propName = src.Name;
        %
        %             switch propName
        %                 case {<List of Props with Individidual get<propName> methods}
        %                     obj.pdepPropIndividualGet(src,evnt);
        %                 case {<List of Props with particular grouped get method>}
        %                     obj.pdepPropGroupedGet(<groupGetMethod1>,src,evnt);
        %                 case {<List of Props with particular grouped get method>}
        %                     obj.pdepPropGroupedGet(<groupGetMethod2>,src,evnt);
        %                 .... etc
        %                 case {<List of Props to treat as ordinary pass-through property, with storage>}
        %                     %Do nothing --> pass-through
        %                 case {<List of Props to defer to superclass for handling>}
        %                     obj.pdepPropHandleGet@<superclassName>(src,evnt)
        %                 otherwise %Designate the Get/Set operation as disallowed (displays error message, but does not set error condition)
        %                     obj.pdepPropGetDisallow(src,evnt)
        %             end
        %       end
        %
        % Depending on the mix of properties and their categorizations, the category assigned to 'otherwise' can be selected,
        %   i.e. 'otherwise' can be used for the largest grouping of properties, reserving others for 'special cases'
        % 
    end
    
    %% PROTECTED/PRIVATE METHODS
    methods (Access=private)                  
        
        %Support for 'pseudo-dependent' properties
        function pdepPropInitialize(obj)           
            %Initialization function for 'pseudo-dependent' properties
            
            mc = metaclass(obj);
            props = mc.Properties;
            
            overridableProps = {'pdepPropGetList' 'pdepSetList' 'pdepPropDefaultError'};
            overrideProps =  props(cellfun(@(x)ismember(x.Name,overridableProps),props));
            
            for i=1:length(overrideProps)
                obj.([overrideProps{i}.Name 'Raw']) = obj.(overrideProps{i}.Name);
            end            
            
            getListenProps = obj.pdepPropGetListRaw;
            if isempty(getListenProps)
                getListenProps = props(cellfun(@(x)x.GetObservable,props));
            end
                
            setListenProps = obj.pdepPropSetListRaw;
            if isempty(setListenProps)
                setListenProps = props(cellfun(@(x)x.SetObservable,props));
            end            
            
            for i=1:length(getListenProps)
                obj.addlistener(getListenProps{i},'PreGet',@obj.pdepPropHandleGetHidden);
            end
            
            for i=1:length(setListenProps)
                obj.addlistener(setListenProps{i},'PostSet',@obj.pdepPropHandleSetHidden);
                obj.addlistener(setListenProps{i},'PreSet',@obj.pdepPropHandlePreSetHidden);
            end                       
        end      
        
         function pdepPropHandleGetHidden(obj,src,evnt)
            %True listener for 'pre-get' property event

            propName = src.Name;
                        
            if ~obj.pdepPropGlobalLock && (~obj.pdepPropLockMap.isKey(propName) || ~obj.pdepPropLockMap(propName))
                try
                    obj.pdepPropLockMap(propName) = true;
                    obj.pdepPropHandleGet(src,evnt);
                    obj.pdepPropLockMap(propName) = false;
                catch ME
                    obj.(propName) = [];
                    obj.pdepPropLockMap(propName) = false;
                    fprintf(2,'WARNING(%s): Unable to access property ''%s'' because of following error:\n\t%s\n',class(obj),propName,ME.message);
                    %ME.rethrow(); %Don't throw error, since this is a callback
                end
            end                       
         end        
        
        function pdepPropHandlePreSetHidden(obj,src,evnt)
            % Caches the existing value before continuing with set operation
            
            % we want to cache the stored value (not actually 'get' the device value), so use the lock
            if obj.pdepPropLockMap.isKey(src.Name)
                existingPropLock = obj.pdepPropLockMap(src.Name);
            else
                existingPropLock = false;
            end
            
            obj.pdepPropLockMap(src.Name) = true;
            
            obj.restoreCachedPropertyValue = obj.(src.Name);
                
            % restore the original lock values
             obj.pdepPropLockMap(src.Name) = existingPropLock;
        end
         
        function pdepPropHandleSetHidden(obj,src,evnt)
            %True listener for 'post-set' property event
           
            propName = src.Name;
            
            if ~obj.pdepPropGlobalLock && (~obj.pdepPropLockMap.isKey(propName) || ~obj.pdepPropLockMap(propName))
                try
                    obj.pdepPropLockMap(propName) = true;
                    obj.pdepPropHandleSet(src,evnt);
                    obj.pdepPropLockMap(propName) = false;
                catch ME
                    if strcmpi(obj.setErrorStrategy,'setErrorHookFcn')
                        %TODO: implement this case
                    else                        
                        switch obj.setErrorStrategy
                            case 'leaveErrorValue'
                                %do nothing
                            case 'setEmpty'
                                obj.(propName) = [];
                            case 'restoreCached'
                                obj.restoreCachedValue(propName);
                        end
                        obj.printErrorMessage(src,ME);
                    end
                    obj.pdepPropLockMap(propName) = false;
                end
                
                % clear the cached value
                if strcmp(obj.setErrorStrategy,'restoreCached')
                    obj.restoreCachedPropertyValue = [];
                end
            end                       
        end  
    
    end
    
    methods (Access=protected)
        
        function pdepPropGetDisallow(obj,src,evnt)                 
            propName = src.Name;
            
            fprintf(2,'Specified property (%s) does not exist or cannot be accessed for objects of class %s\n',propName,class(obj));
            obj.(propName) = []; %Non-implemented property will be returned as empty
        end
        
        function pdepPropSetDisallow(obj,src,evnt)      
            propName = src.Name;
            
            fprintf(2,'Specified property (%s) does not exist or cannot be set for objects of class %s\n',propName,class(obj));           
            obj.restoreCachedValue(propName); %Restore previous value
        end
        
        function pdepPropGetUnavailable(obj, src, evnt) %#ok<INUSD>
            propName = src.Name;
            obj.(propName) = 'N/A'; 
        end
        
        function pdepPropIndividualGet(obj,src,evnt)
            propName = src.Name;            
            obj.(propName) = feval(['get' upper(propName(1)) propName(2:end)],obj);                       
        end
        
        function pdepPropIndividualSet(obj,src,evnt)  
            propName = src.Name;           
            feval(['set' upper(propName(1)) propName(2:end)],obj,obj.(propName));
        end
        
        function pdepPropGroupedGet(obj,methodHandle,src,evnt)
            %Subclasses with pseudo-dependent properties can/should use this in their pdepPropHandleGet() method, for dispatching several properties to identified grouped property get handler
            propName = src.Name;
            obj.(propName) = feval(methodHandle,propName);
        end
        
        function pdepPropGroupedSet(obj,methodHandle,src,evnt)
            %Subclasses with pseudo-dependent properties can/should use this in their pdepPropHandleSet() method, for dispatching several properties to identified grouped property set handler
            propName = src.Name;           
            feval(methodHandle,propName,obj.(propName));
        end
        
        function pdepSetAssert(obj,inVal,assertLogical,errorMessage,varargin)
            %Subclasses with pseudo-dependent properties with set-property-access methods used for error/type-checking should use this method in lieu of 'assert'        
            if ~assertLogical && ~(obj.errorCondition && isempty(inVal)) %Allows empty value to be set during error conditions, as done by this class, regardless of assertLogical condition requirements                outVal = inVal;            
                throwAsCaller(obj.VException('','PropSetAccessError',errorMessage,varargin{:}));
            end
        end
        
        function printErrorMessage(obj, src, ME)
           fprintf(2,'WARNING(%s): Unable to set property ''%s'' because of following error:\n\t%s\n',class(obj),src.Name,ME.message);
           %ME.rethrow(); %Don't bother throwing error, since this is a callback 
        end

        
        function restoreCachedValue(obj,propName)
            % restore the property to its cached value
            obj.pdepPropLockMap(propName) = true;
            obj.(propName) = obj.restoreCachedPropertyValue;
            obj.pdepPropLockMap(propName) = false;
        end
        
        function VClassDisplay(obj)
            mClass = metaclass(obj);
            
            % Show the top-level superclass:            
            parent = mClass.SuperClasses;
            while ~isempty(parent{1}.SuperClasses)
                parent = parent{1}.SuperClasses;
            end
            disp(['<a href = "matlab:help ' mClass.Name '">' mClass.Name '</a>, ' ...
                  '<a href = "matlab:help ' parent{1}.Name '">' parent{1}.Name '</a>']);
            
            %show this containing package for this class:
            disp(['Package: ' mClass.ContainingPackage.Name char(10)]);
            
            %show all of the properties enumerated in 'customDisplayPropertyList'
            for propName=obj.customDisplayPropertyList
                value = obj.(propName{1});
                
                left = sprintf('%35s%2s',propName{1},': '); 
                right = '';
                if isa(value,'cell')
                    right = '{ ';
                    
                    % test if we have nested cell array
                    isNested = sum(cellfun('isclass', value, 'cell'));
                    if isNested
                        for cell=[value]
                            dim = size(cell{1});
                            right = [right '{' num2str(dim(1)) 'x' num2str(dim(2)) ' cell} '];
                        end
                    elseif iscellstr(value)
                        dims = size(value);
                        if dims(2) == 1
                            for i=1:dims(1)
                                right = [right '''' value{i} ''''];
                                if i ~= dims(1)
                                    right = [right '; '];
                                end
                            end
                        else
                            for cell=[value]
                                right = [right '''' cell{:} ''' '];
                            end
                        end
                    else
                        dims = size(value);
                        if dims(2) == 1
                            for i=1:dims(1)
                                right = [right '[' obj.formatVal(value{i})  ']'];
                                if i ~= dims(1)
                                    right = [right '; '];
                                end
                            end
                        else
                            for cell=[value{:}]
                                right = [right '['];
                                right = [right obj.formatVal(cell)];
                                right = [deblank(right) '] '];
                            end
                        end
                    end
                    
                    right = [deblank(right) ' }'];
                elseif ~isscalar(value) && ~isa(value,'char')                    
                    dims = size(value);
                    if ndims(value) > 2 || max(dims) > 4
                        right = [right '['];
                        for i=1:ndims(value)
                            right = [right num2str(dims(i))];
                            if i ~= ndims(value)
                                right = [right 'x'];
                            end
                        end
                        right = [right ' ' class(value) ']'];
                    elseif islogical(value) % boolean values
                        right = mat2str(value);
                    else
                       %right = mat2str(value,3); %This (DOES NOT) formats all 1D and 2D numeric arrays nicely!
                        dims = size(value);
                        
                        if dims(1)*dims(2) > 16 % don't print more than 16 elements
                            right = [right dims(1) 'x' dims(2) ' ' class(value) ']'];
                        else
                            right = [right '['];
                            for j=1:dims(1)
                                for i=1:dims(2)
                                    element = obj.formatVal(value(j,i));
                                    right = [right element];
                                    if i~=dims(2)
                                        right = [right ' '];
                                    end
                                end
                                if j~= dims(1)
                                    right = [right '; '];
                                end
                            end
                            right = [right ']'];
                        end
                       
                    end

                else %scalar OR a string 
                    if size(value,1) > 1
                        dims = size(value);
                        right = ['[' right num2str(dims(1)) 'x' num2str(dims(2)) ' ' class(value) ']'];
                    else
                        right = [right obj.formatVal(value)];
                    end
                end
                    
                disp([left right]);
            end
            
            %construct/display a list of all inherited properties
            inheritedProps = containers.Map({'dummyClassName'}, {{'dummyPropOne' 'dummyPropTwo'}});
            for prop=[mClass.Properties{:}]
                if ~strcmp(prop.DefiningClass.Name,mClass.Name) && ~prop.Hidden %only show inherited, non-hidden props
                    if ~inheritedProps.isKey(prop.DefiningClass.Name)
                        inheritedProps(prop.DefiningClass.Name) = {prop.Name};
                    else
                        current = inheritedProps(prop.DefiningClass.Name);
                        inheritedProps(prop.DefiningClass.Name) = {current{1} prop.Name};
                    end
                end
            end
            remove(inheritedProps,'dummyClassName');
            
            for super=[inheritedProps.keys]
               disp([char(10) 'Inherited from <a href = "matlab:help ' super{1} '">' super{1} '</a>:']);
               propNames = inheritedProps(super{1});
               for i=1:length(propNames)
                  disp([sprintf('%35s%2s',propNames{i},': ') obj.formatVal(obj.(propNames{i}))]);
               end
            end
            
            disp([char(10) '<a href = "matlab:methods(''' mClass.Name ''')">Methods</a>, ' ...
                          '<a href = "matlab:events(''' mClass.Name ''')">Events</a>, ' ...
                          '<a href = "matlab:superclasses(''' mClass.Name ''')">Superclasses</a>']);
        end
        
        function val = formatVal(obj,input)
            val = '';

            if islogical(input)
                if input
                    val = [val sprintf('%s ','true')];
                else
                    val = [val sprintf('%s ','false')];
                end
            elseif isnumeric(input)
                if round(input) == input %print double as an integer
                    val = [val sprintf('%d',input)];
                elseif strcmp(class(input),'double') || strcmp(class(input),'float')
                    if input > 99999.99
                        val = [val sprintf('%.2e',input)];
                    elseif input < 9.9999
                        val = [val sprintf('%.4g',input)];
                    else
                        val = [val sprintf('%.2f',input)];
                    end
                else
                    val = mat2str(input,3);
                end
            elseif isa(input,'char')
                val = [val sprintf('%s ',input)];
            end
        end
        
        function varargout = VException(obj,errorNamespace,errorName,errorMessage,varargin)
            %Streamlined creation of MException objects, either returning creaeted object or throwing exception
            
            %TODO: Remove option to throw error using this method -- leave that to VError. Would need to remove all instances where it is used with this original design of throwing exception when no output argument is used. 
            
            if isempty(errorNamespace)
                errorNamespace = obj.classNameShort;
            elseif ~isempty(strfind(errorNamespace,'.')) %Handle case where full classname is specified
                errorNamespace = obj.getClassNameShort(errorNamespace);
            end
            
            ME = MException([errorNamespace ':' errorName],errorMessage,varargin{:});
            
            if nargout %Return MException object
                varargout{1} = ME;
            else
                ME.throw();
            end
            
        end        
        
        function VError(obj,errorNamespace,errorName,errorMessage,varargin)
            %Streamlined generation of error, in recommended MException format
            
            throw(obj.VException(errorNamespace,errorName,errorMessage,varargin{:}));                      
        end
            
    end
    
   %% STATIC METHODS
    
    %Following are helper/utility functions available to all VClasses
    methods (Static)
        
        function [filteredPropValArgs,otherPropValArgs] = filterPropValArgs(argList,validProps, mandatoryProps)
            %Method for subclasses to filter property-value pairs from supplied argList of property-value pairs
            %filterPropValArgs(argList, validProps, mandatoryProps)
            %   validProps: Cell array list of constructor only properties to extract from argList
            %   mandatoryProps: Optional cell array list specifying subset of validProps which are mandatory; if they are not found in argList, an error is thrown.
            %
            %NOTES
            %   Method is Static, because it must often be invoked by subclass constructors before invoking superclass constructor(s)    
            %
            %   TODO: Further error checking!
            %   TMW: This method passes back the arguments for caller function to do the setting, since in many cases (private or protected properties) it's not possible to set the properties from within this function.
            
            if nargin < 3
                mandatoryProps = {};
            else
                assert(isempty(setdiff(mandatoryProps,validProps)), 'Argument ''mandatoryProps'' must be a subset of the argument ''validProps''');
            end
            
            
            %Extract constructor properties (and the mandatory subset) from supplied argument list        
            [validProps,indices] = intersect(argList(1:2:end), validProps);
            foundMandatoryProps = intersect(argList(1:2:end), mandatoryProps);
            
            %Determine if there are any missing mandatory properties
            missingMandatoryProps= setdiff(mandatoryProps,foundMandatoryProps);
            if ~isempty(missingMandatoryProps)
                throwAsCaller(MException([getClassNameShort(mfilename('class')) ':MissingPropArg'], 'The following required property/value pairs was expected, but not supplied: %s', missingMandatoryProps{1})); %TODO: Find way to (elegantly) display all missing props
            end
            
            filteredPropValArgs = cell(1,2*length(validProps));
            if ~isempty(validProps)
                filteredPropValArgs(1:2:end) = validProps;
                filteredPropValArgs(2:2:end) = argList(2*indices);
                
                %TMW: This doesn't work. Whether as a superclass method, or as a separate function, unable to set properties that are private/protected here.
                %         %Set the provided constructor-only prop/value pairs, mandatory or otherwise
                %         obj.set(constructorProps,argList(2*indices));
                %
                %         %Strip out already processed property-value pairs
                %         argList([2*indices-1 2*indices]) = [];
            else
                filteredPropValArgs = {};
            end
            
            otherPropValArgs = argList;                                   
        end
        
        function errorName = getErrorName(ME)
            errorName =  strtok(ME.identifier,':');               
        end
        
        function errorNamespace = getErrorNameSpace(ME)
            [~,errorNamespace] =  strtok(ME.identifier,':');
        end
               
        
    end
    

    
end

%% HELPER FUNCTIONS
function classNameShort = getClassNameShort(classNameFull)

rem = classNameFull;
while true
    [classNameShort,rem] = strtok(rem,'.');
    if isempty(rem)
        break;
    end
end

end





