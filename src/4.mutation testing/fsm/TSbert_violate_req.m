clc;

mutant_dir = "bert_muts";
mutants_list_ = dir(mutant_dir);
cd bert_muts;

original_model = "a_fsm";

cd ..;
testSuit = readmatrix("fsm_input.csv");
file = fopen('bert_violate_req.txt', 'w');
for i=1:20
    input_1 = testSuit(i, :);
    %run tests on the original model
    [output_org, fitness_org] = compute_fsm(convertStringsToChars(original_model), input_1);
    violate = false;
    for j = 1:length(fitness_org)
        if fitness_org{j} < 0
            violate = true;
            break;
        end
    end
    if violate
        disp(['tc', num2str(i)]);
        fprintf(file, strcat(num2str(i), '\n')); 
    end
end
fclose(file);
    



