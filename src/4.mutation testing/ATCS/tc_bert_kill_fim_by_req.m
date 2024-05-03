clc;

mutant_dir = "FIM_muts";
mutants_list_ = dir(mutant_dir);
cd FIM_muts;

%extracting mutants names
mutants_list = [];
for i = 1:length(mutants_list_)
    if contains(mutants_list_(i).name, ".slx")
        mutants_list = [mutants_list, string(mutants_list_(i).name)];
    end
end
mutants_list = erase(mutants_list, ".slx");
original_model = mutants_list(1);
mutants_list = mutants_list(2:end);
number_of_mutants = length(mutants_list);

cd ../..;
open_system("fimtool-main/FaultInjector_Master/FInjLib");
set_param(gcs, 'Lock', 'off');
save_system(gcs);
cd ATCS/FIM_muts;

mutants_index = [1:number_of_mutants];

cd ..;
inputs = fopen('ATCS_input.json', 'r');
rawData = fread(inputs, '*char')'; 
fclose(inputs);
testSuit = jsondecode(rawData);
cd FIM_muts;

file = fopen('tcbert_kill_fim_req.json', 'w');
TSbert={1,3,6};
dict = containers.Map;

killed_list=[];
for i=1:length(TSbert)
    sampleTime = 0.04;
    numSteps = 751;
    time = sampleTime*(0:numSteps-1);
    time = time';
    throttle = testSuit(i).throttle;
    Break = testSuit(i).brake;
    throttle_simin_ = timeseries(throttle, time);
    break_simin_ = timeseries(Break, time);
    [output_org, fitness_org] = compute_ATCS(convertStringsToChars(original_model),throttle,Break,throttle_simin_,break_simin_); 

    killed_muts={};
    violate = false;
    for m=1:number_of_mutants
        mutant=mutants_list(m);
        try
            [output, fitness] = compute_ATCS(convertStringsToChars(mutant),throttle,Break,throttle_simin_,break_simin_); 
        catch error
            output=output_org;
            fitness=fitness_org;
        end

        for j = 1:length(fitness)
            if fitness_org{j} >= 0 && fitness{j} < 0
                killed_muts=[killed_muts,num2str(m)];
                break;
            end
        end

        close_system(mutant, 0);
    end
    dict(num2str(i))=killed_muts;
    
end
cd ..;
fprintf(file, jsonencode(dict)); 
fclose(file);
    



