classdef Model < most.DClass
    %MODEL Shared functionality for classes which are identifiable as 'models' (rig/user-level)
    
    %Shared functionality includes:
    %
    %   Property validation -- using mdlPropAttributes 'metadata'
    %   Config saving/loading -- storage of all 'saveable' props, respecting order in mdlPropAttributes
    %   Header saving/loading -- storage of all 'headerable' props
    
    %TODO: Allow general property-replacement throughout the property metadata table -- could use to specify 'size' attribute of a property, for instance
    %TODO: Use subsref to allow avoiding need to make boilerplate set-access methods
    %TODO: Allow 'Callback' specification in property attributes -- this will only work in concert somehow with subsref scheme
    %TODO: When validation fails with Options list -- error message should provide the list of valid options    
    %TODO: Better handle the case of empty vaues together with Options list..
    %TODO: Resolve issue -- should we expect that initialize() is /always/ called for a Model? (effectively a 'finalizer' method to complement constructor)

    %% ABSTRACT PROPERTIES
    properties (Abstract, Hidden, SetAccess=protected)
        mdlPropAttributes; %A structure effecting Map from property names to structures whose fields are Tags, with associated values, specifying attributes of each property
        
        %OPTIONAL (Can leave empty)
        mdlHeaderExcludeProps; %String cell array of props to forcibly exclude from header
    end
    
    
    %% SUPERUSER PROPERTIES 
    properties (Hidden)
        mdlVerbose = false; %Indicates whether model should provide command-line warnings/messages otherwise suppressed        
        
        mdlInitialized = false; %Flag indicating whether model has been initialized
    end
    
    properties (Hidden,Dependent)
        mdlDefaultConfigProps; % Returns default subset of props to be saved to Config file.
        mdlDefaultHeaderProps; % Returns default subset of props to be saved to Header file.
    end
    
    %% DEVELOPER PROPERTIES
    %'Friend' properties -- SetAccess would ideally be more restricted
    properties (Hidden,SetAccess=protected)
        hController={}; %Handle to Controller(s), if any, linked to this object 
        
        mdlDependsOnListeners; %Structure, whose fields are names of properties with 'DependsOn' property metadata tag, and whose values are an array of set listener handles        
    end
    
    properties (Access=private,Dependent)
        mdlPropSetVarName; % object-dependent variable name used in propset MAT files
    end
    
    %% CONSTRUCTOR/DESTRUCTOR    
    methods
        
        function obj = Model()
           
            znstProcessPropAttributes(); %Process property attributes            
           
            function znstProcessPropAttributes()

                propNames = fieldnames(obj.mdlPropAttributes);                
                
                for i=1:length(propNames)
                    currPropMD = obj.mdlPropAttributes.(propNames{i});

                    %Processing Step 1: Fill in Classes = 'numeric' if 'Classes' not provided and any of Range/Attributes/Size are set (meaning validateattributes() will get called)
                    if ~isfield(currPropMD,'Classes') && any(ismember(fieldnames(currPropMD),{'Range' 'Size' 'Attributes'}))
                         currPropMD.Classes = 'numeric';
                    end
                    
                    %Processing Step 2: Fill in AllowEmpty=false if 'AllowEmpty' not specified
                    if ~isfield(currPropMD,'AllowEmpty')
                         currPropMD.AllowEmpty = false;
                    end                    
                    
                    %Processing Step 3: Generate observable set event for any properties with 'DependsOn' tags, using intermediate listeners
                    if isfield(currPropMD,'DependsOn')
                        dependsOnList = currPropMD.DependsOn;
                                                
                        %Ensure/make Tag value a cell string array
                        assert(ischar(dependsOnList) || iscellstr(dependsOnList),'DependsOn tag was supplied for property ''%s'' with incorrect value -- must be a string or string cell array',propNames{i});
                        if ischar(dependsOnList)
                            dependsOnList = {dependsOnList};
                        end     
                        
                        %Ensure dependent property has no set method
                        mp = findprop(obj,propNames{i});
                        assert(~isempty(mp.SetMethod),'Properties with ''DependsOn'' tag specified must have a set property-access method defined (typically empty). Property ''%s'' violates this rule.',propNames{i});
                        
                        %Bind listener to each of the properties this one 'dependsOn'   
                        listenerArray = event.proplistener.empty();
                        for j=1:length(dependsOnList)
                            mp = findprop(obj,dependsOnList{j});
                            assert(mp.SetObservable,'Properties specified as ''DependsOn'' tag value must be SetObservable. The DependsOn property ''%s'' for property ''%s'' violates this rule.',dependsOnList{j},propNames{i});
                            
                            listenerArray = [listenerArray addlistener(obj,dependsOnList{j},'PostSet',@(src,evnt)znstDummySet(src,evnt,propNames{i}))]; %#ok<AGROW> %TMW: Somehow it's not allowed to use trick of growing array from end to first, with first assignment providign the allocation.
                        end
                                                
                        obj.mdlDependsOnListeners.(propNames{i}) = listenerArray;                        
                        
                    end
                    
                    obj.mdlPropAttributes.(propNames{i}) = currPropMD;
                end                   
                            
                function znstDummySet(~,evnt,propName)
                    %Set specified property to dummy value -- for purpose of allowing any SetObserving listeners to fire
                    evnt.AffectedObject.(propName) = nan;
                end                
                
            end

        end
        
        function initialize(obj)
            
            %Where appropriate, auto-initialize props not initialized in class definition file
            znstInitializeOptionProps();
            
            %Initialize all app properties with side-effects, respecting any order specified by mdlPropAttributes
            %propNames = fieldnames(obj.mdlPropAttributes);
            mc = metaclass(obj);
            props = mc.Properties;
            propNames = cellfun(@(x)x.Name,props,'UniformOutput',false);            
            propNames = obj.mdlOrderPropList(propNames);
            
            %Put controller into 'robot mode' before setting properties in rapid programmatic fashion
            obj.zprvSetCtlrRobotMode();
            
            %Ensure all model and controller side-effects are honored by property 'eigensets'
            try
                for i=1:length(propNames)
                    mp = findprop(obj,propNames{i});
                    if ~isempty(mp.SetMethod) && strcmpi(mp.SetAccess,'public')
                        obj.(propNames{i}) = obj.(propNames{i}); %Forces set-access method to be invoked
                    end
                end
                
                %Initialize Controller object(s) associated with this model
                for i=1:length(obj.hController)
                    obj.hController{i}.initialize();
                end
            catch ME
                obj.zprvResetCtlrRobotMode();
                ME.rethrow();
            end
            
            %Restore controller(s) robot mode setting
            obj.zprvResetCtlrRobotMode();
            
            %Set flag indicating model has been initialized
            obj.mdlInitialized = true;
            
            return;
            
            function znstInitializeOptionProps()
                propNames = fieldnames(obj.mdlPropAttributes);
                
                for i=1:length(propNames)
                    propMD = obj.mdlPropAttributes.(propNames{i});
                    
                    if isfield(propMD,'Options')
                        
                        if isempty(obj.(propNames{i})) && (~isfield(propMD,'AllowEmpty') || ~propMD.AllowEmpty)
                            optionsList = propMD.Options;
                            
                            %TODO: Global/general string replacement in Model property metadata
                            if ischar(optionsList)
                                optionsList = obj.(propMD.Options);
                            end
                            
                            if isnumeric(optionsList)
                                if isvector(optionsList)
                                    defaultOption = optionsList(1);
                                elseif ndims(optionsList)
                                    defaultOption = optionsList(1,:);
                                else
                                    assert(false);
                                end
                            elseif iscellstr(optionsList)
                                defaultOption = optionsList{1};
                            else
                                assert(false);
                            end
                            
                            
                            if isfield(propMD,'List')
                                listSpec = propMD.List;
                                
                                %TODO: Global/general string replacement in Model property metadata
                                if ischar(listSpec) && ~ismember(lower(listSpec),{'vector' 'fullvector'})
                                    listSpec = obj.(propMD.List);
                                end
                                
                                if isnumeric(listSpec)
                                    if isscalar(listSpec)
                                        initSize = [listSpec 1];
                                    else
                                        initSize = listSpec;
                                    end
                                else %inf, 'vector', 'fullvector' options -- init with scalar value
                                    initSize = [1 1];
                                end
                                
                                obj.(propNames{i}) = repmat({defaultOption},initSize);
                            else
                                obj.(propNames{i}) = defaultOption;                                
                            end
                            
                        end
                    end
                end
            end
        end
        
        function delete(obj)
            for c = 1:numel(obj.hController)
                ctl = obj.hController{c};
                if isvalid(ctl)
                    delete(ctl);
                end
            end
        end

    end
    
    %% PROPERTY ACCESS
    methods        
        
        function v = get.mdlDefaultConfigProps(obj)
            v = obj.getDefaultConfigProps(class(obj));
        end
        
        function v = get.mdlDefaultHeaderProps(obj)
            v = obj.getDefaultHeaderProps(class(obj));           
        end
        
        function v = get.mdlPropSetVarName(obj)
            v = zlclVarNameForSaveAndRestore(class(obj));
        end 
        
    end
    
    %% USER METHODS
    methods

        function addController(obj,hController)
            %hController: Array of Controller objects
            
            validateattributes(hController,{'most.Controller'},{});
            
            for i=1:length(hController)
                obj.hController{end+1} = hController(i);
            end
        end
        
        function modelWarn(obj,warnMsg,varargin)
            if obj.mdlVerbose
                fprintf(2,[warnMsg '\n'],varargin{:});
            end            
        end
        
    end
    
    % Header/Config API
    methods
        
        % Save object configuration to file fname. This method starts with
        % the default configuration properties, then includes optional
        % 'include' or 'exclude' sets.
        %
        % incExcFlag (optional): either 'include' or 'exclude'
        % incExcList (optional): inclusion/exclusion property list (cellstr)
        function mdlSaveConfig(obj,fname,incExcFlag,incExcList)
            
            if nargin < 3
                incExcFlag = 'include';
                incExcList = cell(0,1);
            end
            assert(ischar(fname),'fname must be a filename.');
            assert(any(strcmp(incExcFlag,{'include';'exclude'})),...
                'incExcFlag must be either ''include'' or ''exclude''.');
            assert(iscellstr(incExcList),'incExcList must be a cellstring.');
                        
            defaultCfgProps = obj.mdlDefaultConfigProps;
            switch incExcFlag
                case 'include'
                    cfgProps = union(defaultCfgProps,incExcList);
                case 'exclude'
                    cfgProps = setdiff(defaultCfgProps,incExcList);
            end
                    
            obj.mdlSavePropSetFromList(cfgProps,fname);
        end
        
        function cfgPropSet = mdlLoadConfigToStruct(obj,fname)
            cfgPropSet = obj.mdlLoadPropSetToStruct(fname);            
        end
        
        function mdlLoadConfig(obj,fname)
            obj.mdlLoadPropSet(fname);
        end
        
        % xxx todo make this look like mdlSaveConfig with the include/exclude
        function mdlSaveHeader(obj,fname)
            % Save header properties of obj as a structure in a MAT file.

            pnames = obj.mdlDefaultHeaderProps;
            pnames = sort(pnames);
            obj.mdlSavePropSetFromList(pnames,fname);
        end
        
        % xxx make this more consistent with config?
        function str = modelGetHeader(obj,subsetType,subsetList)
            % Get string encoding of the header properties of obj.
            %   subsetType: One of {'exclude' 'include'}
            %   subsetList: String cell array of properties to exclude from or include in header string

            if nargin < 2            
                pnames = obj.mdlDefaultHeaderProps;
            else
                assert(nargin==3,'If ''subsetType'' is specified, then ''subsetList'' must also be specified');
                switch subsetType
                    case 'exclude'
                        pnames = setdiff(obj.mdlDefaultHeaderProps,subsetList);
                    case 'include'
                        pnames = subsetList;
                    otherwise
                        assert('Unrecognized ''subsetType''');
                end
            end
            
            pnames = setdiff(pnames,obj.mdlHeaderExcludeProps);
            
            str = most.util.structOrObj2Assignments(obj,class(obj),pnames);
        end        
            
    end
    
    %% SUPERUSER METHODS
    methods (Access=protected, Hidden)
        
        function mdlDummySetProp(obj,val,propName)
            %A standardized function to call from 'dummy' SetMethods defined for properties with 'DependsOn' metadata tag
            %Provides error message close to that which would normally be observed for setting a Dependent property with no SetMethod.
            assert(~obj.mdlInitialized || isnan(val),sprintf('In class ''%s'', no (non-dummy) set method is defined for Dependent property ''%s''.  A Dependent property needs a set method to assign its value.', class(obj), propName));
        end
        
        
    end
    
    %% DEVELOPER METHODS
    
    methods (Hidden)    
        
        function options = getPropOptions(obj,propName)
            %Gets the list of valid values for the specified property, if it exists
            
            options = [];
            
            if isfield(obj.mdlPropAttributes, propName)
                propAtt = obj.mdlPropAttributes.(propName);
                
                if isfield(propAtt,'Options')
                    optionsData = propAtt.Options;
                    if ischar(optionsData)
                        if ~isempty(findprop(obj,optionsData))
                            options = obj.(optionsData);
                        else
                            error('Invalid Options property metadata supplied for property ''%s''.',propName);
                        end
                    else
                        options = optionsData;
                    end
                end
            end
        end
        
    end
    
    %Controller robot-mode handling    
    methods (Access=protected)
        %TODO: Eliminate this layer by vectorizing the hController array (and having Controller handle)
        
        function zprvSetCtlrRobotMode(obj)
            for i=1:length(obj.hController)
                obj.hController{i}.robotModeSet();
            end            
        end
        
        function zprvResetCtlrRobotMode(obj)            
            for i=1:length(obj.hController)
                obj.hController{i}.robotModeReset();
            end
        end        
    end

    % PropSet API
    methods (Hidden) % Ultimately, protected
        
        % propNames: a cellstr of property names to get
        % propSet: a struct going from propNames to property values.
        %
        % Property values that are objects are ignored and set to [].
        function propSet = mdlGetPropSet(obj,propList)
            assert(iscellstr(propList),'propList must be a cellstring.');
            propSet = struct();
            for c = 1:numel(propList)
                pname = propList{c};
                try
                    val = obj.(pname);
                    if isobject(val)
                        propSet.(pname) = [];
                    else
                        propSet.(pname) = val;
                    end
                catch %#ok<CTCH>
                    warning('DClass:mdlGetPropSet:ErrDuringPropGet',...
                        'An error occured while getting property ''%s''.',pname);
                    propSet.(pname) = [];
                end
            end
        end
        
        % Apply a propSet to obj. Original values for the affected
        % properties are returned in origPropSet. 
        %
        % tfOrderByPropAttribs (optional): bool, default=true. If true,
        % then apply the property sets in the order specified by
        % obj.mdlPropAttributes. If false, apply property sets in the order
        % of fields in propSet.
        function origPropSet = mdlApplyPropSet(obj,propSet,tfOrder)
            assert(isstruct(propSet));
            if nargin < 3
                tfOrder = true;
            end
            assert(isscalar(tfOrder) && islogical(tfOrder));

            propNames = fieldnames(propSet);
            if tfOrder
                propNames = obj.mdlOrderPropList(propNames);                
            end
            
            obj.zprvSetCtlrRobotMode(); %Set controller(s)' robot mode
            
            try
                origPropSet = struct();
                for c = 1:numel(propNames)
                    pname = propNames{c};
                    try
                        origPropSet.(pname) = obj.(pname);
                        obj.(pname) = propSet.(pname);
                    catch %#ok<CTCH>
                        warning('Model:errSettingProp',...
                            'Error getting/setting property ''%s''.',pname);
                        if ~isfield(origPropSet,pname)
                            origPropSet.(pname) = [];
                        end
                    end
                end
            catch ME
                obj.zprvResetCtlrRobotMode();
                ME.rethrow();
            end
            
            obj.zprvResetCtlrRobotMode();            
        end
        
        % Save a propset to the specified MAT-file. The file is assumed to
        % be a MAT-file. The propSet is overwritten/appended to the
        % MAT-file.
        function mdlSavePropSet(obj,propSet,fname)
            assert(isstruct(propSet));
            assert(ischar(fname));

            varname = obj.mdlPropSetVarName;
            tmp.(varname) = propSet; %#ok<STRNU>
            
            % if (varname) already exists in the file, it will be
            % overwritten
            if exist(fname,'file')==2
                save(fname,'-struct','tmp','-mat','-append');
            else
                save(fname,'-struct','tmp','-mat');
            end
        end
        
        function mdlSavePropSetFromList(obj,propList,fname)
            propSet = obj.mdlGetPropSet(propList);
            obj.mdlSavePropSet(propSet,fname);            
        end
        
        % Load contents of propSet file to propSet struct.
        function propSet = mdlLoadPropSetToStruct(obj,fname)

            assert(exist(fname,'file')==2,'File ''%s'' not found.',fname);
            if isempty(obj)
                propSet = [];
                return;
            end            
            
            fileVars = load(fname,'-mat');
            varname = obj.mdlPropSetVarName;
            if ~isfield(fileVars,varname)
                error('DClass:varNotFound',...
                    'No property information for class ''%s'' found in file ''%s''.',class(obj),fname);
            end
            
            propSet = fileVars.(varname);
        end
        
        function mdlLoadPropSet(obj,fname)
            propSet = obj.mdlLoadPropSetToStruct(fname);
            obj.mdlApplyPropSet(propSet);
        end
        
        % Order property list by mdlPropAttributes. properties not
        % references in mdlPropAttributes are put at the end of the ordered
        % list.
        function propList = mdlOrderPropList(obj,propList)
            assert(iscellstr(propList));
            mdlPropAttribList = fieldnames(obj.mdlPropAttributes);
            [srted unsrted] = zlclGetSortedSubset(propList,mdlPropAttribList);
            propList = [srted(:);unsrted(:)];
        end        
        
    end
    
    methods (Access=protected)
                    
