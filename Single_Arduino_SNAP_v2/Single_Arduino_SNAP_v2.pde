/*
	Single_Arduino_SNAP_v2.pde - 2nd Generation RepRap Protocol

	History:
	* (0.1) Created initial version by Zach Smith.
	
	License: GPL v2.0
*/

//our library includes.
#include <HardwareSerial.h>
#include <SNAP.h>

void setup()
{
	snap.begin(19200);

	init_steppers();
	init_extruder();
	init_process_snap();
}

void loop()
{	
	extruder_manage_temperature();
	process_snap_packet();
}
