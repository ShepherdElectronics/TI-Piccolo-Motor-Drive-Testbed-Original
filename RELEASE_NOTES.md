# Release Notes
- Efficiency figures, methods, and interpretation are now confined to the Embedded Control & Characterization Report; the FRD retains only evidence-traceability requirements.

## v1.9 - 5 August 2026

- Rebuilt both engineering reports from scratch using the approved red/black/gray cover template.
- Reduced the FRD to requirements, interfaces, verification, traceability, constraints, and release status.
- Rebuilt the companion report around Simulink architecture, custom ADC firmware, CAN, host software, and measured characterization.
- Removed duplicated requirement tables, safety text, release-boundary prose, and repeated architecture narrative between reports.
- Preserved all public source models, scripts, hardware references, firmware, and result figures.

# Release Notes - v1.5


## Cover and presentation update

- Rebuilt both report covers to match the established Herder engineering-report visual system.
- Added the full red title field, black/gray metadata grid, document-purpose panel, and first-page report header.
- Retained the technical body, Simulink models, custom ADC source, scripts, hardware references, and validation evidence without substantive removal.
- Re-rendered and visually reviewed every report page before packaging.

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

## v1.9 - FRD explanatory context restored

- Rebuilt the FRD as a true functional requirements document with system purpose, operating concept, functional decomposition, requirement attributes, rationales, operating modes, verification strategy, assumptions, constraints, and acceptance logic.
- Kept efficiency methods and plots exclusively in the Embedded Control & Characterization Report.
- Restored all implementation-report figures as embedded, visible evidence and removed the nearly blank overflow page.
- Updated both reports, repository links, checksums, and publication script to revision 1.9.
