function [fault_table] = replace_suiteMULTI(model_path,model_ext, k, system, level_final, sig_name1, model_name_wo_ext, nb_lines1, source_port_data_type1, SRC1, SRC_info1, DST_info1, SRCPnum1, DSTPNum1, A_src1, A_dst1, block_inform1, SRCBName1, DSTBName1, SRCInfo1, DSTInfo1, ft, ......
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


%% Initiate the process of fault injection
len = 1;
lengthkr = 1;
while len <= lengthkr
    
    %% First create a copy of the original model
    
    % First check if a copy exists, if a copy exists, then
    % delete it and create a new copy
    
    model_copy_name_wo_ext = [ model_name_wo_ext, '_', num2str(k)];
    model_name = strcat(model_name_wo_ext, model_ext);
    model_new_name = strcat(model_name_wo_ext,'_', num2str(k));
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
    %     close_system(system);
    %     disp([ 'Closing the original model ', model_name_wo_ext, ' .' ]);
    
    %% Load the new copied model
    disp([ 'Loading the new model ', model_copy_name_wo_ext, '...' ]);
    system1 = load_system([ model_path, model_copy_name_wo_ext, model_ext ]);
    % disp(['Model ', model_name_wo_ext, ' loaded.']);
    
    fprintf('\n');
    al = strsplit( level_final , '/' );
    kl = al(2:end);
    bl = strjoin(kl,'/');
    level_final = strcat(model_copy_name_wo_ext,'/',bl);
    
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
    %% Now start injecting fault in the new model
    disp([ 'Block replacement (Mutation) in ', model_copy_name_wo_ext, ' at ', level_final ,' ....']);
    
    % Save the information of the faulty model and the injected fault parameters
    My_faulty_model{k,1} = model_copy_name_wo_ext;
    Fault_Type{k,1} = ft;
    
    % Check which block to be used
    if ft == "ROR"
        My_faulty_block{k,1} = strcat('RelationalOperator_Mutation', num2str(k));
    elseif  ft == "LOR"
        My_faulty_block{k,1} = strcat('LogicalOperator_Mutation', num2str(k));
    elseif  ft == "S2P"
        My_faulty_block{k,1} = strcat('Sum2Prod_Mutation', num2str(k));
    elseif  ft == "P2S"
        My_faulty_block{k,1} = strcat('Prod2Sum_Mutation', num2str(k));
    elseif  ft == "ASR"
        My_faulty_block{k,1} = strcat('ArSignReplOperator', num2str(k));
    end
    
    % Save the source and destination information
    SRC_details{k,1} = {};
    SRC_port_number{k,1} = {};
    DST_details{k,1} = {};
    DST_port_number{k,1} = {};
    Parentblock{k,1} = level_final;
    
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
    v = len;
    handle = getSimulinkBlockHandle(x(v));
    set_param(handle, 'Name', strcat(My_faulty_block{k,1}));
    
    
    % Restore the default operator/inputs in each faulty block
    
%     if ft == "ROR"
%         block_inf = strcat(level_final, '/', My_faulty_block{k,1});
%         set_param(block_inf,'LinkStatus', 'None');
%         set_param(strcat(block_inf,'/','RelationalOperator_Default'), 'Operator', orig_oper{len});
%         set_param(block_inf,'LinkStatus', 'Propagate');
%         save_system('FInjLib');
%         
%     elseif ft == "LOR"
%         block_inf = strcat(level_final, '/', My_faulty_block{k,1});
%         set_param(block_inf,'LinkStatus', 'None');
%         set_param(strcat(block_inf,'/','LogicalOperator_Default'), 'Operator', orig_oper{len});
%         set_param(block_inf,'LinkStatus', 'Propagate');
%         save_system('FInjLib');
%         
%     elseif ft == "S2P"
%         block_inf = strcat(level_final, '/', My_faulty_block{k,1});
%         set_param(block_inf,'LinkStatus', 'None');
%         set_param(strcat(block_inf,'/','Default_Sum'), 'Inputs', orig_oper{len});
%         set_param(block_inf,'LinkStatus', 'Propagate');
%         save_system('FInjLib');
%         
%     elseif ft == "ASR"
%         block_inf = strcat(level_final, '/', My_faulty_block{k,1});
%         set_param(block_inf,'LinkStatus', 'None');
%         set_param(strcat(block_inf,'/','Sum_Default'), 'Inputs', orig_oper{len});
%         set_param(block_inf,'LinkStatus', 'Propagate');
%         save_system('FInjLib');
%     end
    
    if ft == "ROR"
        
        block_inf = strcat(level_final, '/', My_faulty_block{k,1});
        set_param(block_inf,'LinkStatus', 'None');
        set_param(strcat(block_inf,'/','RelationalOperator_Default'), 'Operator', orig_oper{len});
        set_param(block_inf,'LinkStatus', 'Propagate');
        
        if length(kr) >= 2
            for i = 1:length(kr)
                if ~isequal(v,i)
                    set_param(kr{i,1},'LinkStatus', 'None');
                    set_param(strcat(kr{i,1},'/','RelationalOperator_Default'), 'Operator', orig_oper{i});
                    set_param(kr{i,1},'LinkStatus', 'Propagate');
                end
            end
%         else
%             set_param(kr{2,1},'LinkStatus', 'None');
%             set_param(strcat(kr{2,1},'/','RelationalOperator_Default'), 'Operator', orig_oper{2});
%             set_param(kr{2,1},'LinkStatus', 'Propagate');
        end
        save_system('FInjLib');
        
    elseif ft == "LOR"
        block_inf = strcat(level_final, '/', My_faulty_block{k,1});
        set_param(block_inf,'LinkStatus', 'None');
        set_param(strcat(block_inf,'/','LogicalOperator_Default'), 'Operator', orig_oper{len});
        set_param(block_inf,'LinkStatus', 'Propagate');
        
        if length(kr) >= 2
            for i = 1:length(kr)
                if ~isequal(v,i)
                    set_param(kr{i,1},'LinkStatus', 'None');
                    set_param(strcat(kr{i,1},'/','LogicalOperator_Default'), 'Operator', orig_oper{i});
                    set_param(kr{i,1},'LinkStatus', 'Propagate');
                end
            end
%         else
%             set_param(kr{2,1},'LinkStatus', 'None');
%             set_param(strcat(kr{2,1},'/','LogicalOperator_Default'), 'Operator', orig_oper{2});
%             set_param(kr{2,1},'LinkStatus', 'Propagate');
        end
        save_system('FInjLib');
        
    elseif ft == "S2P"
        block_inf = strcat(level_final, '/', My_faulty_block{k,1});
        set_param(block_inf,'LinkStatus', 'None');
        set_param(strcat(block_inf,'/','Default_Sum'), 'Inputs', orig_oper{len});
        set_param(block_inf,'LinkStatus', 'Propagate');
        
        if length(kr) >= 2
            for i = 1:length(kr)
                if ~isequal(v,i)
                    set_param(kr{i,1},'LinkStatus', 'None');
                    set_param(strcat(kr{i,1},'/','Default_Sum'), 'Inputs', orig_oper{i});
                    set_param(kr{i,1},'LinkStatus', 'Propagate');
                end
            end
%         else
%             set_param(kr{2,1},'LinkStatus', 'None');
%             set_param(strcat(kr{2,1},'/','Default_Sum'), 'Inputs', orig_oper{2});
%             set_param(kr{2,1},'LinkStatus', 'Propagate');
        end
        save_system('FInjLib');
        
    elseif ft == "ASR"
        block_inf = strcat(level_final, '/', My_faulty_block{k,1});
        set_param(block_inf,'LinkStatus', 'None');
        set_param(strcat(block_inf,'/','Sum_Default'), 'Inputs', orig_oper{len});
        set_param(block_inf,'LinkStatus', 'Propagate');
        
        if length(kr) >= 2
            for i = 1:length(kr)
                if ~isequal(v,i)
                    set_param(kr{i,1},'LinkStatus', 'None');
                    set_param(strcat(kr{i,1},'/','Sum_Default'), 'Inputs', orig_oper{i});
                    set_param(kr{i,1},'LinkStatus', 'Propagate');
                end
            end
%         else
%             set_param(kr{2,1},'LinkStatus', 'None');
%             set_param(strcat(kr{2,1},'/','Sum_Default'), 'Inputs', orig_oper{2});
%             set_param(kr{2,1},'LinkStatus', 'Propagate');
        end
        save_system('FInjLib');
    end
    
    set_param(system1, 'AutoInsertRateTranBlk','on');
    save_system(system1,[],'OverwriteIfChangedOnDisk',true);
    Simulink.BlockDiagram.arrangeSystem(level_final);
    if ParentBlock ~= "NA"
        Simulink.BlockDiagram.arrangeSystem(strcat(level_final,'/',ParentBlock));
    end
    save_system(system1,[],'OverwriteIfChangedOnDisk',true);
    close_system(system1); % close the faulty model
    
    lengthkr = length(kr);
    len = len + 1;
    k = k + 1;
end

% Save the table consisting of the name of the faulty model, the name of the fault injection block, the Parent block, Fault Type, Fault Value,
% Fault Event, Fault Event Value, Fault Effect, Fault Effect Value, Source block information and Destination Block Information
fault_table = table(My_faulty_model, My_faulty_block, Parentblock, Fault_Type, SRC_details, DST_details, SRC_port_number, DST_port_number);


