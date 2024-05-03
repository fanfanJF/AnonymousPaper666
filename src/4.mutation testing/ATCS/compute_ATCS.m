
function [output, fitness]=compute_ATCS(slx,throttle,Break,throttle_simin_,break_simin_)
            open_system(slx);
            sim(slx);
            out1=speed_simout_.Data;
            out2=rpm_simout_.Data;
            out3=throttle_simout_.Data;
            output={out1,out2,out3};
            v_threshold = 120;
            w_threshold = 4500;
            fitness = 100;
            for i = 1:length(speed_simout_.Data)
                fitness = min(v_threshold - speed_simout_.Data(i), w_threshold - rpm_simout_.Data(i));
            end
            fitness = {fitness};

end

