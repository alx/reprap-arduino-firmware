/*
	LinearAxis.h - RepRap Linear Axis library for Arduino

	The interface for controlling a linear axis: stepper motor + min/max sensors + optional encoder

	Memory Usage Estimate: 25 + repstepper usage.

	History:
	* (0.1) Created library by Zach Smith.
	* (0.2) Optimized for less memory usage and faster performance
	* (0.3) Rewrote and refactored all code.  Fixed major interrupt bug by Zach Smith.

	License: GPL v2.0
*/

// ensure this library description is only included once
#ifndef LinearAxis_h
#define LinearAxis_h

#include <RepStepper.h>

// library interface description
class LinearAxis {
  public:
    
	// constructors:
    LinearAxis(char id, int steps, byte dir_pin, byte step_pin, byte min_pin, byte max_pin, byte enable_pin);

	//these are our other object variables.
	RepStepper stepper;

	//various guys to interface with class
	void readState();
	void doStep();
	bool atMin();
	bool atMax();
	bool atTarget();
	
	//various position things.
	void setPosition(long position);
	void setTarget(long t);
	void setMax(long v);
	void forward1();
	void reverse1();
	
	//dda functions
	void initDDA(long max_delta);
	void ddaStep(long max_delta);

	char id;					//what is our id? x, y, z, etc.
	bool can_step;				//are we capable of taking a step yet?

	long delta;					//our delta for our DDA moves.
	long current;				//this is our current position.
	long target;				//this is our target position.
	long max;					//this is our max coordinate.
	long counter;				//this is our counter variable for dda.

  private:
	
	byte min_pin;
	byte max_pin;
};

#endif
