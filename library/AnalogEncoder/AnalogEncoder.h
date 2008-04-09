/*
  AnalogEncoder.h - RepRap Encoder library for Arduino

  This library is used to interface with an Austria Microsystems magnetic encoder in analog mode.

  History:
  * Created intiial library (0.1) by Zach Smith.

*/

// ensure this library description is only included once
#ifndef AnalogEncoder_h
#define AnalogEncoder_h

// include types & constants of Wiring core API
#include "WConstants.h"

// library interface description
class AnalogEncoder {
  public:

    // constructors:
	AnalogEncoder();
    AnalogEncoder(int pin);

	//our interface methods
	void readState();
	int getPosition();
	int getDirection();

    int version();

  private:

    int pin;					//the switch state pin.
	int current_position;		//the current position on last read.
	int last_position;			//the position before our current read.
	int direction;				//the direction the encoder is moving.
};

#endif
