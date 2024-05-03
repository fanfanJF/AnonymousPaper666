
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
cd fsm/FIM_muts;

N = 1;
file = fopen('not_compiled_fim.json', 'w');
for m = 1:N
    input=randi([0, 1], 1, 12);
    for i = 1:number_of_mutants
        slx_name=mutants_list(i);
        err=false;

        try
            [output, fitness]=compute_fsm(convertStringsToChars(slx_name),input);
            %save_system(slx_name,'bert_mut_new');
        catch error
            err=true;
            disp(slx_name);
            fprintf(file, [convertStringsToChars(slx_name),'\n']); 

        end
        close_system(slx_name,0);
    end
end
fclose(file);




