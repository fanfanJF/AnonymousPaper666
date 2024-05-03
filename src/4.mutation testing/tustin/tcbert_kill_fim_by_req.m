clc;

mutant_dir = "FIM_muts";
mutants_list_ = dir(mutant_dir);

cd FIM_muts;

cd ../..
disp("solving FIMTool problem... .");
open_system("fimtool-main/FaultInjector_Master/FInjLib");%local
set_param(gcs, 'Lock', 'off');
save_system(gcs);
cd tustin/FIM_muts;

%extracting mutants names
mutants_list = [];
for i = 1:length(mutants_list_)
    if contains(mutants_list_(i).name, ".slx")
        mutants_list = [mutants_list, string(mutants_list_(i).name)];
    end
end

mutants_list = erase(mutants_list, ".slx");
original_model = mutants_list(1);
mutants_list = mutants_list(2:end);
number_of_mutants = length(mutants_list);

reqs = ["R1a", "R1b", "R1c", "R1d", "R1e", "R2a", "R2b", "R3", "R4a", "R4b"];
violation = zeros(1, length(reqs));
file = fopen('tcbert_kill_fim_req.json', 'w');
itr = 2;
dictionaryCellArray = cell(4*itr, 1);
for tc_cnt = 1:itr
    [mat_name_1, mat_name_11, inputs_1, mat_name_2, inputs_2, mat_name_3, inputs_3] = create_data(tc_cnt);
    %loading test cases
    load(mat_name_1, 'simulation_input_1'); 
    load(mat_name_2, 'simulation_input_2'); 
    load(mat_name_3, 'simulation_input_3'); 
    load(mat_name_11, 'simulation_input_11');
    Xin1 = inputs_1(1); Xin1_save_flag = 0;
    Xin2 = inputs_1(1); Xin2_save_flag = 0;
    Xin3 = inputs_2(1); Xin3_save_flag = 0;
    Xin4 = inputs_3(1); Xin4_save_flag = 0;

    req1_killed_muts={};
    req2_killed_muts={};
    req3_killed_muts={};
    req4_killed_muts={};


    for j = 1:length(mutants_list)
        current_mutant = mutants_list(j);

        %run tests on the original model
        [fitness_org, y1_org, y2_org, y3_org, y4_org] = tustin(inputs_1, inputs_2, inputs_3, 'a_tustin_12B');
        [fitness, y1, y2, y3, y4] = tustin(inputs_1, inputs_2, inputs_3, current_mutant);
        
        req1_killed = false;
        for m = 1:5
            if fitness_org(m) >= 0 && fitness(m) < 0
                req1_killed = true;
                break;
            end
        end

        req2_killed = false;
        for m = 6:7
            if fitness_org(m) >= 0 && fitness(m) < 0
                req2_killed = true;
                break;
            end
        end

        req3_killed = false;
        for m = 8:8
            if fitness_org(m) >= 0 && fitness(m) < 0
                req3_killed = true;
                break;
            end
        end

        req4_killed = false;
        for m = 9:10
            if fitness_org(m) >= 0 && fitness(m) < 0
                req4_killed = true;
                break;
            end
        end


        if req1_killed
            disp(strcat("tc_", string(tc_cnt*4-3), " killed mutant ", num2str(j)))
            req1_killed_muts = [req1_killed_muts, num2str(j)];
        end
        if req2_killed
            disp(strcat("tc_", string(tc_cnt*4-2), " killed mutant ", string(j)))
            req2_killed_muts = [req2_killed_muts, num2str(j)];
        end
        if req3_killed
            disp(strcat("tc_", string(tc_cnt*4-1), " killed mutant ", string(j)))
            req3_killed_muts = [req3_killed_muts, num2str(j)];
        end
        if req4_killed
            disp(strcat("tc_", string(tc_cnt*4), " killed mutant ", string(j)))
            req4_killed_muts = [req4_killed_muts, num2str(j)];
        end

    end
    dictionaryCellArray{tc_cnt*4-3}=req1_killed_muts;
    dictionaryCellArray{tc_cnt*4-2}=req2_killed_muts;
    dictionaryCellArray{tc_cnt*4-1}=req3_killed_muts;
    dictionaryCellArray{tc_cnt*4}=req4_killed_muts;


