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

% FIMulti(Configuration file, Output Directory)

% Configuration file: Stores the details of the fault model, model constants and thresholds, the fault suite and the list of faults to be injected
% Output directory: where information of the results (information of mutants) will be stored

function FIMulti(Faultinjector_config, result_path)
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
fault_suite_filename = 'fault_suiteMULTI.m';
replace_suite_filename = 'replace_suiteMULTI.m';

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

% if ismember('AutotransModel', model)
%    set_param(system, 'Solver', 'ode4', 'StartTime','0', 'StopTime', '30', 'FixedStep', '0.04', 'ReturnWorkspaceOutputs', 'on');
% else
%    set_param(system, 'Solver', 'ode4', 'StartTime','0', 'StopTime', '10', 'FixedStep', '0.01', 'ReturnWorkspaceOutputs', 'on');
% end

% save_system(system,[],'OverwriteIfChangedOnDisk',true);

%% Information
line_handles1 = find_system(system,'FindAll','on','type','line');
nb_lines1 = length(line_handles1);

% In order to read information about signal ports, we need to compile the model
eval(strcat(model_name, "([], [], [], 'compile');"));
for i = 1 : nb_lines1
    line_handle1 = line_handles1(i);
    source_port_handle1 = get_param(line_handle1, 'SrcPortHandle');
    source_port_data_type1{i} = get_param(source_port_handle1, 'CompiledPortDataType');
end
eval(strcat(model_name, "([], [], [], 'term');"));



% %% Change all the 'Sum' blocks from 'round' to 'rectangle' shape // use this in block replacemnet operations
% sumb = find_system(model_name_wo_ext,'BlockType','Sum');
% for i = 1:length(sumb)
%     set_param(sumb{i},'IconShape', "rectangular");
% end
% save_system(system, [],'OverwriteIfChangedOnDisk',true);

%% Information
line_handles1 = find_system(system,'FindAll','on','type','line');

block_handles = find_system(system, 'FindAll', 'on', 'Type', 'Block');

nb_lines1 = length(line_handles1);

for i = 1 : nb_lines1
    line_handle1 = line_handles1(i);
    source_port_handle1 = get_param(line_handle1, 'SrcPortHandle');
    dst_port_handle1 = get_param(line_handle1, 'DstPortHandle');
    source_block_handle1 = get_param(line_handle1, 'SrcBlockHandle');
    dst_block_handle1 = get_param(line_handle1, 'DstBlockHandle');
    sig_name1{i} = get_param(source_port_handle1, 'DataLoggingName');
    
    srcblockname1{i} = get_param(source_block_handle1(1),'Name');
    S_src1{i} = srcblockname1{i};
    Src_name1{i,1} = srcblockname1{i};
    A_src1{i} = S_src1{i}(isstrprop(S_src1{i},'alpha'));
    
    dstblockname1{i} = get_param(dst_block_handle1(1),'Name');
    S_dst1{i} = dstblockname1{i};
    Dst_name1{i,1} = dstblockname1{i};
    A_dst1{i} = S_dst1{i}(isstrprop(S_dst1{i},'alpha'));
    
    block_info1 =  get_param(line_handle1, 'Parent');
    block_inform1{i,1} = convertCharsToStrings(block_info1);
    
    src_block_name1 = get_param(source_port_handle1, 'Parent');
    SRCBName1{i} = convertCharsToStrings(src_block_name1);
    dst_block_name1 = get_param(dst_port_handle1, 'Parent');
    DSTBName1{i} = convertCharsToStrings(dst_block_name1);
    
    SPName1{i} = get_param(source_port_handle1, 'name');
    DPName1{i} = get_param(dst_port_handle1, 'name');
    
    % Obtain the source and destination block info
    Src_info1 = getfullname(get(line_handle1,'SrcBlockHandle'));
    SRC_info1{i,1} = convertCharsToStrings(Src_info1);
    Dst_info1 = getfullname(get(line_handle1,'DstBlockHandle'));
    
    if isa(Dst_info1,'cell')
        DST_info1{i,1} = convertCharsToStrings(Dst_info1(1));
    else
        DST_info1{i,1} = convertCharsToStrings(Dst_info1);
    end
    
    hblkSrc1 = get_param(line_handle1,'SrcBlockHandle');
    hblkDst1 = get_param(line_handle1,'DstBlockHandle');
    
    % Fetch the names of the source and destination
    Src1 = get_param(hblkSrc1,'Name');
    SRC1{i} = convertCharsToStrings(Src1);
    Dst1 = get_param(hblkDst1,'Name');
    DST1{i} = convertCharsToStrings(Dst_info1);
    
    %% Fetching port number info for Src and Dst
    src_port_number1 = num2str(get_param(source_port_handle1, 'PortNumber'));
    SRCPnum1{i,1} = convertCharsToStrings(src_port_number1);
    
    if length(dst_port_handle1) > 1
        for pq = 1:length(dst_port_handle1)
            dst_port_number1(pq) = num2str(get_param(dst_port_handle1(pq), 'PortNumber')); % This is the concatenated string of the port numbers of all the destination blocks
        end
    else
        dst_port_number1 = num2str(get_param(dst_port_handle1, 'PortNumber'));
    end
    DSTPNum1{i,1} = convertCharsToStrings(dst_port_number1(1));
    
    Src_full1 = strcat(Src1, '/', src_port_number1); % Name of the source along with port number
    SRCInfo1{i} = convertCharsToStrings(Src_full1);
    Dst_full1 = strcat(Dst1, '/', dst_port_number1); % Name of the destination along with port number
    DSTInfo1{i} = convertCharsToStrings(Dst_full1);
    
