clc;

mutant_dir = "FIM_muts";
mutants_list_ = dir(mutant_dir);
cd FIM_muts;

%extracting mutants names
mutants_list = [];
for i = 1:length(mutants_list_)
    if contains(mutants_list_(i).name, ".slx") && ~contains(mutants_list_(i).name, ".autosave")
        mutants_list = [mutants_list, string(mutants_list_(i).name)];
    end
end
mutants_list = erase(mutants_list, ".slx");
original_model = mutants_list(1);
mutants_list = mutants_list(2:end);
number_of_mutants = length(mutants_list);

cd ../..
open_system("fimtool-main/FaultInjector_Master/FInjLib");%local
set_param(gcs, 'Lock', 'off');
save_system(gcs);
cd twotanks/FIM_muts;

mutants_index = [1:number_of_mutants];
cd ..;
testSuit = readmatrix("AECS_input.csv");
file = fopen('tcbert_kill_fim_fitness.json', 'w');
TSbert={1};
dict = containers.Map;

for i=1:length(TSbert)
    input_1 = testSuit(TSbert{i});
    killed_muts={};
    %run tests on the original model
    [output_org, fitness_org] = compute_AECS(convertStringsToChars(original_model), input_1);
    for m=1:number_of_mutants
        mutant=mutants_list(m);
        try
            [output, fitness] = compute_AECS(convertStringsToChars(mutant), input_1);
        catch error
            output=output_org;
            fitness=fitness_org;
        end

        found = false;
        for i = 1:length(fitness)
            if ~isequal(cell2mat(fitness_org), cell2mat(fitness))
                found = true;
                killed_muts=[killed_muts,num2str(m)];
                break;
            end
        end

        close_system(mutant, 0);
    end
    dict(num2str(i))=killed_muts;
    
end

fprintf(file, jsonencode(dict)); 
fclose(file);




