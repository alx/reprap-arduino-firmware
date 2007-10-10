/*
  ThermoplastExtruder.h - RepRap Thermoplastic Extruder library for Arduino - Version 0.1

  This library is used to read, control, and handle a thermoplastic extruder.

  History:
  * Created intiial library (0.1) by Zach Smith.

*/

// ensure this library description is only included once
#ifndef ThermoplastExtruder_h
#define ThermoplastExtruder_h

// include types & constants of Wiring core API
#include "WConstants.h"

// library interface description
class ThermoplastExtruder {
  public:
    // constructors:
    ThermoplastExtruder(int motor_dir_pin, int motor_speed_pin, int heater_pin, int thermistor_pin);

    // various setters methods:
    void setSpeed(byte whatSpeed);
	void setDirection(bool direction);
	void setTargetTemp(int target);

	//get various info things.
	byte getSpeed();
	bool getDirection();
	int getTemp();
	int getTargetTemp();
	
	//manage the extruder
	void manageTemp();

	//random other functions
    int version();

  private:

	void calculateHeaterPWM();

    //pin numbers:
    int motor_dir_pin;			//the step signal pin.
    int motor_speed_pin;		//the direction pin.
    int heater_pin;				//the direction pin.
    int thermistor_pin;			//the direction pin.

	//extruder variables
    bool direction;				// Direction of rotation, 1=forward, 0=reverse
    byte speed;					// Speed in PWM, 0-255
	byte heater_pwm;			// Heater PWM, 0-255
	int target_temp;			// Our target temperature, 0-1024
	int current_temp;			// Our current temperature, 0-1024
};

#endif
