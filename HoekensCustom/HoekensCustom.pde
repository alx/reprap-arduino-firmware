/******************
* Get our libraries
******************/

#include <LimitSwitch.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>
#include <ThermoplastExtruder.h>

//the version of our software
#define VERSION 1

/********************************
* digital i/o pin assignment
********************************/
#define X_MIN_PIN 2
#define Y_MIN_PIN 3
#define Z_MIN_PIN 4
#define EXTRUDER_MOTOR_SPEED_PIN 5
#define EXTRUDER_HEATER_PIN 6
#define EXTRUDER_MOTOR_DIR_PIN 7
#define X_DIR_PIN 8
#define X_STEP_PIN 9
#define Y_DIR_PIN 10
#define Y_STEP_PIN 11
#define Z_DIR_PIN 12
#define Z_STEP_PIN 13

/********************************
* unused digital pins...
********************************/
#define X_MAX_PIN -1
#define Y_MAX_PIN -1
#define Z_MAX_PIN -1

/********************************
* analog input pin assignments
********************************/
#define EXTRUDER_THERMISTOR_PIN 0
#define X_ENCODER_PIN 1
#define Y_ENCODER_PIN 2
#define Z_ENCODER_PIN 3
#define EXTRUDER_MOTOR_ENCODER_PIN 4

/********************************
* how many steps do our motors have?
********************************/
#define X_MOTOR_STEPS 200
#define Y_MOTOR_STEPS 200
#define Z_MOTOR_STEPS 200

/********************************
* command declarations
********************************/

// generic version command
#define CMD_VERSION   				0  // asks us for our version #
#define CMD_GET_ALL_STATUS			1 // asks us for our global status

//cartesian bot specific commands
#define CMD_QUEUE_POINT				51  // asks us to queue a point up
#define CMD_CLEAR_QUEUE				52  // asks us to clear our queue
#define CMD_GET_QUEUE				53  // asks us to report our queue
#define CMD_SET_POS					54  // asks us to set our position to this point
#define CMD_GET_POS					55  // asks us to tell our position
#define CMD_SEEK					56  // asks us to go into seek mode (move to points)
#define CMD_PAUSE					57  // asks us to pause operation (pause seeking, extruding)
#define CMD_ABORT					58  // asks us to abort printing operations (stop all operations, go home)
#define CMD_HOME					59  // asks us to go home and reset (just go home)
#define CMD_SET_RPM					60 // asks us to set the speed for a specific axis
#define CMD_GET_RPM					61 // asks us to get the speed of a specific axis
#define CMD_SET_SPEED				62 // asks us to set the speed of a specific axis (in microseconds between steps)
#define CMD_GET_SPEED				63 // asks us to set the speed of a specific axis (in microseconds between steps)
#define CMD_GET_LIMIT_STATUS		64 // asks for our limit switch status
#define CMD_SET_STEPS				65 // sets the number of steps per revoltion for a specific axis
#define CMD_GET_STEPS				66 // gets the number of steps per revoltion for a specific axis

// extruder specific commands
#define CMD_SET_TEMP					100 // asks us to set our temp target (pre conversion ADC)
#define CMD_GET_TEMP					101 // asks us for our current temperature (pre conversion ADC)
#define CMD_EXTRUDER_SET_DIRECTION		102 // asks us to set our extruder's direction
#define CMD_EXTRUDER_GET_DIRECTION		103 // asks us to get our extruder's direction
#define CMD_EXTRUDER_SET_SPEED			104 // asks us to set our extruder's speed
#define CMD_EXTRUDER_GET_SPEED			105 // asks us to get our extruder's speed
#define CMD_EXTRUDER_GET_TARGET_TEMP	106 // asks us for our target temperature (pre conversion ADC)

// our true/false values
#define CMD_REPLY_NAK 0
#define CMD_REPLY_ACK 1

/********************************
*  Global variable declarations
********************************/

//our main objects
CartesianBot bot(
  X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN,
  Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN,
  Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN
);
ThermoplastExtruder extruder(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_MOTOR_SPEED_PIN, EXTRUDER_HEATER_PIN, EXTRUDER_THERMISTOR_PIN);

void setup()
{
	//fire up our serial comms.
	Serial.begin(19200);
	Serial.println("RepDuino v1.0 started up.");
}

void loop()
{
	readState();
	receiveCommands();
	executeCommands();
}

void readState()
{
	extruder.readState();
	bot.readState();
}

