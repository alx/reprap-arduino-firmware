/*
  LimitSwitch.h - RepRap Limit Switch library for Arduino - Version 0.1

  This library is used to interface with a reprap optical limit switch.

  History:
  * Created intiial library (0.1) by Zach Smith.

*/

// ensure this library description is only included once
#ifndef LimitSwitch_h
#define LimitSwitch_h

// include types & constants of Wiring core API
#include "WConstants.h"

// library interface description
class LimitSwitch {
  public:

    // constructors:
    LimitSwitch(int pin);

	//our interface methods
	bool getState();
	bool readState();

    int version();

  private:

    int pin;		//the step signal pin.
    bool state;		//the step signal pin.
};

#endif
