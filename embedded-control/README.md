# Embedded Control

The real-time implementation uses two complementary source layers:

1. **Editable Simulink target models** in [`../models/simulink/target/`](../models/simulink/target/) and [`../models/simulink/subsystems/`](../models/simulink/subsystems/). These models define the field-oriented-control, CAN, current-control, and target signal paths.
2. **Custom low-level C firmware** in [`custom-firmware/`](custom-firmware/) for project-specific F28069M ADC SOC and interrupt configuration.

Generated C/C++ output, binaries, caches, and vendor device-support source are intentionally excluded.
