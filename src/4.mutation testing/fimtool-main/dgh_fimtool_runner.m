clc;

fault_type = ["Negate"];
config_file_name = "fim_auto_configure_tustin.txt";
close_system('tustin_12B');

for i=1:length(fault_type)
    disp(strcat("********************mutants with ", fault_type(i), "********************"))
    mutant_folder_name = strcat('tustin_', fault_type(i), '_mutants');

    mkdir(mutant_folder_name);
    copyfile('tustin_12B.slx', mutant_folder_name);

    %edit the configuration text file
    fileID = fopen(config_file_name,'w');
    fprintf(fileID,'model, constants_thresholds, fault_injector_folder, fault_list\n');
    fprintf(fileID,"tustin_12B.slx, tustin_thresholds.mat, %s, Fault_injection_list_tustin.xlsx", mutant_folder_name);
    fclose(fileID);

    %edit the fautl_injection_list csv file
    T = readtable('Configuration/Fault_injection_list_tustin');
    T.Faulttype_ft(1) = {fault_type(i)};
    writetable(T, 'Configuration/Fault_injection_list_tustin.xlsx');

    %run the tool
    close_system('tustin_12B');
    FIMulti(config_file_name, strcat('tustin_', fault_type(i),'_result'));
end

%%
% Faults -
 
% 1) "Negate" 
% 2) "Invert" 
% 3) "Stuck-at 0"
% 4) "Absolute" 
% 5) "Noise" 
% 6) "Bias/Offset" : Adds a predefined +ve or -ve offset (bias) value to the input signal (for all signals of type 'double')
% 7) "Stuck-at" : the signal value stucks at the last correct value before fault occurrence (for all signals)
% 8) "Time Delay" 
% 9) "Bit Flip" : performs Bitwise NOT operation on the boolean signal. (The bits are inverted in the binary representation of the correct value).
% 10) "Package Drop" : replaces the input signal value by the specified fault value
 
% Mutation operators-

% 11) "ROR" : Relational Operator Replacement - replaces the original relational operator with the chosen one.
 
% Operator list: 
% 1 - >
% 2 - <
% 3 - <=
% 4 - >=
% 5 - ==
% 6 - ~=

% 12) "LOR" : Logical Operator Replacement - replaces the original logical operator with the chosen one.

% Operator list:
% 1 - AND
% 2 - OR
% 3 - NAND
% 4 - NOR
% 5 - XOR
% 6 - NXOR

% 13) "S2P" : Sum to Product mutation - replaces a sum block by a product block
 
% 14) "P2S" : Product to Sum mutation - replaces a Product block by a Sum block
 
% 15) "ASR" : Arithmetic Sign replacement operator - replaces the sign of the sum operator with the chosen one.

% Operator list:
% 1 : +-
% 2 : --
% 3 : ++
% 4 : -+



