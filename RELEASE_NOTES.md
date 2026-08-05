# Release Notes

## v2.4 - 5 August 2026

- Replaced the prior FRD-plus-report arrangement with two actual Functional Requirements Documents built from the approved optical-motion FRD template structure.
- Added a dedicated **Firmware, Host Software & Results FRD** covering embedded behavior, editable Simulink models, CAN, custom ADC integration, host acquisition, verification, and measured characterization.
- Added a dedicated **Platform, Electrical & Interfaces FRD** covering controller/inverter architecture, power, motor phases, encoders, CAN physical wiring, deployment, schematics, BOM, safety, and ownership boundaries.
- Confined efficiency maps and sample-density evidence to the Firmware/Host FRD.
- Removed all efficiency results, analysis methodology, and software-implementation duplication from the Platform/Electrical FRD.
- Preserved the editable Simulink models, custom `F28069M_ADC_Custom_Config.c`, MATLAB utilities, vendor schematic references, connector figures, and approved results.
- Rendered and visually reviewed every page of both FRDs before packaging.
- Regenerated release checksums and verified the ZIP structure.

## Public source retained

- C2000 dual-motor target and CAN target models
- Speedgoat CAN host, efficiency host, and drive-cycle host models
- CAN receive/transmit and current-control subsystem models
- Custom F28069M ADC configuration source
- Selected MATLAB setup, logging, export, plotting, and processing utilities

## Intentionally excluded

Generated C/C++ output, binaries, caches, `slprj`, private raw data, internal tuning history, institution-specific records, editable vendor PCB projects, Gerbers, pick-and-place files, and fabrication packages.
