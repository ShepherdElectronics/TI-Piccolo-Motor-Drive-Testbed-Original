# C2000 Motor Drive Testbed

Organized repository for the TI Piccolo / C2000 motor-drive testbed work.

## Repository Structure

- `docs/` — hardware documentation, setup notes, CAN documentation, lab material
- `models/` — Simulink source models
- `models/can/` — host/target CAN models and examples
- `models/motor_control/` — motor-control and FOC-related models
- `scripts/` — MATLAB setup, plotting, debug, and drive-cycle scripts
- `data/` — selected processed data and signal-editor inputs
- `results/` — selected figures and reports
- `releases/` — versioned release snapshots if needed

## Git Policy

This repository tracks source models, MATLAB scripts, documentation, selected processed data, and selected figures.

Generated Simulink/C2000 build artifacts are intentionally excluded from Git:

- `slprj/`
- `*_ert_rtw/`
- `*_slrealtime_rtw/`
- `CACHE/`
- `CODEGEN/`
- `.obj`, `.out`, `.hex`, `.slxc`, and similar generated files

Large installer archives are also excluded.
