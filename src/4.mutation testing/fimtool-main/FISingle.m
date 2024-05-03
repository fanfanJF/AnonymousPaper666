%% FIM ---- Fault Injection and Mutant generation engine

%  Developed in MATLAB_R2020b
%  Source codes demo version 1.0
% _____________________________________________________

%  Author and programmer: Drishti Yadav
%  PreDoc Researcher at Faculty of Informatics, Institute of Computer Engineering, Cyber-Physical Systems Research Unit
%  Technische Universität Wien, 1040, Vienna, Austria
%  Date created: 24-11-2021

%  Researchgate: https://www.researchgate.net/profile/Drishti-Yadav-3
%  Google scholar: https://scholar.google.com/citations?user=5h2LnBcAAAAJ&hl=en&oi=ao

%  e-Mail: drish131196@gmail.com
%  e-Mail (TU Wien): drishti.yadav@tuwien.ac.at
% __________________________________________________________________
%  Co-author and Advisor: Ezio Bartocci
%
%         e-Mail: ezio.bartocci@gmail.com,
%         e-Mail (TU Wien): ezio.bartocci@tuwien.ac.at
%         Homepage: http://www.eziobartocci.com/
% ___________________________________________________________________
%  Co-authors: Dejan Nickovic, Austrian Institute of Technology; e-Mail: Dejan.Nickovic@ait.ac.at
%              Leonardo Mariani, University of Milan Bicocca; e-Mail: leonardo.mariani@unimib.it
% ___________________________________________________________________

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% FAULT INJECTION & MUTANT GENERATION INTERFACE

% FISingle(Configuration file, Output Directory)

% Configuration file: Stores the details of the fault model, model constants and thresholds, the fault suite and the list of faults to be injected
% Output directory: where information of the results (information of mutants) will be stored

function FISingle(Faultinjector_config, result_path)

%tic;

warning('off','all');

%% Add required folders to path

addpath('Configuration', 'FaultInjector_Master')

%% Set inputs to fault injection experiments and perform initializations

% Load file prefixes and constants
load(['Configuration/FIToolInitialization.mat']); % Inputs necessary for initializing the tool (already provided)
fprintf('\n');
disp('Tool initialization successful');

% Create the ouput directory for storing the results
if (exist(result_path) == 0)
    mkdir(result_path);
else
    rmdir(result_path, 's');
    mkdir(result_path);
end

%% Other parameters

addpath(result_path);

fault_table = {}; % to store the fault injection results

% Initialize system inputs
[model, constants_thresholds, fault_injector_folder, Mainfolder, fault_list] = Init_sys_input(Faultinjector_config);
fault_suite_filename = 'fault_suite.m';
replace_suite_filename = 'replace_suite.m';

% MFIL : my_fault_injection_list
MFIL = readtable(strcat('Configuration/', fault_list), 'VariableNamingRule', 'preserve');

addpath(fault_injector_folder);
[ model_path, model_name_wo_ext, model_ext ] = fileparts( model );
addpath(Mainfolder);

load(constants_thresholds); % Parameters necessary to perform simulations of the system (user defined as a .mat file)

command = sprintf('load(''%s'')', constants_thresholds);
evalin('base', command);

%% Creating a new model

% Obtain filename and path of the model file
[ model_path, model_name_wo_ext, model_ext ] = fileparts( model );
model_original = model;
model_name = model_name_wo_ext;
model_path = Mainfolder;

% Load the model
system = load_system([model_path, model_name_wo_ext, model_ext]);

if ismember('AutotransModel', model)
    set_param(system, 'Solver', 'ode4', 'StartTime','0', 'StopTime', '30', 'FixedStep', '0.04', 'ReturnWorkspaceOutputs', 'on');
else
    set_param(system, 'Solver', 'ode4', 'StartTime','0', 'StopTime', '10', 'FixedStep', '0.01', 'ReturnWorkspaceOutputs', 'on');
end

save_system(system,[],'OverwriteIfChangedOnDisk',true);

