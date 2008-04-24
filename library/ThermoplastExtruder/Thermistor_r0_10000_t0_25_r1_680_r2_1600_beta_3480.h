#ifndef THERMISTOR_TABLE
#define THERMISTOR_TABLE

// Thermistor lookup table for RepRap Temperature Sensor Boards (http://make.rrrf.org/ts)
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=10000 --t0=25 --r1=680 --r2=1600 --beta=3480 --max-adc=315
// r0: 10000
// t0: 25
// r1: 680
// r2: 1600
// beta: 3480
// max adc: 315
#define NUMTEMPS 20
short temptable[NUMTEMPS][2] = {
   {1, 922},
   {17, 327},
   {33, 260},
   {49, 225},
   {65, 202},
   {81, 184},
   {97, 169},
   {113, 156},
   {129, 145},
   {145, 134},
   {161, 125},
   {177, 115},
   {193, 106},
   {209, 96},
   {225, 87},
   {241, 76},
   {257, 64},
   {273, 50},
   {289, 29},
   {305, -45}
};

#endif
