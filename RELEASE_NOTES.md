# Release Notes - v1.4

## Final customer-facing release

- Added the retained custom source `F28069M_ADC_Custom_Config.c`.
- Documented the custom ADC SOC/channel, ePWM trigger, acquisition-window, and interrupt-routing implementation in both reports.
- Distinguished handwritten/custom ADC integration from MathWorks-generated ADC support output.
- Preserved all editable Simulink target, host, and reusable subsystem models from v1.3.
- Reorganized MATLAB setup, logging, and analysis utilities under `host-software/`.
- Replaced the misleading scripts-only `firmware/` folder with an explicit `embedded-control/` source boundary.
- Updated README, NOTICE, report traceability, deployment tooling, checksums, and archive version consistently.

## Included engineering source

- Complete C2000 dual-motor CAN target model.
- Speedgoat CAN host, efficiency-mapping host, and drive-cycle host models.
- CAN receive, CAN transmit, and current-control subsystem models.
- Custom F28069M ADC configuration source adding PWM-triggered simultaneous `SOC12/SOC13` and `SOC14/SOC15` input pairs.
- Selected MATLAB setup, logging, export, plotting, and efficiency-processing utilities.

## Intentionally excluded

Generated C/C++ output, object files, binaries, caches, `slprj`, academic/internal records, private raw data, private tuning history, editable vendor PCB projects, Gerbers, pick-and-place data, and fabrication packages.
