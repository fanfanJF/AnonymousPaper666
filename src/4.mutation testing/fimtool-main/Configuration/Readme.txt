%% This file provides information about the settings in the Configuration file of the FIM
_______________________________________________________________________________________________________________________________________________________________________

Specify the following inputs to the configuration file

model                   ---->  the name of the simulink model along with its path. For e.g., cav_benchmark/Autotrans.slx
constants_thresholds    ---->  constants required for simulating the model stored in .mat file. For e.g., ModelConstantsThresholds_autotransmod04.mat
fault_injector_folder   ---->  the folder which contains all the files related to the chosen model. For e.g., Autotrans_fault_injector
fault_list              ----> a list of faults and information stored in a spreadsheet file. For e.g., Fault_injection_list_Autotrans.xlsx

________________________________________________________________________________________________________________________________________________________________________

%%%% Details of the "fault_list"

Column 1: level_final	 
Column 2: Src_or_InportName	
Column 3: Dst_or_OutportName	
Column 4: ParentBlock	
Column 5: Faulttype_ft	


%% Information about various inputs that the user has to feed in the fault list while using the tool FIM for fault injection 

Column 1: level_final         --------> specify the level in the model (hierarchy depth of the simulink model)
Column 2: Src_or_InportName   -------> selects all lines whose Input port/ Source has the name "Src_or_InportName"
                                        If fault is to be injected in all lines, specify "NA"
Column 3: Dst_or_OutportName  -------> selects all lines whose Output port/ Destination has the name "Dst_or_OutportName"
                                        If fault is to be injected in all lines, specify "NA"
Column 4: ParentBlock         --------> specify the name of the block to select all the lines that either originate from or are are included within this ParentBlock, faults are injected only in the selected lines
                                        If fault is to be injected in all lines, specify "NA"

%% Examples
ParentBlock : "Engine"
Src_or_InportName : "NA"
Dst_or_OutportName : "NA"

The user should ensure that s/he enter valid inputs i.e., valid source, destination and parent block names. If you don't want to specify anything, 
enter "NA". If you enter invalid inputs, there will be errors!!