end
cd ..;
fprintf(file, jsonencode(dictionaryCellArray)); 
fclose(file);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fitness, y1, y2, y3, y4] = tustin(inputs_1, inputs_2, inputs_3, model_name)
    %%%%%%%%%%% R1 
    open_system(model_name);
    cs = getActiveConfigSet(model_name);
    model_cs = cs.copy;
    set_param(model_cs, 'MaxDataPoints' ,' off', 'LimitDataPoints', 'off', 'ReturnWorkspaceOutputs','on','SaveOutput','on', 'OutputSaveName', 'varout');        
    set_param(model_cs, 'ExternalInput', 'simulation_input_1');
    set_param(model_cs, 'FixedStep', string(1));
    simOut = sim(model_name, model_cs);
    t = simOut.varout.time;
    y1 = simOut.varout.signals.values; %output yout
    
    ic = inputs_1(2);
    BL = inputs_1(3);
    TL = inputs_1(4);
    
    fitness = [];
    F = 100 * ones(size(t,1), 1); 
    for i = 1:size(t,1) %R1a             
        Ft = R01aObj(y1(i), TL ,BL ,ic);
        F(i) = Ft;
    end    
    FR = min(F); fitness(1) = FR;

    F = 100 * ones(size(t,1), 1); 
    for i = 1:size(t,1) %R2b
        Ft = R01bObj(y1(i), TL ,BL ,ic);
        F(i) = Ft;
    end
    FR = min(F); fitness(2) = FR;

    F = 100 * ones(size(t,1), 1); 
    for i = 1:size(t,1) %R1c       
        Ft = R01cObj(y1(i), TL ,BL ,ic);
        F(i) = Ft;
    end   
    FR = min(F); fitness(3) = FR;
    
    F = 100 * ones(size(t,1), 1); 
    for i = 1:size(t,1) %R1d       
        Ft = R01dObj(y1(i), TL ,BL ,ic);
        F(i) = Ft;
    end
    FR = min(F); fitness(4) = FR;
    
    F = 100 * ones(size(t,1), 1); 
    for i = 1:size(t,1) %R1e       
        Ft = R01eObj(y1(i), TL ,BL ,ic);
        F(i) = Ft;
    end
    FR = min(F); fitness(5) = FR;
    
    %%%%%%%%%%% R2
    set_param(model_cs, 'ExternalInput', 'simulation_input_11');
    simOut = sim(model_name, model_cs);
    t = simOut.varout.time;
    y2 = simOut.varout.signals.values; %output yout
    F = 100 * ones(size(t,1), 1);  
    for i = 1:size(t,1) %R2a       
        Ft = R02aObj(y2(i),TL, BL);
        F(i) = Ft;
    end   
    FR = min(F); fitness(6) = FR;
    
    F = 100 * ones(size(t,1), 1); 
    for i = 1:size(t,1) %R2b       
        Ft = R02bObj(y2(i),TL, BL);
        F(i) = Ft;
    end 
    FR = min(F); fitness(7) = FR;
    
    %%%%%%%%%%% R3
    open_system(model_name);
    cs = getActiveConfigSet(model_name);
    model_cs = cs.copy;
    set_param(model_cs, 'MaxDataPoints' ,' off', 'LimitDataPoints', 'off', 'ReturnWorkspaceOutputs','on','SaveOutput','on', 'OutputSaveName', 'varout');        
    set_param(model_cs, 'ExternalInput', 'simulation_input_2');
    set_param(model_cs, 'FixedStep', string(0.1));
    simOut = sim(model_name, model_cs);
    t = simOut.varout.time;
    y3 = simOut.varout.signals.values; %output yout
    
    Xin = inputs_2(1:length(inputs_2)-2);
    BL = inputs_2(length(inputs_2)-1);
    TL = inputs_2(length(inputs_2));
    
    fitness(8) = R03Obj(t, y3, TL, BL, Xin, 0.1);
    
    %%%%%%%%%%% R4
    set_param(model_cs, 'ExternalInput', 'simulation_input_3');
    set_param(model_cs, 'FixedStep', string(0.1));
    simOut = sim(model_name, model_cs);
    t = simOut.varout.time;
    y4 = simOut.varout.signals.values; %output yout
    
    BL = inputs_3(2);
    TL = inputs_3(3);
    
    fitness(9) = R04aObj(t, BL, TL, y4, 0.1);
    fitness(10) = R04bObj(t, BL, TL, y4);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [matrix_name_1, matrix_name_11, inputs_1, matrix_name_2, inputs_2, matrix_name_3, inputs_3] = create_data(iteration)
    %%%%%%%%%%%%%%%Reading test
    mainTS = readmatrix("tustinintegrator_input.csv");
    input_10 = mainTS(iteration, 1:11);
    input_101 = mainTS(iteration, 12:112);
    input_101_r4 = cos(mainTS(iteration, 113:213));
    reset = mainTS(iteration, 214);
    ic = mainTS(iteration, 215);
    BL = mainTS(iteration, 216);
    TL = mainTS(iteration, 217);
    %%%%%%%%%%%%%%%R1 setup
    TimeSteps = 11;  
    nbrInputs = 6;
    simulation_input_1.time = 0:1:10;
    % Signals initialization for R1
    for j = 1:nbrInputs
        simulation_input_1.signals(j).values = zeros(TimeSteps,1);
        simulation_input_1.signals(j).dimensions =  1;
    end
    Xin = input_10; 
    for i = 1:TimeSteps
        simulation_input_1.signals(1).values(i) =  Xin(i); % Xin
        simulation_input_1.signals(2).values(i) =  1;   % reset which is fixed on 1
        simulation_input_1.signals(3).values(i) =  1;   % T which is fixed
        simulation_input_1.signals(4).values(i) =  ic;  % A value between 20 and -20; ic  
        simulation_input_1.signals(5).values(i) =  TL;  % A velue between 10 and -10; TL
        simulation_input_1.signals(6).values(i) =  BL;  % A value between 10 and -10; BL
    end
    save inputs_1.mat simulation_input_1;
    matrix_name_1 = 'inputs_1.mat';
    inputs_1 = [Xin, ic, BL, TL];
    
    %%%%%%%%%%%%%%%R2 setup
    % Signals initialization for R2
    simulation_input_11 = simulation_input_1;
    for i = 1:TimeSteps
        simulation_input_11.signals(2).values(i) =  reset; % set Reset to random
    end
    save inputs_11.mat simulation_input_11;
    matrix_name_11 = 'inputs_11.mat';
    
    %%%%%%%%%%%%%%%R3 setup
    TimeSteps = 101;  
    simulation_input_2.time = 0:0.1:10;
    % Signals initialization for R3
    for j = 1:nbrInputs
        simulation_input_2.signals(j).values = zeros(TimeSteps,1);
        simulation_input_2.signals(j).dimensions =  1;
    end
    Xin = input_101; 
    for i = 1:TimeSteps
        simulation_input_2.signals(1).values(i) =  Xin(i); % Xin
        simulation_input_2.signals(2).values(i) =  reset;   % reset which is fixed on 0
        simulation_input_2.signals(3).values(i) =  0.1; % T which is fixed
        simulation_input_2.signals(4).values(i) =  ic;  % A value between 20 and -20; ic  
        simulation_input_2.signals(5).values(i) =  TL;  % A velue between 10 and -10; TL
        simulation_input_2.signals(6).values(i) =  BL;  % A value between 10 and -10; BL
    end
    save inputs_2.mat simulation_input_2;
    matrix_name_2 = 'inputs_2.mat';
    inputs_2 = [Xin, BL, TL];
    
    %%%%%%%%%%%%%%%R4 setup
    simulation_input_3.time = 0:0.1:10;
    % Signals initialization for R4
    for j = 1:nbrInputs
        simulation_input_3.signals(j).values = zeros(TimeSteps,1);
        simulation_input_3.signals(j).dimensions =  1;
    end
    Xin = input_101_r4;  
    for i = 1:TimeSteps
        simulation_input_3.signals(1).values(i) =  Xin(i); % Xin
        simulation_input_3.signals(2).values(i) =  reset;   % reset which is fixed on 0
        simulation_input_3.signals(3).values(i) =  0.1; % T which is fixed
        simulation_input_3.signals(4).values(i) =  ic;  % A value between 20 and -20; ic  
        simulation_input_3.signals(5).values(i) =  TL;  % A velue between 10 and -10; TL
        simulation_input_3.signals(6).values(i) =  BL;  % A value between 10 and -10; BL
    end
    save inputs_3.mat simulation_input_3;
    matrix_name_3 = 'inputs_3.mat';
    inputs_3 = [Xin, BL, TL];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function R01a = R01aObj(y, TL ,BL ,ic)
