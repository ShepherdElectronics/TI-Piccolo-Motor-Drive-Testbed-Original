#!/usr/bin/env bash
set -e

echo "=================================================="
echo "C2000 Motor Drive Testbed - Final Repo Cleanup"
echo "=================================================="
echo ""

# --------------------------------------------------
# Safety check
# --------------------------------------------------

if [ ! -d "." ]; then
  echo "ERROR: Could not access current directory."
  exit 1
fi

echo "Running from:"
pwd
echo ""

# --------------------------------------------------
# Create clean repo structure
# --------------------------------------------------

echo "Creating clean repository structure..."

mkdir -p docs/hardware/BOOSTXL_DRV8305EVM
mkdir -p docs/hardware/LAUNCHXL_F28069M
mkdir -p docs/hardware/can
mkdir -p docs/notes/development_notes
mkdir -p docs/notes/tools

mkdir -p models/can/host
mkdir -p models/can/target
mkdir -p models/can/examples
mkdir -p models/motor_control
mkdir -p models/reference

mkdir -p scripts/setup
mkdir -p scripts/can
mkdir -p scripts/drive_cycles
mkdir -p scripts/plotting
mkdir -p scripts/debug

mkdir -p data/raw
mkdir -p data/processed
mkdir -p data/signal_editor
mkdir -p data/host_inputs

mkdir -p results/figures
mkdir -p results/reports

mkdir -p releases/v0.1_baseline
mkdir -p releases/v0.2_can_host_target
mkdir -p releases/v0.3_speedgoat_can_dyno
mkdir -p releases/v0.4_drive_cycle_tests

# --------------------------------------------------
# Write final .gitignore
# --------------------------------------------------

echo "Writing .gitignore..."

cat > .gitignore <<'EOF'
# ==================================================
# MATLAB / Simulink generated folders
# ==================================================
slprj/
*_ert_rtw/
*_grt_rtw/
*_slrealtime_rtw/
*_rtw/
tmwinternal/
CACHE/
CODEGEN/
html/

# ==================================================
# Simulink cache / build artifacts
# ==================================================
*.slxc
*.mldatx
*.dwo
*.hex
*.out
*.obj
*.o
*.d
*.map
*.mk
*.dmr

buildInfo.mat
codeInfo.mat
compileInfo.mat
codedescriptor.dmr
rtwtypeschksum.mat
rtw_proj.tmw
simulink_cache.xml
checksumOfCache.mat
varInfo.mat
minfo.mat
binfo.mat
BlockTraceInfo.mat
CompileInfo.xml
loggingdb.json
taskinfo.mat
peripheralInfo.mat
profiling_info.mat
instrumentationInfo.mat

# ==================================================
# CCS generated project/build folders
# ==================================================
CCS_Project/
CCS_Workspace/

# ==================================================
# Installer packages / large archives
# ==================================================
*.zip
*.7z
*.rar
*.tar
*.gz
*.iso

# ==================================================
# Autosaves / temp
# ==================================================
*.asv
*.bak
*.tmp
*.log

# ==================================================
# OS/editor junk
# ==================================================
.DS_Store
Thumbs.db
desktop.ini
EOF

# --------------------------------------------------
# Helper move function
# --------------------------------------------------

move_if_exists() {
  src="$1"
  dst="$2"

  if [ -e "$src" ]; then
    mkdir -p "$dst"
    echo "Moving: $src -> $dst/"
    mv "$src" "$dst/"
  fi
}

# --------------------------------------------------
# Organize top-level files
# --------------------------------------------------

echo ""
echo "Organizing project files..."

move_if_exists "Current Progress.docx" "docs"
move_if_exists "Read Me.docx" "docs"
move_if_exists "folder_map.txt" "docs"
move_if_exists "data_processing04.m" "scripts/plotting"

# Setup docs, but not giant software archive
move_if_exists "Setup/Physical Setup.docx" "docs/hardware"
move_if_exists "Setup/Software Setup.docx" "docs/hardware"

# --------------------------------------------------
# Organize documentation
# --------------------------------------------------

move_if_exists "Documentation/BoM.xlsx" "docs/hardware"
move_if_exists "Documentation/PINOUT.xlsx" "docs/hardware"
move_if_exists "Documentation/Speedgoat_C2000_CAN_Dyno_Implementation_Guide.docx" "docs/hardware/can"

move_if_exists "Documentation/BOOSTXL-DRV8305EVM" "docs/hardware/BOOSTXL_DRV8305EVM"
move_if_exists "Documentation/LAUNCHXL-F28069M" "docs/hardware/LAUNCHXL_F28069M"

