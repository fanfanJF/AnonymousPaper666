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
testSuit = readmatrix('fsm_input.csv');
cd bert_muts;

while ~isempty(mutants_index) & tc_cnt<=20 %loop on TSmain
    input_1 = testSuit(tc_cnt,:);

    [output_org, fitness_org] = compute_fsm(convertStringsToChars(original_model), input_1); 
    [output, fitness] = compute_fsm(convertStringsToChars(mutant), input_1);

    found = false;
    for i = 1:length(output)
        if ~isequal(cell2mat(output_org(i)), cell2mat(output(i)))
            found = true;
            break;
        end
    end

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
writematrix([first_row; [mutants_list; second_column; killed_list; third_column]'], "TSbert_output.csv");


%close all the simulations
close_system(original_model,0)
for i = 1:length(mutants_list)
    close_system(mutants_list(i),0)
end


