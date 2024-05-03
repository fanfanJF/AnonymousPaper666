
function [output, fitness]=compute_fsm(slx,input)

  open_system(strcat(slx,'.slx'));
  cs = getActiveConfigSet(slx);
  model_cs = cs.copy;
  set_param(model_cs,'MaxDataPoints' ,' off', 'LimitDataPoints', 'off', 'ReturnWorkspaceOutputs','on','SaveOutput','on', 'OutputSaveName', 'varout');
  
  TimeSteps = 51;  
  nbrInputs = 4;
  var.time = 0:0.2:10;

  for j = 1:nbrInputs
      var.signals(j).values = zeros(TimeSteps,1);
      var.signals(j).dimensions =  1;
  end      

  X=input;
 
  d = 1;
  j=1;
  while j <= 45
      var.signals(1).values(j:j+14) = X(1,d);
      var.signals(2).values(j:j+14) = X(1,d+3);
      var.signals(3).values(j:j+14) = X(1,d+6); 
      var.signals(4).values(j:j+14) = X(1,d+9); 
      d = d+1;
      j = j+15;
  end        
  var.signals(1).values(46:51) = X(1,3);
  var.signals(2).values(46:51) = X(1,6);
  var.signals(3).values(46:51) = X(1,9); 
  var.signals(4).values(46:51) = X(1,12);          

  hws = get_param(slx, 'modelworkspace');
  list = whos;
  N = length(list);
  for  i = 1:N
      hws.assignin(list(i).name,eval(list(i).name));
  end
           
  simOut = sim([slx,'.slx'], model_cs);
  varout=simOut.get('varout');    
    
  %Outputs from the model;
  standby = var.signals(1).values;
  apfail = var.signals(2).values;
  supported = var.signals(3).values;
  limits = var.signals(4).values;
  t = varout.time;
  pullup = varout.signals(1).values;
  state = varout.signals(2).values;
  good = varout.signals(3).values;
  senstate = varout.signals(4).values;
  mode = varout.signals(5).values;
  request = varout.signals(6).values;

  output={pullup,state,good,senstate,mode,request};

  fitness={};
  F = 100 * ones(size(t,1), 1); 
  for i = 1:size(t,1)                          
      Ft = R01Obj(standby(i), apfail(i), supported(i), limits(i), pullup(i));
      F(i) = Ft;
  end
  FR = min(F);
  fitness{1}=FR;

  F = 100 * ones(size(t,1), 1);           
  for i = 2:size(t,1)                          
      Ft = R02Obj(state(i-1), state(i), standby(i));
      F(i-1) = Ft;
  end
  FR = min(F);
  fitness{2}=FR;
            
  F = 100 * ones(size(t,1), 1); 
  for i = 2:size(t,1)                          
      Ft = R03Obj(state(i-1), state(i), supported(i), good(i-1));
      F(i-1) = Ft;
  end 
  FR = min(F);
  fitness{3}=FR;
  
  F = 100 * ones(size(t,1), 1); 
  for i = 2:size(t,1)                          
      Ft = R04Obj(state(i-1), good(i-1), state(i));
      F(i-1) = Ft;
  end
  FR = min(F);
  fitness{4}=FR;
  
  F = 100 * ones(size(t,1), 1); 
  for i = 2:size(t,1)                          
      Ft = R05Obj(state(i-1), standby(i), state(i));
      F(i-1) = Ft;
  end 
  FR = min(F);
  fitness{5}=FR;
  
  F = 100 * ones(size(t,1), 1); 
  for i = 2:size(t,1)                          
      Ft = R06Obj(state(i-1), standby(i), good(i-1), state(i));
      F(i-1) = Ft;
  end   
  FR = min(F);
  fitness{6}=FR;
  
  F = 100 * ones(size(t,1), 1); 
  for i = 2:size(t,1)                          
      Ft = R07Obj(state(i-1), supported(i), good(i-1), state(i));
      F(i-1) = Ft;
  end 
  FR = min(F);
  fitness{7}=FR;
  
  F = 100 * ones(size(t,1), 1); 
  for i = 2:size(t,1)                          
      Ft = R08Obj(state(i-1), standby(i), state(i));
      F(i-1) = Ft;
  end  
  FR = min(F);
  fitness{8}=FR;
  
  F = 100 * ones(size(t,1), 1); 
  for i = 2:size(t,1)                          
      Ft = R09Obj(state(i-1), apfail(i), state(i));
      F(i-1) = Ft;
  end 
  FR = min(F);
  fitness{9}=FR;

  F = 100 * ones(size(t,1), 1);    
  for i = 2:size(t,1)                          
      Ft = R10Obj(senstate(i-1), limits(i), senstate(i));
      F(i-1) = Ft;
  end 
  FR = min(F);
  fitness{10}=FR;

  F = 100 * ones(size(t,1), 1); 
  for i = 2:size(t,1)                          
      Ft = R11Obj(senstate(i-1), request(i), senstate(i));
      F(i-1) = Ft;
  end 
  FR = min(F);
  fitness{11}=FR;

  F = 100 * ones(size(t,1), 1);    
  for i = 2:size(t,1)                          
      Ft = R12Obj(senstate(i-1), request(i), limits(i), senstate(i));
      F(i-1) = Ft;
  end  
  FR = min(F);
  fitness{12}=FR;

  F = 100 * ones(size(t,1), 1);   
  for i = 2:size(t,1)                          
      Ft = R13Obj(senstate(i-1), request(i), mode(i), senstate(i));
      F(i-1) = Ft;
  end    
  FR = min(F);
  fitness{13}=FR;

