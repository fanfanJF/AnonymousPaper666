


function [output, fitness]=compute_twotanks(slx,inp1,inp2)
  open_system(strcat(slx,'.slx'));   
  cs = getActiveConfigSet(slx);
  model_cs = cs.copy;
  set_param(model_cs,'MaxDataPoints' ,' off',  'FixedStep', '0.1', 'LimitDataPoints', 'off', 'ReturnWorkspaceOutputs','on','SaveOutput','on', 'OutputSaveName', 'varout', 'StartTime', '0' , 'StopTime', '500');
  

  %Constants from the model;
  tank1_max_height = 7.0; 
  tank2_max_height = 4.0; 
  tank1_cross_section_area_m2_constant = str2double(get_param([slx,'/Constants/tank1_cross_section_area_m2_constant'],'Value')); 
  tank2_cross_section_area_m2_constant = str2double(get_param([slx,'/Constants/tank2_cross_section_area_m2_constant'],'Value')); 
  tank1_sensor_hi_height_m_constant = str2double(get_param([slx,'/Constants/tank1_sensor_hi_height_m_constant'],'Value'));   
  tank1_sensor_lo_height_m_constant = str2double(get_param([slx,'/Constants/tank1_sensor_lo_height_m_constant'],'Value')); 
  tank2_sensor_hi_height_m_constant = str2double(get_param([slx,'/Constants/tank2_sensor_hi_height_m_constant'],'Value')); 
  tank2_sensor_md_height_m_constant = str2double(get_param([slx,'/Constants/tank2_sensor_md_height_m_constant'],'Value')); 
  tank2_sensor_lo_height_m_constant = str2double(get_param([slx,'/Constants/tank2_sensor_lo_height_m_constant'],'Value')); 
  tank1_pump_flow_rate_m3s_constant = str2double(get_param([slx,'/Constants/tank1_pump_flow_rate_m3s_constant'],'Value')); 
  tank1_valve_flow_rate_m3s_constant = str2double(get_param([slx,'/Constants/tank1_valve_flow_rate_m3s_constant'],'Value')); 
  tank2_e_valve_flow_rate_m3s_constant = str2double(get_param([slx,'/Constants/tank2_e_valve_flow_rate_m3s_constant'],'Value')); 
  tank2_p_valve_flow_rate_m3s_constant = str2double(get_param([slx,'/Constants/tank2_p_valve_flow_rate_m3s_constant'],'Value')); 
  time_increment_s = str2double(get_param([slx,'/time_increment_s'],'Value')); 
  
 

      tank1_init_height_m=inp1; %value between 0 and 2; %input 1
      tank2_init_height_m=inp2; %between 0 and 1; %input 2
      set_param([slx,'/Initializer_and_Updater/Initial Conditions/tank1_init_height_m'],'Value', num2str(tank1_init_height_m)); 
      set_param([slx,'/Initializer_and_Updater/Initial Conditions/tank2_init_height_m'],'Value', num2str(tank2_init_height_m));  
      simOut = sim([slx,'.slx'], model_cs);
      varout=simOut.get('varout');
      %Outputs from the model;
      t = varout.time;
      tank1_liquid_height_m = varout.signals(1).values;
      tank2_liquid_height_m = varout.signals(2).values;
      tank1_SH_value = varout.signals(3).values; 
      tank1_SL_value = varout.signals(4).values; 
      tank2_SH_value = varout.signals(5).values; 
      tank2_SM_value = varout.signals(6).values; 
      tank2_SL_value = varout.signals(7).values;
      pump_state = varout.signals(8).values; 
      valve_state = varout.signals(9).values;
      p_valve_state = varout.signals(10).values;
      e_valve_state = varout.signals(11).values;

      output={tank1_liquid_height_m,tank2_liquid_height_m,tank1_SH_value,tank1_SL_value,tank2_SH_value,tank2_SM_value,tank2_SL_value,pump_state,valve_state,p_valve_state,e_valve_state};
      fitness={};

      F = 100 * ones(size(t,1), 1); 
      for i = 1:size(t,1)       
          %% R1 from page 7: Tank1 shall not overflow.                    
          Ft = R1R2Obj(tank1_liquid_height_m(i), tank1_max_height, tank1_cross_section_area_m2_constant);
          F(i) = Ft;
      end
      FR = min(F);
      fitness{1}=FR;

      F = 100 * ones(size(t,1), 1);      
      for i = 1:size(t,1)       
          %% R2 from page 7: Tank2 shall not overflow.
          Ft = R1R2Obj(tank2_liquid_height_m(i), tank2_max_height, tank2_cross_section_area_m2_constant);
          F(i) = Ft;
      end 
      FR = min(F);
      fitness{2}=FR;

      F = 100 * ones(size(t,1), 1); 
      %% R7 from page 7
      F(1) = R07Obj(tank2_liquid_height_m, tank2_sensor_hi_height_m_constant);
      FR = min(F);
      fitness{3}=FR;

      F = 100 * ones(size(t,1), 1); 
      %% R8 from page 8 
      F(1) = R08Obj(tank2_liquid_height_m, tank2_sensor_lo_height_m_constant); 
      FR = min(F);
      fitness{4}=FR;

      F = 100 * ones(size(t,1), 1); 
      for i = 1:size(t,1)
          %% R05 from Section 1.6, page 10                  
          Ft = R5toR14Obj(tank1_liquid_height_m(i), tank1_sensor_hi_height_m_constant, tank1_SH_value(i), 1); 
          F(i) = Ft;
      end
      FR = min(F);
      fitness{5}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
      %% R06 from Section 1.6, page 11
          Ft = R5toR14Obj(tank1_liquid_height_m(i), tank1_sensor_hi_height_m_constant, tank1_SH_value(i), 0);                    
          F(i) = Ft;
      end     
      FR = min(F);
      fitness{6}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R07 from Section 1.6, page 11        
          Ft = R5toR14Obj(tank1_liquid_height_m(i), tank1_sensor_lo_height_m_constant, tank1_SL_value(i), 1);                              
          F(i) = Ft;
      end
      FR = min(F);
      fitness{7}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R08 from Section 1.6, page 11
          Ft = R5toR14Obj(tank1_liquid_height_m(i), tank1_sensor_lo_height_m_constant, tank1_SL_value(i), 0);
          F(i) = Ft;
      end
      FR = min(F);
      fitness{8}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R09 from Section 1.6, page 11          
          Ft = R5toR14Obj(tank2_liquid_height_m(i), tank2_sensor_hi_height_m_constant, tank2_SH_value(i), 1);                       
          F(i) = Ft;
      end  
      FR = min(F);
      fitness{9}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R10 from Section 1.6, page 11
          Ft = R5toR14Obj(tank2_liquid_height_m(i), tank2_sensor_hi_height_m_constant, tank2_SH_value(i), 0);                    
          F(i) = Ft;
      end 
      FR = min(F);
      fitness{10}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R11 from Section 1.6, page 11
          Ft = R5toR14Obj(tank2_liquid_height_m(i), tank2_sensor_md_height_m_constant, tank2_SM_value(i), 1);                    
          F(i) = Ft;
      end 
      FR = min(F);
      fitness{11}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R12 from Section 1.6, page 11
          Ft = R5toR14Obj(tank2_liquid_height_m(i), tank2_sensor_md_height_m_constant, tank2_SM_value(i), 0);                    
          F(i) = Ft;
      end     
      FR = min(F);
      fitness{12}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R13 from Section 1.6, page 11
          Ft = R5toR14Obj(tank2_liquid_height_m(i), tank2_sensor_lo_height_m_constant, tank2_SL_value(i), 1);                    
          F(i) = Ft;
      end
      FR = min(F);
      fitness{13}=FR;
       
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R14 from Section 1.6, page 12
          Ft = R5toR14Obj(tank2_liquid_height_m(i), tank2_sensor_lo_height_m_constant, tank2_SL_value(i), 0);
          F(i) = Ft;
      end 
      FR = min(F);
      fitness{14}=FR;
        
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R16 from Section 1.7, page 12
          Ft = R16Obj((tank1_liquid_height_m(i)-tank1_liquid_height_m(i-1)), time_increment_s, tank1_valve_flow_rate_m3s_constant, tank1_pump_flow_rate_m3s_constant,tank1_cross_section_area_m2_constant);
          F(i-1) = Ft;
      end   
      FR = min(F);
      fitness{15}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R17 from Section 1.7, page 12
          Ft = R17Obj((tank1_liquid_height_m(i)-tank1_liquid_height_m(i-1)), tank1_valve_flow_rate_m3s_constant, tank1_pump_flow_rate_m3s_constant, time_increment_s, tank1_cross_section_area_m2_constant, pump_state(i),valve_state(i));
          F(i-1) = Ft;
      end
      FR = min(F);
      fitness{16}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R18 from Section 1.7, page 12
          Ft = R18Obj((tank1_liquid_height_m(i)-tank1_liquid_height_m(i-1)),pump_state(i),valve_state(i));
          F(i-1) = Ft;
      end   
      FR = min(F);
      fitness{17}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R19 from Section 1.7, page 12
          Ft = R19Obj((tank1_liquid_height_m(i)-tank1_liquid_height_m(i-1)),pump_state(i),valve_state(i));
          F(i-1) = Ft;
      end
      FR = min(F);
      fitness{18}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R20 from Section 1.7, page 12
          Ft = R20Obj((tank1_liquid_height_m(i)-tank1_liquid_height_m(i-1)),pump_state(i),valve_state(i));
          F(i-1) = Ft;
      end    
      FR = min(F);
      fitness{19}=FR;
       
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R26 from Section 1.8, page 13
          Ft = R26Obj((tank2_liquid_height_m(i)-tank2_liquid_height_m(i-1)), time_increment_s, tank1_valve_flow_rate_m3s_constant, tank2_p_valve_flow_rate_m3s_constant, tank2_e_valve_flow_rate_m3s_constant, tank2_cross_section_area_m2_constant);   
          F(i-1) = Ft;
      end  
      FR = min(F);
      fitness{20}=FR;

      F = 100 * ones(size(t,1), 1);  
      for i = 2:size(t,1)
          %% R27 from Section 1.8, page 13
          Ft = R27Obj((tank2_liquid_height_m(i)-tank2_liquid_height_m(i-1)),tank1_valve_flow_rate_m3s_constant, tank2_p_valve_flow_rate_m3s_constant, tank2_e_valve_flow_rate_m3s_constant,time_increment_s, tank2_cross_section_area_m2_constant, valve_state(i), p_valve_state(i), e_valve_state(i));   
          F(i-1) = Ft;
      end   
      FR = min(F);
      fitness{21}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R28 from Section 1.8, page 13
          Ft = R28Obj((tank2_liquid_height_m(i)-tank2_liquid_height_m(i-1)), valve_state(i), p_valve_state(i), e_valve_state(i));   
          F(i-1) = Ft;
      end
      FR = min(F);
      fitness{22}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R29 from Section 1.8, page 13
          Ft = R29Obj((tank2_liquid_height_m(i)-tank2_liquid_height_m(i-1)), valve_state(i), p_valve_state(i), e_valve_state(i));   
          F(i-1) = Ft;
      end
      FR = min(F);
      fitness{23}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R30 from Section 1.8, page 13
          Ft = R30Obj((tank2_liquid_height_m(i)-tank2_liquid_height_m(i-1)), valve_state(i), p_valve_state(i), e_valve_state(i));   
          F(i-1) = Ft;
      end   
      FR = min(F);
      fitness{24}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R31 from Section 1.8, page 14
          Ft = R31Obj((tank2_liquid_height_m(i)-tank2_liquid_height_m(i-1)), valve_state(i), p_valve_state(i), e_valve_state(i));   
          F(i-1) = Ft;
      end 
      FR = min(F);
      fitness{25}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R01 from Section 2.1, page 14
          Ft = R211Obj(tank1_SL_value(i), pump_state(i), valve_state(i));   
          F(i) = Ft;
      end  
      FR = min(F);
      fitness{26}=FR;
        
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R02 from Section 2.1, page 15
          Ft = R212Obj(tank1_SH_value(i), pump_state(i), valve_state(i));
          F(i) = Ft;
      end   
      FR = min(F);
      fitness{27}=FR;
       
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R03 from Section 2.1, page 15
          Ft = R213Obj(tank1_SH_value(i), tank1_SL_value(i), (pump_state(i)-pump_state(i-1)), (valve_state(i)-valve_state(i-1))); 
          F(i-1) = Ft;
      end    
      FR = min(F);
      fitness{28}=FR;
  
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R07 from Section 2.2, page 15
          Ft = R227Obj(tank2_SL_value(i), p_valve_state(i), e_valve_state(i));
          F(i) = Ft;
      end 
      FR = min(F);
      fitness{29}=FR;
  
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R08 from Section 2.2, page 16
          Ft = R228Obj(tank2_SL_value(i), tank2_SM_value(i), p_valve_state(i), e_valve_state(i));
          F(i) = Ft;
      end    
      FR = min(F);
      fitness{30}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)
          %% R09 from Section 2.2, page 16
          Ft = R229Obj(tank2_SH_value(i), p_valve_state(i), e_valve_state(i));
          F(i) = Ft;
      end   
      FR = min(F);
      fitness{31}=FR;
    
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R10 from Section 2.2, page 16
          Ft = R2210Obj(tank2_SH_value(i),tank2_SM_value(i), p_valve_state(i), e_valve_state(i), e_valve_state(i-1));
          F(i-1) = Ft;
      end   
      FR = min(F);
      fitness{32}=FR;
      
      F = 100 * ones(size(t,1), 1);
      for i = 2:size(t,1)
          %% R11 from Section 2.2, page 16
          Ft = R2211Obj(tank2_SH_value(i),tank2_SM_value(i), p_valve_state(i), e_valve_state(i), e_valve_state(i-1));
          F(i-1) = Ft;
      end 
      FR = min(F);
      fitness{33}=FR;
    
      F = 100 * ones(size(t,1), 1);
      for i = 1:size(t,1)       
          %% R1 from page 7: Tank1 shall not overflow.                    
          Ft = R1R2Obj(tank1_liquid_height_m(i), tank1_max_height, tank1_cross_section_area_m2_constant);
          F(i) = Ft;
      end   
      FR = min(F);
      fitness{34}=FR;

