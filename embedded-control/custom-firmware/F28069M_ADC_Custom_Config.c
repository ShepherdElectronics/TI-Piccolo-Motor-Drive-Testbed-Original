#include "c2000BoardSupport.h"
#include "F2806x_Device.h"
#include "F2806x_Examples.h"
#include "F2806x_GlobalPrototypes.h"
#include "rtwtypes.h"
#include "mcb_pmsm_foc_qep_dyno_f28069m.h"
#include "mcb_pmsm_foc_qep_dyno_f28069m_private.h"

void config_ADC_SOC4_SOC5(void)
{
  EALLOW;
  AdcRegs.ADCCTL2.bit.CLKDIV2EN = 1U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.CLKDIV4EN = 0U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.ADCNONOVERLAP = 0U;
                                 /* Set ADCNONOVERLAP contorl bit to  Allowed */
  AdcRegs.ADCSAMPLEMODE.bit.SIMULEN4 = 1U;
                                /* Simultaneous sample mode set for SOC4_SOC5.*/
  AdcRegs.ADCSOC4CTL.bit.CHSEL = 0U;
                             /* Set SOC4 channel select to ADCINA0 and ADCINB0*/
  AdcRegs.ADCSOC4CTL.bit.TRIGSEL = 0U;
  AdcRegs.ADCSOC4CTL.bit.ACQPS = (uint16_T)6.0;
                                /* Set SOC4 S/H Window to 7.0 ADC Clock Cycles*/
  AdcRegs.ADCINTSOCSEL1.bit.SOC4 = 0U;
                                   /* SOCx No ADCINT Interrupt Trigger Select.*/
  AdcRegs.ADCOFFTRIM.bit.OFFTRIM = (uint16_T)AdcRegs.ADCOFFTRIM.bit.OFFTRIM;/* Set Offset Error Correctino Value*/
  AdcRegs.ADCCTL1.bit.ADCREFSEL = 0U ; /* Set Reference Voltage*/
  AdcRegs.ADCCTL1.bit.INTPULSEPOS = 1U;
                                /* Late interrupt pulse trips AdcResults latch*/
  AdcRegs.SOCPRICTL.bit.SOCPRIORITY = 0U;/* All in round robin mode SOC Priority*/
  EDIS;
}

void config_ADC_SOC6_SOC7(void)
{
  EALLOW;
  AdcRegs.ADCCTL2.bit.CLKDIV2EN = 1U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.CLKDIV4EN = 0U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.ADCNONOVERLAP = 0U;
                                 /* Set ADCNONOVERLAP contorl bit to  Allowed */
  AdcRegs.ADCSAMPLEMODE.bit.SIMULEN6 = 1U;
                                /* Simultaneous sample mode set for SOC6_SOC7.*/
  AdcRegs.ADCSOC6CTL.bit.CHSEL = 3U;
                             /* Set SOC6 channel select to ADCINA3 and ADCINB3*/
  AdcRegs.ADCSOC6CTL.bit.TRIGSEL = 0U;
  AdcRegs.ADCSOC6CTL.bit.ACQPS = (uint16_T)6.0;
                                /* Set SOC6 S/H Window to 7.0 ADC Clock Cycles*/
  AdcRegs.ADCINTSOCSEL1.bit.SOC6 = 0U;
                                   /* SOCx No ADCINT Interrupt Trigger Select.*/
  AdcRegs.ADCOFFTRIM.bit.OFFTRIM = (uint16_T)AdcRegs.ADCOFFTRIM.bit.OFFTRIM;/* Set Offset Error Correctino Value*/
  AdcRegs.ADCCTL1.bit.ADCREFSEL = 0U ; /* Set Reference Voltage*/
  AdcRegs.ADCCTL1.bit.INTPULSEPOS = 1U;
                                /* Late interrupt pulse trips AdcResults latch*/
  AdcRegs.SOCPRICTL.bit.SOCPRIORITY = 0U;/* All in round robin mode SOC Priority*/
  EDIS;
}

