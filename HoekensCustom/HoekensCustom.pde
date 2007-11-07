
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
#define MY_ADDRESS 1
#define HOST_ADDRESS 0

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
#define CMD_REPLY					2  // this is our ack/nack reply

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

PackIt pkt();

void setup()
{
	//fire up our serial comms.
	Serial.begin(19200);
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
	int cmd;
	bool ret = false;
	
	while (Serial.available() > 1)
	{
		cmd = Serial.read();
		
		//start our reply
		pkt.clear();
		pkt.add(cmd);

		//did we get a valid command?
		if (cmd >= 0)
		{
			//these are basically just global commands
			if (cmd == CMD_VERSION)
				ret = cmd_version();
			
			//these are for our cartesian bot.
			else if (cmd == CMD_QUEUE_POINT)
				ret = cmd_queue_point();
				
			else if (cmd == CMD_CLEAR_QUEUE)
				ret bot.clearQueue();
			else if (cmd == CMD_GET_QUEUE)
				ret = cmd_get_queue();
			else if (cmd == CMD_SET_POS)
				ret = cmd_set_pos();
			else if (cmd == CMD_GET_POS)
				ret = cmd_get_pos();
			else if (cmd == CMD_SEEK)
				ret = cmd_seek();
			else if (cmd == CMD_PAUSE)
				ret = cmd_pause();
			else if (cmd == CMD_ABORT)
				ret = cmd_abort();
			else if (cmd == CMD_HOME)
				ret = cmd_home();
			else if (cmd == CMD_SET_RPM)
				ret = cmd_set_rpm();
			else if (cmd == CMD_GET_RPM)
				ret = cmd_get_rpm();
			else if (cmd == CMD_SET_SPEED)
				ret = cmd_set_speed();
			else if (cmd == CMD_GET_SPEED)
				ret = cmd_get_speed();
			else if (cmd == CMD_GET_LIMIT_STATUS)
				ret = cmd_get_limit_status();
			else if (cmd == CMD_SET_STEPS)
				ret = cmd_set_steps();
			else if (cmd == CMD_GET_STEPS)
				ret = cmd_get_steps();
			
			//okay, these are for our extruder.
			else if (cmd == CMD_SET_TEMP)
				ret = cmd_set_temp();
			else if (cmd == CMD_GET_TEMP)
				ret = cmd_get_temp();
			else if (cmd == CMD_EXTRUDER_SET_DIRECTION)
				ret = cmd_extruder_set_direction();
			else if (cmd == CMD_EXTRUDER_GET_DIRECTION)
				ret = cmd_extruder_get_direction();
			else if (cmd == CMD_EXTRUDER_SET_SPEED)
				ret = cmd_extruder_set_speed();
			else if (cmd == CMD_EXTRUDER_GET_SPEED)
				ret = cmd_extruder_get_speed();
			else if (cmd == CMD_EXTRUDER_GET_TARGET_TEMP)
				ret = cmd_extruder_get_target_temp();
		}
		
		pkt.add(ret);
		pkt.reply(HOST_ADDRESS);
	}
}

void executeCommands()
{
	extruder.manageTemp();
	bot.move();
}

void cmd_version()
{
	pkt.add(VERSION);
}


void cmd_queue_point()
{
	Point point;
	
	point.x = readInt();
	point.y = readInt();
	point.z = readInt();
	
	return bot.queuePoint(point));
	
		ack();
	else
		nak();
}


void cmd_clear_queue()
{
	
	ack();
}

void cmd_get_queue()
{
//TODO: Add print queue function
	//bot.printQueue();
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
  //todo: add extruder.abort()
//	extruder.abort();
	bot.abort();
	ack();
}

void cmd_home()
{
  //todo: add bot.home()
//	bot.home();
	ack();
}

void cmd_set_rpm()
{
	char axis = Serial.read();
	byte speed = Serial.read();
	
	if (axis == 'a')
	{
		bot.x.stepper.setRPM(speed);
		bot.y.stepper.setRPM(speed);
		bot.z.stepper.setRPM(speed);					
	}
	else if (axis == 'x')
		bot.x.stepper.setRPM(speed);
	else if (axis == 'y')
		bot.y.stepper.setRPM(speed);
	else if (axis == 'z')
		bot.z.stepper.setRPM(speed);

	ack();
}

