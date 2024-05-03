clc;

mutant_dir = "bert_muts";
mutants_list_ = dir(mutant_dir);
cd bert_muts;

cd ..;
original_model = "ATCS";
inputs = fopen('ATCS_input.json', 'r');
rawData = fread(inputs, '*char')'; 
fclose(inputs);
testSuit = jsondecode(rawData);
cd bert_muts;

file = fopen('bert_violate_req.txt', 'w');
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
            break;
        end
    end
    disp(['tc', num2str(i)]);
    if violate
        fprintf(file, '%d\n', num2str(i)); 
    end
end
fclose(file);
    