%    save_system(strcat(slx,'.slx'));
%    close_system(strcat(slx,'.slx'));
      
end


%% For System Level Requirements, R1-R2
function R1R2 = R1R2Obj(TankHeight, TankMaxHeight, TankCrossSec)      
    
    % Req:       TankHeight(t) <= TankMaxHeight * TankCrossSec
    % Violation: TankHeight(t) > TankMaxHeight * TankCrossSec
    
        R1R2 = 0.0001 - (TankHeight - (TankMaxHeight * TankCrossSec)); 
    

end

function R07 = R07Obj(TankHeight, SafeLevel)   
 
% Violation:    F( B(Tank2Height(t) >= SafeLevel) AND B(Tank2Height(t+1) >= SafeLevel) AND ...AND B(Tank2Height(t+k) >= SafeLevel) )
 
    xmin = 1000;
    termk = zeros(1,1);
    
    for k=1:1
        
    for t=1:size(TankHeight,1)-1
        
        term = round(SafeLevel - TankHeight(t), 4);
       
        termk(k) = round(SafeLevel - TankHeight(t+k), 4);
    
    end
    
    xmin = min(xmin, max(term, max(termk)));
      
    end
    
    R07 = xmin;
        
end


function R08 = R08Obj(TankHeight, SafeLevel)   

