clc;


mutant_dir = "bert_muts";
mutants_list_ = dir(mutant_dir);
cd bert_muts;

mutants_list = [];
for i = 1:length(mutants_list_)
    if contains(mutants_list_(i).name, ".slx") && ~contains(mutants_list_(i).name, ".slxc")
        mutants_list = [mutants_list, string(mutants_list_(i).name)];
    end
end
mutants_list = erase(mutants_list, ".slx");
original_model = mutants_list(1);
mutants_list = mutants_list(2:end);
number_of_mutants = length(mutants_list);

killed_list = zeros(1, length(mutants_list));
third_column = [];
for i = 1:length(mutants_list) 
    third_column = [third_column ""];
end

% file3 = fopen('ATCS_input.json', 'w');
% N = 20;
% allData = cell(N, 1);
% 
% for m = 1:N
%     numSteps = 751;
%     throttle = 50 * rand(numSteps, 1) + 50;
%     brake = 2 * rand(numSteps, 1) - 1; 
%     currentData = struct();
%     currentData.throttle = throttle;
%     currentData.brake = brake; 
% 
%     allData{m} = currentData;
% end
% 
% input_jsonstr = jsonencode(allData);
% fprintf(file3, input_jsonstr);
% fclose(file3);
% 
cd ..;
inputs = fopen('ATCS_input.json', 'r');
rawData = fread(inputs, '*char')'; 
fclose(inputs);
testSuit = jsondecode(rawData);
cd bert_muts;


mutants_index = [1:number_of_mutants];
m = randi([1, length(mutants_index)]);
mutant = mutants_list(mutants_index(m));
disp(strcat(string(mutants_index(m)), "th mutant (", mutant, ") is picked randomly."));
tc_cnt = 1;


while ~isempty(mutants_index) & tc_cnt<=20 %loop on TSmain
    sampleTime = 0.04;
    numSteps = 751;
    time = sampleTime*(0:numSteps-1);
    time = time';
    throttle = testSuit(tc_cnt).throttle;
    Break = testSuit(tc_cnt).brake;
    throttle_simin_ = timeseries(throttle, time);
    break_simin_ = timeseries(Break, time);
    %run tests on the original model
    [output_org, fitness_org] = compute_ATCS(convertStringsToChars(original_model),throttle,Break,throttle_simin_,break_simin_); 
    
    %run tc* on the mutant(m)
    [output, fitness] = compute_ATCS(convertStringsToChars(mutant),throttle,Break,throttle_simin_,break_simin_);

    violate = false;
    for j = 1:length(fitness)
        if ~isequal(fitness_org{j},fitness{j})
            violate = true;
            break;
        end
    end
    %if ~isequal(cell2mat(output_org), cell2mat(output)) 
    if violate
        third_column(mutants_index(m)) = strcat(third_column(mutants_index(m)), ", tc_", string(tc_cnt));
        disp(strcat("tc_", string(tc_cnt), " killed mutant ", string(mutants_index(m))))
        killed_list(mutants_index(m)) = 1;
    end

    if killed_list(mutants_index(m))==1
        close_system(mutant, 0);
        %remove mutant(m)
        mutants_index = mutants_index(mutants_index ~= mutants_index(m));
        if ~isempty(mutants_index)
            %check if tc_i can kill other mutants
            m = randi([1, length(mutants_index)]);
            mutant = mutants_list(mutants_index(m));
            disp(strcat(string(mutants_index(m)), "th mutant (", mutant, ") is picked randomly."));
        end
    else
        disp(strcat("mutant ", string(mutants_index(m)), " is not killed with tc_",  string(tc_cnt),"."));
        tc_cnt = tc_cnt + 1;
        if tc_cnt > 20 && length(mutants_index)>1
            tc_cnt = 1;
            mutants_index = mutants_index(mutants_index ~= mutants_index(m));
            m = randi([1, length(mutants_index)]);
            mutant = mutants_list(mutants_index(m));
            disp(strcat(string(mutants_index(m)), "th mutant (", mutant, ") is picked randomly."));
        end
    end %if killed_list(m) == 1

    
end %end of loop on TSmain
disp("end of loop!")

cd ..
first_row = ["mutant name" "mutant type" "killed" "tests that killed"];
second_column = [];
for i=1:length(mutants_list)
    second_column = [second_column "?"];
end
writematrix([first_row; [mutants_list; second_column; killed_list; third_column]'], "TSbert_fitness.csv");










