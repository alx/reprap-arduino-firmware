
#include "WProgram.h"
#include "ThermoplastExtruder.h"

ThermoplastExtruder::ThermoplastExtruder(int motor_dir_pin, int motor_speed_pin, int heater_pin, int thermistor_pin)
{
	this->motor_dir_pin = motor_dir_pin;
    this->motor_speed_pin = motor_speed_pin;
	this->heater_pin = heater_pin;
    this->thermistor_pin = thermistor_pin;

	pinMode(this->motor_dir_pin, OUTPUT);
	pinMode(this->motor_speed_pin, OUTPUT);
	pinMode(this->heater_pin, OUTPUT);
	
	this->getTemp();
	this->setDirection(1);
	this->setSpeed(0);
	this->setTargetTemp(0);
}

void ThermoplastExtruder::setSpeed(byte whatSpeed)
{
	this->speed = whatSpeed;
	analogWrite(this->motor_speed_pin, this->speed);
}

void ThermoplastExtruder::setDirection(bool direction)
{
	this->direction = direction;
	digitalWrite(this->motor_dir_pin, this->direction);
}

void ThermoplastExtruder::setTargetTemp(int target)
{
	this->target_temp = target;
}

byte ThermoplastExtruder::getSpeed()
{
	return this->speed;
}

bool ThermoplastExtruder::getDirection()
{
	return this->direction;
}

int ThermoplastExtruder::getTemp()
{
	this->current_temp = analogRead(this->thermistor_pin);
	
	return this->current_temp;
}

int ThermoplastExtruder::getTargetTemp()
{
	return this->target_temp;
}

void ThermoplastExtruder::manageTemp()
{
	this->calculateHeaterPWM();
	analogWrite(this->heater_pin, this->heater_pwm);
}

void ThermoplastExtruder::calculateHeaterPWM()
{
	this->getTemp();

	if (this->current_temp < this->target_temp)
		this->heater_pwm = 255;
	else
		this->heater_pwm = 255;
}

int ThermoplastExtruder::version()
{
	return 1;
}
