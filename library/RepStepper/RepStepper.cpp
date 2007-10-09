
#include "WProgram.h"
#include "RepStepper.h"

/*
 * two-wire constructor.
 * Sets which wires should control the motor.
 */
RepStepper::RepStepper(int number_of_steps, int step_pin, int direction_pin)
{
	//init our variables.
	this->direction = 1;
	this->speed = 0;
	this->step_delay = 0;
	this->current_step = 0;
	this->target_step = 0;
	this->last_step_time = 0;

	//get our parameters
	this->number_of_steps = number_of_steps;
	this->step_pin = step_pin;
	this->direction_pin = direction_pin;
	
	// setup the pins on the microcontroller:
	pinMode(this->step_pin, OUTPUT);
	pinMode(this->direction_pin, OUTPUT);
}

/*
  Sets the speed in revs per minute

*/
void RepStepper::setSpeed(byte whatSpeed)
{
	this->speed = whatSpeed;

	if (this->speed > 0)
		this->step_delay = 60L * 1000L / this->number_of_steps / this->speed;
	else
		this->step_delay = 100000;
}

void RepStepper::setTarget(int steps)
{
	if (steps < 0)
		this->setDirection(RS_REVERSE);
	else
		this->setDirection(RS_FORWARD);
		
	this->current_step = 0;
	this->target_step = abs(steps);
}

void RepStepper::setDirection(bool direction)
{
	this->direction = direction;
	digitalWrite(this->direction_pin, this->direction);
}

void RepStepper::step()
{  
	if (this->canStep())
	{
		this->pulse();
		this->current_step++;		
	}
}

bool RepStepper::canStep()
{
	int now = millis();
	
	if (this->current_step < this->target_step && now > last_step_time + step_delay)
		return true;
	
	return false;
}

void RepStepper::pulse()
{
	digitalWrite(this->step_pin, HIGH);
	delayMicroseconds(2);
	digitalWrite(this->step_pin, LOW);
}

/*
* returns the version of the library:
*/
int RepStepper::version(void)
{
  return 1;
}