void receiveCommands()
{
	int command;
	
	while (Serial.available() > 1)
	{
		command = Serial.read();
		
		//start our reply.
		beginReply(command);
		
		//did we get a valid command?
		if (cmd >= 0)
		{
			//these are basically just global commands
			if (cmd == CMD_VERSION)
				cmd_version();
			else if (cmd == CMD_GET_ALL_STATUS)
				cmd_get_all_status();
			//these are for our cartesian bot.
			else if (cmd == CMD_QUEUE_POINT)
				cmd_queue_point();
			else if (cmd == CMD_CLEAR_QUEUE)
				cmd_clear_queue();
			else if (cmd == CMD_GET_QUEUE)
				cmd_get_queue();
			else if (cmd == CMD_SET_POS)
				cmd_set_pos();
			else if (cmd == CMD_GET_POS)
				cmd_get_pos();
			else if (cmd == CMD_SEEK)
				cmd_seek();
			else if (cmd == CMD_PAUSE)
				cmd_pause();
			else if (cmd == CMD_ABORT)
				cmd_abort();
			else if (cmd == CMD_HOME)
				cmd_home();
			else if (cmd == CMD_SET_RPM)
				cmd_set_rpm();
			else if (cmd == CMD_GET_RPM)
				cmd_get_rpm();
			else if (cmd == CMD_SET_SPEED)
				cmd_set_speed();
			else if (cmd == CMD_GET_SPEED)
				cmd_get_speed();
			else if (cmd == CMD_GET_LIMIT_STATUS)
				cmd_get_limit_status();
			else if (cmd == CMD_SET_STEPS)
				cmd_set_steps();
			else if (cmd == CMD_GET_STEPS)
				cmd_get_steps();
			//okay, these are for our extruder.
			else if (cmd == CMD_SET_TEMP)
				cmd_set_temp();
			else if (cmd == CMD_GET_TEMP)
				cmd_get_temp();
			else if (cmd == CMD_EXTRUDER_SET_DIRECTION)
				cmd_extruder_set_direction();
			else if (cmd == CMD_EXTRUDER_GET_DIRECTION)
				cmd_extruder_get_direction();
			else if (cmd == CMD_EXTRUDER_SET_SPEED)
				cmd_extruder_set_speed();
			else if (cmd == CMD_EXTRUDER_GET_SPEED)
				cmd_extruder_get_speed();
			else if (cmd == CMD_EXTRUDER_GET_TARGET_TEMP)
				cmd_extruder_get_target_temp();
			//we didnt get any valid commands???
			else
				nak();
		}
		
		endReply();
	}
}

void executeCommands()
{
	extruder.manageTemp();
	bot.move();
}

/**********************************************
*  These are our command handling functions. 
**********************************************/

void cmd_version()
{
	Serial.print(VERSION);
	ack();
}

void cmd_get_all_status()
{
/*	
	//our analog readings.
	Serial.print("T:");
	Serial.print(thermistor_reading);
	Serial.print('Xe:');
	Serial.print(x_encoder_reading);
	Serial.print('Ye:');
	Serial.print(y_encoder_reading);
	Serial.print('Ze:');
	Serial.print(z_encoder_reading);
	Serial.print('Ee:');
	Serial.print(extruder_motor_encoder_reading);

	//our current position and such
	Serial.print('Xp:');
	Serial.print(x_position);
	Serial.print('Yp:');
	Serial.print(y_position);
	Serial.print('Zp:');
	Serial.print(z_position);

	//are we at our limit?
	Serial.print('Xmin:');
	Serial.print(x_at_home);
	Serial.print('Ymin:');
	Serial.print(y_at_home);
	Serial.print('Zmin:');
	Serial.print(z_at_home);

	//what direction?
	Serial.print('Xdir:');
	Serial.print(x_direction);
	Serial.print('Ydir:');
	Serial.print(y_direction);
	Serial.print('Zdir:');
	Serial.print(z_direction);

	//what about our extruder?
	Serial.print('Edir:');
	Serial.print(extruder_direction);
	Serial.print('Espeed:');
	Serial.print(extruder_speed);
	Serial.print('Heater:');
	Serial.print(extruder_heater_pwm);
	Serial.print();
*/	
	ack();
}

void cmd_queue_point()
{
	Point point;
	
	point.x = readInt();
	point.y = readInt();
	point.z = readInt();
	
	if (bot.queuePoint(point))
		ack();
	else
		nak();
}

void cmd_clear_queue()
{
	bot.clearQueue();
	ack();
}

void cmd_get_queue()
{
	bot.printQueue();
	ack();
}

void cmd_set_pos()
{
	bot.current_position.x = readInt();
	bot.current_position.y = readInt();
	bot.current_position.z = readInt();
}

void cmd_get_pos()
{
	Serial.print(bot.current_position.x);
	Serial.print(bot.current_position.y);
	Serial.print(bot.current_position.z);
}

void cmd_seek()
{
	bot.start();
	ack();
}

void cmd_pause()
{
	bot.stop();
	ack();
}

void cmd_abort()
{
	extruder.abort();
	extruder.abort();
	ack();
}

void cmd_home()
{
	bot.home();
	ack();
}

