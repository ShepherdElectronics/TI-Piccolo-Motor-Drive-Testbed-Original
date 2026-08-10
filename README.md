# TI Piccolo Dual-Motor PMSM Dynamometer

An integrated motor-control and test platform built around a TI C2000 Piccolo controller, two inverter stages, two coupled permanent-magnet synchronous machines, and a real-time measurement workflow.

## What the platform is

The dynamometer is a laboratory test system used to operate one motor as the drive machine and the second as a controlled load. The platform brings together:

- TI C2000 LaunchPad control hardware
- Two inverter stages and a shared DC supply
- Encoder feedback and current/voltage measurement
- CAN-connected supervisory control
- Simulink and real-time test orchestration
- Torque, speed, power, and efficiency characterization

The engineering work covers the integration boundary between the physical dyno, embedded control, host-side test execution, measurement, and technical evidence.

## Customer-facing engineering report

The [public FRD PDF](docs/Dual_Motor_Dynamometer_Platform_FRD_Public.pdf) provides the concise engineering overview, system boundary, architecture context, selected evidence, and qualification limits. The [editable DOCX version](docs/Dual_Motor_Dynamometer_Platform_FRD_Public.docx) is provided for document review.

For the broader project presentation, see the [online dyno case study](https://herdersystemen.com/projects/ti-piccolo-pmsm-dynamometer).

## Selected evidence

- [Screened efficiency points](results/04_valid_efficiency_points.png)
- [Interpolated efficiency map](results/07_interpolated_efficiency_map.png)
- [Efficiency contour](results/08_efficiency_contour.png)

## Public release boundary

This repository is a customer-facing evidence release. It is intended to make the platform and engineering scope easy to understand quickly; it is not a build or deployment package.

Implementation source, editable control models, host scripts, hardware interface records, schematics, bills of material, setup procedures, calibration values, raw data, and internal engineering documentation are intentionally kept private.

The released material does not claim production qualification, safety certification, vendor endorsement, or turnkey operation.
