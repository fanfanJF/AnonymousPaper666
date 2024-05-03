function [fault_table] = fault_suite(k, system, level_final, sig_name, model_copy_name_wo_ext, nb_lines, source_port_data_type, SRC, SRC_info, DST_info, SRCPnum, DSTPNum, A_src, A_dst, block_inform, SRCBName, DSTBName, SRCInfo, DSTInfo, ft,  ......
    constants_thresholds, ParentBlock, Src_or_InportName, Dst_or_OutportName)

% Fault injection function

%% PROGRAM: Fault Injection experiments in Simulink Model
% Creating a new Faulty model with faults injected in all lines specified by level_final, ParentBlock, Src_or_InportName, Dst_or_OutportName
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


while i <= nb_lines
    
    condition =  length(DSTInfo{i}) == 1 ;
    
    if strcmp('NA', ParentBlock) && strcmp('NA', Src_or_InportName) && strcmp('NA', Dst_or_OutportName)
        condition_final = condition;
    end
    
    if ~strcmp('NA', ParentBlock)
        condition_final = condition && contains(SRCBName{i}, ParentBlock);
    end
    if ~strcmp('NA', Src_or_InportName)
        condition_final = condition &&  isequal(A_src{i}, Src_or_InportName);
    end
    if ~strcmp('NA', Dst_or_OutportName)
        condition_final = condition &&  isequal(A_dst{i}, Dst_or_OutportName);
    end
    
    condition_final = condition_final && contains(block_inform{i}, level_final);
    
    if ft == "Noise" || ft == "Bias/Offset" || ft == "Absolute" || ft == "Negate"
        condition_final = condition_final && isequal(source_port_data_type{i}, 'double'); % for "Noise"/"Bias/Offset"/"Absolute/"Negate" : inject faults only in signals of type "double"
    end
    
    %% Initiate the process of fault injection
    if condition_final
        
        %% Now start injecting fault in the new model
        disp([ 'Injecting fault in ', model_copy_name_wo_ext, '...line', num2str(k) ]);
        
        % Save the information of the faulty model and the injected fault parameters
        My_faulty_model{r,1} = model_copy_name_wo_ext;
        Fault_Type{r,1} = ft;
        
        
        % Check which block to be used
        if ft == "Noise"
            My_faulty_block{r,1} = strcat('Noise', num2str(k));
        elseif ft == "Negate"
            My_faulty_block{r,1} = strcat('Negate', num2str(k));
        elseif ft == "Invert"
            My_faulty_block{r,1} = strcat('Inverter', num2str(k));
        elseif ft == "Absolute"
            My_faulty_block{r,1} = strcat('Absolute', num2str(k));
        elseif ft == "Stuck-at 0"
            My_faulty_block{r,1} = strcat('Zerofault', num2str(k));
        elseif  ft == "Bias/Offset"
            My_faulty_block{r,1} = strcat('Offset', num2str(k));
        elseif ft == "Stuck-at"
            My_faulty_block{r,1} = strcat('Stuck-at', num2str(k));
        elseif ft == "Time Delay"
            My_faulty_block{r,1} = strcat('TimeDelay', num2str(k));
        elseif  ft == "Bit Flip"
            My_faulty_block{r,1} = strcat('BitFlip', num2str(k));
        elseif ft == "Package Drop"
            My_faulty_block{r,1} = strcat('PackageDrop', num2str(k));
        end
        
        %% For faults on lines, do the following
        
        % Save the source and destination information
            SRC_details{r,1} = SRC_info{i,1};
            SRC_port_number{r,1} = SRCPnum{i,1};
            DST_details{r,1} = DST_info{i,1};
            DST_port_number{r,1} = DSTPNum{i,1};
            Parentblock{r,1} = block_inform{i,1};
            
            %% First delete the line
            
            SPH = get_param(SRCBName{i},'PortHandles'); % for Source output port handle
            DPH = get_param(DSTBName{i},'PortHandles'); % for Destination input port handles
            
            if length(DPH) == 1
                if (length(DPH.Inport) < str2double(DSTPNum{i,1}) &&  length(DPH.Enable) == 1)
                    delete_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), DPH.Enable); % Connecting FI to Destn
                else
                    delete_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), DPH.Inport(str2double(DSTPNum{i,1}))); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
                end
            else
                
                for p = 1:length(dst_port_handle)
                    if (length(DPH{p,1}.Inport) < str2double(DSTPNum{i,1}(p)) &&  length(DPH{p,1}.Enable) == 1)
                        delete_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), DPH{p,1}.Enable); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
                    else
                        delete_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), DPH{p,1}.Inport(str2double(DSTPNum{i,1}(p)))); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
                    end
                end
            end
            
            % Then add the Fault Injection Block (FIB) into the copied model
            if ft == "Noise"
                final = strcat(block_inform{i}, '/Noise', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/Noise', final, 'CopyOption','duplicate');
                
            elseif ft == "Bias/Offset"
                final = strcat(block_inform{i}, '/Offset', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/Offset', final);%, 'CopyOption','duplicate');
                
            elseif ft == "Negate"
                final = strcat(block_inform{i}, '/Negate', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/Negate', final);%, 'CopyOption','duplicate');
                
            elseif ft == "Invert"
                final = strcat(block_inform{i}, '/Inverter', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/Inverter', final);%, 'CopyOption','duplicate');
                
            elseif ft == "Absolute"
                final = strcat(block_inform{i}, '/Absolute', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/Absolute', final);%, 'CopyOption','duplicate');
                
            elseif ft == "Stuck-at 0"
                final = strcat(block_inform{i}, '/Zerofault', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/Zerofault', final);%, 'CopyOption','duplicate');
                
            elseif ft == "Stuck-at"
                final = strcat(block_inform{i}, '/Stuck-at', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/Stuck-at', final);%, 'CopyOption','duplicate');
                
            elseif ft == "Time Delay"
                final = strcat(block_inform{i}, '/TimeDelay', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/TimeDelay', final);%, 'CopyOption','duplicate');
                
            elseif ft == "Bit Flip"
                final = strcat(block_inform{i}, '/BitFlip', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/BitFlip', final);%, 'CopyOption','duplicate');
                
            elseif ft == "Package Drop"
                final = strcat(block_inform{i}, '/PackageDrop', num2str(k)); % Info of destination with FIB
                add_block('FInjLib/PackageDrop', final);%, 'CopyOption','duplicate');
                
            end
            
            
            % Now add the line (Get the port handles and connect the ports using 'add_line')
            % We connect SP (Source port) to FIBP (Fault injection block port)
            % to DP (Destination port)
            FIBPH = get_param(final,'PortHandles'); % for FIB input and output port handles
            
            add_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), FIBPH.Inport, 'autorouting','on'); % Connecting Source to FI
            set_param(SPH.Outport(str2double(SRCPnum{i,1})),'DataLogging','off'); % Turn off the data log since we are now adding the FIB, the ouput of FIB is our desired signal
            
            if length(DPH) == 1
                if (length(DPH.Inport) < str2double(DSTPNum{i,1}) &&  length(DPH.Enable) == 1)
                    add_line(block_inform{i}, FIBPH.Outport, DPH.Enable, 'autorouting','on'); % Connecting FI to Destn
                else
                    add_line(block_inform{i}, FIBPH.Outport, DPH.Inport(str2double(DSTPNum{i,1})), 'autorouting','on'); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
                end
            else
                
                for p = 1:length(dst_port_handle)
                    if (length(DPH{p,1}.Inport) < str2double(DSTPNum{i,1}(p)) &&  length(DPH{p,1}.Enable) == 1)
                        add_line(block_inform{i}, FIBPH.Outport, DPH{p,1}.Enable, 'autorouting','on'); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
                    else
                        add_line(block_inform{i}, FIBPH.Outport, DPH{p,1}.Inport(str2double(DSTPNum{i,1}(p))), 'autorouting','on'); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
                    end
                end
            end
            
            set_param(SPH.Outport(str2double(SRCPnum{i,1})),'DataLogging','off'); % Turn off the data log since we are now adding the FIB, the ouput of FIB is our desired signal
            
            
            % Retain the same logging name of the signal from FIB to Destination block
            set_param(FIBPH.Outport,'DataLogging','on');
            set_param(FIBPH.Outport, 'DataLoggingNameMode', 'Custom');
            set_param(FIBPH.Outport, 'DataLoggingName', sig_name{i});
%             Simulink.BlockDiagram.arrangeSystem(block_inform{i});
            set_param(system, 'AutoInsertRateTranBlk','on');
            save_system(system,[],'OverwriteIfChangedOnDisk',true);
            k = k + 1;
            i = i + 1;
            r = r + 1;
            
    else
        count = length(DSTInfo{i});
        i = i + count;
        
    end
    
end
% Simulink.BlockDiagram.arrangeSystem(level_final);
% if ParentBlock ~= "NA"
%     Simulink.BlockDiagram.arrangeSystem(strcat(level_final,'/',ParentBlock));
% end
% Save the table consisting of the name of the faulty model, the name of the fault injection block, the Parent block, Fault Type, Fault Value,
% Fault Event, Fault Event Value, Fault Effect, Fault Effect Value, Source block information and Destination Block Information
fault_table = table(My_faulty_model, My_faulty_block, Parentblock, Fault_Type, SRC_details, DST_details, SRC_port_number, DST_port_number);


