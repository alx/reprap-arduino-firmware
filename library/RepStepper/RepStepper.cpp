
#include "RepStepper.h"

/*
 * two-wire constructor.
 * Sets which wires should control the motor.
 */
RepStepper::RepStepper(int number_of_steps, byte dir_pin, byte step_pin, byte enable_pin)
{
	//init our variables.
	this->setSpeed(0);

	//get our parameters
	this->number_of_steps = number_of_steps;
	this->step_pin = step_pin;
	this->direction_pin = dir_pin;
	this->enable_pin = enable_pin;
	
	// setup the pins on the microcontroller:
	pinMode(this->step_pin, OUTPUT);
	pinMode(this->direction_pin, OUTPUT);
	this->enable();
	this->setDirection(RS_FORWARD);
}

/*
  Sets the speed in ticks per step
*/
void RepStepper::setSpeed(long speed)
{
	step_delay = speed;
	
	if (step_delay > 0)
		rpm = 960000000UL / (step_delay * number_of_steps);
	else
		rpm = 0;
}

/*
  Sets the speed in revs per minute
*/
void RepStepper::setRPM(int new_rpm)
{
	if (new_rpm == 0)
	{
		step_delay = 0;
		rpm = 0;
	}
	else
	{
		rpm = new_rpm;
		
		//lets use the highest precision possible... processor ticks.
		// 16MHZ = 16,000,000 ticks/sec * 60 seconds in a minute = 960,000,000 ticks / minute
		// take the total # of ticks / steps per rev / number of revolutions per minute = ticks per step
		step_delay = (960000000UL / number_of_steps) / rpm;
	}
}

void RepStepper::setSteps(int steps)
{
	number_of_steps = steps;
	
	//recalculate our speed.
	this->setRPM(this->rpm);
}

void RepStepper::setDirection(bool direction)
{
	digitalWrite(this->direction_pin, direction);
	delayMicroseconds(10); //make sure it stabilizes..
	this->direction = direction; //save our direction.
}

int RepStepper::getMicros()
{
	return step_delay / 16;
}

void RepStepper::enable()
{
	if (this->enable_pin != 255)
	{
		digitalWrite(enable_pin, HIGH);
		delayMicroseconds(10); //make sure it stabilizes
	}

	enabled = true;
}

void RepStepper::disable()
{
	if (this->enable_pin != 255)
	{
		digitalWrite(this->enable_pin, LOW);
		delayMicroseconds(10); //make sure it stabilizes
	}

	enabled = false;
}

//this sends a pulse to our stepper controller.
void RepStepper::pulse()
{
	digitalWrite(this->step_pin, HIGH);
	delayMicroseconds(5); //make sure it stabilizes... for opto isolated stepper drivers.
	digitalWrite(this->step_pin, LOW);
}
