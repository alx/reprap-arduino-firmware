
#include "WProgram.h"
#include "LimitSwitch.h"

LimitSwitch::LimitSwitch(int pin)
{
	this->pin = pin;
	
	pinMode(pin, INPUT);
}

bool LimitSwitch::getState()
{
	return this->state;
}

bool LimitSwitch::readState()
{
	this->state = digitalRead(pin);
	
	return this->state;
}

//random other functions
int LimitSwitch::version()
{
	return 1;
}