%% Information
line_handles = find_system(system,'FindAll','on','type','line');
nb_lines = length(line_handles);

% In order to read information about signal ports, we need to compile the model
eval(strcat(model_name, "([], [], [], 'compile');"));
for i = 1 : nb_lines
    line_handle = line_handles(i);
    source_port_handle = get_param(line_handle, 'SrcPortHandle');
    source_port_data_type{i} = get_param(source_port_handle, 'CompiledPortDataType');
end
eval(strcat(model_name, "([], [], [], 'term');"));

%% First create a copy of the original model

% First check if a copy exists, if a copy exists, then
% delete it and create a new copy

model_copy_name_wo_ext = [ model_name_wo_ext, '_copy'];
model_name = strcat(model_name_wo_ext, model_ext);
model_new_name = strcat(model_name_wo_ext,'_copy');
model_new_name = strcat(model_new_name, model_ext);
prev_model = strcat(model_path, model_new_name);
if (exist(prev_model) == 4)
    delete(prev_model);
    bdclose(prev_model);
end

fprintf('\n');
% disp('Model copying initiated ....');
disp([ 'Copying the model ', model_name_wo_ext, '...' ]);
status = copyfile(strcat(model_path, model_name), strcat(model_path, model_new_name));

if (status == 0)
    disp([ 'The copy of ', model_name_wo_ext, ' was not successful.' ]);
else
    disp([ 'The copy of ', model_name_wo_ext, ' was successful.' ]);
end
close_system(system);
disp([ 'Closing the original model ', model_name_wo_ext, ' .' ]);

%% Load the new copied model
disp([ 'Loading the new model ', model_copy_name_wo_ext, '...' ]);
system = load_system([ model_path, model_copy_name_wo_ext, model_ext ]);
% disp(['Model ', model_name_wo_ext, ' loaded.']);

fprintf('\n');


%% Change all the 'Sum' blocks from 'round' to 'rectangle' shape // use this in block replacemnet operations
sumb = find_system(model_copy_name_wo_ext,'BlockType','Sum');
for i = 1:length(sumb)
    set_param(sumb{i},'IconShape', "rectangular");
end
save_system(system, [],'OverwriteIfChangedOnDisk',true);

%% Information
line_handles = find_system(system,'FindAll','on','type','line');

block_handles = find_system(system, 'FindAll', 'on', 'Type', 'Block');

nb_lines = length(line_handles);

