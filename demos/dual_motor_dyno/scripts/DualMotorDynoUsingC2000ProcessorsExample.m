%% Control PMSM Loaded with Dual Motor (Dyno) Using C2000 Processors
% 
% This example uses field-oriented control (FOC) to control two three-phase
% permanent magnet synchronous motors (PMSM) coupled in a dyno setup.
% Motor 1 runs in the closed-loop speed control mode. Motor 2 runs in the
% torque control mode and loads Motor 1 because they are mechanically
% coupled. You can use this example to test a motor in different load
% conditions.
% 
% The example simulates two motors that are connected back-to-back. You can
% use a different speed reference for Motor 1 and a different torque
% reference for Motor 2 (derived from the magnitude and electrical position
% of the Motor 2 reference stator current). Motor 1 runs at the reference speed for
% the load conditions provided by Motor 2 (with a different torque
% reference).
% 
% The example runs in the controller hardware board. You can input the
% speed reference for Motor 1 and current reference for Motor 2 using a host
% model. The host model uses serial communication to communicate with the
% controller hardware board.
% 
% Current control loops in Motor 1 and Motor 2 control algorithms are offset
% by Ts/2, where Ts is the control-loop execution rate.
% 

% Copyright 2021-2023 The MathWorks, Inc.

%% Single CPU Dyno Models
% 
% The example includes the following models:
%
% * <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_sensorless_dyno_f28379d') mcb_pmsm_foc_sensorless_dyno_f28379d>. 
%
% * <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_qep_dyno_f28069m') mcb_pmsm_foc_qep_dyno_f28069m>.
%
% * For QEP based dyno *mcb_pmsm_foc_f28379d_dyno* example, refer <docid:mcb_gs#mw_b3b394ff-bb9c-48ff-9f47-540e96d25b43 MCB> .
% 
% You can use mcb_pmsm_foc_sensorless_dyno_f28379d and mcb_pmsm_foc_qep_dyno_f28069m models for both simulation and code generation. You can also use the open_system command to open the Simulink(R) model. 
% These models use timer0 as a base rate trigger. 
% For example, use this command for a F28379D based controller:
%%
open_system('mcb_pmsm_foc_sensorless_dyno_f28379d.slx');
%%
% 
%% Dual CPU Dyno Models
%
% The example includes the following models:
%
% * <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_dual_cpu1_f28379d') mcb_pmsm_foc_dual_cpu1_f28379d>. 
%
% * <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_dual_cpu2_f28379d') mcb_pmsm_foc_dual_cpu2_f28379d>.
%
% You can also use the open_system command to open the Simulink(R) model.
%
% *Note*: Dual core CPU models does not support simulation.
%
% For example, use this command for a F28379D based controller:
%%
open_system('mcb_pmsm_foc_dual_cpu1_f28379d.slx');
%%
% 
%%
open_system('mcb_pmsm_foc_dual_cpu2_f28379d.slx');
%%
% *IPC Communication for Dual Core Processors*
%
% The CPU1 transmits the following data to CPU2 through IPC channels:
%
% * Torque reference
%
% * Signal select
%
% * Enable Motor2(EnMtr2Ctrl)
%
% The CPU2 transmits the debug signal according to the signal select of CPU1.
%
% Core1 transmits data to its allocated memory (Core1-to-Core2 Message RAM) and receives data from the allocated memory of Core2 (Core2-to-Core1 Message RAM). 
% Similarly, Core2 transmits data to its allocated memory (Core2-to-Core1
% Message RAM) and receives data from allocated memory of Core1
% (Core1-to-Core2 Message RAM). For more information, refer <docid:c2b_ug#mw_e0a33a9f-ddd1-4f04-b06f-3c9a766046d7 Inter-Processor Communication Using IPC Blocks>. 
%
% <<../ipc_dyno.png>>
%% Peripheral Block Configurations for Dyno Setup
% Set the peripheral block configurations for this model. Double-click on the blocks to open block parameter configurations. You can use the same parameter values if you want to run this example for other hardware boards.
%
% * *ePWM Block Configuration*
% The ePWM1/2/3 is offset by ePWM time period from ePWM4/5/6. This is achieved by sending a synchronization signal from ePWM3 to ePWM4 and setting the phase offset value of ePWM4 as |Target.PWM_counter_period|.
%
% <<../epwm_dyno2.png>>
%
% <<../epwm_dyno.png>>
%
% <<../epwm_dyno1.png>>
%
% * *ADC Block Configuration*
%
% The algorithm in this example uses an asynchronous scheduling. The pulse
% width modulation (PWM) block triggers the ADC conversion. At the end of
% conversion, the ADC posts an interrupt that triggers the main FOC
% algorithm. For more information, refer
% <docid:c2b_ug#mw_ce3bbb8e-3411-4ab3-826d-d5dcc239ead4 ADC Interrupt Based Scheduling>.
%
% For *Single CPU* model:
%
% * ADC channel for Inverter 1
% 
% <<../adc_dyno.png>>
%
% * ADC channel for inverter 2
%
% <<../adc_dyno1.png>>
%
% For *Dual CPU* model, the ADC channels for inverter 2 is defined in the initialize function of the CPU1 model. In CPU2 model, we use Memory Copy blocks, to access the value of the ADC registers.
%
% <<../adc_dyno2.png>>
%
% <<../memory_dyno.png>>
%
%% Configure the Model 
% *1.* Open the 'mcb_pmsm_foc_dual_cpu1_f28379d' and 'mcb_pmsm_foc_dual_cpu2_f28379d' model. This model is configured for TI Delfino F28379D Launchpad.
%
% *2.* To run the model on other TI C2000(TM) processors, first press *Ctrl+E* to open the Configuration Parameters dialog box. Then, select the required hardware board by navigating to *Hardware Implementation* > *Hardware board*.
% 
% *3.* The following screenshots show the scheduler configurations performed in the *Dual CPU* model.
%
% <<../configure_dyno.png>>
%
% <<../configure_dyno1.png>>
%
% *Note:*
%
% * For Single CPU model, ensure that the *base rate trigger* is *Timer0*.
%
% * Ensure that the *Default parameter behavior* is set to *Inlined* (*Configuration Parameters* > *Code Generation* > *Optimization*).
% 
% *4.* Ensure that the baud rate is set to 12e6 bits/sec.
%
%% Required MathWorks(R) Products
% 
% *To simulate model:*
% 
% * Motor Control Blockset(TM)
% 
% *To generate code and deploy model:*
% 
% * Motor Control Blockset(TM)
% * Embedded Coder(R)
% * C2000(TM) Microcontroller Blockset
% * Fixed-Point Designer(TM) (only needed for optimized code generation)
% 
%% Prerequisites
% 
% *1.* Obtain the motor parameters for both Motor 1 and Motor 2. We provide default motor parameters with the Simulink(R) model that you can replace with the values from either the motor datasheet or other sources.
% 
% However, if you have the motor control hardware, you can estimate the parameters for the motor that you want to use, by using the Motor Control Blockset(TM) parameter estimation tool. For instructions, see <docid:mcb_gs#mw_5020c0a3-3cde-4f36-bebc-21090973f8f5 Estimate Motor Parameters by Using Motor Control Blockset Parameter Estimation Tool>.
%
% *2.* Update the motor parameters (that you obtained from the datasheet, other sources, or parameter estimation tool) and inverter parameters in the model initialization script associated with the Simulink(R) model. For instructions, see <docid:mcb_gs#mw_dd32d1fd-68d8-4cfd-8dea-ef7f7ed008c0 Estimate Control Gains from Motor Parameters>.
% 
% For this example, update the motor parameters for both the motors in the model initialization script.
% 
%% Simulate Model
% 
% This example supports simulation. Follow these steps to simulate the
% model.
% 
% *1.* Open <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_sensorless_dyno_f28379d') mcb_pmsm_foc_sensorless_dyno_f28379d> or 
% <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_qep_dyno_f28069m') mcb_pmsm_foc_qep_dyno_f28069m>
% model included with this example.
% 
% *2.* Click *Run* on the *Simulation* tab to simulate the model.
% 
% *3.* Click *Data Inspector* on the *Simulation* tab to view and analyze the simulation
% results.
% 
% *4.* Input a different speed reference for Motor 1 and a different current reference (load) for Motor 2. Observe the measured speed and other logged signals in the Data Inspector.
% 
%% Generate Code and Deploy Model to Target Hardware
% This section instructs you to generate code and run the FOC algorithm on
% the target hardware.
% 
% The example uses a host and a target model. The host model is a user interface to the controller hardware board.  You can run the host model on the host computer. The prerequisite to use the host model is to deploy the target model to the controller hardware board. The host model uses serial communication to command the target Simulink(R) model and run the motor in a closed-loop control.
% 
% *Required Hardware*
%
% The example supports this hardware configuration. You can also use the target model name to open the model for the corresponding hardware configuration, from the MATLAB(R) command prompt.
% 
% * LAUNCHXL-F28069M controller + 2 BOOSTXL-DRV8305 inverters: <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_sensorless_dyno_f28379d') mcb_pmsm_foc_sensorless_dyno_f28379d>
% 
% * LAUNCHXL-F28379D controller + 2 BOOSTXL-DRV8305 inverters: <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_qep_dyno_f28069m') mcb_pmsm_foc_qep_dyno_f28069m>
%
% * LAUNCHXL-F28379D controller + 2 BOOSTXL-DRV8305 inverters: <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_dual_cpu1_f28379d') mcb_pmsm_foc_dual_cpu1_f28379d>. 
%
% * LAUNCHXL-F28379D controller + 2 BOOSTXL-DRV8305 inverters: <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_dual_cpu2_f28379d') mcb_pmsm_foc_dual_cpu2_f28379d>.
% 
% * For LAUNCHXL-F28379D controller + 2 BOOSTXL-3PHGANINV inverters:
% <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_f28379d_dyno') mcb_pmsm_foc_f28379d_dyno>, refer to <docid:mcb_gs#mw_b3b394ff-bb9c-48ff-9f47-540e96d25b43 MCB>
% 
% For connections related to the preceding hardware configuration, see <docid:c2b_ug#mw_afa3a9f7-301c-42dd-a6bd-9bf5dbdbaae1 Hardware Connections>.
% 
% *Generate Code and Run Model on Target Hardware*
%
% *1.* Simulate the target model and observe the simulation results.
% 
% *2.* Complete the hardware connections.
% 
% *3.* The model automatically computes the ADC (or current) offset values. To disable this functionality (enabled by default), update the value 0 to the variable inverter.ADCOffsetCalibEnable in the model initialization script.
%  
% Alternatively, you can compute the ADC offset values and update it manually in the model initialization scripts. For instructions, see <docid:c2b_ug#mw_91be046f-02bb-4256-b09b-a4c9b86191a3 Open-loop example>.
% 
% *4.* Compute the quadrature encoder index offset value and update it in the model initialization scripts associated with the target model. For instructions, see <docid:c2b_ug#mw_6c933bed-960e-4698-b1f3-cba2e0f5b9a3 Quadrature Encoder Offset Calibration for PMSM Motor>.
% 
% For this example, update the QEP offset values in the pmsm_motor1.PositionOffset and pmsm_motor2.PositionOffset variables in initialization script.
% 
% *5.* Open the target model. If you want to change the default hardware configuration settings for the model, see <docid:mcb_gs#mw_3286e9a5-4b65-4b84-9133-a92130b252bc Model Configuration
% Parameters for Sensors>.
%
% *6.* To ensure that CPU2 is not mistakenly configured to use the board peripherals intended for CPU1, load a sample program to CPU2 of LAUNCHXL-F28379D, for example, a program that operates the CPU2 blue LED by using GPIO31 (c28379D_cpu2_blink.slx).
%
% *Note*: 
%
% * For dual CPU model, you must build and download CPU1 and CPU2 models to respective cores of the processor. 
% Each core controls one motor on the dual motor control kit. Two cores communicate each other using IPC. CPU1 model sends Load Torque request to CPU2. CPU2 sends data to be logged to CPU1.
%
% * After deploying the code, full power reset should be done on the launchpad to ensure proper execution of the code. 
% 
% *7.* Click *Build, Deploy & Start* on the *Hardware* tab to deploy the model to the hardware.
% 
% *8.* Click the *host model* hyperlink in the target model to open the
% associated host model. These are the following host models:
% 
% * <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_dual_host_model') mcb_pmsm_foc_dual_host_model>. 
%
% * <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_host_model_dyno_f28379d') mcb_pmsm_foc_host_model_dyno_f28379d>.
%
% *
% <matlab:openExample('c2b/DualMotorDynoUsingC2000ProcessorsExample','supportingFile','mcb_pmsm_foc_host_model_dyno_f28069m') mcb_pmsm_foc_host_model_dyno_f28069m>.
%
% You can also use the open_system command to open the host model:
%%
open_system('mcb_pmsm_foc_host_model_dyno_f28379d.slx'); 
%%
%  
% *9.* Set the parameter *Port* of the following blocks in the
% <matlab:mcb_pmsm_foc_host_model_dyno_f28379d mcb_pmsm_foc_host_model_dyno_f28379d> model to match the COM
% port of the host computer. Similarly you can perform the same configuration for other host models in this example:
%
% * mcb_pmsm_foc_host_model_dyno_f28379d > Host Serial Setup.
% * mcb_pmsm_foc_host_model_dyno_f28379d > Serial Communication > Host
% Serial Receive.
% * mcb_pmsm_foc_host_model_dyno_f28379d > Serial Communication > SCI_TX >
% Host Serial Transmit.
%
% *10.* Click *Run* on the *Simulation* tab to run the host model.
%  
% *11.* Change the position of the *Motor 1* switch to Start, to run the motor.
%  
% *12.* Update the *Motor 1 - Reference Speed (RPM)* and *Motor 2 - Iq Ref
% (A)* in the host model.
% 
% *13.* Select the debug signals that you want to monitor, to observe them
% in the Time Scope block of host model.
% 
%% Other Things to Try
% 
% You can also use SoC Blockset(TM) to develop a real-time motor control
% application for a dual motor setup that utilizes multiple processor cores
% to obtain design modularity, improved controller performance, and other
% design goals. For details, see <docid:c2b_ug#mw_83ab84af-47c4-473d-938a-7c68170b4cc9 Partition Motor
% Control for Multiprocessor MCUs>.
% 