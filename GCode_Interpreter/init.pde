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

// define the parameters of our machine.
float X_STEPS_PER_INCH  = 416.772354;
float X_STEPS_PER_MM    = 16.4083604;
int   X_MAX_SPEED       = 30;
int   X_MOTOR_STEPS     = 400;

float Y_STEPS_PER_INCH  = 416.772354;
float Y_STEPS_PER_MM    = 16.4083604;
int   Y_MAX_SPEED       = 100;
int   Y_MOTOR_STEPS     = 400;

float Z_STEPS_PER_INCH  = 16256.0;
float Z_STEPS_PER_MM    = 640.0;
int   Z_MAX_SPEED       = 40;
int   Z_MOTOR_STEPS     = 400;

//default to inches for units
static float x_units = X_STEPS_PER_INCH;
static float y_units = Y_STEPS_PER_INCH;
static float z_units = Z_STEPS_PER_INCH;

#include <HardwareSerial.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <ThermoplastExtruder.h>

// our point structure to make things nice.
struct Point {
	int x;
	int y;
 	int z;
};

LinearAxis x('x', X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN, X_ENABLE_PIN);
LinearAxis y('y', Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN, Y_ENABLE_PIN);
LinearAxis z('z', Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN, Z_ENABLE_PIN);

void setup()
{
	//Do startup stuff here
	Serial.begin(19200);
	Serial.println("Startup");
	
	x.stepper.setRPM(X_MAX_SPEED);
	y.stepper.setRPM(Y_MAX_SPEED);
	z.stepper.setRPM(Z_MAX_SPEED);
}