void config_ADC_SOC2_SOC3(void)
{
  EALLOW;
  AdcRegs.ADCCTL2.bit.CLKDIV2EN = 1U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.CLKDIV4EN = 0U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.ADCNONOVERLAP = 0U;
                                 /* Set ADCNONOVERLAP contorl bit to  Allowed */
  AdcRegs.ADCSAMPLEMODE.bit.SIMULEN2 = 1U;
                                /* Simultaneous sample mode set for SOC2_SOC3.*/
  AdcRegs.ADCSOC2CTL.bit.CHSEL = 3U;
                             /* Set SOC2 channel select to ADCINA3 and ADCINB3*/
  AdcRegs.ADCSOC2CTL.bit.TRIGSEL = 11U;
  AdcRegs.ADCSOC2CTL.bit.ACQPS = (uint16_T)6.0;
                                /* Set SOC2 S/H Window to 7.0 ADC Clock Cycles*/
  AdcRegs.INTSEL1N2.bit.INT2E = 1U;    /* Enabled/Disable ADCINT2 interrupt*/
  AdcRegs.INTSEL1N2.bit.INT2SEL = 3U;  /* Setup EOC3 to trigger ADCINT2*/
  AdcRegs.INTSEL1N2.bit.INT2CONT = 1U;
                                     /* Enable/Disable ADCINT2 Continuous mode*/
  AdcRegs.ADCINTSOCSEL1.bit.SOC2 = 0U;
                                   /* SOCx No ADCINT Interrupt Trigger Select.*/
  AdcRegs.ADCOFFTRIM.bit.OFFTRIM = (uint16_T)AdcRegs.ADCOFFTRIM.bit.OFFTRIM;/* Set Offset Error Correctino Value*/
  AdcRegs.ADCCTL1.bit.ADCREFSEL = 0U ; /* Set Reference Voltage*/
  AdcRegs.ADCCTL1.bit.INTPULSEPOS = 1U;
                                /* Late interrupt pulse trips AdcResults latch*/
  AdcRegs.SOCPRICTL.bit.SOCPRIORITY = 0U;/* All in round robin mode SOC Priority*/
  EDIS;
}

void config_ADC_SOC0_SOC1(void)
{
  EALLOW;
  AdcRegs.ADCCTL2.bit.CLKDIV2EN = 1U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.CLKDIV4EN = 0U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.ADCNONOVERLAP = 0U;
                                 /* Set ADCNONOVERLAP contorl bit to  Allowed */
  AdcRegs.ADCSAMPLEMODE.bit.SIMULEN0 = 1U;
                                /* Simultaneous sample mode set for SOC0_SOC1.*/
  AdcRegs.ADCSOC0CTL.bit.CHSEL = 0U;
                             /* Set SOC0 channel select to ADCINA0 and ADCINB0*/
  AdcRegs.ADCSOC0CTL.bit.TRIGSEL = 5U;
  AdcRegs.ADCSOC0CTL.bit.ACQPS = (uint16_T)6.0;
                                /* Set SOC0 S/H Window to 7.0 ADC Clock Cycles*/
  AdcRegs.INTSEL1N2.bit.INT1E = 1U;    /* Enabled/Disable ADCINT1 interrupt*/
  AdcRegs.INTSEL1N2.bit.INT1SEL = 1U;  /* Setup EOC1 to trigger ADCINT1*/
  AdcRegs.INTSEL1N2.bit.INT1CONT = 1U;
                                     /* Enable/Disable ADCINT1 Continuous mode*/
  AdcRegs.ADCINTSOCSEL1.bit.SOC0 = 0U;
                                   /* SOCx No ADCINT Interrupt Trigger Select.*/
  AdcRegs.ADCOFFTRIM.bit.OFFTRIM = (uint16_T)AdcRegs.ADCOFFTRIM.bit.OFFTRIM;/* Set Offset Error Correctino Value*/
  AdcRegs.ADCCTL1.bit.ADCREFSEL = 0U ; /* Set Reference Voltage*/
  AdcRegs.ADCCTL1.bit.INTPULSEPOS = 1U;
                                /* Late interrupt pulse trips AdcResults latch*/
  AdcRegs.SOCPRICTL.bit.SOCPRIORITY = 0U;/* All in round robin mode SOC Priority*/
  EDIS;
}

