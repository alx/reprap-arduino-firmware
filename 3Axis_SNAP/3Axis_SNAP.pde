
/******************
* Get our libraries
******************/

#include <SNAP.h>
#include <LimitSwitch.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>

//the version of our software
#define VERSION_MAJOR 2
#define VERSION_MINOR 0
#define X_ADDRESS 2
#define Y_ADDRESS 3
#define Z_ADDRESS 4
#define HOST_ADDRESS 0

/********************************
* digital i/o pin assignment
********************************/
#define X_STEP_PIN 2
#define X_DIR_PIN 3
#define X_MIN_PIN 4
#define X_MAX_PIN 5
#define Y_STEP_PIN 6
#define Y_DIR_PIN 7
#define Y_MIN_PIN 8
#define Y_MAX_PIN 9
#define Z_STEP_PIN 10
#define Z_DIR_PIN 11
#define Z_MIN_PIN 12
#define Z_MAX_PIN 13

/********************************
* how many steps do our motors have?
********************************/
#define X_MOTOR_STEPS 400
#define Y_MOTOR_STEPS 400
#define Z_MOTOR_STEPS 400

/********************************
* command declarations
********************************/
#define CMD_VERSION   0
#define CMD_FORWARD   1
#define CMD_REVERSE   2
#define CMD_SETPOS    3
#define CMD_GETPOS    4
#define CMD_SEEK      5
#define CMD_FREE      6
#define CMD_NOTIFY    7
#define CMD_SYNC      8
#define CMD_CALIBRATE 9
#define CMD_GETRANGE  10
#define CMD_DDA       11
#define CMD_FORWARD1  12
#define CMD_BACKWARD1 13
#define CMD_SETPOWER  14
#define CMD_GETSENSOR 15
#define CMD_HOMERESET 16

/********************************
*  Global mode declarations
********************************/
enum functions {
  func_idle,
  func_forward,
  func_reverse,
  func_syncwait,   // Waiting for sync prior to seeking
  func_seek,
  func_findmin,    // Calibration, finding minimum
  func_findmax,    // Calibration, finding maximum
  func_ddamaster,
  func_homereset   // Move to min position and reset
};

/********************************
*  Global variable declarations
********************************/

//our cartesian bot object
volatile CartesianBot bot(
  X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN,
  Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN,
  Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN
);

//our communicator object
SNAP snap();

//what are we doing?
int function;
	

SIGNAL(SIG_OUTPUT_COMPARE0A)
{
	bot.handleInterrupt();
}

	
void setup()
{
	//fire up our serial comms.
	Serial.begin(19200);
}

void loop()
{
	receiveCommands();
	
	if (snap.packetReady())
		executeCommands();
}

void receiveCommands()
{
	byte cmd;

	while (Serial.available() > 1)
	{
		cmd = Serial.read();
		snap.receiveByte(cmd);
	}
}