end

disp('Initiating Fault Injection and Mutation ....');
fprintf('\n');

for pq = 1 : height(MFIL)
    
    level_final = cell2mat(table2array(MFIL(pq,1)));
%     if isa(table2array(MFIL(p,1)),'cell')
%         fot = cell2mat(table2array(MFIL(p,1)));
%     elseif isa(table2array(MFIL(p,1)),'double')
%         fot = num2str(table2array(MFIL(p,1)));
%     end
    
    if level_final == "NA"%isempty(level_final)
        level_final = model_name_wo_ext; % Level in the SUT
    else
        level_final = strcat(model_name_wo_ext,'/',level_final); % Level in the SUT
    end
    
    Src_or_InportName = cell2mat(table2array(MFIL(pq,2))); % Name of the source/input port
    Dst_or_OutportName = cell2mat(table2array(MFIL(pq,3))); % Name of the destination/output port
    ParentBlock = cell2mat(table2array(MFIL(pq,4))); % Name of the parent block
    ft = cell2mat(table2array(MFIL(pq,5))); % Fault type
    
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
        fault_table{pq} = eval(strcat(fault_suite_filename_wo_ext, '(model_path, model_ext, k, system, level_final, sig_name1, model_name_wo_ext, nb_lines1, source_port_data_type1, SRC1, SRC_info1, DST_info1, SRCPnum1, DSTPNum1, A_src1, A_dst1, block_inform1, SRCBName1, DSTBName1, SRCInfo1, DSTInfo1, ft, constants_thresholds, ParentBlock, Src_or_InportName, Dst_or_OutportName);'));
        inj_time(pq) = toc;
    else
        tic
        fault_table{pq} = eval(strcat(replace_suite_filename_wo_ext, '(model_path, model_ext, k, system, level_final, sig_name1, model_name_wo_ext, nb_lines1, source_port_data_type1, SRC1, SRC_info1, DST_info1, SRCPnum1, DSTPNum1, A_src1, A_dst1, block_inform1, SRCBName1, DSTBName1, SRCInfo1, DSTInfo1, ft, constants_thresholds, ParentBlock, Src_or_InportName, Dst_or_OutportName);'));
        inj_time(pq) = toc;
    end
    
    if length(fault_table) == 1
        newtable = [fault_table{1}];
    else
        newtable = vertcat(fault_table{:});
        idx = all(cellfun(@isempty,newtable{:,:}),2);
        newtable(idx,:)=[];
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
        idx = all(cellfun(@isempty,newtable{:,:}),2);
        newtable(idx,:)=[];
    end
    
    % Then write the table in the desired folder as .xls file
    writetable(newtable, strcat(result_path, '/Fault_table.xls'));
    
    fprintf('\n');
    disp(['Note: The Fault injection results are saved in the folder: ', result_path, ' (as ''Fault_table.xls'' file).']);
    
end
%toc;
