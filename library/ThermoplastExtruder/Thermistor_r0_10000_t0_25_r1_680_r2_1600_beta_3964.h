#ifndef THERMISTOR_TABLE
#define THERMISTOR_TABLE

// Thermistor lookup table for RepRap Temperature Sensor Boards (http://make.rrrf.org/ts)
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=10000 --t0=25 --r1=680 --r2=1600 --beta=3964 --max-adc=305
// r0: 10000
// t0: 25
// r1: 680
// r2: 1600
// beta: 3964
// max adc: 305
#define NUMTEMPS 19
short temptable[NUMTEMPS][2] = {
   {1, 601},
   {17, 260},
   {33, 213},
   {49, 187},
   {65, 170},
   {81, 156},
   {97, 144},
   {113, 134},
   {129, 125},
   {145, 117},
   {161, 109},
   {177, 101},
   {193, 94},
   {209, 86},
   {225, 78},
   {241, 69},
   {257, 59},
   {273, 46},
   {289, 28}
};

#endif