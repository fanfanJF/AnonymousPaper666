%% This file provides information about various faults used in the FIM for conducting fault injection experiments 

___________________________________________________________________________________________________________________________________________________________________
___________________________________________________________________________________________________________________________________________________________________

## Faulttype_ft	
We utilize the following faults (see the simulink library 'FInjLib.slx' in the folder 'FaultInjector_Master' for more details):

Faults -

1) "Negate" : u to -u (for all signals of type 'double')
2) "Invert" : inverts a non-zero signal 'u' to 0; otherwise if u is 0, then inverts u to not u i.e., 0 to 1 (for all signals)
3) "Stuck-at 0" : (Zero fault): makes the signal value 0 for the specified time (for all signals)
4) "Absolute" : u to |u| (for all signals of type 'double')
5) "Noise" : Adds a band limited white noise to the input signal based on the specified fault value [noise power] (for all signals of type 'double')
6) "Bias/Offset" : Adds a predefined +ve or -ve offset (bias) value to the input signal (for all signals of type 'double')
7) "Stuck-at" : the signal value stucks at the last correct value before fault occurrence (for all signals)
8) "Time Delay" : introduces a delay of specified duration in the input signal
9) "Bit Flip" : performs Bitwise NOT operation on the boolean signal. (The bits are inverted in the binary representation of the correct value).
10) "Package Drop" : replaces the input signal value by the specified fault value

Mutation operators-

11) "ROR" : Relational Operator Replacement - replaces the original relational operator with the chosen one.

Operator list:

1 - >
2 - <
3 - <=
4 - >=
5 - ==
6 - ~=

12) "LOR" : Logical Operator Replacement - replaces the original logical operator with the chosen one.

Operator list:

1 - AND
2 - OR
3 - NAND
4 - NOR
5 - XOR
6 - NXOR

13) "S2P" : Sum to Product mutation - replaces a sum block by a product block

14) "P2S" : Product to Sum mutation - replaces a Product block by a Sum block

15) "ASR" : Arithmetic Sign replacement operator - replaces the sign of the sum operator with the chosen one.

Operator list:

1 : +-
2 : --
3 : ++
4 : -+
__________________________________________________________________________________________________________________________________________________________________

## Faultvalue_fv	

For the faults "Noise", "Bias/Offset" and "Package Drop", we specify the 'fault value' as:
1) For "Noise" fault: Fault value = Noise power of the band limited white noise
2) For "Bias/Offset" fault: Fault value = +ve or -ve offset (bias) value
3) For "Package Drop": The correct output is replaced by the specified fault value

___________________________________________________________________________________________________________________________________________________________________

## FaultOccurenceTime_fot

For each fault, we also specify the time of fault occurence (i.e., the time at which the fault is injected in the simulink model).

___________________________________________________________________________________________________________________________________________________________________

## FaultEffect_fe

For all the faults (from 1-15 listed above), FIM provides two types of fault effects: 
1) Constant time: The fault is injected during the specified time. (Fault is injected at the time of fault occurence and fault persists for the specified duration.)
2) Infinite time: The fault persists till the simulation time starting from the time of fault occurence.

___________________________________________________________________________________________________________________________________________________________________

## Fault Duration_fd
	
If fault effect is "Constant time", we need to specify the fault duration (time in seconds). 

___________________________________________________________________________________________________________________________________________________________________

## Fault Operator Number_fo

Specify the operator number from the operator list if "Faulttype_ft" is "ROR"/"LOR"/"ASR"
