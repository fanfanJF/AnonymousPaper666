clc;



cd ..;
open_system("fimtool-main/FaultInjector_Master/FInjLib");
set_param(gcs, 'Lock', 'off');
save_system(gcs);
cd ATCS;

original_model = "ATCS";
inputs = fopen('ATCS_input.json', 'r');
rawData = fread(inputs, '*char')'; 
fclose(inputs);
testSuit = jsondecode(rawData);
cd FIM_muts;

mutant_dir = "FIM_muts";
mutants_list_ = dir(mutant_dir);


file = fopen('FIM_violate_req.txt', 'w');
for i=1:20
    sampleTime = 0.04;
    numSteps = 751;
    time = sampleTime*(0:numSteps-1);
    time = time';
    throttleData = testSuit(i).throttle;
    Break = testSuit(i).brake;
    throttle_simin_ = timeseries(throttle, time);
    break_simin_ = timeseries(Break, time);
    %run tests on the original model
    [output_org, fitness_org] = compute_ATCS(convertStringsToChars(original_model),throttle,Break,throttle_simin_,break_simin_); 

    violate = false;
    for j = 1:length(fitness_org)
        if fitness_org{j} < 0
            violate = true;
            fprintf(file, '%d\n', num2str(i)); 
            break;
        end
    end
    disp([num2str(i)]);
end
fclose(file);
    



