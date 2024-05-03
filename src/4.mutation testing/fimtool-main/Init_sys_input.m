function [ model, constants_thresholds, fault_injector_folder, Mainfolder,  fault_list] = Init_sys_input(file_name)
% Function: Initialize system inputs
% Extracts file names inputs to system diagnostics (Model, Constants and thresholds, source folder information and fault info)
% Created:  24-11-2021
% Author:   Drishti Yadav

function_inputs = readtable( file_name, 'Delimiter', ',' );

% Function input files and parameters
model = [cell2mat(function_inputs.model)];
[ model_path, model_name_wo_ext, model_ext ] = fileparts( model ); 
model_name = model_name_wo_ext;

model_path = [ model_path, '/' ];

fault_injector_folder = [cell2mat(function_inputs.fault_injector_folder)];

constants_thresholds = [cell2mat(function_inputs.constants_thresholds)];

Mainfolder = [fault_injector_folder,'/', model_path ];

fault_list = cell2mat(function_inputs.fault_list);

fprintf('\n');
disp('Initialize_system_inputs.m: Initialized system inputs successfully');

end
