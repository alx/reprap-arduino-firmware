#include "LinearAxis.h"
#include "WConstants.h"

LinearAxis::LinearAxis(char id, int steps, byte dir_pin, byte step_pin, byte min_pin, byte max_pin, byte enable_pin) : stepper(steps, dir_pin, step_pin, enable_pin)
{
	this->id = id;
	this->current = 0;
	this->target = 0;
	this->max = 0;
	this->min_pin = min_pin;
	this->max_pin = max_pin;

	this->stepper.setDirection(RS_FORWARD);

	this->readState();
}

void LinearAxis::readState()
{
	//stop us if we're on target
	if (this->target == this->current)
		this->can_step = false;
	//stop us if we're at home and still going 
	else if (this->atMin() && (this->stepper.direction == RS_REVERSE))
		this->can_step = false;
	//stop us if we're at max and still going
	else if (this->atMax() && (this->stepper.direction == RS_FORWARD))
		this->can_step = false;
	//default to being able to step
	else
		this->can_step = true;
}

bool LinearAxis::atMin()
{
	return digitalRead(this->min_pin);
}

/*
 * NB!!!  Turned off by Adrian to free up pins
*/
bool LinearAxis::atMax()
{
	return 0;
	//return digitalRead(this->max_pin);
}

void LinearAxis::doStep()
{
	//gotta call readState() before you can step again!
	//this->can_step = false;
	
	//record our step
	if (this->stepper.direction == RS_FORWARD)
		this->forward1();
	else
		this->reverse1();
}

void LinearAxis::forward1()
{
	stepper.setDirection(RS_FORWARD);
	stepper.pulse();
	
	this->current++;
}

void LinearAxis::reverse1()
{
	stepper.setDirection(RS_REVERSE);
	stepper.pulse();
	
	this->current--;
}

void LinearAxis::setPosition(long p)
{
	this->current = p;
	
	//recalculate stuff.
	this->setTarget(this->target);
}

void LinearAxis::setTarget(long t)
{
	this->target = t;
	
	if (this->target >= this->current)
		stepper.setDirection(RS_FORWARD);
	else
		stepper.setDirection(RS_REVERSE);
		
	this->delta = abs(this->target - this->current);
}

void LinearAxis::initDDA(long max_delta)
{
	this->counter = -max_delta/2;
}

void LinearAxis::ddaStep(long max_delta)
{
	this->counter += this->delta;

	if (this->counter > 0)
	{
		this->doStep();
		this->counter -= max_delta;
	}
}
