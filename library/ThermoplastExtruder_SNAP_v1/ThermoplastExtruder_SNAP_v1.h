/*
	ThermoplastExtruder_SNAP_v1.h - Thermoplastic Extruder SNAP Communications library for Arduino

	This library implements/emulates v1 of the RepRap Thermoplastic Extruder communications protocol.
	The initial protocol was designed around measuring temperature by the amount of time
	it takes to charge a capacitor through the thermistor.  In order to maintain compatibility,
	the Arduino takes its analog reading and converts it into the value a PIC would return.
	
	More information on the protocol here: http://reprap.org/bin/view/Main/ExtruderController

	Memory Usage Estimate: 5 - 50? + ThermoplastExtruder

	History:
	* (0.1) Created intial library by Zach Smith.
	* (0.2) Updated to emulate PIC based temperature measuring.
	* (0.3) Updated with new values from Steve DeGroof (http://forums.reprap.org/read.php?70,8034)
	* (0.4) Rewrote and refactored all code.  Fixed major interrupt bug by Zach Smith.
	

	License: GPL v2.0
*/

#ifndef THERMOPLAST_EXTRUDER_SNAP_V1H
#define THERMOPLAST_EXTRUDER_SNAP_V1_H

//
// constants for temp/pic temp conversion. from reprap.properties.dist
//
#define BETA 550.0
#define CAPACITOR 0.000003
#define RZ 4837
#define ABSOLUTE_ZERO 273.15

//our include files.
#include <ThermoplastExtruder.h>
#include <SNAP.h>
#include <math.h>

//
// Various processing commands.
//
void setup_extruder_snap_v1();
void process_thermoplast_extruder_snap_commands_v1();

//
// Conversion commands
//
int calculateTemperatureForPicTemp(int picTemp);
int calculatePicTempForCelsius(int temperature);

//
// Version information
//
#define VERSION_MAJOR 1
#define VERSION_MINOR 0
#define EXTRUDER_ADDRESS 8
#define DEVICE_TYPE 1

//
// Extruder commands
//
#define CMD_VERSION       0
#define CMD_FORWARD       1
#define CMD_REVERSE       2
#define CMD_SETPOS        3
#define CMD_GETPOS        4
#define CMD_SEEK          5
#define CMD_FREE          6
#define CMD_NOTIFY        7
#define CMD_ISEMPTY       8
#define CMD_SETHEAT       9
#define CMD_GETTEMP       10
#define CMD_SETCOOLER     11
#define CMD_VALVEOPEN  	  12
#define CMD_VALVECLOSE    13
#define CMD_PWMPERIOD     50
#define CMD_PRESCALER     51 //apparently doesnt exist...
#define CMD_SETVREF       52
#define CMD_SETTEMPSCALER 53
#define CMD_GETDEBUGINFO  54 //apparently doesnt exist...
#define CMD_GETTEMPINFO   55 //apparently doesnt exist...
#define CMD_DEVICE_TYPE   255

extern ThermoplastExtruder extruder;

#endif
