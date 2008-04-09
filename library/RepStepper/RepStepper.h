/*
	RepStepper.h - RepRap Stepper library for Arduino

	This library interfaces with the RepRap Stepper Motor Driver and other standard stepper controllers
	that use the 2 wire Step/Direction interface.  Loosely based on the Stepper library by Tom Igoe & others: http://www.arduino.cc/en/Reference/Stepper
		
	More information on the stepper driver circuit here: http://make.rrrf.org/smd

	Memory Usage Estimate: 13 bytes

	History:
	
	* (0.1) Forked library by Zach Smith.
	* (0.2) Optimizations to reduce code overhead by Zach Smith
	* (0.3) Added delays for optocoupled driver boards as well as variables to record enable/direction status.
	* (0.4) Rewrote and refactored all code.  Fixed major interrupt bug by Zach Smith.
	
	License: GPL v2.0
*/

// ensure this library description is only included once
#ifndef RepStepper_h
#define RepStepper_h

#include "WConstants.h"

#define RS_FORWARD 1
#define RS_REVERSE 0

// library interface description
class RepStepper {
  public:
    // constructors:
    RepStepper(int number_of_steps, byte dir_pin, byte step_pin, byte enable_pin);

    // various setters methods
	void setRPM(int rpm);
    void setSpeed(long speed);
	void setDirection(bool direction);
	void setSteps(int steps);
	
	int getMicros();
	
    //various methods dealing with stepping.
	void pulse();
	void enable();
	void disable();
	
	//various internal variables: READ ONLY!  Do not set these directly.
	int rpm;					// Speed in RPMs
	long step_delay;  			// delay between steps, in processor ticks, based on speed
    int number_of_steps;		// total number of steps this motor can take
	bool enabled;				//are we enabled?
	bool direction;				//what is our direction?
	
	// motor pin numbers:
    byte step_pin;				//the step signal pin.

  private:


    byte direction_pin;			//the direction pin.
    byte enable_pin;			//the enable pin.
};

#endif
