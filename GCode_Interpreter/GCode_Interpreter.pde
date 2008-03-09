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
int   X_MOTOR_STEPS     = 400;

float Y_STEPS_PER_INCH  = 416.772354;
float Y_STEPS_PER_MM    = 16.4083604;
int   Y_MOTOR_STEPS     = 400;

float Z_STEPS_PER_INCH  = 16256.0;
float Z_STEPS_PER_MM    = 640.0;
int   Z_MOTOR_STEPS     = 400;

#define FAST_XY_FEEDRATE 1000.0
#define FAST_Z_FEEDRATE  50.0

//default to inches for units
float x_units = X_STEPS_PER_INCH;
float y_units = Y_STEPS_PER_INCH;
float z_units = Z_STEPS_PER_INCH;

//our direction vars
byte x_direction = 1;
byte y_direction = 1;
byte z_direction = 1;

//these our the default values for the extruder.
int extruder_speed = 128;

#include <HardwareSerial.h>
#include <ThermoplastExtruder.h>

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

FloatPoint current_units;
FloatPoint target_units;
FloatPoint delta_units;

FloatPoint current_steps;
FloatPoint target_steps;
FloatPoint delta_steps;

//our command string
#define COMMAND_SIZE 128
char word[COMMAND_SIZE];
byte serial_count;
int no_data = 0;

boolean abs_mode = false;   //0 = incremental; 1 = absolute

void setup()
{
	//Do startup stuff here
	Serial.begin(19200);
	Serial.println("start");
	
	//init our command
	for (byte i=0; i<COMMAND_SIZE; i++)
		word[i] = 0;
	serial_count = 0;
	
	//default to room temp.
	extruder.setTemperature(21);
	extruder.heater_low = 64;
	extruder.heater_high = 255;
	
	//init our points.
	current_units.x = 0.0;
	current_units.y = 0.0;
	current_units.z = 0.0;
	target_units.x = 0.0;
	target_units.y = 0.0;
	target_units.z = 0.0;
	
	//figure our stuff.
	calculate_deltas();
	
	pinMode(X_STEP_PIN, OUTPUT);
	pinMode(X_DIR_PIN, OUTPUT);
	pinMode(X_ENABLE_PIN, OUTPUT);
	pinMode(X_MIN_PIN, INPUT);
	pinMode(X_MAX_PIN, INPUT);
	
	pinMode(Y_STEP_PIN, OUTPUT);
	pinMode(Y_DIR_PIN, OUTPUT);
	pinMode(Y_ENABLE_PIN, OUTPUT);
	pinMode(Y_MIN_PIN, INPUT);
	pinMode(Y_MAX_PIN, INPUT);
	
	pinMode(Z_STEP_PIN, OUTPUT);
	pinMode(Z_DIR_PIN, OUTPUT);
	pinMode(Z_ENABLE_PIN, OUTPUT);
	pinMode(Z_MIN_PIN, INPUT);
	pinMode(Z_MAX_PIN, INPUT);
}

void loop()
{
	char c;
	
	//keep it hot!
	extruder.manageTemperature();

	//read in characters if we got them.
	if (Serial.available() > 0)
	{
		c = Serial.read();
		no_data = 0;
		
		//newlines are ends of commands.
		if (c != '\n')
		{
			word[serial_count] = c;
			serial_count++;
		}
	}
	//mark no data.
	else
	{
		no_data++;
		delayMicroseconds(10);
	}

	//if theres a pause or we got a real command, do it
	if (serial_count && (c == '\n' || no_data > 100))
	{
		//process our command!
		process_string(word, serial_count);

		//clear command.
		for (byte i=0; i<COMMAND_SIZE; i++)
			word[i] = 0;
		serial_count = 0;
	}
}
