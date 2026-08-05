# TI Piccolo-Based Dual-Motor Dynamometer Control Platform

Public engineering release **v1.7**

This repository contains the actual editable Simulink control models, custom low-level F28069M ADC firmware, selected MATLAB host tooling, hardware-interface evidence, and measured characterization outputs for a dual-PMSM dynamometer built around a TI C2000 Piccolo F28069M and two DRV8305 inverter stages.

> Independent engineering work by Herder Elektronische Systemen. Texas Instruments did not author, approve, or sponsor this repository.

## Engineering problem

The inherited platform contained usable controller and inverter hardware, but its documented phase and encoder connections did not match the physical bench. The recovery and extension work corrected those interfaces, stabilized dual-machine control and acquisition, produced defensible efficiency-map evidence, migrated supervisory operation from SCI to CAN, and added project-specific ADC acquisition channels for instrumentation.

## Demonstrated work

- Corrected three-phase and quadrature-encoder assignments for the coupled drive/load machines.
- Restored stable dual-machine field-oriented control.
- Included the complete editable C2000 dual-motor CAN target and host-side Simulink models.
- Implemented CAN command/diagnostic transport using public identifiers `0x100` and `0x101`.
- Added custom F28069M ADC SOC configuration for two additional PWM-triggered simultaneous analog-input pairs.
- Built fixed-dwell, efficiency-mapping, and compressed drive-cycle host workflows.
- Retained measured-bin efficiency, validity-mask, sample-density, interpolation, and contour evidence as separate outputs.

## Primary documents

- [Functional Requirements & Validation Report](docs/Dual_Motor_Dynamometer_FRD_v1.7.pdf)
- [Embedded Control, CAN & Characterization Report](docs/Embedded_Control_and_Characterization_Report_v1.7.pdf)

## Repository map

- `embedded-control/` - custom F28069M ADC firmware and embedded-source boundary
- `models/simulink/` - actual editable C2000 target, Speedgoat host, test hosts, and reusable subsystems
- `host-software/` - MATLAB setup, logging, export, plotting, and analysis utilities
- `hardware/` - public interface notes, BOM, and vendor schematic references
- `results/` - approved characterization figures
- `media/` - connector-level board and hardware reference figures
- `docs/` - FRD and companion engineering report
- `scripts/` - release deployment tooling

## Custom ADC integration

[`embedded-control/custom-firmware/F28069M_ADC_Custom_Config.c`](embedded-control/custom-firmware/F28069M_ADC_Custom_Config.c) is project-specific source, not generated `MW_c28xx_adc.c` output. It configures simultaneous ADC SOC pairs for the motor-control and data-acquisition path, including added ePWM1-triggered `SOC12/SOC13` on `ADCINA2/ADCINB2` and `SOC14/SOC15` on `ADCINA1/ADCINB1`, with end-of-conversion interrupt routing.

## Release boundary

The editable `.slx` models and custom ADC configuration source are intentionally public. Generated code, binaries, caches, private raw datasets, internal tuning history, editable vendor CAD, Gerbers, fabrication packages, and institution-specific records remain excluded. This is an engineering evidence release, not a production-qualified or safety-certified motor-drive product.