%         function props = getOrderedSaveableProps(obj)
%             p = fieldnames(obj.mdlPropAttributes);
%             tf = ismember(p,obj.mdlDefaultConfigProps);
%             props = p(tf);    
%         end
        
        function str = genAssertMsg(obj,val)
            %General error message to use for assertion failure in property  set-access methods
            %TODO: Factor this out one way or another (smartProperties??)
            %TODO: Possibly allow property name to be (optionally) specified, and reported in message
            
            if ischar(val) && isvector(val)
                str = sprintf('Value supplied (''%s'') not valid. Property was not set.',val);
            elseif isnumeric(val)
                str = sprintf('Value supplied (''%g'') not valid. Property was not set.',val);
            else
                str = sprintf('Invalid value supplied. Property was not set.');
            end
            
        end
        
        function val = validatePropArg(obj,propname,val)
            
            % TAGS
            %   Classes: <String or string cell array> One or more strings which are valid 'classes' for validateattributes() call OR one/both of {'cellstr' 'string'}
            %   Attributes: <String or cell array> List of arguments which are valid 'attributes' for validateattributes() call, or one of the added attributes: {'nonscalar'}
            %   AllowEmpty: <0 or 1> Specifies whether to allow empty value --> removes the 'nonempty' attribute supplied by default to validateattributes() call.
            %   Range: <Numeric or cell 2-vector or string> Simply a short hand, [min max], for using '>=' and '<=' validateattributes() attributes. If cell array, string values are names of (another) class property supplying the min/max value (inclusive) for the property.  If string, name of property supplying numeric 2-vector range.
            %   Size: <cell array or string> Fills in 'size' attribute for validateattributes() call using either single object property or a cell array converted to numeric array, with each string value replaced by object property
            %   Options: <cell array or numeric vector or string> If cell array, a list of valid values for the property. If string, name of (another) class property which supplies the list of valid values for the property. 
            %   List: <Integer scalar/array, or empty val, or Inf, or string member of {'vector' 'fullvector'}, or string> Specifies that property is a cell array of specified length/size of values each satisfying Classes/Attributes/Range constraint. If empty, any cell array size is allowed,including empty. If Inf, any non-empty cell array size is allowed. If 'vector', then any vector is allowed (including empty). If 'fullvector', then any non-empty vector is allowed. If other string, name of property supplying array size information.
            %
            % NOTES
            %   If Classes is left empty, and any of Attributes/Range/Size is specified, value of {'numeric'} is used for validateattributes() call
            %   The special class 'binaryflex' implies: 1) classes {'numeric' 'logical'} are used and 2) attribute 'binary' is used, for the validateattributes() call -- this allows 0/1 values to work with 
            %   The special classes 'binarylogical' and 'binarynumeric' are the same as 'binaryflex', with the property being coerced to a logical/double, respectively.
            %
            %   The 'nonempty' attribute is included by default in validateattributes() calls, unless AllowEmpty is specified.
            %   The 'scalar' attribute is included by default in validateattributes() calls -- to prevent this, use 'size', 'vector', or the added attribute 'nonscalar'.
            %   The 'size' attribute is modified to allow a scalar value which specifies that value is vector of specified length
            %               
            %   If Options is specified, and is a cell array, then it overrides Classes/Attributes/Range/Size. If numeric, then those still apply.
            %
            %
            % TIPS
            %   Options (of numeric type) and Size tags can be combined for properties which are matrices comprising a list of array-values, with both the array-value options and the length being specifiable (possibly as object properties).
            %   To test for a flexible logical array (either 0/1 or true/false array), specify 'binary' as one of Attributes (no need to specify Classes)
            %
            %   TODO: What to do with AllowEmpty & Options combination?? For numeric Options, at moment empty values are not allowed, but they might want to be in some cases??
            %   TODO: Support for Size more/all of the options that are supported for List (Inf, empty val)
            
            propMDAll = obj.mdlPropAttributes;
            errorArgs = {'most:InvalidPropVal','Invalid value for property ''%s'' supplied.',propname};
            optionsErrorArgs = {'Invalid Options property metadata supplied for property ''%s''.',propname};
            
            if isfield(propMDAll,propname)
                
                propMD = propMDAll.(propname);
                
                if isfield(propMD,'List')
                    
                    %Ensure that List is a cell array of correct size attributes 
                    if isempty(val)
                        val = {};
                    end
                    assert(iscell(val),errorArgs{:});
                    
                    listData = propMD.List;
                    
                    %Ensure that list matches any size constraints specified
                    checkList(val,listData);
                    
                    %Iterate through cell array
                    for i=1:numel(val)
                        val{i} = znstValidateValue(val{i},propMD);
                    end
                    
                else
                    val = znstValidateValue(val,propMD);
                end                                
            end           
                      
            function val = znstValidateValue(val,propMD)
                
                allowEmpty = isfield(propMD,'AllowEmpty') && propMD.AllowEmpty;

                optionsData = obj.getPropOptions(propname);
                if iscell(optionsData)
                    if isempty(val)
                        assert(allowEmpty,errorArgs{:});
                    else
                        checkOptions(val,optionsData);
                    end
                    return; %Cell-array options supercedes all other Tags/constraints
                end                 
               
                if isfield(propMD,{'Classes'})
                    classesData = propMD.Classes;
                    if ~iscell(classesData)
                        classesData = {classesData};
                    end

                    %Handle special classes added by this validator {'string' 'cellstr'} -- these override use of validateattributes()
                    if ~isempty(intersect(classesData,{'string' 'cellstr'}))
                        if isempty(val)
                            assert(allowEmpty,errorArgs{:});
                            if ismember('cellstr',classesData)
                                val = {};
                            else
                                val = '';
                            end
                        else
                            if ismember('cellstr',classesData)
                                if ismember('string',classesData)
                                    assert(most.idioms.isstring(val) || iscellstr(val),errorArgs{:})
                                    val = cellstr(val);
                                else
                                    assert(iscellstr(val),errorArgs{:})
                                end
                            else
                                assert(most.idioms.isstring(val),errorArgs{:})
                            end
                        end
                        
                        return; %Don't pass onto validateattributes()
                    end
                    
                    %                 else
                    %                     classesData = {'numeric'};
                    %                 end
                    %
                    %if ~isempty(classesData)  || any(isfield(propMD,{'Attributes' 'Range' 'Size'}))
                    
                    %Use validateattributes()

                    convertFcn = [];
                    attributesData = {};

                    %Handle special classes 
                    if any(ismember({'binaryflex' 'binarylogical' 'binarynumeric'},classesData))
                        if ismember('binarylogical',classesData)
                            convertFcn = @logical;
                        elseif ismember('binarynumeric',classesData)
                            convertFcn = @double;
                        end
                        classesData = {'numeric' 'logical'};
                        attributesData = {'binary'};
                    end
                        
                    if isfield(propMD,{'Attributes'}) 
                        attributesData = [attributesData propMD.Attributes];
                        
                        if ~allowEmpty %At moment, not actively removing 'nonempty' if it's in attributes with AllowEmpty
                            attributesData = [attributesData 'nonempty'];
                        end
                        
                        %Add 'scalar' attribute, by default
                        attributesDataChar = attributesData(cellfun(@ischar,attributesData));
                        if ~any(ismember({'nonscalar' 'size' 'vector'},attributesDataChar))
                            attributesData = [attributesData 'scalar'];
                        end
                        
                        %Remove 'nonscalar' special attribute, if supplied
                        attributesData(cellfun(@(x)ischar(x) && strcmpi(x,'nonscalar'),attributesData)) = []; 

                    end
                    
                    if isfield(propMD,{'Range'})    
                        attributesData = [attributesData rangeData2Attributes(propMD.Range)];                                                
                    end
                    
                    if isfield(propMD,{'Size'})                        
                        attributesData = [attributesData sizeData2Attributes(val,propMD.Size)];
                    end
                    
                    %Do the actual validateattributes() call!
                    try
                        validateattributes(val,classesData,attributesData);
                    catch ME
                        if strfind(ME.identifier,'validateattributes')  %error in usage of validateAttributes() -- shouldn't happen!
                            ME.rethrow(); 
                        else
                            %Deal with some validateattributes() behaviors that are not as we'd like
                            if any(isinf(val(:))) && ~isempty(strfind(ME.identifier,'expectedInteger')) %allow 'infinite' integers
                                %do nothing   
                            elseif allowEmpty && isempty(val) && (~isempty(strfind(ME.identifier,'expectedScalar')) || ~isempty(strfind(ME.identifier,'expectedVector'))) %allow empty arrays to pass, where allowed, with 'scalar' attribute specified
                                %do nothing                                
                            else  %validateAttributes indicates validation failure to report
                                error('most:InvalidPropVal','Invalid value for property ''%s'' supplied:\n\t%s\n',propname,ME.message);
                            end
                        
                        end
                    end       
                    
                    %Do any type conversion
                    if ~isempty(convertFcn)
                        val = convertFcn(val);
                    end
                    
                end
                
                %Check numeric Options, if any
                if ~isempty(optionsData)
                    if isempty(val)
                        assert(allowEmpty,errorArgs{:});
                    else
                        checkOptions(val,optionsData);
                    end
                end
            end   
            
            
            function checkList(val,listData)
                
                try
                    if isempty(listData)
                        %Do nothing -- any size works, including empty
                    elseif ischar(listData)
                        if strcmpi(listData,'fullvector')
                            assert(isvector(val),errorArgs{:});
                        elseif strcmpi(listData,'vector')
                            assert(isempty(val) || isvector(val),errorArgs{:});
                        elseif ~isempty(findprop(obj,listData))
                            checkList(val,obj.(listData));
                        else
                            error('Invalid List property metadata supplied for property ''%s''.',propname);
                        end
                    elseif isinf(listData)
                        assert(~isempty(val),errorArgs{:});
                    elseif isnumeric(listData)
                        if isscalar(listData)
                            assert(length(val) == listData,errorArgs{:});
                        else
                            try
                                validateattributes(val,{'cell'},{'size',listData});
                            catch ME
                                if ~strfind(ME.identifier,'validateAttributes')
                                    error(errorArgs{:});
                                else
                                    ME.rethrow();
                                end
                            end
                        end
                    else
                        error('Invalid List property metadata supplied for property ''%s''.',propname);
                    end
                catch ME
                    ME.throwAsCaller();
                end
            end
            
             function checkOptions(val,optionsData)   
                 try 
                     if iscellstr(optionsData)
                         assert(most.idioms.isstring(val) && ismember(val,optionsData),errorArgs{:});
                         
                     elseif isnumeric(optionsData) && isvector(optionsData) %Numeric vector of valid scalar values
                         assert(isscalar(val) && ismember(val,optionsData),errorArgs{:});
                         
                     elseif isnumeric(optionsData) && ndims(optionsData)==2  %2-d Array whose rows specify vector options for the value
                         assert(isnumeric(val) && size(val,2) == size(optionsData,2) && all(ismember(val,optionsData,'rows')),errorArgs{:});
                         
                     else
                         error(optionsErrorArgs{:});
                     end
                 catch ME
                     ME.throwAsCaller();
                 end
             end
            
             function sizeAttributes = sizeData2Attributes(val,sizeData)
                 %Determines 'size' attributes for validateattributes() call. Applies any length constraints directly to supplied val.
                 
                 sizeErrorArgs = {'Invalid Size property metadata supplied for property ''%s''.',propname};
             
                 if ischar(sizeData) %&& ~isempty(findprop(obj,sizeData))
                     sizeAttributes = sizeData2Attributes(val,obj.(sizeData));
                     return;
                 elseif isnumeric(sizeData)
                     sizeVal = sizeData;  %This would be dumb, but allowable %Not checking that rangeData is a 2-vector
                 elseif iscell(sizeData)
                     sizeVal = zeros(size(sizeData));
                     for j=1:numel(sizeData)
                         if isnumeric(sizeData{j})
                             sizeVal(j) = sizeData{j};
                         elseif ~isempty(findprop(obj,sizeData{j}))
                             sizeVal(j) = obj.(sizeData{j});
                         else
                             error(sizeErrorArgs{:});
                         end
                     end                     
                 else
                     error(sizeErrorArgs{:});
                 end                 
                 
                 if isscalar(sizeVal) %a length constraint
                     assert(isvector(val) && length(val) == sizeVal,errorArgs{:}); 
                     sizeAttributes = {};
                 else                                  
                     sizeAttributes = {'size' sizeVal};
                 end
             end
            
             
            function rangeAttributes = rangeData2Attributes(rangeData)
                try 
                    rangeErrorArgs = {'Invalid Range property metadata supplied for property ''%s''.',propname};
                    
                    if ischar(rangeData) %&& ~isempty(findprop(obj,rangeData))
                        rangeAttributes = rangeData2Attributes(obj.(rangeData));
                        return;
                    elseif isnumeric(rangeData)
                        rangeAttributes = {'>=',rangeData(1),'<=',rangeData(2)}; %Not checking that rangeData is a 2-vector
                    elseif iscell(rangeData)
                        if isnumeric(rangeData{1})
                            rangeAttributes = {'>=',rangeData{1}};
                        elseif ischar(rangeData{1})
                            rangeAttributes = {'>=',obj.(rangeData{1})};
                        else
                            error(rangeErrorArgs{:});
                        end
                        
                        if isnumeric(rangeData{2})
                            rangeAttributes = [rangeAttributes,{'<=',rangeData{2}}];
                        elseif ischar(rangeData{2})
                            rangeAttributes = [rangeAttributes,{'>=',obj.(rangeData{2})}];
                        else
                            error(rangeErrorArgs{:});
                        end
                    else
                        error(rangeErrorArgs{:});
                    end
                catch ME
                    ME.throwAsCaller();
                end
            end      
                                            
        end
        
    end
    
    methods (Static,Access=protected)
  
        function propNames = getDefaultConfigProps(clsName)
            fcn = @(x)(strcmpi(x.SetAccess,'public') && strcmpi(x.GetAccess,'public') && ...
                       ~x.Transient && ~x.Dependent && ~x.Constant && ~x.Hidden);
            propNames = most.Model.getAllPropsWithCriterion(clsName,fcn);                    
        end
        
        function propNames = getDefaultHeaderProps(clsName)
            fcn = @(x)(strcmpi(x.GetAccess,'public') && ~x.Hidden);
            propNames = most.Model.getAllPropsWithCriterion(clsName,fcn);
        end
        
        % predicateFcn is a function that returns a logical when given a
        % meta.Property object
        function propNames = getAllPropsWithCriterion(clsName,predicateFcn)
            mc = meta.class.fromName(clsName);
            ps = mc.Properties;
            tf = cellfun(predicateFcn,ps);
            ps = ps(tf);
            propNames = cellfun(@(x)x.Name,ps,'UniformOutput',false);     
        end
        
        % returns true if propName can be utilized as a config prop for the
        % given class.
        function tf = isPropConfigable(clsName,propName)
            mc = meta.class.fromName(clsName);
            allmp = mc.Properties;
            tf = cellfun(@(x)strcmp(x.Name,propName),allmp);
            assert(nnz(tf)==1);
            
            mp = allmp(tf);
            tf = strcmpi(mp.SetAccess,'public') && strcmpi(mp.GetAccess,'public');
        end
        