void executeCommands()
{
	byte cmd = snap.getByte(0);
	byte dest = snap.getDestination();
	unsigned long position;
	
	switch(cmd)
	{
		case CMD_VERSION:
			snap.sendReply();
			snap.sendDataByte(CMD_VERSION);  // Response type 0
			snap.sendDataByte(0);  // Minor
			snap.sendDataByte(2);  // Major
			snap.endMessage();
			break;

		case CMD_FORWARD:
			//okay, set our speed.
			if (dest == X_ADDRESS)
				bot.x.stepper.setRPM(snap.getByte(1));
			else if (dest == Y_ADDRESS)
				bot.y.stepper.setRPM(snap.getByte(1));
			else if (dest == Z_ADDRESS)
				bot.z.stepper.setRPM(snap.getByte(1));

			function = func_forward;
			break;

		case CMD_REVERSE:
			//okay, set our speed.
			if (dest == X_ADDRESS)
				bot.x.stepper.setRPM(snap.getByte(1));
			else if (dest == Y_ADDRESS)
				bot.y.stepper.setRPM(snap.getByte(1));
			else if (dest == Z_ADDRESS)
				bot.z.stepper.setRPM(snap.getByte(1));
			
			function = func_reverse;
			break;

		case CMD_SETPOS:
			position = (snap.getByte(2) << 8) + (snap.getByte(1));
		
			//okay, set our speed.
			if (dest == X_ADDRESS)
				bot.x.setPosition(position);
			else if (dest == Y_ADDRESS)
				bot.y.setPosition(position);
			else if (dest == Z_ADDRESS)
				bot.z.setPosition(position);
		break;

		case CMD_GETPOS:
			//okay, set our speed.
			if (dest == X_ADDRESS)
				position = bot.x.getPosition();
			else if (dest == Y_ADDRESS)
				position = bot.y.getPosition();
			else if (dest == Z_ADDRESS)
				position = bot.z.getPosition();
		
			// Get position counter
			snap.sendReply();
			snap.sendDataByte(CMD_GETPOS);
			snap.sendDataByte(position);
			snap.sendDataByte(position >> 8);
			snap.endMessage();
			break;

		case CMD_SEEK:
			// Goto position
			position = (snap.getByte(3) << 8) + snap.getByte(2);

			//okay, set our speed.
			if (dest == X_ADDRESS)
			{
				bot.x.stepper.setRPM(snap.getByte(1));
				bot.x.setTarget(position);
			}
			else if (dest == Y_ADDRESS)
			{
				bot.y.stepper.setRPM(snap.getByte(1));
				bot.y.setTarget(position);
			}
			else if (dest == Z_ADDRESS)
			{
				bot.z.stepper.setRPM(snap.getByte(1));
				bot.z.setTarget(position);
			}
			
			//recalculate our DDA algo.
			bot.calculateDDA();
			
			if (sync_mode == sync_seek)
				function = func_syncwait;
			else
				function = func_seek;
			break;

		case CMD_FREE:
			//we dont have enough pins to enable/disable the stepper :-/
			function = func_idle;
			break;

		case CMD_NOTIFY:
			// Set seek completion (and calibration) notification
			seekNotify = snap.getByte(1);
			break;

		case CMD_SYNC:
			// Set sync mode
			sync_mode = snap.getByte(1);
			break;

		case CMD_CALIBRATE:
			// Request calibration (search at given speed)
			if (dest == X_ADDRESS)
				bot.x.stepper.setRPM(snap.getByte(1));
			else if (dest == Y_ADDRESS)
				bot.y.stepper.setRPM(snap.getByte(1));
			else if (dest == Z_ADDRESS)
				bot.z.stepper.setRPM(snap.getByte(1));
		
			function = func_findmin;
			break;

		case CMD_GETRANGE:
			if (dest == X_ADDRESS)
				position = bot.x.stepper.getMaximum();
			else if (dest == Y_ADDRESS)
				position = bot.y.stepper.getMaximum();
			else if (dest == Z_ADDRESS)
				position = bot.z.stepper.getMaximum();

			// Request range
			sendReplyply();
			sendDataByte(CMD_GETRANGE);
			sendDataByte((position >> 8));
			sendDataByte((position));
			endMessage();
			break;

		case CMD_DDA:
		// Master a DDA
		// Assumes head is already positioned correctly at x0 and extrusion
		// is starting

		seekPosition.bytes[0] = buffer[2];
		seekPosition.bytes[1] = buffer[3];
		dda_deltay.bytes[0] = buffer[4];
		dda_deltay.bytes[1] = buffer[5];
		dda_error = 0;

		dda_deltax = seekPosition.ival - currentPosition.ival;
		if (dda_deltax < 0) dda_deltax = -dda_deltax;

		function = func_ddamaster;
		setTimer(buffer[1]);
		break;

		case CMD_FORWARD1:
			if (dest == X_ADDRESS)
				position = bot.x.stepper.blockingStep(1);
			else if (dest == Y_ADDRESS)
				position = bot.y.stepper.blockingStep(1);
			else if (dest == Z_ADDRESS)
				position = bot.z.stepper.blockingStep(1);
			break;

		case CMD_BACKWARD1:
			if (dest == X_ADDRESS)
				position = bot.x.stepper.blockingStep(-1);
			else if (dest == Y_ADDRESS)
				position = bot.y.stepper.blockingStep(-1);
			else if (dest == Z_ADDRESS)
				position = bot.z.stepper.blockingStep(-1);
			break;

		case CMD_SETPOWER:
			//doesnt matter because power is handled by the stepper driver board!
			break;

		case CMD_GETSENSOR:
		sendReply();
		sendDataByte(CMD_GETSENSOR);
		sendDataByte(PORTA);
		sendDataByte(PORTB);
		endMessage();
		break;

		case CMD_HOMERESET:
			// Seek to home position and reset (search at given speed)
			if (dest == X_ADDRESS)
				bot.x.stepper.setRPM(snap.getByte(1));
			else if (dest == Y_ADDRESS)
				bot.y.stepper.setRPM(snap.getByte(1));
			else if (dest == Z_ADDRESS)
				bot.z.stepper.setRPM(snap.getByte(1));
			
			function = func_homereset;
			break;
	}
}
