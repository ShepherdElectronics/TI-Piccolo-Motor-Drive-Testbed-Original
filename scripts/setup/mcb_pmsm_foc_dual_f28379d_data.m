% Model         :   PMSM Field Oriented Control
% Description   :   Set Parameters for PMSM Field Oriented Control
% File name     :   mcb_pmsm_foc_dual_f28379d_data.m

% Copyright 2020 The MathWorks, Inc.

%% Simulation Parameters

%% Set PWM Switching frequency
PWM_frequency 	= 20e3;    %Hz          // Converter s/w freq
T_pwm           = 1/PWM_frequency;  %s  // PWM switching time period

%% Set Sample Times
Ts          	= T_pwm;        %sec        // Sample time for control system
Ts_simulink     = T_pwm/2;      %sec        // Simulation time step for model simulation
Ts_motor        = T_pwm/2;      %sec        // Simulation sample time for pmsm
Ts_inverter     = T_pwm/2;      %sec        // Simulation time step for inverter
Ts_speed        = 20*Ts;        %sec        // Sample time for speed controller

%% Set data type for controller & code-gen
% Uncomment the required data type and comment the other
dataType = 'single';            % Floating point code-generation 
%dataType = fixdt(1,32,24);       % Fixed point code-generation  

%% System Parameters // Hardware parameters

% Set motor parameters
pmsm = mcb_SetPMSMMotorParameters('Teknic2310P');
% Set SMO parameters
smo = mcb_SetSMOParameters;

%% Target & Inverter Parameters

target = mcb_SetProcessorDetails('F28379D',PWM_frequency);

inverter = mcb_SetInverterParameters('BoostXL-DRV8305');

%% Calibration section // Uncomment and update relevant parameters

% Enable automatic calibration of ADC offset for current measurement
inverter.ADCOffsetCalibEnable = 1;  % Enable: 1, Disable:0 

% If automatic ADC offset calibration is disabled, uncomment and update the 
% offset values below manually
% inverter.CtSensAOffset = 2295;      % ADC Offset for phase current A 
% inverter.CtSensBOffset = 2286;      % ADC Offset for phase current B

% Setting inverter.ADCGain 1 for default SPI gain setting
inverter.ADCGain = 1;

% Voltage output of inverter current sense circuit
inverter.ISenseVoltPerAmp = inverter.ISenseVoltPerAmp * inverter.ADCGain; 
% Update ISenseMax that is measurable by target ADC
inverter.ISenseMax = inverter.ISenseMax * target.ADC_Vref / inverter.ISenseVref; 
% Update ISenseMax according to set ADC gain
inverter.ISenseMax = inverter.ISenseMax/inverter.ADCGain;

% Max and min ADC counts for current sense offsets
inverter.CtSensOffsetMax = 2500; % Maximum permitted ADC counts for current sense offset
inverter.CtSensOffsetMin = 1500; % Minimum permitted ADC counts for current sense offset

%% Derive Characteristics
pmsm.N_base = mcb_getBaseSpeed(pmsm,inverter); % rpm // Base speed of motor at given Vdc
% mcb_getCharacteristics(pmsm,inverter);       % Uncomment for motor characteristics

%% PU System details // Set base values for pu conversion
PU_System = mcb_SetPUSystem(pmsm,inverter);

%% Open loop reference values
T_Ref_openLoop          = 1;                    % Sec // Time for open-loop start-up
Speed_openLoop_PU       = 0.1;                  % PU  // Per-Unit speed referene for open-loop start-up
Vd_Ref_openLoop_PU      = Speed_openLoop_PU;    % Use 1.2x for Dyno setup and 1x for others

%% Controller design // Get ballpark values!
PI_params = mcb.internal.SetControllerParameters(pmsm,inverter,PU_System,T_pwm,2*Ts,Ts_speed);

%Updating delays for simulation
PI_params.delay_Currents    = 1; % No of samples delayed for current sensing

% %Uncomment for frequency domain analysis
% mcb_getControlAnalysis(pmsm,inverter,PU_System,PI_params,Ts,Ts_speed);

%% Displaying model variables
disp(pmsm);
disp(inverter);
disp(target);
disp(PU_System);
