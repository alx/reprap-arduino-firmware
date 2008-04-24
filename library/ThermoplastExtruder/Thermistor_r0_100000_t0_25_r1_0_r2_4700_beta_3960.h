#ifndef THERMISTOR_TABLE
#define THERMISTOR_TABLE

// Thermistor lookup table for RepRap Temperature Sensor Boards (http://make.rrrf.org/ts)
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=100000 --t0=25 --r1=0 --r2=4700 --beta=3960 --max-adc=1023
// r0: 100000
// t0: 25
// r1: 0
// r2: 4700
// beta: 3960
// max adc: 1023
#define NUMTEMPS 20
short temptable[NUMTEMPS][2] = {
   {1, 929},
   {54, 266},
   {107, 217},
   {160, 190},
   {213, 172},
   {266, 158},
   {319, 146},
   {372, 136},
   {425, 127},
   {478, 119},
   {531, 111},
   {584, 103},
   {637, 96},
   {690, 88},
   {743, 80},
   {796, 71},
   {849, 62},
   {902, 50},
   {955, 34},
   {1008, 2}
};

#endif
