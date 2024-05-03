clc;

mutant_dir = "bert_muts";
mutants_list_ = dir(mutant_dir);
cd bert_muts;

original_model = "basictwotanks";

cd ..;
testSuit = readmatrix("twotanks_testSuite.csv");
file = fopen('bert_violate_req.txt', 'w');
for i=1:20
    input_1 = testSuit(i, 1);
    input_2 = testSuit(i, 2);
    %run tests on the original model
    [output_org, fitness_org] = compute_twotanks(convertStringsToChars(original_model), input_1, input_2);
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
    



