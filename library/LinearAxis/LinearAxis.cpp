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
	if (this->atTarget())
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
	return this->current <= 0;
}

bool LinearAxis::atMax()
{
	return this->current >= this->max;
}

/*
* Used for all axis, depending on stepper direction
*/
bool LinearAxis::atTarget()
{
	if (this->stepper.direction == RS_FORWARD)
		return this->current >= this->target || this->atMax();
	else
		return this->current <= this->target || this->atMin();
}

void LinearAxis::doStep()
{
	this->readState();
	if (this->can_step)
	{
		if (this->stepper.direction == RS_FORWARD)
			this->forward1();
		else
			this->reverse1();
	}
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

void LinearAxis::setMax(long v)
{
	this->max = v;
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
