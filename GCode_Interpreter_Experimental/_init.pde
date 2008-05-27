
// define the parameters of our machine.
#define X_STEPS_PER_INCH 416.772354
#define X_STEPS_PER_MM   16.4083604
#define X_MOTOR_STEPS    400

#define Y_STEPS_PER_INCH 416.772354
#define Y_STEPS_PER_MM   16.4083604
#define Y_MOTOR_STEPS    400

#define Z_STEPS_PER_INCH 16256.0
#define Z_STEPS_PER_MM   640.0
#define Z_MOTOR_STEPS    400

//our maximum feedrates
#define FAST_XY_FEEDRATE 1000.0
#define FAST_Z_FEEDRATE  50.0

// Units in curve section
#define CURVE_SECTION_INCHES 0.019685
#define CURVE_SECTION_MM 0.5

// Set to one if sensor outputs inverting (ie: 1 means open, 0 means closed)
// RepRap opto endstops are *not* inverting.
#define SENSORS_INVERTING 0

// How many temperature samples to take.  each sample takes about 100 usecs.
#define TEMPERATURE_SAMPLES 5

//these defines are for using rotary encoders on the extruder
#define EXTRUDER_ENCODER_STEPS 512		//number of steps per revolution
#define EXTRUDER_MIN_SPEED 50			//minimum PWM speed to use
#define EXTRUDER_MAX_SPEED 255			//maximum PWM speed to use
#define EXTRUDER_ERROR_MARGIN 10		//our error margin (to prevent constant seeking)
#define INVERT_QUADRATURE			0 // 1 = inverted, 0 = not inverted

/****************************************************************************************
* digital i/o pin assignment
*
* this uses the undocumented feature of Arduino - pins 14-19 correspond to analog 0-5
****************************************************************************************/

//cartesian bot pins
#define X_STEP_PIN 7
#define X_DIR_PIN 8
#define X_MIN_PIN 14
#define X_MAX_PIN 17
#define X_ENABLE_PIN 18

#define Y_STEP_PIN 9
#define Y_DIR_PIN 10
#define Y_MIN_PIN 15
#define Y_MAX_PIN 17
#define Y_ENABLE_PIN 18

#define Z_STEP_PIN 12
#define Z_DIR_PIN 13
#define Z_MIN_PIN 16
#define Z_MAX_PIN 17
#define Z_ENABLE_PIN 18

//extruder pins
#define EXTRUDER_ENCODER_A_PIN 2		//quadrature a pin
#define EXTRUDER_ENCODER_B_PIN 3		//quadrature b pin
#define EXTRUDER_MOTOR_DIR_PIN     4
#define EXTRUDER_MOTOR_SPEED_PIN   5
#define EXTRUDER_HEATER_PIN        6
#define EXTRUDER_FAN_PIN           11
#define EXTRUDER_THERMISTOR_PIN    5  //a -1 disables thermistor readings
#define EXTRUDER_THERMOCOUPLE_PIN  -1 //a -1 disables thermocouple readings