%         % This saves the specified properties of obj as a struct into the
%         % specified MATfile. The properties are put in the struct in order.
%         % The variable name stored in the MATfile is the classname of obj.      
%         function savePropsInOrder(obj,props,filename)
%             
%             s = obj.mdlGetPropSet(props);
%             
%             % generate a varname to save in the mat file
%             varname = zlclVarNameForSaveAndRestore(class(obj));
%             tmp.(varname) = s; %#ok<STRNU>
%             
%             % if (varname) already exists in the file, it will be
%             % overwritten
%             save(filename,'-struct','tmp');            
%         end
        
    end
            
end

%         % Saves the values of all properties in propList to the config file
%         % fname. The properties will be not necessarily be saved in the
%         % order given by propList. (The order is restricted as necessary by
%         % the ordering of mdlPropAttributes.)
%         function mdlSavePropSetFromList(obj,propList,fname)
%             
%             if numel(obj)~=1
%                 error('DClass:mdlSavePropSetFromList:invalidArg','obj must be a scalar object.');
%             end
%             
%             allSaveableProps = obj.getAllConfigSaveableProps;
%             tfSaveable = ismember(propList,allSaveableProps);
%             if ~all(tfSaveable)
%                 error('DClass:mdlSavePropSetFromList:invalidProp',...
%                       'One or more specified properties cannot be saved to a configuration.');
%             end
%             
%             allOrderedProps = obj.getOrderedSaveableProps;
%             [sortedProps unsortedProps] = zlclGetSortedSubset(propList,allOrderedProps);
%             propList = [sortedProps;unsortedProps];
%             
%             obj.savePropsInOrder(propList,fname);            
%            
%         end