for i = 1 : nb_lines
    line_handle = line_handles(i);
    source_port_handle = get_param(line_handle, 'SrcPortHandle');
    dst_port_handle = get_param(line_handle, 'DstPortHandle');
    source_block_handle = get_param(line_handle, 'SrcBlockHandle');
    dst_block_handle = get_param(line_handle, 'DstBlockHandle');
    sig_name{i} = get_param(source_port_handle, 'DataLoggingName');
    
    srcblockname{i} = get_param(source_block_handle(1),'Name');
    S_src{i} = srcblockname{i};
    Src_name{i,1} = srcblockname{i};
    A_src{i} = S_src{i}(isstrprop(S_src{i},'alpha'));
    
    dstblockname{i} = get_param(dst_block_handle(1),'Name');
    S_dst{i} = dstblockname{i};
    Dst_name{i,1} = dstblockname{i};
    A_dst{i} = S_dst{i}(isstrprop(S_dst{i},'alpha'));
    
    block_info =  get_param(line_handle, 'Parent');
    block_inform{i,1} = convertCharsToStrings(block_info);
    
    src_block_name = get_param(source_port_handle, 'Parent');
    SRCBName{i} = convertCharsToStrings(src_block_name);
    dst_block_name = get_param(dst_port_handle, 'Parent');
    DSTBName{i} = convertCharsToStrings(dst_block_name);
    
    SPName{i} = get_param(source_port_handle, 'name');
    DPName{i} = get_param(dst_port_handle, 'name');
    
    % Obtain the source and destination block info
    Src_info = getfullname(get(line_handle,'SrcBlockHandle'));
    SRC_info{i,1} = convertCharsToStrings(Src_info);
    Dst_info = getfullname(get(line_handle,'DstBlockHandle'));
    
    if isa(Dst_info,'cell')
        DST_info{i,1} = convertCharsToStrings(Dst_info(1));
    else
        DST_info{i,1} = convertCharsToStrings(Dst_info);
    end
    
    hblkSrc = get_param(line_handle,'SrcBlockHandle');
    hblkDst = get_param(line_handle,'DstBlockHandle');
    
    % Fetch the names of the source and destination
    Src = get_param(hblkSrc,'Name');
    SRC{i} = convertCharsToStrings(Src);
    Dst = get_param(hblkDst,'Name');
    DST{i} = convertCharsToStrings(Dst_info);
    
    %% Fetching port number info for Src and Dst
    src_port_number = num2str(get_param(source_port_handle, 'PortNumber'));
    SRCPnum{i,1} = convertCharsToStrings(src_port_number);
    
    if length(dst_port_handle) > 1
        for p = 1:length(dst_port_handle)
            dst_port_number(p) = num2str(get_param(dst_port_handle(p), 'PortNumber')); % This is the concatenated string of the port numbers of all the destination blocks
        end
    else
        dst_port_number = num2str(get_param(dst_port_handle, 'PortNumber'));
    end
    DSTPNum{i,1} = convertCharsToStrings(dst_port_number(1));
    
    Src_full = strcat(Src, '/', src_port_number); % Name of the source along with port number
    SRCInfo{i} = convertCharsToStrings(Src_full);
    Dst_full = strcat(Dst, '/', dst_port_number); % Name of the destination along with port number
    DSTInfo{i} = convertCharsToStrings(Dst_full);
    
end

disp('Initiating Fault Injection and Mutation ....');
fprintf('\n');

for p = 1 : height(MFIL)
    
    level_final = cell2mat(table2array(MFIL(p,1)));
