# Interface Summary

- Motor 1 encoder: QEP-A input path
- Motor 2 encoder: QEP-B input path
- Motor phases: MOTA/MOTB/MOTC on each inverter
- DC bus: 24 V nominal, polarity verified before energization
- CAN command frame: standard identifier 0x100, 8 bytes
- CAN diagnostic echo: standard identifier 0x101, 8 bytes
- Host payload: four packed 16-bit command words
- Telemetry scope: Id, Iq, Vd, Vq, speed, torque estimate, and mechanical power channels