%         function mdlRestorePropSubset(obj,fname)
%              assert(false,'Obsolete');
% %             if isempty(obj)
% %                 return;
% %             end
% %             
% %             s = load(fname,'-mat');
% %             varname = zlclVarNameForSaveAndRestore(class(obj));
% %             if ~isfield(s,varname)
% %                 error('DClass:mdlRestorePropSubset:ClassNotFound',...
% %                     'No information for class ''%s'' found in config file ''%s''.',class(obj),fname);
% %             end
% %             s = s.(varname);
% %             propList = fieldnames(s);
% %             
% %             
% %             % restore in order of current propMetadata (order in saved struct may be different)
% %             allSaveableProps = obj.getAllConfigSaveableProps;
% %             tfSaveable = ismember(propList,allSaveableProps);
% %             notfound = propList(~tfSaveable);
% %             for c = 1:numel(notfound)
% %                 warning('DClass:mdlRestorePropSubset',...
% %                     'Property ''%s'' saved to configuration cannot be restored.',notfound{c});
% %             end
% %             propList = propList(tfSaveable);
% %             
% %             allOrderedProps = obj.getOrderedSaveableProps;
% %             [sortedProps unsortedProps] = zlclGetSortedSubset(propList,allOrderedProps);
% %             propList = [sortedProps;unsortedProps];
% %             
% %             for c = 1:numel(propList)
% %                 pname = propList{c};
% %                 for d = 1:numel(obj)
% %                     try
% %                         obj(d).(pname) = s.(pname);
% %                     catch %#ok<CTCH>
% %                         warning('DClass:mdlRestorePropSubset:ErrDuringPropSet',...
% %                             'An error occured while restoring property ''%s''.',pname);
% %                     end
% %                 end
% %             end            
%         end


% sortedSubset is the subset of list that is in sortedReferenceList.
% sortedSubset is sorted by the reference list. unsortedSubset is the
% remainder of list. Its order is indeterminate.
function [sortedSubset unsortedSubset] = zlclGetSortedSubset(list,sortedReferenceList)

[tfOrdered loc] = ismember(list,sortedReferenceList);
sortedSubset = sortedReferenceList(sort(loc(tfOrdered)));
unsortedSubset = setdiff(list,sortedSubset);

end

function n = zlclVarNameForSaveAndRestore(clsName)
    n = regexprep(clsName,'\.','_');
end
        
