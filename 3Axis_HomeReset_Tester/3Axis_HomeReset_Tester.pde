/*
	3Axis_HomeReset_Tester.pde - RepRap cartesian bot home/reset tester.

	History:
	* (0.1) Created initial version by Zach Smith.
	* (0.2) Updated to work with new optimizations by Zach Smith.
	
	License: GPL v2.0
*/

#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>

/********************************
 * digital i/o pin assignment
 ********************************/
#define X_STEP_PIN 2
#define X_DIR_PIN 3
#define X_MIN_PIN 4
#define X_MAX_PIN 5
#define X_ENABLE_PIN 14
#define Y_STEP_PIN 6
#define Y_DIR_PIN 7
#define Y_MIN_PIN 8
#define Y_MAX_PIN 9
#define Y_ENABLE_PIN 15
#define Z_STEP_PIN 10
#define Z_DIR_PIN 11
#define Z_MIN_PIN 12
#define Z_MAX_PIN 13
#define Z_ENABLE_PIN 16

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

int speed = 255;

enum functions {
	func_idle,
	func_forward,
	func_reverse,
	func_syncwait,   // Waiting for sync prior to seeking
	func_seek,
	func_findmin,    // Calibration, finding minimum
	func_findmax,    // Calibration, finding maximum
	func_ddamaster,
	func_homereset   // Move to min position and reset
};

byte x_notify = 0;
byte y_notify = 0;
byte z_notify = 0;

byte x_function;
byte y_function;
byte z_function;

#define X_ADDRESS 2
#define Y_ADDRESS 3
#define Z_ADDRESS 4

SIGNAL(SIG_OUTPUT_COMPARE1A)
{
	bot.readState();

	if (x_function == func_homereset)
	{
		if (!bot.x.atMin())
			bot.x.stepper.pulse();
		else
		{
			bot.x.setPosition(0);
			x_function = func_idle;
			
			if (x_notify != 255)
				notifyTargetReached(x_notify, X_ADDRESS);
		}
	}

	if (y_function == func_homereset)
	{
		if (!bot.y.atMin())
			bot.y.stepper.pulse();
		else
		{
			bot.y.setPosition(0);
			y_function = func_idle;
			
			if (y_notify != 255)
				notifyTargetReached(y_notify, Y_ADDRESS);	
		}
	}

	if (z_function == func_homereset)
	{
		if (!bot.z.atMin())
			bot.z.stepper.pulse();
		else
		{
			bot.z.setPosition(0);
			z_function = func_idle;

			if (z_notify != 255)
				notifyTargetReached(z_notify, Z_ADDRESS);
		}
	}
}
	
void setup()
{
	bot.setupTimerInterrupt();

	Serial.begin(57600);
	Serial.println("Starting 3 axis home reset exerciser.");

	//set our speed.
	bot.x.stepper.setRPM(speed);
	bot.setTimer(bot.x.stepper.step_delay);

	//debug info.
	Serial.print("RPM: ");
	Serial.println((int)bot.x.stepper.rpm);
	Serial.print("Speed: ");
	Serial.println(bot.x.stepper.step_delay);
	
	//tell all axes to go home.
	x_function = func_homereset;
	y_function = func_homereset;
	z_function = func_homereset;

	//start the homereset deal.
	bot.enableTimerInterrupt();
}

void loop()
{
	//update our switches.
	bot.readState();
	
	Serial.println("Sensors:");
	Serial.print("X Min: ");
	Serial.println(bot.x.atMin());
	Serial.print("X Max: ");
	Serial.println(bot.x.atMax());
	Serial.print("Y Min: ");
	Serial.println(bot.y.atMin());
	Serial.print("Y Max: ");
	Serial.println(bot.y.atMax());
	Serial.print("Z Min: ");
	Serial.println(bot.z.atMin());
	Serial.print("Z Max: ");
	Serial.println(bot.z.atMax());
	Serial.println(" ");
	
	delay(2000);
}

void notifyTargetReached(byte to, byte from)
{
	Serial.print(to, DEC);
	Serial.print(", ");
	Serial.print(from, DEC);
	Serial.println(" is at home");
}