void cmd_set_rpm()
{
	char axis = Serial.read();
	byte speed = Serial.read();
	
	if (axis == 'a')
	{
		bot.x.setRPM(speed);
		bot.y.setRPM(speed);
		bot.z.setRPM(speed);					
	}
	else if (axis == 'x')
		bot.x.setRPM(speed);
	else if (axis == 'y')
		bot.y.setRPM(speed);
	else if (axis == 'z')
		bot.z.setRPM(speed);

	ack();
}

void cmd_get_rpm()
{
	char axis = Serial.read();
	
	if (axis == 'a')
	{
		Serial.print(bot.x.getRPM());
		Serial.print(bot.y.getRPM());
		Serial.print(bot.z.getRPM());					
	}
	if (axis == 'x')
		Serial.print(bot.x.getRPM());
	else if (axis == 'y')
		Serial.print(bot.y.getRPM());
	else if (axis == 'z')
		Serial.print(bot.z.getRPM());

	ack();
}

void cmd_set_speed()
{
	char axis = Serial.read();
	int speed = readInt();
	
	if (axis == 'a')
	{
		bot.x.setSpeed(speed);
		bot.y.setSpeed(speed);
		bot.z.setSpeed(speed);					
	}
	else if (axis == 'x')
		bot.x.setSpeed(speed);
	else if (axis == 'y')
		bot.y.setSpeed(speed);
	else if (axis == 'z')
		bot.z.setSpeed(speed);

	ack();
}

void cmd_get_speed()
{
	char axis = Serial.read();

	if (axis == 'a')
	{
		Serial.print(bot.x.getSpeed());
		Serial.print(bot.y.getSpeed());
		Serial.print(bot.z.getSpeed());					
	}
	if (axis == 'x')
		Serial.print(bot.x.getSpeed());
	else if (axis == 'y')
		Serial.print(bot.y.getSpeed());
	else if (axis == 'z')
		Serial.print(bot.z.getSpeed());
	
	ack();
}

void cmd_get_limit_status()
{
	char axis = Serial.read();

	if (axis == 'a')
	{
		Serial.print(bot.x.min.getState());
		Serial.print(bot.x.max.getState());
		Serial.print(bot.y.min.getState());
		Serial.print(bot.y.max.getState());
		Serial.print(bot.z.min.getState());
		Serial.print(bot.z.max.getState());
	}
	if (axis == 'x')
	{
		Serial.print(bot.x.min.getState());
		Serial.print(bot.x.max.getState());
	}
	else if (axis == 'y')
	{
		Serial.print(bot.y.min.getState());
		Serial.print(bot.y.max.getState());
	}
	else if (axis == 'z')
	{
		Serial.print(bot.z.min.getState());
		Serial.print(bot.z.max.getState());
	}
	
	ack();
}

void cmd_set_steps()
{
	char axis = Serial.read();
	int steps = readInt();
	
	if (axis == 'a')
	{
		bot.x.setSteps(steps);
		bot.y.setSteps(steps);
		bot.z.setSteps(steps);					
	}
	else if (axis == 'x')
		bot.x.setSteps(steps);
	else if (axis == 'y')
		bot.y.setSteps(steps);
	else if (axis == 'z')
		bot.z.setSteps(steps);
		
	ack();
}

void cmd_get_steps()
{
	char axis = Serial.read();

	if (axis == 'a')
	{
		Serial.print(bot.x.getSteps());
		Serial.print(bot.y.getSteps());
		Serial.print(bot.z.getSteps());					
	}
	if (axis == 'x')
		Serial.print(bot.x.getSteps());
	else if (axis == 'y')
		Serial.print(bot.y.getSteps());
	else if (axis == 'z')
		Serial.print(bot.z.getSteps());

	ack();
}

void cmd_set_temp()
{
	extruder.setTargetTemp(readInt());
	ack();
}

void cmd_get_temp()
{
	Serial.print(extruder.getTemp());
	ack();
}

void cmd_extruder_set_direction()
{
	extruder.setDirection(Serial.read());
	ack();
}

void cmd_extruder_get_direction()
{
	Serial.print(extruder.getDirection());
	ack();
}

void cmd_extruder_set_speed()
{
	extruder.setSpeed(Serial.read());
	ack();
}

void cmd_extruder_get_speed()
{
	Serial.print(extruder.getSpeed());
	ack();
}

void cmd_extruder_get_target_temp()
{
	Serial.print(extruder.getTargetTemp());
	ack();
}

/*******************************************
* Serial comms helper functions.
*******************************************/

int readInt()
{
	int tmp;

	//read in an integer.
	tmp = Serial.read();
	tmp = tmp << 8;
	tmp |= Serial.read();
	
	return tmp;
}

void ack()
{
	Serial.print(CMD_REPLY_ACK);
}

void nak()
{
	Serial.print(CMD_REPLY_NAK);
}
