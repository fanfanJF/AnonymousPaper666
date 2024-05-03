clear;
dir_curr=fileparts(mfilename('fullpath'));
cd(dir_curr);


model_name='basictwotanks';  %basictwotanks tustinintegrator fsm AECS
file_json=[dir_curr,'\',model_name, '_mut.json'];
file_slx=[dir_curr,'\',model_name,'.slx'];
fun_update_all(file_slx,file_json,dir_curr);

function fun_update_all(file_slx,file_json,dir_curr)
[~,model_name,~]=fileparts(file_slx);
dir_folder=[dir_curr,'\',model_name];
if ~isequal(exist(dir_folder,'dir'),7)
    mkdir(dir_folder);
end

[targetSID_v,propertyName_v,propertyValue_v,original_propertyValue_v]=fun_parse(file_json);
n=length(targetSID_v);
j=1;
for i=1:n
    file_slx_new=[dir_folder,'\',model_name,'_',num2str(j+45),'.slx'];
    copyfile(file_slx,file_slx_new);
    try
        fun_update_single(file_slx_new,targetSID_v{i},propertyName_v{i},propertyValue_v{i},original_propertyValue_v{i});
        j=j+1;
    catch err
        delete(file_slx_new); 
    end
end
end

function [targetSID_v,propertyName_v,propertyValue_v,original_propertyValue_v]=fun_parse(file_json)
fh=fopen(file_json,'r');
i=1;
targetSID_v=[];
propertyName_v=[];
propertyValue_v=[];
original_propertyValue_v=[];
while 1>0
    s0=fgetl(fh);
    if s0<0
        break;
    end
    %s0=strrep(s0,'Infinity','"Infinity"');
    s=eval(s0);

    original_val=s(end);
    m_sid=s(end-1);
    m_name=s(end-2);
    s_new=s(1:end-3);
    for k=1:length(s_new)
        targetSID_v{i}=m_sid;
        propertyName_v{i}=m_name;
        propertyValue_v{i}=s_new(k);
        original_propertyValue_v{i}=original_val;
        i=i+1;
    end

end
fclose(fh);
end

function fun_update_single(file_slx,targetSID,propertyName,propertyValue,original_propertyValue)
persistent updatedBlocks;
if isempty(updatedBlocks)
    updatedBlocks = {};
end

[~,modelName,~]=fileparts(file_slx);
% Load the Simulink model
load_system(file_slx);
% Find the block with the matching SID
blocks = find_system(modelName, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Type', 'Block');
blockPath = '';
for i = 1:length(blocks)
    blockSID = strrep(Simulink.ID.getSID(blocks{i}),[modelName,':'],'');
    if strcmp(blockSID, targetSID)
        blockPath = blocks{i};
        break;
    end
end
% Check if the block with the specified SID is found

if isempty(blockPath)
    disp('Block with the specified SID not found.');
else
    % Update block properties
    set_param(blockPath, propertyName, propertyValue);
    try
        set_param(blockPath, propertyName, propertyValue);

        save_system(modelName);
        updatedBlocks{end+1} = {propertyName, propertyValue,original_propertyValue,targetSID};

    catch ME
        disp(['Error while setting the property: ', ME.message]);
    end
    close_system(modelName);



data = struct('propertyName', {}, 'propertyValue', {});


for i = 1:length(updatedBlocks)
    data(i).propertyName = updatedBlocks{i}{1};
    data(i).propertyValue = updatedBlocks{i}{2};
    data(i).original_propertyValue = updatedBlocks{i}{3};
    data(i).targetSID = updatedBlocks{i}{4};
   
end

%%%%%%%%%%
filename = 'AECS_updatedBlocks.json';  
disp(filename)
fid = fopen(filename, 'w');
if fid == -1, error('Cannot create JSON file'); end
for i = 1:length(data)
    fprintf(fid, '%s\n', jsonencode(data(i)));
end
fclose(fid);
%disp('total num of mutations:')
%disp(length(blocks))
%disp('total num of generated mutations:')
%disp(length(updatedBlocks))

end
end