void cmd_get_rpm()
{
	char axis = Serial.read();
	
	if (axis == 'a')
	{
		Serial.print(bot.x.stepper.getRPM());
		Serial.print(bot.y.stepper.getRPM());
		Serial.print(bot.z.stepper.getRPM());					
	}
	if (axis == 'x')
		Serial.print(bot.x.stepper.getRPM());
	else if (axis == 'y')
		Serial.print(bot.y.stepper.getRPM());
	else if (axis == 'z')
		Serial.print(bot.z.stepper.getRPM());

	ack();
}

void cmd_set_speed()
{
	char axis = Serial.read();
	int speed = readInt();
	
	if (axis == 'a')
	{
		bot.x.stepper.setSpeed(speed);
		bot.y.stepper.setSpeed(speed);
		bot.z.stepper.setSpeed(speed);					
	}
	else if (axis == 'x')
		bot.x.stepper.setSpeed(speed);
	else if (axis == 'y')
		bot.y.stepper.setSpeed(speed);
	else if (axis == 'z')
		bot.z.stepper.setSpeed(speed);

	ack();
}

void cmd_get_speed()
{
	char axis = Serial.read();

	if (axis == 'a')
	{
		Serial.print(bot.x.stepper.getSpeed());
		Serial.print(bot.y.stepper.getSpeed());
		Serial.print(bot.z.stepper.getSpeed());					
	}
	if (axis == 'x')
		Serial.print(bot.x.stepper.getSpeed());
	else if (axis == 'y')
		Serial.print(bot.y.stepper.getSpeed());
	else if (axis == 'z')
		Serial.print(bot.z.stepper.getSpeed());
	
	ack();
}

void cmd_get_limit_status()
{
	char axis = Serial.read();

	if (axis == 'a')
	{
		Serial.print(bot.x.min_switch.getState());
		Serial.print(bot.x.max_switch.getState());
		Serial.print(bot.y.min_switch.getState());
		Serial.print(bot.y.max_switch.getState());
		Serial.print(bot.z.min_switch.getState());
		Serial.print(bot.z.max_switch.getState());
	}
	if (axis == 'x')
	{
		Serial.print(bot.x.min_switch.getState());
		Serial.print(bot.x.max_switch.getState());
	}
	else if (axis == 'y')
	{
		Serial.print(bot.y.min_switch.getState());
		Serial.print(bot.y.max_switch.getState());
	}
	else if (axis == 'z')
	{
		Serial.print(bot.z.min_switch.getState());
		Serial.print(bot.z.max_switch.getState());
	}
	
	ack();
}

void cmd_set_steps()
{
	char axis = Serial.read();
	int steps = readInt();
	
	if (axis == 'a')
	{
		bot.x.stepper.setSteps(steps);
		bot.y.stepper.setSteps(steps);
		bot.z.stepper.setSteps(steps);					
	}
	else if (axis == 'x')
		bot.x.stepper.setSteps(steps);
	else if (axis == 'y')
		bot.y.stepper.setSteps(steps);
	else if (axis == 'z')
		bot.z.stepper.setSteps(steps);
		
	ack();
}

void cmd_get_steps()
{
	char axis = Serial.read();

	if (axis == 'a')
	{
		Serial.print(bot.x.stepper.getSteps());
		Serial.print(bot.y.stepper.getSteps());
		Serial.print(bot.z.stepper.getSteps());					
	}
	if (axis == 'x')
		Serial.print(bot.x.stepper.getSteps());
	else if (axis == 'y')
		Serial.print(bot.y.stepper.getSteps());
	else if (axis == 'z')
		Serial.print(bot.z.stepper.getSteps());

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

void beginReply(int cmd)
{
}

void ack()
{
	Serial.print(CMD_REPLY_ACK);
}

void nak()
{
	Serial.print(CMD_REPLY_NAK);
}

void endReply()
{
}
