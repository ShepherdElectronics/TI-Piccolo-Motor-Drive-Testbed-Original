# Simulink Models

These are the actual project models retained as customer-facing engineering evidence. They are not generated screenshots, placeholder diagrams, or generated C/C++ output.

## Host models

- `Efficiency_Mapping_Host.slx` - supervisory model used for dynamometer efficiency-map acquisition.
- `Drive_Cycle_Host.slx` - host workflow for commanded drive-cycle operation.
- `Speedgoat_CAN_Host.slx` - Simulink Real-Time supervisory CAN command and telemetry model.

## Target model

- `C2000_Dual_Motor_CAN_Target.slx` - complete C2000 dual-motor target with CAN integration and retained field-oriented-control signal paths.

## Reusable subsystems

- `CAN_Receive.slx` - CAN receive and payload-unpack subsystem.
- `CAN_Transmit.slx` - CAN return/telemetry subsystem.
- `Current_Control.slx` - current-control subsystem used by the target model.

## Use and dependencies

The models require compatible MATLAB/Simulink releases and the relevant TI C2000 and Simulink Real-Time support packages. Hardware targets, board revisions, referenced data dictionaries, and local setup scripts must be verified before building or energizing hardware.

Generated code, binaries, caches, `slprj`, and build products are intentionally excluded. The included `.slx` files are the editable engineering models.

## Custom peripheral source

The target-model layer is complemented by handwritten/custom ADC SOC configuration under [`../../embedded-control/custom-firmware/`](../../embedded-control/custom-firmware/). This source adds the project-specific PWM-triggered simultaneous ADC input pairs used by the instrumentation path.