%((reset and ic<=TL and ic>=BL) AND yout <> ic); #1a 
    term1 = round(ic - TL, 4);
    term2 = round(BL - ic, 4);
    term3 = 0.0001 - abs(round(y - ic, 4));
    R01a = max(max(term1, term2), term3);
end

function R01b = R01bObj(y, TL ,BL ,ic)
%((reset and ic>=TL and TL>=BL) AND yout <> TL); #1b 
    term4 = round(TL - ic, 4);
    term5 = round(BL - TL, 4);
    term6 = 0.0001 - abs(round(y - TL, 4));
    R01b = max(max(term4, term5), term6);
end

function R01c = R01cObj(y, TL ,BL ,ic)
%((reset and ic<=BL and TL>=BL) AND yout <> BL); #1c
    term7 = round(ic - BL, 4);
    term8 = round(BL - TL, 4);
    term9 = 0.0001 - abs(round(y - BL, 4));
    R01c = max(max(term7, term8), term9);
end

function R01d = R01dObj(y, TL ,BL ,ic)
%((reset and ic>=BL and TL<BL) AND yout <> BL); #1d
    term10 = round(BL - ic, 4);
    term11 = 0.0001 + round(TL - BL, 4);
    term12 = 0.0001 - abs(round(y - BL, 4));
    R01d = max(max(term10, term11), term12);