move_if_exists "Documentation/Development notes/3-Phase_Motor_Drives_w_Oscilloscope_48W-TECTRONICS.pdf" "docs/notes/development_notes"
move_if_exists "Documentation/Development notes/data_processing.png" "docs/notes/development_notes"
move_if_exists "Documentation/Development notes/DEBUG SIGNAL NOTES.docx" "docs/notes/development_notes"
move_if_exists "Documentation/Development notes/Hardware Setup and Activities Main.docx" "docs/notes/development_notes"
move_if_exists "Documentation/Development notes/Mathwork answer.pdf" "docs/notes/development_notes"
move_if_exists "Documentation/Development notes/PMSM FIELD-ORIENTED CONTROL (FOC) NOTES [Power Equations].docx" "docs/notes/development_notes"
move_if_exists "Documentation/Development notes/TI User Manual.docx" "docs/notes/development_notes"

move_if_exists "Documentation/Development notes/Tools/Data collection rates.docx" "docs/notes/tools"
move_if_exists "Documentation/Development notes/Tools/Straightforward data collection table.docx" "docs/notes/tools"

# --------------------------------------------------
# Organize CAN models
# --------------------------------------------------

move_if_exists "Documentation/MTU_DMD_CAN/C2000_TARGET/HOST_CAN.slx" "models/can/host"
move_if_exists "Documentation/MTU_DMD_CAN/C2000_TARGET/TARGET_CAN.slx" "models/can/target"
move_if_exists "Documentation/MTU_DMD_CAN/C2000_TARGET/TARGET_CAN_WORKING_BUILD.slx" "models/can/target"

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/CAN_rx1.slx" "models/can/examples"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/CAN_TX.slx" "models/can/examples"

# --------------------------------------------------
# Organize motor-control models
# --------------------------------------------------

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/current_control.slx" "models/motor_control"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/foc_sensorless_algorithm.slx" "models/motor_control"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/sensorless_algorithm.slx" "models/motor_control"

# --------------------------------------------------
# Organize setup/data scripts
# --------------------------------------------------

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/c28069pmsmfocdual_ert.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/c28377Spmsmfocdual_ert.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/c28379dpmsmfocdual_cpu1_ert.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/c28379dpmsmfocdual_cpu2_ert.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/mcb_pmsm_foc_dual_f28379d_data.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/mcb_pmsm_foc_dual_f28379d_datascript.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/mcb_pmsm_foc_qep_dyno_f28069m_data.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/mcb_pmsm_foc_sensorless_dyno_f28379d_data.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/mcb_pmsm_foc_sensorless_dyno_f28379d_datascript.m" "scripts/setup"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/soc_mcb_pmsm_foc_dyno_f28379d_data.m" "scripts/setup"

# --------------------------------------------------
# Organize drive-cycle / lab scripts
# --------------------------------------------------

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/DRIVECYCLE_TEST_001.m" "scripts/drive_cycles"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/DRIVECYCLE_TEST_002.m" "scripts/drive_cycles"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/DRIVECYCLE_TEST_003.m" "scripts/drive_cycles"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/EPAtest.m" "scripts/drive_cycles"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/DualMotorDynoUsingC2000ProcessorsExample.m" "scripts/drive_cycles"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/ReferenceRuns.m" "scripts/drive_cycles"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/ReferenceRunsSINE.m" "scripts/drive_cycles"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/SINES.m" "scripts/drive_cycles"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/step.m" "scripts/drive_cycles"

# --------------------------------------------------
# Organize plotting/debug scripts
# --------------------------------------------------

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/PLOTS.m" "scripts/plotting"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/plot_all_dyno_runs.m" "scripts/plotting"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/plot_currents_with_ftp75.m" "scripts/plotting"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/post_dyno_export.m" "scripts/plotting"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/TRIMandPLOT.m" "scripts/plotting"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/FINALCODE.m" "scripts/plotting"

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/debug_1_is_mtr1REF_debug2_is_mtr1FEEDBACK.m" "scripts/debug"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/save_and_plot_debug12.m" "scripts/debug"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/save_and_plot_debug_radio.m" "scripts/debug"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/save_debug_session.m" "scripts/debug"