%     if isa(table2array(MFIL(p,1)),'cell')
%         fot = cell2mat(table2array(MFIL(p,1)));
%     elseif isa(table2array(MFIL(p,1)),'double')
%         fot = num2str(table2array(MFIL(p,1)));
%     end
    
    if level_final == "NA"%isempty(level_final)
        level_final = model_copy_name_wo_ext; % Level in the SUT
    else
        level_final = strcat(model_copy_name_wo_ext,'/',level_final); % Level in the SUT
    end
    
    Src_or_InportName = cell2mat(table2array(MFIL(p,2))); % Name of the source/input port
    Dst_or_OutportName = cell2mat(table2array(MFIL(p,3))); % Name of the destination/output port
    ParentBlock = cell2mat(table2array(MFIL(p,4))); % Name of the parent block
    ft = cell2mat(table2array(MFIL(p,5))); % Fault type
    
    load_system('FInjLib');
    % Setting up the Fault Injector block parameters
    set_param('FInjLib', 'Lock', 'off');
    
    if ft == "Stuck-at 0"
        set_param('FInjLib/Zerofault', 'FInjBlockNum', "1");   % Name of the Fault Injector block
        set_param('FInjLib/Zerofault', 'FIEnableflag', "off"); % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "Bias/Offset"
        set_param('FInjLib/Offset', 'FInjBlockNum', "1");   % Name of the Fault Injector block
        set_param('FInjLib/Offset', 'FIEnableflag', "off"); % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "Noise"
        set_param('FInjLib/Noise', 'FInjBlockNum', "1");   % Name of the Fault Injector block
        set_param('FInjLib/Noise', 'FIEnableflag', "off"); % Turn off fault injector
        % These are model specific parameters, user needs to modify based on the model requirements
        if ismember('AutotransModel', model)
            set_param('FInjLib/Noise/Band-Limited White Noise', 'Ts', "0.04");
        else
            set_param('FInjLib/Noise/Band-Limited White Noise', 'Ts', "0.04");
        end
        save_system('FInjLib');
        
    elseif ft == "Negate"
        set_param('FInjLib/Negate', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/Negate', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "Invert"
        set_param('FInjLib/Inverter', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/Inverter', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "Absolute"
        set_param('FInjLib/Absolute', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/Absolute', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "Stuck-at"
        set_param('FInjLib/Stuck-at', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/Stuck-at', 'FIEnableflag', "off");     % Turn off fault injector 
        save_system('FInjLib');
        
    elseif ft == "Time Delay"
        set_param('FInjLib/TimeDelay', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/TimeDelay', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "Bit Flip"
        set_param('FInjLib/BitFlip', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/BitFlip', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "Package Drop"
        set_param('FInjLib/PackageDrop', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/PackageDrop', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "ROR"
        set_param('FInjLib/RelationalOperator_Mutation', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/RelationalOperator_Mutation', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "LOR"
        set_param('FInjLib/LogicalOperator_Mutation', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/LogicalOperator_Mutation', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "S2P"
        set_param('FInjLib/Sum2Prod_Mutation', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/Sum2Prod_Mutation', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
    elseif ft == "P2S"
        set_param('FInjLib/Prod2Sum_Mutation', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/Prod2Sum_Mutation', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
        
        
    elseif ft == "ASR"
        set_param('FInjLib/ArSignReplOperator', 'FInjBlockNum', "1"); % Name of the Fault Injector block
        set_param('FInjLib/ArSignReplOperator', 'FIEnableflag', "off");     % Turn off fault injector
        save_system('FInjLib');
    end
    
    
    save_system('FInjLib');
    
    %% Fault Injection Experiments
    % Execute fault suite and obtain information about the faults injected in the model
    fault_suite_filename_wo_ext = fault_suite_filename(1:regexp(fault_suite_filename,'\.')-1);
    replace_suite_filename_wo_ext = replace_suite_filename(1:regexp(replace_suite_filename,'\.')-1);
    
    if isempty(fault_table)
        k = 1;
    end
    
    if ft == "Noise" || ft == "Negate" || ft == "Invert" || ft == "Absolute" || ft == "Stuck-at 0" || ft == "Bias/Offset" || ft == "Stuck-at" || ft == "Time Delay" || ft == "Bit Flip" || ft == "Package Drop"
        tic
        fault_table{p} = eval(strcat(fault_suite_filename_wo_ext, '(k, system, level_final, sig_name, model_copy_name_wo_ext, nb_lines, source_port_data_type, SRC, SRC_info, DST_info, SRCPnum, DSTPNum, A_src, A_dst, block_inform, SRCBName, DSTBName, SRCInfo, DSTInfo, ft, constants_thresholds, ParentBlock, Src_or_InportName, Dst_or_OutportName);'));
        inj_time(p) = toc;
    else
        tic
        fault_table{p} = eval(strcat(replace_suite_filename_wo_ext, '(k, system, level_final, sig_name, model_copy_name_wo_ext, nb_lines, source_port_data_type, SRC, SRC_info, DST_info, SRCPnum, DSTPNum, A_src, A_dst, block_inform, SRCBName, DSTBName, SRCInfo, DSTInfo, ft, constants_thresholds, ParentBlock, Src_or_InportName, Dst_or_OutportName);'));
        inj_time(p) = toc;
    end
    
    if length(fault_table) == 1
        newtable = [fault_table{1}];
    else
        newtable = vertcat(fault_table{:});
    end
    
    l = height(newtable);
    k = l + 1;
    
end

if ~isempty(fault_table)
    %% Create a table with all information of the injected faults and save the table in the target location
    
    % First create a single table with details of all fault injections
    if length(fault_table) == 1
        newtable = [fault_table{1}];
    else
        newtable = vertcat(fault_table{:});
    end
    
    % Then write the table in the desired folder as .xls file
    writetable(newtable, [result_path, '/Fault_table.xls']);
    
    fprintf('\n');
    disp(['Note: The Fault injection results are saved in the folder: ', result_path, ' (as ''Fault_table.xls'' file).']);
    
end
%toc;
