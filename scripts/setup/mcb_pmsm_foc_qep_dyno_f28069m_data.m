% Model         :   PMSM Field Oriented Control
% Description   :   Set Parameters for PMSM Field Oriented Control
% File name     :   mcb_pmsm_foc_qep_dyno_f28069m_data.m

% Copyright 2020 The MathWorks, Inc.

%% Simulation Parameters

%% Set PWM Switching frequency
PWM_frequency 	= 10e3;    %Hz          // converter s/w freq
T_pwm           = 1/PWM_frequency;  %s  // PWM switching time period

%% Set Sample Times
Ts          	= T_pwm;        %sec        // simulation time step for controller
Ts_simulink     = T_pwm/2;      %sec        // simulation time step for model simulation
Ts_motor        = T_pwm/2;      %Sec        // Simulation sample time
Ts_inverter     = T_pwm/2;      %sec        // simulation time step for average value inverter
Ts_speed        = 10*Ts;        %Sec        // Sample time for speed controller

%% Set data type for controller & code-gen
% Uncomment the required data type and comment out the other
%dataType = fixdt(1,32,17);    % Fixed point code-generation
dataType = 'single';           % Floating point code-generation
%% System Parameters // Hardware parameters 

pmsm_motor1 = mcb_SetPMSMMotorParameters('Teknic2310P');
pmsm_motor1.PositionOffset = 0.1687; % Enter offset values from calibration

pmsm_motor2 = mcb_SetPMSMMotorParameters('Teknic2310P');
pmsm_motor2.PositionOffset = 0.1655; % Enter offset values from calibration

%% Target & Inverter Parameters
target = mcb_SetProcessorDetails('F28069M',PWM_frequency);

inverter_motor1 = mcb_SetInverterParameters('BoostXL-DRV8305');
inverter_motor2 = mcb_SetInverterParameters('BoostXL-DRV8305');

%% Calibration section

% Enable automatic calibration of ADC offset for current measurement
inverter_motor1.ADCOffsetCalibEnable = 1; % Enable: 1, Disable:0
inverter_motor2.ADCOffsetCalibEnable = 1; % Enable: 1, Disable:0

% If automatic ADC offset calibration is disabled, uncomment and update the 
% offset values below manually
% inverter_motor1.CtSensAOffset = 2265;      % ADC Offset for phase current A 
% inverter_motor1.CtSensBOffset = 2286;      % ADC Offset for phase current B
% 
% inverter_motor2.CtSensAOffset = 2265;      % ADC Offset for phase current A 
% inverter_motor2.CtSensBOffset = 2286;      % ADC Offset for phase current B

% BoostXL-DRV8305 Current sense gain remains 10 V/V (default value)
inverter_motor1.ADCGain = 1;   % ADC Range = +- 19.300A wrt 0-4095 counts
inverter_motor1.SPI_Gain_Setting = 0x5000;

inverter_motor2.ADCGain = 1;   % ADC Range = +- 19.300A wrt 0-4095 counts
inverter_motor2.SPI_Gain_Setting = 0x5000;
% Max and min ADC counts for current sense offsets for both inverters
inverter_motor1.CtSensOffsetMax = 2500; 
inverter_motor1.CtSensOffsetMin = 1500;

inverter_motor2.CtSensOffsetMax = 2500;
inverter_motor2.CtSensOffsetMin = 1500;

%% Derive Characteristics
pmsm_motor1.N_base = mcb_getBaseSpeed(pmsm_motor1,inverter_motor1); %rpm // Base speed of motor at given Vdc
pmsm_motor2.N_base = mcb_getBaseSpeed(pmsm_motor2,inverter_motor2); %rpm // Base speed of motor at given Vdc
% mcb_getCharacteristics(pmsm_motor1,inverter_motor1);
% mcb_getCharacteristics(pmsm_motor2,inverter_motor2);

%% PU System details // Set base values for pu conversion

PU_System_motor1 = mcb_SetPUSystem(pmsm_motor1,inverter_motor1);
PU_System_motor2 = mcb_SetPUSystem(pmsm_motor2,inverter_motor2);

%% Controller design // Get ballpark values!
% for motor 1 
PI_params_motor1 = mcb.internal.SetControllerParameters(pmsm_motor1,inverter_motor1,PU_System_motor1,T_pwm,Ts,Ts_speed);

%Updating delays for simulation
PI_params_motor1.delay_Currents    = 0; %int32(Ts/Ts_simulink);
PI_params_motor1.delay_Position    = 0; %int32(Ts/Ts_simulink);

% mcb_getControlAnalysis(pmsm_motor1,inverter_motor1,PU_System_motor1,PI_params_motor1,Ts,Ts_speed); 

% for motor 2
PI_params_motor2 = mcb.internal.SetControllerParameters(pmsm_motor2,inverter_motor2,PU_System_motor2,T_pwm,Ts,Ts_speed);

%Updating delays for simulation
PI_params_motor2.delay_Currents    = 0; %int32(Ts/Ts_simulink);
PI_params_motor2.delay_Position    = 0; %int32(Ts/Ts_simulink);

% mcb_getControlAnalysis(pmsm_motor2,inverter_motor2,PU_System_motor2,PI_params_motor2,Ts,Ts_speed); 
%% Displaying model variables
disp(pmsm_motor1);
disp(pmsm_motor2);
disp(inverter_motor1);
disp(inverter_motor2);
disp(target);
disp(PU_System_motor1);
disp(PU_System_motor2);

Kt = pmsm_motor1.Kt;     % N*m/A  (peak torque constant)
J  = pmsm_motor1.J;      % kg*m^2 (combined rotor+coupler inertia used by the example)
B  = pmsm_motor1.B;      % N*m*s/rad (viscous friction)
BaseRPM = pmsm_motor1.N_base;  % rpm (from your DC bus and motor params)
disp(table(Kt,J,B,BaseRPM))
