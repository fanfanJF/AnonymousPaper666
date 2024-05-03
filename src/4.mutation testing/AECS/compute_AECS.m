function [output, fitness]=compute_AECS(slx,inp1)
    open_system(strcat(slx,'.slx'));  
    ws = get_param(slx, 'modelworkspace');
    set_param(slx, 'StopTime', '30');
    ws.assignin('amp_cmd', inp1);

    sim(slx);
    pos_left  = simout.Data(:, 1); %left elevator
    pos_right = simout.Data(:, 2); %right elevators
    
    fitness1 = AECS_fitness_1(pos_left, pos_right, inp1);
    fitness2 = AECS_fitness_2(pos_left, pos_right, inp1);

    output={pos_left, pos_right};
    fitness={fitness1, fitness2};
end

function [fitness] = AECS_fitness_2(pos_left, pos_right, cmd)
    m = 0.09;
    n = 0.02;
    T = 1070;
    a = 100;
    if cmd > m
        term1 = sum(pos_left(T:T+a) > n+cmd);
        term2 = sum(pos_right(T:T+a) > n+cmd);
        if term1 || term2
            fitness = -1;
        else
            fitness = 1;
        end
    else
        fitness = 1;
    end
end

function [fitness] = AECS_fitness_1(pos_left, pos_right, cmd)
    m = 0.09; %0.09;
    n = 0.02;
    a = 1;
    T = 2;
    term4_left = 99999;
    term4_right = 99999;
    for i = 1:T
        term1 = m - cmd;
        term2_left  = min(n - abs(cmd - pos_left(i:i+a)));
        term2_right = min(n - abs(cmd - pos_right(i:i+a)));
        term3_left  = max(term1, term2_left);
        term3_right = max(term1, term2_right);
        if term3_left < term4_left
            term4_left = term3_left;
        end
        if term3_right < term4_right
            term4_right = term3_right;
        end
    end
    fitness = min(term4_left, term4_right);
end

