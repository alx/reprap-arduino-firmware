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

const int StepsInInch = 1000; //TODO: Calibrate these
const int StepsInMM   = 50;   //TODO: Calibrate these
const int MAX_SPEED   = 1650; //TODO: Calibrate these

#include <HardwareSerial.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>
#include <ThermoplastExtruder.h>

void setup()
{
	//Do startup stuff here
	Serial.begin(19200);
	Serial.println("Startup");  
}
