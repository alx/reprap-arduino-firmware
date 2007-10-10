/*
  LimitSwitch.h - RepRap Limit Switch library for Arduino - Version 0.1

  This library is used to interface with a reprap optical limit switch.

  History:
  * Created intiial library (0.1) by Zach Smith.

*/

// ensure this library description is only included once
#ifndef CartesianBot_h
#define CartesianBot_h

#define POINT_QUEUE_SIZE 64

// include types & constants of Wiring core API
#include "WConstants.h"
#include "RepStepper.h"

// our point structure to make things nice.
struct Point {
	int x;
	int y;
	int z;
};

// library interface description
class CartesianBot {
  public:

    // constructors:
    CartesianBot();

	// add various physical hardware options
	void addStepper(char axis, int steps, int dir_pin, int step_pin);
	void addEncoder(char axis, int encoder_pin);
	void addHomeSwitch(char axis, int switch_pin);
	
	//info on if we have axes or not.
	bool hasStepper(char axis);
	bool hasEncoder(char axis);
	bool hasHomeSwitch(char axis);
	
	// add in various points
	bool queuePoint(Point &point);
	void clearQueue();
	void setTargetPoint(Point &point);

	//our interface methods
	bool readState();
	void move();
	void abort();
	
	//boring version stuff
    int version();

	//our variables
	RepStepper x_stepper;
	RepStepper y_stepper;
	RepStepper z_stepper;

	//our limit switches!
	LimitSwitch x_home;
	LimitSwitch y_home;
	LimitSwitch z_home;

	//our encoders!
	Encoder x_encoder;
	Encoder y_encoder;
	Encoder z_encoder;

  private:
	
	bool atPoint(Point &point);
	struct Point unqueuePoint();
		

	//this is for tracking to a point.
	byte point_index = 0;
	Point point_queue[POINT_QUEUE_SIZE];
	Point target_point;
	Point current_position;
};

#endif
