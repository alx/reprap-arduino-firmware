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
#define X_STEP_PIN 
#define X_DIR_PIN 
#define X_MIN_PIN 
#define X_MAX_PIN 
#define X_ENABLE_PIN 
#define Y_STEP_PIN 
#define Y_DIR_PIN 
#define Y_MIN_PIN 
#define Y_MAX_PIN 
#define Y_ENABLE_PIN 
#define Z_STEP_PIN 
#define Z_DIR_PIN 
#define Z_MIN_PIN 
#define Z_MAX_PIN 
#define Z_ENABLE_PIN

//extruder pins
#define EXTRUDER_MOTOR_SPEED_PIN  
#define EXTRUDER_MOTOR_DIR_PIN    
#define EXTRUDER_HEATER_PIN       
#define EXTRUDER_THERMISTOR_PIN 0

//the addresses of our emulated axes.
#define X_ADDRESS 2
#define Y_ADDRESS 3
#define Z_ADDRESS 4
#define EXTRUDER_ADDRESS 8

// how many steps do our motors have?
#define X_MOTOR_STEPS 400
#define Y_MOTOR_STEPS 400
#define Z_MOTOR_STEPS 400

//our library includes.
#include <SNAP.h>
#include <LimitSwitch.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>
#include <CartesianBot_SNAP_v1.h>
#include <ThermoplastExtruder_SNAP_v2.h>

void setup()
{
	Serial.begin(19200);
	
	//run any setup code we need.
	setup_cartesian_bot_snap_v1();
	setup_extruder_snap_v2();
}

void loop()
{	
	//get our state status / manage our status.
	bot.readState();
	extruder.manageState();

	//process our commands
	snap.receivePacket();
	if (snap.packetReady())
	{
		//who is it for?
		byte dest = snap.getDestination();
	
		//route the command to the proper object.
		if (dest == EXTRUDER_ADDRESS)
			process_thermoplast_extruder_snap_commands_v2();
		else
			process_cartesian_bot_snap_commands_v1();
	}
}
