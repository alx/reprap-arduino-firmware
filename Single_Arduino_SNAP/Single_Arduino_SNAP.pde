/*
	Single_Arduino_SNAP.pde - Combined cartesian bot + extruder firmware.

	History:
	* Created initial version (0.1) by Zach Smith.
*/

/****************************************************************************************
* digital i/o pin assignment
*
* this uses the undocumented feature of Arduino - pins 14-19 correspond to analog 0-5
****************************************************************************************/

//cartesian bot pins
#define X_STEP_PIN 2
#define X_DIR_PIN 3
#define X_MIN_PIN 4
#define X_MAX_PIN 9
#define X_ENABLE_PIN 15
#define Y_STEP_PIN 10
#define Y_DIR_PIN 7
#define Y_MIN_PIN 8
#define Y_MAX_PIN 13
#define Y_ENABLE_PIN 15
#define Z_STEP_PIN 19
#define Z_DIR_PIN 18
#define Z_MIN_PIN 17
#define Z_MAX_PIN 16
#define Z_ENABLE_PIN 15

//extruder pins
#define EXTRUDER_MOTOR_SPEED_PIN  11
#define EXTRUDER_MOTOR_DIR_PIN    12
#define EXTRUDER_HEATER_PIN       6
#define EXTRUDER_FAN_PIN          5
#define EXTRUDER_THERMISTOR_PIN   0

// how many steps do our motors have?
#define X_MOTOR_STEPS 400
#define Y_MOTOR_STEPS 400
#define Z_MOTOR_STEPS 400

//our library includes.
#include <SNAP.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>
#include <ThermoplastExtruder.h>
#include <CartesianBot_SNAP_v1.h>
#include <ThermoplastExtruder_SNAP_v1.h>

ThermoplastExtruder extruder(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_MOTOR_SPEED_PIN, EXTRUDER_HEATER_PIN, EXTRUDER_FAN_PIN, EXTRUDER_THERMISTOR_PIN);

CartesianBot bot = CartesianBot(
	'x', X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN, X_ENABLE_PIN,
	'y', Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN, Y_ENABLE_PIN,
	'z', Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN, Z_ENABLE_PIN
);

SIGNAL(SIG_OUTPUT_COMPARE1A)
{
	handleInterrupt();
}

void setup()
{
	Serial.begin(19200);
	
	//run any setup code we need.
	setup_cartesian_bot_snap_v1();
	setup_extruder_snap_v1();
}

void loop()
{	
	//get our state status / manage our status.
	bot.readState();
	extruder.manageTemperature();

	//process our commands
	snap.receivePacket();
	if (snap.packetReady())
	{
		//who is it for?
		byte dest = snap.getDestination();
	
		//route the command to the proper object.
		if (dest == EXTRUDER_ADDRESS)
			process_thermoplast_extruder_snap_commands_v1();
		else
			process_cartesian_bot_snap_commands_v1();
	}
}
