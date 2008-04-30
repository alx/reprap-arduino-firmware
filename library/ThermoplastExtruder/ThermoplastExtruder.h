/*
	ThermoplastExtruder.h - RepRap Thermoplastic Extruder library for Arduino

	This library is used to read, control, and handle a thermoplastic extruder.
	
	More information at: http://reprap.org/bin/view/Main/RepRapOneDarwinThermoplastExtruder

	Memory Usage Estimate: 18 bytes

	History:
	* (0.1) Created intial library by Zach Smith.
	* (0.2) Initial rework by Marius Kintel <kintel@sim.no>
	* (0.3) Updated and optimized by Zach Smith
	* (0.4) Updated with new default values for 100K thermistor.
	* (0.3) Rewrote and refactored all code by Zach Smith.
	
	
	License: GPL v2.0
*/

#ifndef THERMOPLASTEXTRUDER_H
#define THERMOPLASTEXTRUDER_H

#include "WConstants.h"

class ThermoplastExtruder
{
	public:
		ThermoplastExtruder(byte motor_dir_pin, byte motor_pwm_pin, byte heater_pin, 
		byte cooler_pin, byte thermistor_pin, byte valve_dir_pin, 
		byte valve_enable_pin);

		// various setters methods:
		void setSpeed(byte speed);
		void setDirection(bool dir);
		void setCooler(byte speed);

		//temparature control
		void setTemperature(int temp);
		int getTemperature();
		int calculateTemperatureFromRaw(int raw);
		void manageTemperature();
		
		// Open and close the valve
		void setValve(bool dir, byte pulse_time);

		//variables for easy access.
		byte heater_low;		// Low heater, for when we're at our temp, 0-255
		byte heater_high;		// High heater, for when we're below our temp, 0-255
		int target_celsius;		// Our target temperature
		int max_celsius;		// Our max temperature

	private:

		//pin numbers:
		byte motor_pwm_pin;		// motor PWM pin
		byte motor_dir_pin;		// motor direction pin
		byte valve_enable_pin;	// valve enable pin
		byte valve_dir_pin;		// valve direction pin		
		byte heater_pin;		// heater PWM pin
		byte thermistor_pin;	// thermistor analog input pin
		byte cooler_pin;		// cooler fan PWM pin

		//extruder variables
		bool motor_dir;			// Motor direction (true = forward, false = backward)
		byte motor_pwm;			// Speed in PWM, 0-255
		byte cooler_pwm;		// Fan speed in PWM, 0-255
		int current_celsius;	// Our current temperature
		int raw_temperature;	// our raw temperature reading.
};

#endif
