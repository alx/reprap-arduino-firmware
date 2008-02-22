 /*
	Extruder_SNAP.pde - RepRap Thermoplastic Extruder firmware for Arduino

	Main firmware for the extruder (heater, motor and temp. sensor)

	History:
	* (0.1) Created intial version by Philipp Tiefenbacher and Marius Kintel
	* (0.2) Updated code to properly work with the RepRap host software.
	* (0.3) Updated code to work with v1 of the comms protocol and the associated optimizations by Zach Smith.
	* (0.4) Updated with new library changes by Zach Smith.

	License: GPL v2.0
*/

#include <ThermoplastExtruder.h>
#include <SNAP.h>
#include <ThermoplastExtruder_SNAP_v1.h>

#define EXTRUDER_MOTOR_SPEED_PIN  3
#define EXTRUDER_MOTOR_DIR_PIN    4
#define EXTRUDER_HEATER_PIN       5
#define EXTRUDER_COOLER_PIN       6
#define EXTRUDER_THERMISTOR_PIN   0

ThermoplastExtruder extruder(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_MOTOR_SPEED_PIN, EXTRUDER_HEATER_PIN, EXTRUDER_COOLER_PIN, EXTRUDER_THERMISTOR_PIN);

#include <SoftwareSerial.h>

void setup()
{      
	Serial.begin(19200);

	setup_extruder_snap_v1();
}

void loop()
{
	//manage our temperature
	extruder.manageTemperature();

	//process our commands
	snap.receivePacket();
	if (snap.packetReady())
		process_thermoplast_extruder_snap_commands_v1();
}
