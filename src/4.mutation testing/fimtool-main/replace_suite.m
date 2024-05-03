function [fault_table] = replace_suite(k, system, level_final, sig_name, model_copy_name_wo_ext, nb_lines, source_port_data_type, SRC, SRC_info, DST_info, SRCPnum, DSTPNum, A_src,  A_dst, block_inform, SRCBName, DSTBName, SRCInfo, DSTInfo, ft, ......
    constants_thresholds, ParentBlock, Src_or_InportName, Dst_or_OutportName)

% Mutant generation function

%% PROGRAM: Fault Injection experiments in Simulink Model
% Creating a new Faulty model by replacing blocks specified by level_final and the type of mutation
% Created: 24-11-2021
% Author: Drishti Yadav

load(constants_thresholds); % Parameters necessary to perform simulations of the system (user defined as a .mat file)

%% Loop for all signals

My_faulty_model = {};
My_faulty_block = {};
Fault_Type = {};
SRC_details = {};
SRC_port_number = {};
DST_details = {};
DST_port_number = {};
Parentblock = {};

r = 1;
i = 1;

if ft == "S2P" || ft == "ASR"
    kr =  find_system(level_final,'BlockType','Sum');
elseif ft == "ROR"
    kr =  find_system(level_final,'BlockType','RelationalOperator');
elseif ft == "LOR"
    kr =  find_system(level_final,'BlockType','LogicalOperator');
elseif ft == "P2S"
    kr =  find_system(level_final,'BlockType','Product');
end

% Save operator info only if fault is ROR/LOR/S2P/ASR
% Fetch the original operator in the corresponding block of the model
for i = 1: length(kr)
    if ft == "ROR"
        orig_oper{i} =  get_param(kr{i}, 'Operator');
        a = 'FInjLib/RelationalOperator_Mutation';
        save_system('FInjLib');
    elseif ft == "LOR"
        orig_oper{i} =  get_param(kr{i}, 'Operator');
        a = 'FInjLib/LogicalOperator_Mutation';
        save_system('FInjLib');
    elseif ft == "S2P"
        orig_opera =  get_param(kr{i}, 'Inputs');
        orig_oper{i} = orig_opera(~ismember( orig_opera,'|'));
        a = 'FInjLib/Sum2Prod_Mutation';
        save_system('FInjLib');
    elseif ft == "ASR"
        orig_opera =  get_param(kr{i}, 'Inputs');
        orig_oper{i} = orig_opera(~ismember( orig_opera,'|'));
        a = 'FInjLib/ArSignReplOperator';
        save_system('FInjLib');
    elseif ft == "P2S"
        a = 'FInjLib/Prod2Sum_Mutation';
        save_system('FInjLib');
    end
end

%% Initiate the process of fault injection

%% Now start injecting fault in the new model
disp([ 'Block replacement (Mutation) in ', model_copy_name_wo_ext, ' at ', level_final ,' ....']);

while r <= length(kr)
    % Save the information of the faulty model and the injected fault parameters
    My_faulty_model{r,1} = model_copy_name_wo_ext;
    Fault_Type{r,1} = ft;
    
    % Check which block to be used
    if ft == "ROR"
        My_faulty_block{r,1} = strcat('RelationalOperator_Mutation', num2str(k));
    elseif  ft == "LOR"
        My_faulty_block{r,1} = strcat('LogicalOperator_Mutation', num2str(k));
    elseif  ft == "S2P"
        My_faulty_block{r,1} = strcat('Sum2Prod_Mutation', num2str(k));
    elseif  ft == "P2S"
        My_faulty_block{r,1} = strcat('Prod2Sum_Mutation', num2str(k));
    elseif  ft == "ASR"
        My_faulty_block{r,1} = strcat('ArSignReplOperator', num2str(k));
    end
    
    % Save the source and destination information
    SRC_details{r,1} = {};
    SRC_port_number{r,1} = {};
    DST_details{r,1} = {};
    DST_port_number{r,1} = {};
    Parentblock{r,1} = level_final;
    
    k = k + 1;
    i = i + 1;
    r = r + 1;
    
end
if ft == "S2P" || ft == "ASR"
    x = replace_block(level_final, 'Sum', a, 'noprompt');
elseif ft == "ROR"
    x = replace_block(level_final, 'RelationalOperator', a, 'noprompt');
elseif ft == "LOR"
    x = replace_block(level_final, 'LogicalOperator', a, 'noprompt');
elseif ft == "P2S"
    x = replace_block(level_final, 'Product', a, 'noprompt');
end

% Rename the inserted blocks according to My_faulty_block
r = 1;
for v = 1 : length(x)
    handle = getSimulinkBlockHandle(x(v));
    set_param(handle, 'Name', strcat(My_faulty_block{r,1}));
    r = r + 1;
end

% Restore the default operator/inputs in each faulty block
for r = 1 : length(kr)
    if ft == "ROR"
        block_inf = strcat(level_final, '/', My_faulty_block{r,1});
        set_param(block_inf,'LinkStatus', 'None');
        set_param(strcat(block_inf,'/','RelationalOperator_Default'), 'Operator', orig_oper{r});
        set_param(block_inf,'LinkStatus', 'Propagate');
        save_system('FInjLib');
        
    elseif ft == "LOR"
        block_inf = strcat(level_final, '/', My_faulty_block{r,1});
        set_param(block_inf,'LinkStatus', 'None');
        set_param(strcat(block_inf,'/','LogicalOperator_Default'), 'Operator', orig_oper{r});
        set_param(block_inf,'LinkStatus', 'Propagate');
        save_system('FInjLib');
        
    elseif ft == "S2P"
        block_inf = strcat(level_final, '/', My_faulty_block{r,1});
        set_param(block_inf,'LinkStatus', 'None');
        set_param(strcat(block_inf,'/','Default_Sum'), 'Inputs', orig_oper{r});
        set_param(block_inf,'LinkStatus', 'Propagate');
        save_system('FInjLib');
        
    elseif ft == "ASR"
        block_inf = strcat(level_final, '/', My_faulty_block{r,1});
        set_param(block_inf,'LinkStatus', 'None');
        set_param(strcat(block_inf,'/','Sum_Default'), 'Inputs', orig_oper{r});
        set_param(block_inf,'LinkStatus', 'Propagate');
        save_system('FInjLib');
    end
end

set_param(system, 'AutoInsertRateTranBlk','on');
save_system(system,[],'OverwriteIfChangedOnDisk',true);
Simulink.BlockDiagram.arrangeSystem(level_final);
if ParentBlock ~= "NA"
    Simulink.BlockDiagram.arrangeSystem(strcat(level_final,'/',ParentBlock));
end

% Save the table consisting of the name of the faulty model, the name of the fault injection block, the Parent block, Fault Type, Fault Value,
% Fault Event, Fault Event Value, Fault Effect, Fault Effect Value, Source block information and Destination Block Information
fault_table = table(My_faulty_model, My_faulty_block, Parentblock, Fault_Type, SRC_details, DST_details, SRC_port_number, DST_port_number);


