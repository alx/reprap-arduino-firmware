
#include "WConstants.h"
#include "AnalogEncoder.h"

AnalogEncoder::AnalogEncoder(int pin)
{
	this->pin = pin;
	this->current_position = -1;
	this->last_position = -1;
	this->direction = -1;
}

//our interface methods
void AnalogEncoder::readState()
{
	this->last_position = this->current_position;
	this->current_position = analogRead(this->pin);
	
	if (this->current_position < 16)
	{
		if (this->last_position > 768)
			this->direction = 1;
		else
			this->direction = 0;
	}
	else if (this->current_position > 1008)
	{
		if (this->last_position < 256)
			this->direction = 0;
		else
			this->direction = 1;
	}
	else
	{
		if (this->current_position > this->last_position)
			this->direction = 1;
		else
			this->direction = 0;
	}
}

int AnalogEncoder::getPosition()
{
	return this->current_position;
}

int AnalogEncoder::getDirection()
{
	return this->direction;
}

int AnalogEncoder::version()
{
	return 1;
}