end


%% Requirement 1
% Exceeding sensor  limits shall latch an autopilot pullup when the pilot 
% is not in control (not standby) and the system is supported without failures (not apfail).
function R01 = R01Obj(standby, apfail, supported, limits, pullup)      
 % REQ: (not standby and not apfail and supported and limits) ==> pullup;
 % VIOLATION: (not standby and not apfail and supported and limits) and not pullup;
term1 = zeros(5,1);    
    if (standby == 0 )
        term1(1) = -1;
    else
        term1(1) = 1;
    end
    
    if (apfail == 0 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
    if (supported == 1 )
        term1(3) = -1;
    else
        term1(3) = 1;
    end
    
    if (limits == 1 )
        term1(4) = -1;
    else
        term1(4) = 1;
    end
    
    if (pullup == 0 )
        term1(5) = -1;
    else
        term1(5) = 1;
    end
    
    R01 = max(term1);
end


%% Requirement 2
% The autopilot shall change states from TRANSITION to STANDBY when the pilot is in control (standby). 
function R02 = R02Obj(statepv, state, standby)    
% REQ: (FiniteStateMachine.STATE{t-1}==0 and standby) impl FiniteStateMachine.STATE{t}==3;
% VIOLATION: (FiniteStateMachine.STATE{t-1}==0 and standby) and FiniteStateMachine.STATE{t}~=3;
 term1 = zeros(3,1);       

 term1(1) = abs(statepv);
    
    if (standby == 1 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
 term1(3) = 0.0001 - abs(state - 3);
       
 R02 = max(term1); 
 
end

%% Requirement 3
% The autopilot shall change states from TRANSITION to NOMINAL when the system is supported and sensor data is good.
function R03 = R03Obj(statepv, state, supported, goodpv)    
% REQ: (FiniteStateMachine.STATE{t-1}==0 and supported{t} and FiniteStateMachine.good{t-1}) impl (FiniteStateMachine.STATE{t}==1);
% VIOLATION: (FiniteStateMachine.STATE{t-1}==0 and supported{t} and FiniteStateMachine.good{t-1}) and (FiniteStateMachine.STATE{t}~=1);
term1 = zeros(4,1);

term1(1) = abs(statepv);
    
    if (supported == 1 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
    if (goodpv == 1 )
        term1(3) = -1;
    else
        term1(3) = 1;
    end
    
term1(4) = 0.0001 - abs(state - 1);
      
R03 = max(term1);

end

%% Requirement 4
% The autopilot shall change states from NOMINAL to MANEUVER when the sensor data is not good.
function R04 = R04Obj(statepv, goodpv, state)    
% REQ: (FiniteStateMachine.STATE{t-1} == 1 and not FiniteStateMachine.good{t-1}) impl (FiniteStateMachine.STATE{t}==2);
% VIOLATION:(FiniteStateMachine.STATE{t-1} == 1 and not FiniteStateMachine.good{t-1}) and (FiniteStateMachine.STATE{t}~=2);
term1 = zeros(3,1);

term1(1) = abs(statepv - 1);
    
    if (goodpv == 0 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
term1(3) = 0.0001 - abs(state - 2);
     
R04 = max(term1);    

end

%% Requirement 5
% The autopilot shall change states from NOMINAL to STANDBY when the pilot is in control (standby).
function R05 = R05Obj(statepv, standby, state)    
%REQ: (FiniteStateMachine.STATE{t-1}==1 and standby) impl (FiniteStateMachine.STATE{t}==3)
%VIOLATION: (FiniteStateMachine.STATE{t-1}==1 and standby) and (FiniteStateMachine.STATE{t}~=3)

term1 = zeros(3,1);    

term1(1) = abs(statepv - 1);
    
    if (standby == 1 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
term1(3) = 0.0001 - abs(state - 3);

R05 = max(term1);          
end

%% Requirement 6
% The autopilot shall change states from MANEUVER to STANDBY when the pilot is in control (standby) and sensor data is good.
function R06 = R06Obj(statepv, standby, goodpv, state)    
%REQ: (FiniteStateMachine.STATE{t-1}==2 and standby{t} and FiniteStateMachine.good{t-1}) impl (FiniteStateMachine.STATE{t}==3);
%VIOLATION: (FiniteStateMachine.STATE{t-1}==2 and standby{t} and FiniteStateMachine.good{t-1}) and (FiniteStateMachine.STATE{t}~=3);

term1 = zeros(4,1); 

term1(1) = abs(statepv - 2);
   
    if (standby == 1 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
    if (goodpv == 1 )
        term1(3) = -1;
    else
        term1(3) = 1;
    end
    
    term1(4) = 0.0001 - abs(state - 3);

  
    R06 = max(term1);    
end


%% Requirement 7
% The autopilot shall change states from PULLUP to TRANSITION when the system is supported and sensor data is good.
function R07 = R07Obj(statepv, supported, goodpv, state)    
%REQ: (FiniteStateMachine.STATE{t-1}==2 and supported{t} and FiniteStateMachine.good{t-1}) impl (FiniteStateMachine.STATE{t}==0);
%VIOLATION: (FiniteStateMachine.STATE{t-1}==2 and supported{t} and FiniteStateMachine.good{t-1}) and (FiniteStateMachine.STATE{t}~=0);
 term1 = zeros(4,1); 
 
 term1(1) = abs(statepv - 2);
    
    if (supported == 1 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
    if (goodpv == 1 )
        term1(3) = -1;
    else
        term1(3) = 1;
    end
    
    term1(4) = 0.0001 - abs(state);
    
    R07 = max(term1);
end

%% Requirement 8
% The autopilot shall change states from STANDBY to TRANSITION when the pilot is not in control (not standby).
function R08 = R08Obj(statepv, standby, state)    
%REQ: (FiniteStateMachine.STATE{t-1}==3 and not standby) impl (FiniteStateMachine.STATE{t}==0);
%VIOLATION: (FiniteStateMachine.STATE{t-1}==3 and not standby) and (FiniteStateMachine.STATE{t}~=0);

term1 = zeros(3,1); 

 term1(1) = abs(statepv - 3);
    
    if (standby == 0 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
   term1(3) = 0.0001 - abs(state);
        
   R08 = max(term1);       
end


%% Requirement 9
% The autopilot shall change states from STANDBY to MANEUVER when a failure occurs (apfail).
function R09 = R09Obj(statepv, apfail, state)    
%REQ: (FiniteStateMachine.STATE{t-1}==3 and FiniteStateMachine.apfail) impl (FiniteStateMachine.STATE{t}==2);
%VIOLATION: (FiniteStateMachine.STATE{t-1}==3 and FiniteStateMachine.apfail) and (FiniteStateMachine.STATE{t}~=2);
term1 = zeros(3,1); 

    term1(1) = abs(statepv - 3);
    
    if (apfail == 1 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
    term1(3) = 0.0001 - abs(state - 2);
    
    R09 = max(term1);          
end

%% Requirement 10
% The sensor shall change states from NOMINAL to FAULT when limits are exceeded.
function R10 = R10Obj(senstatepv, limits, senstate)    
%REQ: (FiniteStateMachine.SENSTATE{t-1}==0 and limits) impl (FiniteStateMachine.SENSTATE{t}==2);
%VIOLATION: (FiniteStateMachine.SENSTATE{t-1}==0 and limits) and (FiniteStateMachine.SENSTATE{t}~=2);
  term1 = zeros(3,1);
  
    term1(1) = abs(senstatepv);
    
    if (limits == 1 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end    
    
    term1(3) = 0.0001 - abs(senstate - 2);
    
    R10 = max(term1);     
end

%% Requirement 11
% The sensor shall change states from NOMINAL to TRANSITION when the autopilot is not requesting support (not request).
function R11 = R11Obj(senstatepv, request, senstate)    
%REQ: (FiniteStateMachine.SENSTATE{t-1}==0 and not FiniteStateMachine.REQUEST{t}) impl (FiniteStateMachine.SENSTATE{t}==1);
%VIOLATION: (FiniteStateMachine.SENSTATE{t-1}==0 and not FiniteStateMachine.REQUEST{t}) and (FiniteStateMachine.SENSTATE{t}~=1);
 term1 = zeros(3,1);   
 
    term1(1) = abs(senstatepv);
    
    if (request == 0 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
    term1(3) = 0.0001 - abs(senstate - 1);
    
    R11 = max(term1);        
end

%% Requirement 12
% The sensor shall change states from FAULT to TRANSITION when the autopilot
% is not requesting support (not request) and limits are not exceeded (not limits).
function R12 = R12Obj(senstatepv, request, limits, senstate)    
%REQ: (FiniteStateMachine.SENSTATE{t-1}==2 and not FiniteStateMachine.REQUEST and not limits) impl (FiniteStateMachine.SENSTATE{t}==1);
%VIOLATION: (FiniteStateMachine.SENSTATE{t-1}==2 and not FiniteStateMachine.REQUEST and not limits) and (FiniteStateMachine.SENSTATE{t}~=1);
 term1 = zeros(4,1); 
    
    term1(1) = abs(senstatepv - 2);  
    
    if (request == 0 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
    if (limits == 0 )
        term1(3) = -1;
    else
        term1(3) = 1;
    end
    
    term1(4) = 0.0001 - abs(senstate - 1);
    
    R12 = max(term1);        
end

%% Requirement 13
%  The sensor shall change states from TRANSITION to NOMINAL when the autopilot
% is requesting support (request) and the autopilot reports the correct active mode (mode).
function R13 = R13Obj(senstatepv, request, mode, senstate)    
%REQ: (FiniteStateMachine.SENSTATE{t-1}==1 and FiniteStateMachine.REQUEST and FiniteStateMachine.MODE) impl (FiniteStateMachine.SENSTATE{t}==0);
%VIOLATION: (FiniteStateMachine.SENSTATE{t-1}==1 and FiniteStateMachine.REQUEST and FiniteStateMachine.MODE) and (FiniteStateMachine.SENSTATE{t}~=0);
   term1 = zeros(4,1); 
   
    term1(1) = abs(senstatepv - 1); 
    
    if (request == 1 )
        term1(2) = -1;
    else
        term1(2) = 1;
    end
    
    if (mode == 1 )
        term1(3) = -1;
    else
        term1(3) = 1;
    end
    
   term1(4) = 0.0001 - abs(senstate);
    
    R13 = max(term1);         
end
  
  






