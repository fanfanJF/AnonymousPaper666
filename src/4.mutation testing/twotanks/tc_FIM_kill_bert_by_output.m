clc;

mutant_dir = "bert_muts";
mutants_list_ = dir(mutant_dir);
cd bert_muts;

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


mutants_index = [1:number_of_mutants];
cd ..;
testSuit = readmatrix("twotanks_testSuite.csv");
file = fopen('tcfim_kill_bert_output.json', 'w');
TSFIM={1};
dict = containers.Map;

for i=1:length(TSFIM)
    input_1 = testSuit(TSFIM{i}, 1);
    input_2 = testSuit(TSFIM{i}, 2);
    killed_muts={};
    %run tests on the original model
    [output_org, fitness_org] = compute_twotanks(convertStringsToChars(original_model), input_1, input_2);
    for m=1:number_of_mutants
        mutant=mutants_list(m);
        try
            [output, fitness] = compute_twotanks(convertStringsToChars(mutant), input_1, input_2);
        catch error
            output=output_org;
            fitness=fitness_org;
        end

        if ~isequal(cell2mat(output_org), cell2mat(output))
            killed_muts=[killed_muts,num2str(m)];
        end

        close_system(mutant, 0);
    end
    dict(num2str(i))=killed_muts;
    
end

fprintf(file, jsonencode(dict)); 
fclose(file);




