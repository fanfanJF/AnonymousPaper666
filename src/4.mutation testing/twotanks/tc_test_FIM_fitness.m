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

disp("solving FIMTool problem... .");
cd ../..
open_system("fimtool-main/FaultInjector_Master/FInjLib");%local
set_param(gcs, 'Lock', 'off');
save_system(gcs);
cd twotanks/FIM_muts;

killed_list = zeros(1, length(mutants_list));
third_column = [];
for i = 1:length(mutants_list) 
    third_column = [third_column ""];
end

mutants_index = [1:number_of_mutants];
m = randi([1, length(mutants_index)]);
mutant = mutants_list(mutants_index(m));
disp(strcat(string(mutants_index(m)), "th mutant (", mutant, ") is picked randomly."));
tc_cnt = 1;
cd ..;
testSuit = readmatrix("twotanks_testSuite.csv");
cd FIM_muts;

while ~isempty(mutants_index) & tc_cnt<=20 %loop on TSmain
    input_1 = testSuit(tc_cnt, 1);
    input_2 = testSuit(tc_cnt, 2);
    %run tests on the original model
    [output_org, fitness_org] = compute_twotanks(convertStringsToChars(original_model), input_1, input_2); 
    
    %run tc* on the mutant(m)
    [output, fitness] = compute_twotanks(convertStringsToChars(mutant), input_1, input_2);

    found = false;
    for i = 1:length(fitness)
        if ~isequal(cell2mat(fitness_org), cell2mat(fitness))
            found = true;
            break;
        end
    end

%     if ~isequal(cell2mat(output_org), cell2mat(output)) %mutant is killed 
    if found
        third_column(mutants_index(m)) = strcat(third_column(mutants_index(m)), ", tc_", string(tc_cnt));
        disp(strcat("tc_", string(tc_cnt), " killed mutant ", string(mutants_index(m))))
        killed_list(mutants_index(m)) = 1;
    end
    
    close_system(mutant, 0);
    if killed_list(mutants_index(m))==1
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
    end 

end %end of loop on TSmain
disp("end of loop!")


cd ..;
first_row = ["mutant name" "mutant type" "killed" "tests that killed"];
second_column = [];
for i=1:length(mutants_list)
    second_column = [second_column "?"];
end
writematrix([first_row; [mutants_list; second_column; killed_list; third_column]'], "TSFIM_fitness.csv");


%close all the simulations
close_system(original_model,0)
for i = 1:length(mutants_list)
    close_system(mutants_list(i),0)
end


