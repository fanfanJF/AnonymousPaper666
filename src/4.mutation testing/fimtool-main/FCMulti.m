%% FC

%% INTERFACE FOR MODEL SIMULATION WITH MUTANTS/INJECTED FAULTS

% Aim: To Read the data from the generated fault table and simulate the model based on the selected faults
% Created: 26-11-2021
% Author:  Drishti Yadav

% FCMulti(Configuration file, Output Directory, Fault_list)
% Configuration file: Stores the details of the fault model, model constants and thresholds, the fault suite and the list of faults to be injected
% Output directory: where information of the results (information of mutants) are stored
% Fault_list : contains a list of faults which need to be enabled during a simulation.

function FCMulti(Faultinjector_config, result_path, Fault_enable_list)

warning('off','all');

addpath('Configuration', 'FaultInjector_Master')

% Initialize system inputs
[model, constants_thresholds, fault_injector_folder, Mainfolder, fault_list] = Init_sys_input(Faultinjector_config);
fault_suite_filename = 'fault_suite.m';
replace_suite_filename = 'replace_suite.m';

% FEL : fault_enable_list
FEL = readtable(strcat('Configuration/', Fault_enable_list), 'VariableNamingRule', 'preserve');

addpath(fault_injector_folder);
addpath(Mainfolder);

% Obtain filename and path of the model file
[ model_path, model_name_wo_ext, model_ext ] = fileparts( model );
model_path = [ model_path, '/' ];

newtable = readtable(strcat(result_path, '/Fault_table.xls'));

load(constants_thresholds); % Parameters necessary to perform simulations of the system (user defined as a .mat file)

command = sprintf('load(''%s'')', constants_thresholds);
evalin('base', command);

fprintf('\n');

for p = 1 : height(FEL)
    block_num = table2array(FEL(p,1));
    model_copy_name_wo_ext = cell2mat(table2array(newtable(block_num,1)));
    % Load the system
    system = load_system([model_path, model_copy_name_wo_ext, model_ext]);

    set_param(system, 'AutoInsertRateTranBlk','on');
    ft = table2array(newtable(block_num,4));
    
    % fv = cell2mat(table2array(FEL(p,2))); % Fault value
    % Fault value
    if isa(table2array(FEL(p,2)),'cell')
        fv = cell2mat(table2array(FEL(p,2)));
    elseif isa(table2array(FEL(p,2)),'double')
        fv = num2str(table2array(FEL(p,2)));
    end
    
    % Fault Occurence Time
    if isa(table2array(FEL(p,3)),'cell')
        fot = cell2mat(table2array(FEL(p,3)));
    elseif isa(table2array(FEL(p,3)),'double')
        fot = num2str(table2array(FEL(p,3)));
    end
    
    fe = cell2mat(table2array(FEL(p,4))); % Fault Effect : Infinite time/ Constant time
    
    %  % Fault Duration (if Fault Effect is 'Constant time')
    if isa(table2array(FEL(p,5)),'cell')
        fd = cell2mat(table2array(FEL(p,5)));
    elseif isa(table2array(FEL(p,5)),'double')
        fd = num2str(table2array(FEL(p,5)));
    end
    
    % fo = cell2mat(table2array(FEL(p,6))); % Fault Operator Number (if Fault type is ROR [Relational Operator Replacement], LOR [Logical Operator Replacement], ASR [Arithmetic Sign Replacement])
    fo = (table2array(FEL(p,6))); % Fault Operator Number (if Fault type is ROR [Relational Operator Replacement], LOR [Logical Operator Replacement], ASR [Arithmetic Sign Replacement])
    if isnumeric(fo) == 1
        fo = num2str(fo);
    end
    
    % Read the block information from the generated fault table
    % First read the details of the corresponding fault injector block
    FIBName = cell2mat(table2array(newtable(block_num,2)));
    Parentblock = table2array(newtable(block_num,3));
    hh = Parentblock{1,1};
    Fullpath = strcat(hh, '/', FIBName);
    
    status = get_param(Fullpath, 'FIEnableFlag');
    
    
    % Then turn on the fault injector block
    disp([ 'Turning on the block ', FIBName, ' and updating parameters.' ]);
    
    set_param(Fullpath, 'FIEnableFlag', "on");
    set_param(strcat(Fullpath, '/Enable_flag'), 'Value', "1");
    
    set_param(Fullpath, 'FaultOccurenceTime', fot); % Set the fault occurence time
    
    if fe == "Infinite time"
       set_param(strcat(Fullpath, '/Step'), 'Time', fot);
    else
       set_param(strcat(Fullpath, '/Pulse Generator'), 'PhaseDelay', fot);
       set_param(strcat(Fullpath, '/Pulse Generator'), 'PulseWidth', fd);
    end
    
    set_param(Fullpath, 'FaultEffect', fe); % Set the fault effect
    if fe == "Constant time"
        set_param(Fullpath, 'FaultDuration', fd); % Set the fault duration
    end
    if ft == "Bias/Offset" || ft == "Noise" || ft == "Package Drop"
        set_param(Fullpath, 'FaultValue', fv);
    end
    
    if ft == "ROR" || ft == "LOR" || ft == "ASR"
        set_param(Fullpath, 'OperatorNum', fo);
        set_param(strcat(Fullpath, '/Operator Num'), 'Value', fo);
    end
    

    save_system('FInjLib');
    
    % save the changes made in the model
    save_system(system,[],'OverwriteIfChangedOnDisk',true);
    set_param(Fullpath,'LinkStatus','none');
    save_system(system,[],'OverwriteIfChangedOnDisk',true);
    close_system(system);
    disp('Model successfully updated with selected faults and fault parameters!!!')
end

fprintf('\n');
disp('All selected models successfully updated (with selected faults and fault parameters)!!!');

end


