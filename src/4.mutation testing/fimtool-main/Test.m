%% Script to simulate the original model and the mutated model

addpath('FaultInjector_Master');
addpath('Aircraft_fault_injector/sf_aircraft_model');

%% Load the Fault Injection library
load_system('FInjLib');
% For accessing the Fault Injector block parameters in the mutated models, the Library should be unlocked
set_param('FInjLib', 'Lock', 'off');

%% Load the original system

Omodel = 'Aircraft';
system = load_system('Aircraft.slx');
set_param(system, 'Solver', 'ode4', 'StopTime', '10', 'ReturnWorkspaceOutputs', 'on');

% simulate the original model
simout_original = sim(Omodel);
SO_original = simout_original.get('logsout');

%% Load the mutant

Mmodel = 'Aircraft_1';
system = load_system('Aircraft_1.slx');
set_param(system, 'Solver', 'ode4', 'StopTime', '10', 'ReturnWorkspaceOutputs', 'on');
% simulate the mutated model
simout_mutant = sim(Mmodel);
SO_mutant = simout_mutant.get('logsout');

