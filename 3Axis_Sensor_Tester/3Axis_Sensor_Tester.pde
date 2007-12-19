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
                 'x', X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN, X_ENABLE_PIN,
                 'y', Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN, Y_ENABLE_PIN,
                 'z', Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN, Z_ENABLE_PIN
                 );
Point p;
	
void setup()
{
	Serial.begin(57600);
	Serial.println("Starting 3 axis sensor tester.");
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
	
	delay(1000);
}
