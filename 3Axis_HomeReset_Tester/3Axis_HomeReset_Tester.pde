/*
  3Axis_SNAP.pde - RepRap cartesian firmware for Arduino

  History:
  * Created initial version (0.1) by Zach Smith.
  * Rewrite (0.2) by Marius Kintel <kintel@sim.no> and Philipp Tiefenbacher <wizards23@gmail.com>

  */
#include <SNAP.h>
#include <LimitSwitch.h>
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
                 'x', X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN,
                 'y', Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN,
                 'z', Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN
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

#define X_ADDRESS 2
#define Y_ADDRESS 3
#define Z_ADDRESS 4

SIGNAL(SIG_OUTPUT_COMPARE1A)
{
	if (bot.mode == MODE_HOMERESET)
	{
		bot.readState();

		if (bot.x.function == func_homereset)
		{
			if (!bot.x.atMin())
				bot.x.stepper.pulse();
			else
			{
				bot.x.setPosition(0);
				bot.x.function = func_idle;
				
				if (x_notify != 255)
					notifyTargetReached(x_notify, X_ADDRESS);
			}
		}

		if (bot.y.function == func_homereset)
		{
			if (!bot.y.atMin())
				bot.y.stepper.pulse();
			else
			{
				bot.y.setPosition(0);
				bot.y.function = func_idle;
				
				if (y_notify != 255)
					notifyTargetReached(y_notify, Y_ADDRESS);	
			}
		}

		if (bot.z.function == func_homereset)
		{
			if (!bot.z.atMin())
				bot.z.stepper.pulse();
			else
			{
				bot.z.setPosition(0);
				bot.z.function = func_idle;

				if (z_notify != 255)
					notifyTargetReached(z_notify, Z_ADDRESS);
			}
		}
	}
}
	
void setup()
{
	Serial.begin(57600);
	Serial.println("Starting 3 axis home reset exerciser.");

	//set our speed.
	bot.x.stepper.setRPM(speed);
	bot.setTimer(bot.x.stepper.getSpeed());

	//debug info.
	Serial.print("RPM: ");
	Serial.println(bot.x.stepper.getRPM());
	Serial.print("Speed: ");
	Serial.println(bot.x.stepper.getSpeed());
	
	//tell all axes to go home.
	bot.x.function = func_homereset;
	bot.y.function = func_homereset;
	bot.z.function = func_homereset;

	//start the homereset deal.
	bot.startHomeReset();
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
