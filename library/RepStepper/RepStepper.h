/*
  RepStepper.h - RepRap Stepper library for Arduino - Version 0.1
  
  Based on Stepper library by Tom Igoe & others: http://www.arduino.cc/en/Reference/Stepper

  History:
  * Forked library (0.1) by Zach Smith.

  Drives a bipolar stepper motor using 2 wires: Step and Direction.
*/

// ensure this library description is only included once
#ifndef RepStepper_h
#define RepStepper_h

#define RS_FORWARD 1
#define RS_REVERSE 0

// include types & constants of Wiring core API
#include "WConstants.h"

// library interface description
class RepStepper {
  public:
    // constructors:
    RepStepper(int number_of_steps, int step_pin, int dir_pin);

    // various setters methods:
    void setSpeed(byte whatSpeed);
	void setTarget(int target);
	void setDirection(bool direction);
	
    // mover method:
    void step();

	// info stuff
	bool canStep();

	//random other functions
    int version();

  private:
    void pulse();
    
	//various internal variables
    bool direction;				// Direction of rotation
    byte speed;		// Speed in RPMs
    int step_delay;   			// delay between steps, in microseconds, based on speed
    int number_of_steps;		// total number of steps this motor can take
    int current_step;			// which step the motor is on
	int target_step;			//the target position
	
    // motor pin numbers:
    int step_pin;				//the step signal pin.
    int direction_pin;			//the direction pin.
    
    int last_step_time;			// time stamp in ms of when the last step was taken
};

#endif
