// Arduino G-code Interpreter
// v1.0 by Mike Ellery (mellery@gmail.com)
// v1.1 by Zach Smith  (hoeken@gmail.com)

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
int   X_MAX_SPEED       = 20;
int   X_MOTOR_STEPS     = 400;

float Y_STEPS_PER_INCH  = 416.772354;
float Y_STEPS_PER_MM    = 16.4083604;
int   Y_MAX_SPEED       = 20;
int   Y_MOTOR_STEPS     = 400;

float Z_STEPS_PER_INCH  = 16256.0;
float Z_STEPS_PER_MM    = 640.0;
int   Z_MAX_SPEED       = 40;
int   Z_MOTOR_STEPS     = 400;

//default to inches for units
float x_units = X_STEPS_PER_INCH;
float y_units = Y_STEPS_PER_INCH;
float z_units = Z_STEPS_PER_INCH;

//these our the default values for the extruder.
int extruder_speed = 128;

#include <HardwareSerial.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <ThermoplastExtruder.h>

LinearAxis x('x', X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN, X_ENABLE_PIN);
LinearAxis y('y', Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN, Y_ENABLE_PIN);
LinearAxis z('z', Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN, Z_ENABLE_PIN);

ThermoplastExtruder extruder(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_MOTOR_SPEED_PIN, EXTRUDER_HEATER_PIN, EXTRUDER_FAN_PIN, EXTRUDER_THERMISTOR_PIN);

// our point structure to make things nice.
struct LongPoint {
	long x;
	long y;
 	long z;
};

struct FloatPoint {
	float x;
	float y;
 	float z;
};

FloatPoint current;
FloatPoint target;
FloatPoint delta;

void setup()
{
	//Do startup stuff here
	Serial.begin(19200);
	Serial.println("start");
	
	x.stepper.setRPM(X_MAX_SPEED);
	y.stepper.setRPM(Y_MAX_SPEED);
	z.stepper.setRPM(Z_MAX_SPEED);
	
	//default to room temp.
	extruder.setTemperature(21);
	extruder.heater_low = 64;
	extruder.heater_high = 255;
	
	current.x = 0.0;
	current.y = 0.0;
	current.z = 0.0;
	
	target.x = 0.0;
	target.y = 0.0;
	target.z = 0.0;
}

void loop()
{
	char c;
	char word[256] = "";  //TODO: magic numbers are bad
	int serial_count;

	if (Serial.available() > 0)
	{
		serial_count = 0;
		while(Serial.available() > 0)
		{
			c = Serial.read();
			
			if (c == '\n')
				break;
				
			word[serial_count] = c;
			delayMicroseconds(1000);  //TODO: is there a better way to wait for serial?
			serial_count++;
		}
		word[serial_count] = ' '; //TODO: kinda hacky

		process_string(word, sizeof(word));

		Serial.println("done");
	}
	
	extruder.manageTemperature();
}
