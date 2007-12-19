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

unsigned int rpm = 1;
unsigned int speed = 50;
unsigned int timer = 0;

SIGNAL(SIG_OUTPUT_COMPARE1A)
{
	bot.x.stepper.pulse();
	bot.y.stepper.pulse();
	bot.z.stepper.pulse();
}

void setup()
{
    bot.setupTimerInterrupt();
	
    Serial.begin(57600);
    Serial.println("Starting timer tester.");
    
    for (int i=1; i<500; i++)
    {
	    bot.enableTimerInterrupt();
		bot.x.stepper.setRPM(i);
		bot.setTimer(bot.x.stepper.getSpeed());

		Serial.print("RPM: ");
		Serial.println(bot.x.stepper.getRPM(), DEC);
		Serial.print("Speed: ");
		Serial.println(bot.x.stepper.getSpeed(), DEC);
		Serial.print("Resolution: ");
		Serial.println(bot.getTimerResolution(bot.x.stepper.getSpeed()), DEC);
		Serial.print("OCR1A: ");
		Serial.println(OCR1A, DEC);
		Serial.println(" ");

		delay(5000);
		bot.disableTimerInterrupt();
		delay(500);
    }
}

void loop()
{
  
}
