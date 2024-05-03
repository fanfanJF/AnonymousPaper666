clc;

% mutant_dir = "FIM_muts";
% mutants_list_ = dir(mutant_dir);
% cd FIM_muts;

original_model = "a_fsm";

cd ..;
open_system("fimtool-main/FaultInjector_Master/FInjLib");%local
set_param(gcs, 'Lock', 'off');
save_system(gcs);
cd fsm;


testSuit = readmatrix("fsm_input.csv");

file = fopen('FIM_violate_req.txt', 'w');
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
    



