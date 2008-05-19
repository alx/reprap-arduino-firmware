/*
	3Axis_DDA_Tester.pde - RepRap DDA Movement Tester

	History:
	* (0.1) Created initial version by Zach Smith.
	* (0.2) Updated to handle optimization changes by Zach Smith.
	* (0.3) Updated with new library changes by Zach Smith.

	License: GPL v2.0
*/

#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>

/********************************
 * digital i/o pin assignment
 ********************************/
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

/********************************
 * how many steps do our motors have?
 ********************************/
#define X_MOTOR_STEPS 400
#define Y_MOTOR_STEPS 400
#define Z_MOTOR_STEPS 400

/********************************
 *  Global variable declarations
 ********************************/

//our cartesian bot object

CartesianBot bot(
                 'x', X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN, X_ENABLE_PIN,
                 'y', Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN, Y_ENABLE_PIN,
                 'z', Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN, Z_ENABLE_PIN
                 );
Point p;

int max_speed = 100;
int max_x = 2500;
int max_y = 2500;

SIGNAL(SIG_OUTPUT_COMPARE1A)
{
	if (bot.x.can_step)
		bot.x.ddaStep(bot.max_delta);

	if (bot.y.can_step)
		bot.y.ddaStep(bot.max_delta);

	if (bot.z.can_step)
		bot.z.ddaStep(bot.max_delta);
}
	
void setup()
{
	bot.setupTimerInterrupt();
	
	Serial.begin(57600);
	Serial.println("Starting 3 axis DDA exerciser.");

	bot.x.stepper.setRPM(max_speed);
	bot.setTimer(bot.x.stepper.step_delay);
	
	Serial.print("RPM: ");
	Serial.println((int)bot.x.stepper.rpm);
	Serial.print("Speed: ");
	Serial.println((int)bot.x.stepper.step_delay);

	p.x = max_x;
	p.y = max_y;
	p.z = 0;
	bot.queuePoint(p);

	p.x = 0;
	p.y = max_y;
	p.z = 0;
	bot.queuePoint(p);
	
	p.x = max_x;
	p.y = 0;
	p.z = 0;
	bot.queuePoint(p);

	p.x = 0;
	p.y = 0;
	p.z = 0;
	bot.queuePoint(p);
}

void loop()
{
	//load up teh queue
	while (!bot.isQueueFull())
	{
		p.x = random(0, max_x);
		p.y = random(0, max_y);
		p.z = 0;
		bot.queuePoint(p);
	}

	//get our state status.
	bot.readState();
	
	//if we are at our target, stop us.
	if (bot.atTarget())
	{
		//get our next point.
		bot.getNextPoint();
		bot.calculateDDA();
		bot.disableTimerInterrupt();
		
		//diagnostic data stuff.
		Serial.print("Seeking to ");
		Serial.print((int)bot.x.target);
		Serial.print(", ");
		Serial.print((int)bot.y.target);
		Serial.print(", ");
		Serial.print((int)bot.z.target);
		Serial.print(" at clock ");
		Serial.println((int)OCR1A);

		//dda diagnostics
		Serial.println("DDA info");
		Serial.print("Deltas: ");
		Serial.print((int)bot.x.delta);
		Serial.print(", ");
		Serial.print((int)bot.y.delta);
		Serial.print(", ");
		Serial.println((int)bot.z.delta);
		Serial.print("Max Delta: ");
		Serial.println((int)bot.max_delta);

		bot.enableTimerInterrupt();
	}
	
	Serial.print("Current: ");
	Serial.print(bot.x.current);
	Serial.print(" ");
	Serial.print(bot.y.current);
	Serial.print(" ");
	Serial.println(bot.z.current);
	
	Serial.print("At min: ");
	Serial.print(bot.x.atMin());
	Serial.print(" ");
	Serial.print(bot.y.atMin());
	Serial.print(" ");
	Serial.println(bot.z.atMin());

	Serial.print("At max: ");
	Serial.print(bot.x.atMax());
	Serial.print(" ");
	Serial.print(bot.y.atMax());
	Serial.print(" ");
	Serial.println(bot.z.atMax());
	
	Serial.print("At target: ");
	Serial.print(bot.x.atTarget());
	Serial.print(" ");
	Serial.print(bot.y.atTarget());
	Serial.print(" ");
	Serial.println(bot.z.atTarget());
	
	Serial.print("Can step: ");
	Serial.print(bot.x.can_step);
	Serial.print(" ");
	Serial.print(bot.y.can_step);
	Serial.print(" ");
	Serial.println(bot.z.can_step);
	delay(1000);

}