% Violation:    F( B(Tank2Height(t) <= SafeLevel) AND B(Tank2Height(t+1) >= SafeLevel) AND ...AND B(Tank2Height(t+k) <= SafeLevel) )

    xmin = 1000;
    termk = zeros(1,1);
    
    for k=1:1
        
    for t=1:size(TankHeight,1)-1
            
        term = round(TankHeight(t) - SafeLevel, 4);
                         
        termk(k) = round(TankHeight(t+k) - SafeLevel, 4);

    end
        
        xmin = min(xmin, max(term, max(termk))); 
      
    end
    
    R08 = xmin;
        
end

 %% For Sensor Requirements (Section 1.6), R05--R14
 function R5toR14 = R5toR14Obj(TankHeight, TankSensorHeight,TankSensorValue, Var)     
    
    % Req:       (TankHeight(t) > TankSensorHeight) ==> (TankSensorValue == Var)
    % Violation: (TankHeight(t) > TankSensorHeight) AND (TankSensorValue <> Var)
 
        term1 = 0.0001 - (TankHeight - TankSensorHeight);

        term2 = 0.0001 - abs(round(TankSensorValue - Var, 4));
 
        R5toR14 = max(term1 ,term2);     

 end
 
 %% For Tank 1 Requirements (Section 1.7), R16
 function R16 = R16Obj(TankHeightDiff, TimeIncrement, TankValveFlow, TankPumpFlow, TankCrossSec)     
 
   % (TimeIncrement * -TankValveFlow <= 
   % (TankHeight(t) - TankHeight(t-1)) * TankCrossSec)
   % AND
   % ((TankHeight(t) - TankHeight(t-1)) * TankCrossSec) <= 
   % TimeIncrement * TankPumpFlow) 
     
   % term1 = (TimeIncrement * (-TankValveFlow)) - ((TankHeight(t) - TankHeight(t-1)) * TankCrossSec)
   % term2 = ((TankHeight(t) - TankHeight(t-1)) * TankCrossSec) - (TimeIncrement * TankPumpFlow);
    x = TimeIncrement * (-1 * TankValveFlow);
    y = TankHeightDiff * TankCrossSec; %TankHeight = TankHeight(t) - TankHeight(t-1)
    z = TimeIncrement * TankPumpFlow;
    
    % Req :       x<=y AND y<=z  
    % Violation : y<x OR z<y    
    term1 = 0.0001 + round(y - x, 4); 

    term2 = 0.0001 + round(z - y, 4);

    R16 = min(term1, term2);

 end
 
  %% For Tank 1 Requirements (Section 1.7), R17
 function R17 = R17Obj(TankHeightDiff, TankValveFlow, TankPumpFlow, TimeIncrement, TankCrossSec, PumpState, ValveState)     
        format short g;
        termR = zeros(4,1);
        termC1  = zeros(3,1);
        termC2  = zeros(3,1);
        termC3  = zeros(3,1);
        termC4  = zeros(3,1);
        %%%%%%%%%R17-term1%%%%%%%%%%%%
        % Req:          % ((PumpState == 1) AND (ValveState == 1)) ==> 
                        % (TankHeight(t) == TankHeight(t-1) + (TankPumpFlow -TankValveFlow) * TimeIncrement / TankCrossSec)
        
        % Violation :   %((PumpState == 1) AND (ValveState == 1)) AND
                        %(TankHeight(t) <> TankHeight(t-1) + (TankPumpFlow -TankValveFlow) * TimeIncrement / TankCrossSec)
        
        C1 = ((TankPumpFlow -  TankValveFlow) * TimeIncrement) / TankCrossSec;            
 
            termC1(1) = abs(PumpState-1);
            termC1(2) = abs(ValveState-1);           
            termC1(3) = 0.0001 - abs(round(TankHeightDiff - C1, 4));
        
            termR(1) = max(termC1);

        
        %%%%%%%%%R17-term2%%%%%%%%%%%%
        % Req:          % ((PumpState == 1) AND (ValveState == 0)) ==> 
                        % TankHeight(t) == TankHeight(t-1) + (TankPumpFlow  * TimeIncrement / TankCrossSec)
        
        % Violation :   % ((PumpState == 1) AND (ValveState == 0)) AND
                        % TankHeight(t) <> TankHeight(t-1) + (TankPumpFlow  * TimeIncrement / TankCrossSec)
        
        C2 = (TankPumpFlow  * TimeIncrement)/ TankCrossSec;
        
            termC2(1) = abs(PumpState-1);
            termC2(2) = abs(ValveState);
            termC2(3) = 0.0001 - abs(round(TankHeightDiff - C2, 4));

            termR(2) = max(termC2);
            
        
        %%%%%%%%%R17-term3%%%%%%%%%%%%
        % Req:          % (PumpState == 0 AND ValveState == 1 ==> 
                        % TankHeight(t) == TankHeight(t-1) - (TankValveFlow * TimeIncrement / TankCrossSec)
        
        % Violation :   % (PumpState == 0 AND ValveState == 1 AND
                        % TankHeight(t) <> TankHeight(t-1) - (TankValveFlow * TimeIncrement / TankCrossSec)  
        
        C3 = (-1 * TankValveFlow  * TimeIncrement) / TankCrossSec;
        
            termC3(1) = abs(PumpState);
            termC3(2) = abs(ValveState-1);
            termC3(3) = 0.0001 - abs(round(TankHeightDiff - C3, 4));
        
            termR(3) = max(termC3);
                
        %%%%%%%%%R17-term4%%%%%%%%%%%%
        % Req:          % (PumpState == 0 AND ValveState == 0 ==> 
                        % TankHeight(t) == TankHeight(t-1) 
        
        % Violation :   % (PumpState == 0 AND ValveState == 0 AND 
                        % TankHeight(t) <> TankHeight(t-1)
            
            termC4(1) = abs(PumpState);
            termC4(2) = abs(ValveState);
            termC4(3) = 0.0001 - abs(TankHeightDiff);
            
            termR(4) = max(termC4);
                
     R17 = min(termR);
    
      
 end
 
  %% For Tank 1 Requirements (Section 1.7), R18
 function R18 = R18Obj(TankHeightDiff, PumpState, ValveState) 
 
        term = zeros(3,1);
        % Req:          % (PumpState == 1 AND ValveState == 0 ==> 
                        % TankHeight(t) > TankHeight(t-1) 
        
        % Violation :   % (PumpState == 1 AND ValveState == 0 AND
                        % TankHeight(t) <= TankHeight(t-1)
                        
        term(1) = abs(PumpState-1); 
        term(2) = abs(ValveState); 
        term(3) = TankHeightDiff;
                        
        R18 = max(term);
                                       
 end
 
   %% For Tank 1 Requirements (Section 1.7), R19
 function R19 = R19Obj(TankHeightDiff, PumpState, ValveState)     
       
        term = zeros(3,1);
        % Req:          % (PumpState == 0 AND ValveState == 1 ==> 
                        % TankHeight(t) < TankHeight(t-1) 
        
        % Violation :   % (PumpState == 0 AND ValveState == 1 AND
                        % TankHeight(t) >= TankHeight(t-1)  

           
        term(1) = abs(PumpState); 
        term(2) = abs(ValveState-1); 
        term(3) = (-1) * TankHeightDiff;
        
        R19 =  max(term);
        
 end
 
   %% For Tank 1 Requirements (Section 1.7), R20
 function R20 = R20Obj(TankHeightDiff, PumpState, ValveState)     
        
        term = zeros(3,1);
         % Req:          % (PumpState == 0 AND ValveState == 0 ==> 
                        % TankHeight(t) == TankHeight(t-1) 

        % Violation :   % PumpState == 0 AND ValveState == 0 AND
                        % TankHeight(t) <> TankHeight(t-1)   

        term(1) = abs(PumpState); 
        term(2) = abs(ValveState); 
        term(3) = 0.0001 - abs(TankHeightDiff);
                        
        R20 = max(term);
                             
 end
 
  %% For Tank 2 Requirements (Section 1.8), R26
 function R26 = R26Obj(TankHeightDiff, TimeIncrement, TankValveFlow, TankPValveFlow, TankEValveFlow, TankCrossSec)     
 
        % (- (TankPValveFlow + TankEValveFlow) * TimeIncrement ) <= 
        % (TankCrossSec * (TankHeight(t) - TankHeight(t-1))
        % AND
        % ((TankCrossSec * (TankHeight(t) - TankHeight(t-1))  <= 
        % TimeIncrement * Tank1ValveFlow) 
        
        x= -1 * (TankPValveFlow + TankEValveFlow) * TimeIncrement;
        y = TankHeightDiff * TankCrossSec; %TankHeight = TankHeight(t) - TankHeight(t-1)
        z = TimeIncrement * TankValveFlow;
        
   
        % Req :       x<=y AND y<=z  
        % Violation : y<x OR z<y
            term1 = 0.0001 + round(y - x, 4);

            term2 = 0.0001 + round(z - y, 4);     
       
            R26 = min(term1, term2);

 end
 
  %% For Tank 2 Requirements (Section 1.8), R27
 function R27 = R27Obj(TankHeightDiff, TankValveFlow, TankPValveFlow, TankEValveFlow, TimeIncrement, TankCrossSec, ValveState, PValveState, EValveState)     
        format short g;
        termR = zeros(8,1);
        termC1  = zeros(4,1);
        termC2  = zeros(4,1);
        termC3  = zeros(4,1);
        termC4  = zeros(4,1);
        termC5  = zeros(4,1);
        termC6  = zeros(4,1);
        termC7  = zeros(4,1);
        termC8  = zeros(4,1);
        
        %%%%%%%%%R27-term1%%%%%%%%%%%% 
        % Req:          % ((ValveState == 1) AND (PValveState == 1) AND (EValveState == 1)   ==> 
                        % (TankHeight(t) == TankHeight(t-1) + (TankValveFlow - TankPValveFlow - TankEValveFlow) * TimeIncrement / TankCrossSec)
        
        
        % Violation :   % ((ValveState == 1) AND (PValveState == 1)) AND (EValveState == 1) AND
                        % (TankHeight(t) <> TankHeight(t-1) + (TankValveFlow - TankPValveFlow - TankEValveFlow) * TimeIncrement / TankCrossSec)
        C1 = (TankValveFlow -  TankPValveFlow - TankEValveFlow) * TimeIncrement / TankCrossSec;
        
        termC1(1) = abs(ValveState-1);
        termC1(2) = abs(PValveState-1);
        termC1(3) = abs(EValveState-1);
        termC1(4) = 0.0001 - abs(round(TankHeightDiff - C1, 4));
        
        termR(1) = max(termC1);
        
        %%%%%%%%%R27-term2%%%%%%%%%%%%
        % Req:          % ((ValveState == 1) AND (PValveState == 1) AND (EValveState == 0)   ==> 
                        % (TankHeight(t) == TankHeight(t-1) + (TankValveFlow - TankPValveFlow) * TimeIncrement / TankCrossSec)
                        
        % Violation :   % ((ValveState == 1) AND (PValveState == 1)) AND (EValveState == 0) AND
                        % (TankHeight(t) <> TankHeight(t-1) + (TankValveFlow - TankPValveFlow) * TimeIncrement / TankCrossSec)

        C2 = (TankValveFlow -  TankPValveFlow) * TimeIncrement / TankCrossSec;
        
        termC2(1) = abs(ValveState-1);
        termC2(2) = abs(PValveState-1);
        termC2(3) = abs(EValveState);
        termC2(4) = 0.0001 - abs(round(TankHeightDiff - C2, 4));
        
        termR(2) = max(termC2);
        
        %%%%%%%%%R27-term3%%%%%%%%%%%%
        % Req:          % ((ValveState == 1) AND (PValveState == 0) AND (EValveState == 1)   ==> 
                        % (TankHeight(t) == TankHeight(t-1) + (TankValveFlow - TankEValveFlow) * TimeIncrement / TankCrossSec)

        % Violation :   % ((ValveState == 1) AND (PValveState == 0)) AND (EValveState == 1) AND
                        % (TankHeight(t) <> TankHeight(t-1) + (TankValveFlow - TankEValveFlow) * TimeIncrement / TankCrossSec)

        C3 = (TankValveFlow - TankEValveFlow) * TimeIncrement / TankCrossSec;
        
        termC3(1) = abs(ValveState-1);
        termC3(2) = abs(PValveState);
        termC3(3) = abs(EValveState-1);
        termC3(4) = 0.0001 - abs(round(TankHeightDiff - C3, 4));
        
        termR(3) = max(termC3);
              
        %%%%%%%%%R27-term4%%%%%%%%%%%%
        % Req:          % ((ValveState == 1) AND (PValveState == 0) AND (EValveState == 0)   ==> 
                        % (TankHeight(t) == TankHeight(t-1) + TankValveFlow  * TimeIncrement / TankCrossSec)
        
        % Violation :   % (ValveState == 1) AND (PValveState == 0) AND (EValveState == 0) AND
                        % (TankHeight(t) <> TankHeight(t-1) + TankValveFlow * TimeIncrement / TankCrossSec)
        
        C4 = TankValveFlow  * TimeIncrement / TankCrossSec;
        
        termC4(1) = abs(ValveState-1);
        termC4(2) = abs(PValveState);
        termC4(3) = abs(EValveState);
        termC4(4) = 0.0001 - abs(round(TankHeightDiff - C4, 4));
        
        termR(4) = max(termC4);
              
            
        %%%%%%%%%R27-term5%%%%%%%%%%%%
        % Req:          % (ValveState == 0) AND (PValveState == 1) AND (EValveState == 1)   ==> 
                        % (TankHeight(t) == TankHeight(t-1) + ( - TankPValveFlow - TankEValveFlow) * TimeIncrement / TankCrossSec)
        
        % Violation :   % (ValveState == 0) AND (PValveState == 1) AND (EValveState == 1) AND
                        % (TankHeight(t) <> TankHeight(t-1) + ( - TankPValveFlow - TankEValveFlow) * TimeIncrement / TankCrossSec)
        
        C5 = (-1 *  (TankPValveFlow + TankEValveFlow)) * TimeIncrement / TankCrossSec;
        
        termC5(1) = abs(ValveState);
        termC5(2) = abs(PValveState-1);
        termC5(3) = abs(EValveState-1);
        termC5(4) = 0.0001 - abs(round(TankHeightDiff - C5, 4));
        
        termR(5) = max(termC5);
                        
        %%%%%%%%%R27-term6%%%%%%%%%%%%
        % Req:          % (ValveState == 0) AND (PValveState == 1) AND (EValveState == 0)   ==> 
                        % (TankHeight(t) == TankHeight(t-1) + (- TankPValveFlow ) * TimeIncrement / TankCrossSec)
        
        % Violation :   % (ValveState == 0) AND (PValveState == 1) AND (EValveState == 0) AND
                        % (TankHeight(t) <> TankHeight(t-1) + (- TankPValveFlow ) * TimeIncrement / TankCrossSec)

        C6 = ( -1 * TankPValveFlow ) * TimeIncrement / TankCrossSec;
        
        termC6(1) = abs(ValveState);
        termC6(2) = abs(PValveState-1);
        termC6(3) = abs(EValveState);
        termC6(4) = 0.0001 - abs(round(TankHeightDiff - C6, 4));
        
        termR(6) = max(termC6);
        
        %%%%%%%%%R27-term7%%%%%%%%%%%%
        % Req:          % (ValveState == 0) AND (PValveState == 0) AND (EValveState == 1)   ==> 
                        % (TankHeight(t) == TankHeight(t-1) + (- TankEValveFlow) * TimeIncrement / TankCrossSec)
        
        % Violation :   % (ValveState == 0) AND (PValveState == 0) AND (EValveState == 1) AND
                        % (TankHeight(t) <> TankHeight(t-1) + (- TankEValveFlow ) * TimeIncrement / TankCrossSec)

        C7 = (-1 * TankEValveFlow) * TimeIncrement / TankCrossSec;
        
        termC7(1) = abs(ValveState);
        termC7(2) = abs(PValveState);
        termC7(3) = abs(EValveState-1);
        termC7(4) = 0.0001 - abs(round(TankHeightDiff - C7, 4));
        
        termR(7) = max(termC7);
        %%%%%%%%%R27-term8%%%%%%%%%%%%
        % Req:          % (ValveState == 0) AND (PValveState == 0) AND (EValveState == 0)   ==> 
                        % (TankHeight(t) == TankHeight(t-1) 
                        
        % Violation :   % (ValveState == 0) AND (PValveState == 0) AND (EValveState == 0) AND
                        % (TankHeight(t) <> TankHeight(t-1) 
        
        termC8(1) = abs(ValveState);
        termC8(2) = abs(PValveState);
        termC8(3) = abs(EValveState);
        termC8(4) = 0.0001 - abs(TankHeightDiff);
        
        termR(8) = max(termC8);
        
        R27 = min(termR);
    
 end
 
 
    %% For Tank 2 Requirements (Section 1.8), R28
 function R28 = R28Obj(TankHeightDiff, ValveState, PValveState, EValveState)     
        
        term = zeros(4,1);
        %Requirement:
        % (ValveState == 1 AND PValveState == 0 AND EValveState == 0==> 
        % TankHeight(t) > TankHeight(t-1)
         
        %Violation:        
        % (ValveState == 1 AND PValveState == 0 AND EValveState == 0 AND 
        % (TankHeight(t) <= TankHeight(t-1))
        
                        
        term(1) = abs(ValveState-1);
        term(2) = abs(PValveState);
        term(3) = abs(EValveState);
        term(4) = TankHeightDiff;
        
          
        R28 = max(term);
               
        
 end
 
    %% For Tank 2 Requirements (Section 1.8), R29
 function R29 = R29Obj(TankHeightDiff, ValveState, PValveState, EValveState)     
        
        term = zeros(4,1);
        %Requirement:
        % (ValveState == 1 AND PValveState == 1 AND EValveState == 0==> 
        % TankHeight(t) > TankHeight(t-1) 
        
        %Violation:
        % (ValveState == 1 AND PValveState == 1 AND EValveState == 0 AND 
        % (TankHeight(t) <= TankHeight(t-1)) 
                               
        term(1) = abs(ValveState-1);
        term(2) = abs(PValveState-1);
        term(3) = abs(EValveState);
        term(4) = TankHeightDiff;
        
          
        R29 = max(term);
                      
 end
 
   %% For Tank 2 Requirements (Section 1.8), R30
 function R30 = R30Obj(TankHeightDiff, ValveState, PValveState, EValveState)     
        
        term = zeros(4,1);
        %Requirement:
        % (ValveState == 1 AND PValveState == 0 AND EValveState == 1  ==> 
        % TankHeight(t) < TankHeight(t-1)                        
        
        %Violation:
        % (ValveState == 1 AND PValveState == 0 AND EValveState == 1 AND 
        % (TankHeight(t) >= TankHeight(t-1))  
                        
        term(1) = abs(ValveState-1);
        term(2) = abs(PValveState);
        term(3) = abs(EValveState-1);
        term(4) = (-1) * TankHeightDiff;
        
          
        R30 = max(term);
        
 end
 
   %% For Tank 2 Requirements (Section 1.8), R31
 function R31 = R31Obj(TankHeightDiff, ValveState, PValveState, EValveState)     
        
        term = zeros(4,1);
        %Requirement:
        % (ValveState == 0 AND PValveState == 0 AND EValveState == 0 ==> 
        % TankHeight(t) == TankHeight(t-1)                    

        %Violation:
        % (ValveState == 0 AND PValveState == 0 AND EValveState == 0 AND 
        % (TankHeight(t) <> TankHeight(t-1)) 
     
        term(1) = abs(ValveState);
        term(2) = abs(PValveState);
        term(3) = abs(EValveState);
        term(4) = 0.0001 -  abs(TankHeightDiff);
        
          
        R31 = max(term);       
               
 end
 
   %% For Tank 1 Controller Requirements (Section 2.1), R01
  function R211 = R211Obj(TankSensorValue, PumpState, ValveState)

        %Requirement:
        %(TankSensorValue == 0 ==> PumpState == 1 AND ValveState == 0
       
        %Violation:
        %(TankSensorValue == 0 AND (PumpState == 0 OR ValveState == 1)
        
        term1 = abs(TankSensorValue);
        term2 = min(abs(PumpState),abs(ValveState-1));

        
        R211 = max(term1, term2);
        
  end
  
   %% For Tank 1 Controller Requirements (Section 2.1), R02
  function R212 = R212Obj(TankSensorValue, PumpState, ValveState)
      
        %Requirement:
        %(TankSensorValue == 1 ==> PumpState == 0 AND ValveState == 1
        
        %Violation:
        %(TankSensorValue == 1 AND (PumpState == 1 OR ValveState == 0)
        term1 = abs(TankSensorValue-1);
        term2 = min(abs(PumpState-1),abs(ValveState));
        
        R212 = max(term1, term2);
         
  end
     %% For Tank 1 Controller Requirements (Section 2.1), R03
  function R213 = R213Obj(TankSensorHValue, TankSensorLValue, PumpStateDiff, ValveStateDiff)

        term = zeros(3,1);
        %Requirement:
        % (TankHSensorValue == 0 AND TankSensorLValue == 1 ==> 
        % PumpState(t) == PumpState(t-1) AND ValveState(t) ==
        % ValveState(t-1)
        
       %Violation:
       % (TankHSensorValue == 0 AND TankSensorLValue == 1 AND 
        % (PumpState(t) <> PumpState(t-1) OR ValveState(t) <>
        % ValveState(t-1))
        
        term(1) = abs(TankSensorHValue);
        term(2) = abs(TankSensorLValue-1);
        term(3) = min(0.0001 - abs(PumpStateDiff), 0.0001 - abs(ValveStateDiff));
        
        R213 = max(term);
           
        
  end

%% For Tank 2 Controller Requirements (Section 2.2), R07
  function R227 = R227Obj(TankSensorValue, PValveState, EValveState)
       
       %Requirment:   
       %(TankSensorValue == 0 ==> PValveState == 0 AND EValveState == 0

       %Violation:
       %(TankSensorValue == 0 AND (PValveState == 1 OR EValveState == 1)
       
        
        term1 = abs(TankSensorValue);
        term2 = min(abs(PValveState-1), abs(EValveState-1)) ;

        R227 = max(term1, term2);
  end

  %% For Tank 2 Controller Requirements (Section 2.2), R08
  function R228 = R228Obj(TankSensorLValue, TankSensorMValue, PValveState, EValveState)
       
        term = zeros(3,1);
        %Requirement:
        %(TankSensorLValue == 1 AND TankSensorMValue == 0 ==> PValveState == 1 AND EValveState == 0
        
        %Violation:
        %(TankSensorLValue == 1 AND TankSensorMValue == 0 AND (PValveState == 0 OR EValveState == 1)
           
        term(1) = abs(TankSensorLValue-1);
        term(2) = abs(TankSensorMValue);
        term(3) = min(abs(PValveState), abs(EValveState-1));
        
        R228 = max(term);
             
     
  end
  %% For Tank 2 Controller Requirements (Section 2.2), R09
  function R229 = R229Obj(TankSensorValue, PValveState, EValveState)

        %Requirement:
        %(TankSensorValue == 1 ==> PValveState == 1 AND EValveState == 1   
        
        %Violation:
        % (TankSensorValue == 1 AND (PValveState == 0 OR EValveState == 0)
        
        term1 = abs(TankSensorValue-1);
        term2 = min(abs(PValveState), abs(EValveState));

        R229 = max(term1, term2);
        
  end
 
  %% For Tank 2 Controller Requirements (Section 2.2), R10
  function R2210 = R2210Obj(TankSensorHValue, TankSensorMValue, PValveState, EValveState, EValveStateP)

        term = zeros(4,1);
        %Requirement:
        %(TankSensorHValue == 0 AND TankSensorMValue == 1 AND
        %EValveState(t-1) == 1  ==> PValveState == 1 AND EValveState == 1      
 
        %Violation:
        % (TankSensorHValue == 0 AND TankSensorMValue == 1 AND
        % EValveState(t-1) == 1  AND (PValveState == 0 OR EValveState == 0)
     
        term(1) = abs(TankSensorHValue);
        term(2) = abs(TankSensorMValue-1);
        term(3) = abs(EValveStateP-1);
        term(4) = (min(abs(PValveState), abs(EValveState)));
        
      R2210 = max(term);
      
  end
  
  %% For Tank 2 Controller Requirements (Section 2.2), R11
  function R2211 = R2211Obj(TankSensorHValue, TankSensorMValue, PValveState, EValveState, EValveStateP)

        term = zeros(4,1);
        %Requirement:
        %(TankSensorHValue == 0 AND TankSensorMValue == 1 AND
        % EValveState(t-1) == 0  ==> PValveState == 1 AND EValveState == 0
 
        %Violation:
        % (TankSensorHValue == 0 AND TankSensorMValue == 1 AND
        % EValveState(t-1) == 0  AND (PValveState == 0 OR EValveState == 1)
   
        term(1) = abs(TankSensorHValue);
        term(2) = abs(TankSensorMValue-1);
        term(3) = abs(EValveStateP);
        term(4) = (min(abs(PValveState), abs(EValveState-1)));
        
        R2211 = max(term);
  end
  
  