void config_ADC_SOC14_SOC15(void)
{
  EALLOW;
  AdcRegs.ADCCTL2.bit.CLKDIV2EN = 1U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.CLKDIV4EN = 0U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.ADCNONOVERLAP = 0U;
                                 /* Set ADCNONOVERLAP contorl bit to  Allowed */
  AdcRegs.ADCSAMPLEMODE.bit.SIMULEN14 = 1U;
                              /* Simultaneous sample mode set for SOC14_SOC15.*/
  AdcRegs.ADCSOC14CTL.bit.CHSEL = 1U;
                            /* Set SOC14 channel select to ADCINA1 and ADCINB1*/
  AdcRegs.ADCSOC14CTL.bit.TRIGSEL = 5U;
  AdcRegs.ADCSOC14CTL.bit.ACQPS = (uint16_T)6.0;
                               /* Set SOC14 S/H Window to 7.0 ADC Clock Cycles*/
  AdcRegs.INTSEL9N10.bit.INT9E = 1U;   /* Enabled/Disable ADCINT9 interrupt*/
  AdcRegs.INTSEL9N10.bit.INT9SEL = 15U;/* Setup EOC15 to trigger ADCINT9*/
  AdcRegs.INTSEL9N10.bit.INT9CONT = 1U;
                                     /* Enable/Disable ADCINT9 Continuous mode*/
  AdcRegs.ADCINTSOCSEL2.bit.SOC14 = 1U;
                                     /* SOCx ADCINT1 Interrupt Trigger Select.*/
  AdcRegs.ADCOFFTRIM.bit.OFFTRIM = (uint16_T)AdcRegs.ADCOFFTRIM.bit.OFFTRIM;/* Set Offset Error Correctino Value*/
  AdcRegs.ADCCTL1.bit.ADCREFSEL = 0U ; /* Set Reference Voltage*/
  AdcRegs.ADCCTL1.bit.INTPULSEPOS = 1U;
                                /* Late interrupt pulse trips AdcResults latch*/
  AdcRegs.SOCPRICTL.bit.SOCPRIORITY = 0U;/* All in round robin mode SOC Priority*/
  EDIS;
}

void config_ADC_SOC12_SOC13(void)
{
  EALLOW;
  AdcRegs.ADCCTL2.bit.CLKDIV2EN = 1U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.CLKDIV4EN = 0U;  /* Set ADC clock division */
  AdcRegs.ADCCTL2.bit.ADCNONOVERLAP = 0U;
                                 /* Set ADCNONOVERLAP contorl bit to  Allowed */
  AdcRegs.ADCSAMPLEMODE.bit.SIMULEN12 = 1U;
                              /* Simultaneous sample mode set for SOC12_SOC13.*/
  AdcRegs.ADCSOC12CTL.bit.CHSEL = 2U;
                            /* Set SOC12 channel select to ADCINA2 and ADCINB2*/
  AdcRegs.ADCSOC12CTL.bit.TRIGSEL = 5U;
  AdcRegs.ADCSOC12CTL.bit.ACQPS = (uint16_T)6.0;
                               /* Set SOC12 S/H Window to 7.0 ADC Clock Cycles*/
  AdcRegs.INTSEL5N6.bit.INT5E = 1U;    /* Enabled/Disable ADCINT5 interrupt*/
  AdcRegs.INTSEL5N6.bit.INT5SEL = 13U; /* Setup EOC13 to trigger ADCINT5*/
  AdcRegs.INTSEL5N6.bit.INT5CONT = 1U;
                                     /* Enable/Disable ADCINT5 Continuous mode*/
  AdcRegs.ADCINTSOCSEL2.bit.SOC12 = 1U;
                                     /* SOCx ADCINT1 Interrupt Trigger Select.*/
  AdcRegs.ADCOFFTRIM.bit.OFFTRIM = (uint16_T)AdcRegs.ADCOFFTRIM.bit.OFFTRIM;/* Set Offset Error Correctino Value*/
  AdcRegs.ADCCTL1.bit.ADCREFSEL = 0U ; /* Set Reference Voltage*/
  AdcRegs.ADCCTL1.bit.INTPULSEPOS = 1U;
                                /* Late interrupt pulse trips AdcResults latch*/
  AdcRegs.SOCPRICTL.bit.SOCPRIORITY = 0U;/* All in round robin mode SOC Priority*/
  EDIS;
}
