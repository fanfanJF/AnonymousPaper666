function [fault_table] = fault_suiteMULTI(model_path,model_ext, k, system, level_final, sig_name1, model_name_wo_ext, nb_lines1, source_port_data_type1, SRC1, SRC_info1, DST_info1, SRCPnum1, DSTPNum1, A_src1, A_dst1, block_inform1, SRCBName1, DSTBName1, SRCInfo1, DSTInfo1, ft, ......
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


while i <= nb_lines1
    
    condition =  length(DSTInfo1{i}) == 1 ;
    
    if strcmp('NA', ParentBlock) && strcmp('NA', Src_or_InportName) && strcmp('NA', Dst_or_OutportName)
        condition_final = condition;
    end
    
    if ~strcmp('NA', ParentBlock)
        condition_final = condition && contains(SRCBName1{i}, ParentBlock);
    end
    if ~strcmp('NA', Src_or_InportName)
        condition_final = condition &&  isequal(A_src1{i}, Src_or_InportName);
    end
    if ~strcmp('NA', Dst_or_OutportName)
        condition_final = condition &&  isequal(A_dst1{i}, Dst_or_OutportName);
    end
    
    condition_final = condition_final && contains(block_inform1{i}, level_final);
    
    if ft == "Noise" || ft == "Bias/Offset" || ft == "Absolute" || ft == "Negate"
        condition_final = condition_final && isequal(source_port_data_type1{i}, 'double'); % for "Noise"/"Bias/Offset"/"Absolute/"Negate" : inject faults only in signals of type "double"
    end
    
    %% Initiate the process of fault injection
    if condition_final
        
        %% First create a copy of the original model
        
        % First check if a copy exists, if a copy exists, then
        % delete it and create a new copy
        
        %model_copy_name_wo_ext = [ model_name_wo_ext, '_copy'];
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
        close_system(system);
        disp([ 'Closing the original model ', model_name_wo_ext, ' .' ]);
        
        %% Load the new copied model
        disp([ 'Loading the new model ', model_copy_name_wo_ext, '...' ]);
        system = load_system([ model_path, model_copy_name_wo_ext, model_ext ]);
        % disp(['Model ', model_name_wo_ext, ' loaded.']);
        
        fprintf('\n');
        
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
        %% Information
        line_handles = find_system(system,'FindAll','on','type','line');
        
        block_handles = find_system(system, 'FindAll', 'on', 'Type', 'Block');
        
        nb_lines = length(line_handles);
        
        for i1 = 1 : nb_lines
            line_handle = line_handles(i1);
            source_port_handle = get_param(line_handle, 'SrcPortHandle');
            dst_port_handle = get_param(line_handle, 'DstPortHandle');
            source_block_handle = get_param(line_handle, 'SrcBlockHandle');
            dst_block_handle = get_param(line_handle, 'DstBlockHandle');
            sig_name{i1} = get_param(source_port_handle, 'DataLoggingName');
            
            srcblockname{i1} = get_param(source_block_handle(1),'Name');
            S_src{i1} = srcblockname{i1};
            Src_name{i1,1} = srcblockname{i1};
            A_src{i1} = S_src{i1}(isstrprop(S_src{i1},'alpha'));
            
            dstblockname{i1} = get_param(dst_block_handle(1),'Name');
            S_dst{i1} = dstblockname{i1};
            Dst_name{i1,1} = dstblockname{i1};
            A_dst{i1} = S_dst{i1}(isstrprop(S_dst{i1},'alpha'));
            
            block_info =  get_param(line_handle, 'Parent');
            block_inform{i1,1} = convertCharsToStrings(block_info);
            
            src_block_name = get_param(source_port_handle, 'Parent');
            SRCBName{i1} = convertCharsToStrings(src_block_name);
            dst_block_name = get_param(dst_port_handle, 'Parent');
            DSTBName{i1} = convertCharsToStrings(dst_block_name);
            
            SPName{i1} = get_param(source_port_handle, 'name');
            DPName{i1} = get_param(dst_port_handle, 'name');
            
            % Obtain the source and destination block info
            Src_info = getfullname(get(line_handle,'SrcBlockHandle'));
            SRC_info{i1,1} = convertCharsToStrings(Src_info);
            Dst_info = getfullname(get(line_handle,'DstBlockHandle'));
            
            if isa(Dst_info,'cell')
                DST_info{i1,1} = convertCharsToStrings(Dst_info(1));
            else
                DST_info{i1,1} = convertCharsToStrings(Dst_info);
            end
            
            hblkSrc = get_param(line_handle,'SrcBlockHandle');
            hblkDst = get_param(line_handle,'DstBlockHandle');
            
            % Fetch the names of the source and destination
            Src = get_param(hblkSrc,'Name');
            SRC{i1} = convertCharsToStrings(Src);
            Dst = get_param(hblkDst,'Name');
            DST{i1} = convertCharsToStrings(Dst_info);
            
            %% Fetching port number info for Src and Dst
            src_port_number = num2str(get_param(source_port_handle, 'PortNumber'));
            SRCPnum{i1,1} = convertCharsToStrings(src_port_number);
            
            if length(dst_port_handle) > 1
                for p = 1:length(dst_port_handle)
                    dst_port_number(p) = num2str(get_param(dst_port_handle(p), 'PortNumber')); % This is the concatenated string of the port numbers of all the destination blocks
                end
            else
                dst_port_number = num2str(get_param(dst_port_handle, 'PortNumber'));
            end
            DSTPNum{i1,1} = convertCharsToStrings(dst_port_number(1));
            
            Src_full = strcat(Src, '/', src_port_number); % Name of the source along with port number
            SRCInfo{i1} = convertCharsToStrings(Src_full);
            Dst_full = strcat(Dst, '/', dst_port_number); % Name of the destination along with port number
            DSTInfo{i1} = convertCharsToStrings(Dst_full);
            
        end
        
%         if level_final == "NA"%isempty(level_final)
%             level_final1 = model_copy_name_wo_ext; % Level in the SUT
%         else
%             level_final1 = strcat(model_copy_name_wo_ext,'/',level_final); % Level in the SUT
%         end
        % Save the source and destination information
        SRC_details{r,1} = SRC_info{i,1};
        SRC_port_number{r,1} = SRCPnum{i,1};
        DST_details{r,1} = DST_info{i,1};
        DST_port_number{r,1} = DSTPNum{i,1};
        Parentblock{r,1} = block_inform{i,1};
        
        %% First delete the line
        delete_line(line_handles(i));
        SPH = get_param(SRCBName{i},'PortHandles'); % for Source output port handle
        DPH = get_param(DSTBName{i},'PortHandles'); % for Destination input port handles
        
%         if length(DPH) == 1
%             if (length(DPH.Inport) < str2double(DSTPNum{i,1}) &&  length(DPH.Enable) == 1)
%                 delete_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), DPH.Enable); % Connecting FI to Destn
%             else
%                 delete_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), DPH.Inport(str2double(DSTPNum{i,1}))); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
%             end
%         else
%             
%             for p = 1:length(dst_port_handle)
%                 if (length(DPH{p,1}.Inport) < str2double(DSTPNum{i,1}) &&  length(DPH{p,1}.Enable) == 1)
%                     delete_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), DPH{p,1}.Enable); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
%                 else
%                     delete_line(block_inform{i}, SPH.Outport(str2double(SRCPnum{i,1})), DPH{p,1}.Inport(str2double(DSTPNum{i,1}))); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
%                 end
%             end
%         end
        
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
                if (length(DPH{p,1}.Inport) < str2double(DSTPNum{i,1}) &&  length(DPH{p,1}.Enable) == 1)
                    add_line(block_inform{i}, FIBPH.Outport, DPH{p,1}.Enable, 'autorouting','on'); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
                else
                    add_line(block_inform{i}, FIBPH.Outport, DPH{p,1}.Inport(str2double(DSTPNum{i,1})), 'autorouting','on'); % Connecting FI to Destn DPH.Inport with number 'dst_port_number'
                end
            end
        end
        
        set_param(SPH.Outport(str2double(SRCPnum{i,1})),'DataLogging','off'); % Turn off the data log since we are now adding the FIB, the ouput of FIB is our desired signal
        
        
        % Retain the same logging name of the signal from FIB to Destination block
        set_param(FIBPH.Outport,'DataLogging','on');
        set_param(FIBPH.Outport, 'DataLoggingNameMode', 'Custom');
        set_param(FIBPH.Outport, 'DataLoggingName', sig_name{i});
        set_param(system, 'AutoInsertRateTranBlk','on');
        save_system(system,[],'OverwriteIfChangedOnDisk',true);
        k = k + 1;
        i = i + 1;
        r = r + 1;
%         Simulink.BlockDiagram.arrangeSystem(level_final1);
%         if ParentBlock ~= "NA"
%             Simulink.BlockDiagram.arrangeSystem(strcat(level_final1,'/',ParentBlock));
%         end
%         save_system(system);
        close_system(system); % close the faulty model (i.e., model with fault injected at 'sig_name')
        disp([ 'Fault Injection: Fault injected in ', model_copy_name_wo_ext, ' successfully...' ]);
        
        
    else
        count = length(DSTInfo1{i});
        i = i + count;
        
    end
 
    %% Load the original model again for injecting new fault
    
    system = load_system([model_path, model_name_wo_ext, model_ext]);
end

% Save the table consisting of the name of the faulty model, the name of the fault injection block, the Parent block, Fault Type, Fault Value,
% Fault Event, Fault Event Value, Fault Effect, Fault Effect Value, Source block information and Destination Block Information
fault_table = table(My_faulty_model, My_faulty_block, Parentblock, Fault_Type, SRC_details, DST_details, SRC_port_number, DST_port_number);