end

function R01e = R01eObj(y, TL ,BL ,ic)
%((reset and ic<=TL and TL<BL) AND yout <> TL); #1e 
    term13 = round(ic - TL, 4);
    term14 = 0.0001 + round(TL - BL, 4);
    term15 = 0.0001 - abs(round(y - TL, 4));
    R01e = max(max(term13, term14), term15);    
end

function R02a = R02aObj(y, TL ,BL)
%(TL>=BL) AND (BL>yout OR yout>TL); #2a
    term1 = round(BL - TL, 4);
    term2 = min(0.0001 - round(BL - y, 4), 0.0001 - round(y - TL, 4));    
    R02a = max(term1, term2);
end

function R02b = R02bObj(y, TL ,BL) 
%(TL<BL) AND (TL>yout OR yout>BL); #2b       
    term1 = 0.0001 + round(TL - BL, 4);        
    term2 = min(0.0001 - round(TL - y, 4), 0.0001 - round(y - BL, 4));
    R02b = max(term1, term2);
end

function R03 = R03Obj(t, y, TL, BL, Xin, T)
    F = 1000 * ones(size(t,1), 1);
    for i = 2:size(t,1)
        term1 = round(y(i) - TL, 4);
        term2 = round(BL - y(i), 4);
        term3 = round(y(i) - BL, 4);
        term4 = round(TL - y(i), 4);
        term5 = 0.0001 - abs(y(i) - (0.5 * T * (Xin(i) + Xin(i-1)) + y(i-1))); 
        Ft = max(min(max(term1, term2), max(term3, term4)), term5);
        F(i-1) = Ft;
    end
    R03 = min(F);    
end

function R4a = R04aObj(t, BL, TL, y, T)
    F = 1000 * ones(size(t,1), 1);
    for i = 1:size(t,1)
        term1 = round(BL - TL, 4);
        term2 = round(BL - y(i), 4);
        term3 = round(y(i) - TL, 4);
        term4 = round(TL - BL, 4);
        term5 = round(TL - y(i), 4);
        term6 = round(y(i) - BL, 4);
        term7 = 0.0001 - ((abs(y(i) - (i * T))) - 0.1); 
        Ft = max(min(max(max(term1, term2),term3),max(max(term4, term5),term6)),term7);
        F(i) = Ft;
    end
    R4a =  min(F);
end

function R4b = R04bObj(t, BL, TL, y)
    F = 1000 * ones(size(t,1), 1);
    for i = 1:size(t,1)
        term1 = round(BL - TL, 4);
        term2 = round(BL - y(i), 4);
        term3 = round(y(i) - TL, 4);
        term4 = round(TL - BL, 4);
        term5 = round(TL - y(i), 4);
        term6 = round(y(i) - BL, 4);
        term8 = 0.0001 - (abs(y(i) - sin(t(i))) - 0.1);
        Ft = max(min(max(max(term1, term2),term3),max(max(term4, term5),term6)),term8);
        F(i) = Ft;
    end
    R4b = min(F);
end