# --------------------------------------------------
# Organize data/results
# --------------------------------------------------

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/channel_1_trimmed.csv" "data/processed"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/channel_2_trimmed.csv" "data/processed"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/speed_feedback_debug_1_trimmed.csv" "data/processed"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/speed_reference_debug_2_trimmed.csv" "data/processed"

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/test_step_signal_editor.mat" "data/signal_editor"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/work_please_signal_editor.mat" "data/signal_editor"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/host_can_inputs.mat" "data/host_inputs"

move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/configure_dyno.png" "results/figures"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/configure_dyno1.png" "results/figures"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/debug_overlay_trimmed.png" "results/figures"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/debug_pair_01_overlay_trimmed.png" "results/figures"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/epwm_dyno.png" "results/figures"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/epwm_dyno1.png" "results/figures"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/epwm_dyno2.png" "results/figures"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/ipc_dyno.png" "results/figures"
move_if_exists "Documentation/MTU_DMD_CAN/COMMON_DATA/memory_dyno.png" "results/figures"

# --------------------------------------------------
# Organize Lab folder if present
# --------------------------------------------------

move_if_exists "Lab" "docs"

# --------------------------------------------------
# Delete known huge / broken installer archive
# --------------------------------------------------

echo ""
echo "Deleting known large installer/archive files..."

if [ -f "Setup/Software.zip" ]; then
  echo "Deleting Setup/Software.zip"
  rm -f "Setup/Software.zip"
fi

# Delete all archives that should not enter Git
find . -type f \( \
  -name "*.zip" -o \
  -name "*.7z" -o \
  -name "*.rar" -o \
  -name "*.tar" -o \
  -name "*.gz" -o \
  -name "*.iso" \
  \) -print -delete

# --------------------------------------------------
# Delete generated folders
# --------------------------------------------------

echo ""
echo "Deleting generated Simulink / C2000 build folders..."

find . -type d \( \
  -name "slprj" -o \
  -name "tmwinternal" -o \
  -name "CACHE" -o \
  -name "CODEGEN" -o \
  -name "html" -o \
  -name "CCS_Project" -o \
  -name "CCS_Workspace" -o \
  -name "*_ert_rtw" -o \
  -name "*_grt_rtw" -o \
  -name "*_slrealtime_rtw" -o \
  -name "*_rtw" \
  \) -prune -exec rm -rf {} +

# --------------------------------------------------
# Delete generated files
# --------------------------------------------------

echo ""
echo "Deleting generated Simulink / C2000 build files..."

find . -type f \( \
  -name "*.slxc" -o \
  -name "*.mldatx" -o \
  -name "*.dwo" -o \
  -name "*.hex" -o \
  -name "*.out" -o \
  -name "*.obj" -o \
  -name "*.o" -o \
  -name "*.d" -o \
  -name "*.map" -o \
  -name "*.mk" -o \
  -name "*.dmr" -o \
  -name "*.bat" -o \
  -name "buildInfo.mat" -o \
  -name "codeInfo.mat" -o \
  -name "compileInfo.mat" -o \
  -name "codedescriptor.dmr" -o \
  -name "rtwtypeschksum.mat" -o \
  -name "rtw_proj.tmw" -o \
  -name "simulink_cache.xml" -o \
  -name "checksumOfCache.mat" -o \
  -name "varInfo.mat" -o \
  -name "minfo.mat" -o \
  -name "binfo.mat" -o \
  -name "BlockTraceInfo.mat" -o \
  -name "CompileInfo.xml" -o \
  -name "loggingdb.json" -o \
  -name "taskinfo.mat" -o \
  -name "peripheralInfo.mat" -o \
  -name "profiling_info.mat" -o \
  -name "instrumentationInfo.mat" \
  \) -print -delete

# --------------------------------------------------
# Create README if missing
# --------------------------------------------------

if [ ! -f "README.md" ]; then
  echo "Creating README.md..."

  cat > README.md <<'EOF'
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
EOF
fi

# --------------------------------------------------
# Final report
# --------------------------------------------------

echo ""
echo "=================================================="
echo "Cleanup complete."
echo "=================================================="
echo ""

echo "Largest remaining files:"
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -Command "Get-ChildItem -Recurse -File | Sort-Object Length -Descending | Select-Object -First 15 @{Name='Size_MB';Expression={[math]::Round(\$_.Length/1MB,2)}}, FullName | Format-List"
else
  find . -type f -printf '%s %p\n' 2>/dev/null | sort -nr | head -15
fi

echo ""
echo "Next commands:"
echo "  git init"
echo "  git branch -M main"
echo "  git add ."
echo "  git status"
echo "  git commit -m \"Organize C2000 motor drive testbed repository\""