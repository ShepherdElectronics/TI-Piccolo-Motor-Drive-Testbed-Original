# Custom F28069M ADC Firmware

`F28069M_ADC_Custom_Config.c` is the retained handwritten/custom peripheral-configuration source used with the model-based C2000 target. It is distinct from MathWorks-generated `MW_c28xx_adc.c` build output.

## Engineering purpose

The source configures the F28069M ADC start-of-conversion (SOC) resources used by the dual-motor control and data-acquisition path. In addition to the baseline motor-current sampling pairs, it adds two PWM-triggered simultaneous-input pairs:

- `SOC12/SOC13`: `ADCINA2` and `ADCINB2`, triggered by ePWM1, with EOC13 routed to ADCINT5.
- `SOC14/SOC15`: `ADCINA1` and `ADCINB1`, triggered by ePWM1, with EOC15 routed to ADCINT9.

The file also retains the existing SOC0/1, SOC2/3, SOC4/5, and SOC6/7 configuration functions. Each configured pair uses simultaneous sampling and a seven-ADC-clock acquisition window.

## Public boundary

This repository includes the custom source because it represents project-specific low-level integration. TI device-support headers, C2000Ware/controlSUITE sources, generated code, object files, and target binaries are not redistributed. A compatible TI/MathWorks toolchain and the referenced target model are required for a build.
