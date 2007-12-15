/*
  3Axis_SNAP.pde - RepRap cartesian firmware for Arduino

  History:
  * Created initial version (0.1) by Zach Smith.
  * Rewrite (0.2) by Marius Kintel <kintel@sim.no> and Philipp Tiefenbacher <wizards23@gmail.com>
  * Updated and tested (0.3) to work with current RepRap host software by Zach Smith <hoeken@rrrf.org>
  */
#include <SNAP.h>
#include <LimitSwitch.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>

//the version of our software
#define VERSION_MAJOR 0
#define VERSION_MINOR 2
#define X_ADDRESS 2
#define Y_ADDRESS 3
#define Z_ADDRESS 4
#define HOST_ADDRESS 0

/********************************
 * digital i/o pin assignment
 ********************************/

//this uses the undocumented feature of Arduino - pins 14-19 correspond to analog 0-5
#define X_STEP_PIN 2
#define X_DIR_PIN 3
#define X_MIN_PIN 4
#define X_MAX_PIN 5
#define X_ENABLE_PIN 14
#define Y_STEP_PIN 6
#define Y_DIR_PIN 7
#define Y_MIN_PIN 8
#define Y_MAX_PIN 9
#define Y_ENABLE_PIN 15
#define Z_STEP_PIN 10
#define Z_DIR_PIN 11
#define Z_MIN_PIN 12
#define Z_MAX_PIN 13
#define Z_ENABLE_PIN 16

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
 *  Sync mode declarations
 ********************************/
enum sync_modes {
  sync_none,     // no sync (default)
  sync_seek,     // synchronised seeking
  sync_inc,      // inc motor on each pulse
  sync_dec       // dec motor on each pulse
};
byte x_sync_mode = sync_none;
byte y_sync_mode = sync_none;

/********************************
 *  Global variable declarations
 ********************************/

//our cartesian bot object
CartesianBot bot(
	'x', X_MOTOR_STEPS, X_DIR_PIN, X_STEP_PIN, X_MIN_PIN, X_MAX_PIN,
	'y', Y_MOTOR_STEPS, Y_DIR_PIN, Y_STEP_PIN, Y_MIN_PIN, Y_MAX_PIN,
	'z', Z_MOTOR_STEPS, Z_DIR_PIN, Z_STEP_PIN, Z_MIN_PIN, Z_MAX_PIN
);

//our communicator object
SNAP snap;

byte x_notify = 255;
byte y_notify = 255;
byte z_notify = 255;

//uncomment this define to enable the debug mode.
#define DEBUG_MODE
#ifdef DEBUG_MODE
	#include <SoftwareSerial.h>
	#define DEBUG_RX_PIN 14
	#define DEBUG_TX_PIN 15
	SoftwareSerial debug =  SoftwareSerial(DEBUG_RX_PIN, DEBUG_TX_PIN);
#endif

SIGNAL(SIG_OUTPUT_COMPARE1A)
{
	bot.readState();
	
	if (bot.mode == MODE_SEEK)
	{
		if (bot.x.can_step)
			bot.x.doStep();
		if (bot.x.atTarget() && x_notify != 255)
			notifySeek(x_notify, X_ADDRESS, (int)bot.x.getPosition());

		if (bot.y.can_step)
			bot.y.doStep();
		if (bot.y.atTarget() && y_notify != 255)
			notifySeek(y_notify, Y_ADDRESS, (int)bot.y.getPosition());

		if (bot.z.can_step)
			bot.z.doStep();
		if (bot.z.atTarget() && z_notify != 255)
			notifySeek(z_notify, Z_ADDRESS, (int)bot.z.getPosition());
			
		if (bot.atTarget())
			bot.stop();
	}
	else if (bot.mode == MODE_DDA)
	{
		if (bot.x.can_step)
			bot.x.ddaStep(bot.max_delta);
		
		if (bot.y.can_step)
			bot.y.ddaStep(bot.max_delta);
			
		//z-axis not supported in v1.0 of comms.	

		if (bot.atTarget())
		{
			if (x_notify != 255)
				notifyDDA(x_notify, X_ADDRESS, (int)bot.x.getPosition());
			if (y_notify != 255)
				notifyDDA(y_notify, Y_ADDRESS, (int)bot.y.getPosition());
			
			bot.stop();
		}
	}
	else if (bot.mode == MODE_HOMERESET)
	{
		if (bot.x.function == func_homereset)
		{
			if (!bot.x.atMin())
				bot.x.stepper.pulse();
			else
			{
				bot.x.setPosition(0);
				bot.x.function = func_idle;
				bot.stop();
				
				if (x_notify != 255)
					notifyHomeReset(x_notify, X_ADDRESS);
			}
		}

		if (bot.y.function == func_homereset)
		{
			if (!bot.y.atMin())
				bot.y.stepper.pulse();
			else
			{
				bot.y.setPosition(0);
				bot.y.function = func_idle;
				bot.stop();
				
				if (y_notify != 255)
					notifyHomeReset(y_notify, Y_ADDRESS);	
			}
		}

		if (bot.z.function == func_homereset)
		{
			if (!bot.z.atMin())
				bot.z.stepper.pulse();
			else
			{
				bot.z.setPosition(0);
				bot.z.function = func_idle;
				bot.stop();

				if (z_notify != 255)
					notifyHomeReset(z_notify, Z_ADDRESS);
			}
		}
	}
	else if (bot.mode == MODE_FIND_MIN)
	{
		if (bot.x.function == func_findmin)
		{
			if (!bot.x.atMin())
				bot.x.stepper.pulse();
			else
			{
				bot.x.setPosition(0);
				bot.x.stepper.setDirection(RS_FORWARD);
				bot.x.function = func_findmax;
				bot.mode = MODE_FIND_MAX;
			}
		}

		if (bot.y.function == func_findmin)
		{
			if (!bot.y.atMin())
				bot.y.stepper.pulse();
			else
			{
				bot.y.setPosition(0);
				bot.y.stepper.setDirection(RS_FORWARD);
				bot.y.function = func_findmax;
				bot.mode = MODE_FIND_MAX;
			}
		}

		if (bot.z.function == func_findmin)
		{
			if (!bot.z.atMin())
				bot.z.stepper.pulse();
			else
			{
				bot.z.setPosition(0);
				bot.z.stepper.setDirection(RS_FORWARD);
				bot.z.function = func_findmax;
				bot.mode = MODE_FIND_MAX;
			}
		}
	}
	else if (bot.mode == MODE_FIND_MAX)
	{
		if (bot.x.function == func_findmax)
		{
			//do a step if we're not there yet.
			if (!bot.x.atMax())
				bot.x.doStep();
			
			//are we there yet?
			if (bot.x.atMax())
			{
				bot.x.setMax(bot.x.getPosition());
				bot.x.function = func_idle;
				bot.stop();
				
				if (x_notify != 255)
					notifyCalibrate(x_notify, X_ADDRESS, bot.x.getMax());
			}
		}
		
		if (bot.y.function == func_findmax)
		{
			//do a step if we're not there yet.
			if (!bot.y.atMax())
				bot.y.doStep();
			
			//are we there yet?
			if (bot.y.atMax())
			{
				bot.y.setMax(bot.y.getPosition());
				bot.y.function = func_idle;
				bot.stop();
				
				if (x_notify != 255)
					notifyCalibrate(x_notify, X_ADDRESS, bot.y.getMax());
			}
		}
		
		if (bot.z.function == func_findmax)
		{
			//do a step if we're not there yet.
			if (!bot.z.atMax())
				bot.z.doStep();
			
			//are we there yet?
			if (bot.z.atMax())
			{
				bot.z.setMax(bot.z.getPosition());
				bot.z.function = func_idle;
				bot.stop();
				
				if (x_notify != 255)
					notifyCalibrate(x_notify, X_ADDRESS, bot.z.getMax());
			}
		}
	}
}
	
void setup()
{
	bot.setupTimerInterrupt();

	Serial.begin(19200);
	snap.addDevice(X_ADDRESS);
	snap.addDevice(Y_ADDRESS);
	snap.addDevice(Z_ADDRESS);

	bot.stop();

	#ifdef DEBUG_MODE
		pinMode(DEBUG_RX_PIN, INPUT);
		pinMode(DEBUG_TX_PIN, OUTPUT);
		debug.begin(2400);
		debug.println("Debug active.");
	#endif
}

void loop()
{	
	//process our commands
	snap.receivePacket();
	if (snap.packetReady())
		executeCommands();

	//get our state status.
	bot.readState();

	//if we are at our target, stop us.
//	if (bot.atTarget())
//		bot.stop();
}

int notImplemented(int cmd)
{
}

void executeCommands()
{
	byte cmd = snap.getByte(0);
	byte dest = snap.getDestination();
	unsigned long position;

	switch (cmd)
	{
		case CMD_VERSION:
			snap.sendReply();
			snap.sendDataByte(CMD_VERSION);  // Response type 0
			snap.sendDataByte(VERSION_MINOR);
			snap.sendDataByte(VERSION_MAJOR);
			snap.endMessage();
		break;

		case CMD_FORWARD:
			//okay, set our speed.
			if (dest == X_ADDRESS)
			{
				bot.x.stepper.setRPM(snap.getByte(1));
				bot.x.stepper.setDirection(RS_FORWARD);
				bot.x.function = func_forward;
				bot.setTimer(bot.x.stepper.getSpeed());
			}
			else if (dest == Y_ADDRESS)
			{
				bot.y.stepper.setRPM(snap.getByte(1));
				bot.y.stepper.setDirection(RS_FORWARD);
				bot.y.function = func_forward;
				bot.setTimer(bot.y.stepper.getSpeed());
			}
			else if (dest == Z_ADDRESS)
			{
				bot.z.stepper.setRPM(snap.getByte(1));
				bot.z.stepper.setDirection(RS_FORWARD);
				bot.z.function = func_forward;
				bot.setTimer(bot.z.stepper.getSpeed());
			}
		break;

		case CMD_REVERSE:
			if (dest == X_ADDRESS)
			{
				bot.x.stepper.setRPM(snap.getByte(1));
				bot.x.stepper.setDirection(RS_REVERSE);
				bot.x.function = func_reverse;
				bot.setTimer(bot.x.stepper.getSpeed());
			}
			else if (dest == Y_ADDRESS)
			{
				bot.y.stepper.setRPM(snap.getByte(1));
				bot.y.stepper.setDirection(RS_REVERSE);
				bot.y.function = func_reverse;
				bot.setTimer(bot.y.stepper.getSpeed());
			}
			else if (dest == Z_ADDRESS)
			{
				bot.z.stepper.setRPM(snap.getByte(1));
				bot.z.stepper.setDirection(RS_REVERSE);
				bot.z.function = func_reverse;
				bot.setTimer(bot.z.stepper.getSpeed());
			}
		break;

		case CMD_SETPOS:
			position = (snap.getByte(2) << 8) + (snap.getByte(1));

			if (dest == X_ADDRESS)
			{
				bot.x.setPosition(position);
				bot.x.setTarget(position);
			}
			else if (dest == Y_ADDRESS) 
			{
				bot.y.setPosition(position);
				bot.y.setTarget(position);
			}
			else if (dest == Z_ADDRESS)
			{
				bot.z.setPosition(position);
				bot.z.setTarget(position);
			}
		break;

		case CMD_GETPOS:
			if (dest == X_ADDRESS)
				position = bot.x.getPosition();
			else if (dest == Y_ADDRESS)
				position = bot.y.getPosition();
			else if (dest == Z_ADDRESS)
				position = bot.z.getPosition();

			snap.sendReply();
			snap.sendDataByte(CMD_GETPOS);
			snap.sendDataByte(position & 0xff);
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
				bot.setTimer(bot.x.stepper.getSpeed());
				bot.x.setTarget(position);
			}
			else if (dest == Y_ADDRESS)
			{
				bot.y.stepper.setRPM(snap.getByte(1));
				bot.setTimer(bot.y.stepper.getSpeed());
				bot.y.setTarget(position);
			}
			else if (dest == Z_ADDRESS)
			{
				bot.z.stepper.setRPM(snap.getByte(1));
				bot.setTimer(bot.z.stepper.getSpeed());
				bot.z.setTarget(position);
			}

			//recalculate our DDA algo.
			bot.startSeek();
	    break;

		case CMD_FREE:
			if (dest == X_ADDRESS)
			{
				digitalWrite(X_ENABLE_PIN, LOW);
				bot.x.function = func_idle;
			}
			if (dest == Y_ADDRESS)
			{
				digitalWrite(Y_ENABLE_PIN, LOW);
				bot.y.function = func_idle;
			}
			if (dest == Z_ADDRESS)
			{
				digitalWrite(Z_ENABLE_PIN, LOW);
				bot.y.function = func_idle;
			}
		break;

		case CMD_NOTIFY:
			// Parameter is receiver of notification, or 255 if notification should be turned off
			if (dest == X_ADDRESS)
				x_notify = snap.getByte(1);
			if (dest == Y_ADDRESS)
				y_notify = snap.getByte(1);
			if (dest == Z_ADDRESS)
				z_notify = snap.getByte(1);
		break;

		case CMD_SYNC:
			// Set sync mode.. used to determine which direction to move slave stepper
			if (dest == X_ADDRESS)
				x_sync_mode = snap.getByte(1);
			else if (dest == Y_ADDRESS)
				y_sync_mode = snap.getByte(1);
		break;

		case CMD_CALIBRATE:
			//stop other stuff.
			bot.stop();
		
			// Request calibration (search at given speed)
			if (dest == X_ADDRESS)
			{
				bot.x.stepper.setRPM(snap.getByte(1));
				bot.setTimer(bot.x.stepper.getSpeed());
				bot.x.function = func_findmin;
			}
			else if (dest == Y_ADDRESS)
			{
				bot.y.stepper.setRPM(snap.getByte(1));
				bot.setTimer(bot.y.stepper.getSpeed());
				bot.y.function = func_findmin;
			}
			else if (dest == Z_ADDRESS) bot.z.stepper.setRPM(snap.getByte(1));
			{
				bot.z.stepper.setRPM(snap.getByte(1));
				bot.setTimer(bot.z.stepper.getSpeed());
				bot.z.function = func_findmin;
			}
			
			//start our calibration.
			bot.startCalibration();
		break;

		case CMD_GETRANGE:
			if (dest == X_ADDRESS)
				position = bot.x.getMax();
			else if (dest == Y_ADDRESS)
				position = bot.y.getMax();
			else if (dest == Z_ADDRESS)
				position = bot.z.getMax();

			//tell the host.
			snap.sendReply();
			snap.sendDataByte(CMD_GETPOS);
			snap.sendDataInt(position);
			snap.endMessage();
		break;

		case CMD_DDA:
			unsigned long target;

			//stop the bot.
			bot.stop();
			
			//get our coords.
			position = snap.getInt(2);
			target = snap.getInt(4);
			
			//which axis is leading?
			if (dest == X_ADDRESS)
			{
				debug.println("x master");
				bot.x.setTarget(position);
				
				//we can figure out the target based on the sync mode
				if (y_sync_mode == sync_inc)
					bot.y.setTarget(bot.y.getPosition() + target);
				else
					bot.y.setTarget(bot.y.getPosition() - target);
			}
			else if (dest == Y_ADDRESS)
			{
				debug.println("y master");
				bot.y.setTarget(position);
				bot.x.setTarget(target);

				//we can figure out the target based on the sync mode
				if (x_sync_mode == sync_inc)
					bot.x.setTarget(bot.x.getPosition() + target);
				else
					bot.x.setTarget(bot.x.getPosition() - target);
			}
			
			debug.print("position: ");
			debug.println(position);
			debug.print("target: ");
			debug.println(target);
	
			debug.print("x: ");
			debug.print((int)bot.x.getPosition());
			debug.print(" -> ");
			debug.println((int)bot.x.getTarget());

			debug.print("y: ");
			debug.print((int)bot.y.getPosition());
			debug.print(" -> ");
			debug.println((int)bot.y.getTarget());
			
			debug.print("x notify: ");
			debug.println(x_notify, DEC);
			debug.print("y notify: ");
			debug.println(y_notify, DEC);
			
			//set z's target to itself.
			bot.z.setTarget(bot.z.getPosition());
			
			//set our speed.
			bot.x.stepper.setRPM(snap.getByte(1));
			bot.setTimer(bot.x.stepper.getSpeed());
			
			//init our DDA stuff!
			bot.calculateDDA();
		break;

		case CMD_FORWARD1:
			if (dest == X_ADDRESS)
				bot.x.forward1();
			else if (dest == Y_ADDRESS)
				bot.y.forward1();
			else if (dest == Z_ADDRESS)
				bot.z.forward1();
		break;

		case CMD_BACKWARD1:
			if (dest == X_ADDRESS)
				bot.x.reverse1();
			else if (dest == Y_ADDRESS)
				bot.y.reverse1();
			else if (dest == Z_ADDRESS)
				bot.z.reverse1();
		break;

		case CMD_SETPOWER:
			//doesnt matter because power is handled by the stepper driver board!
		break;

		case CMD_GETSENSOR:
			snap.sendReply();
			snap.sendDataByte(CMD_GETSENSOR);
			// FIXME: Dummy values for now
			snap.sendDataByte(0);
			snap.sendDataByte(0);
			snap.endMessage();
		break;

		case CMD_HOMERESET:
			bot.stop();
		
			if (dest == X_ADDRESS)
			{
				//configure our axis
				bot.x.stepper.setDirection(RS_REVERSE);
				bot.x.stepper.setRPM(snap.getByte(1));
				bot.setTimer(bot.x.stepper.getSpeed());

				//tell our axis to go home.
				bot.x.function = func_homereset;
			}
			else if (dest == Y_ADDRESS)
			{
				//configure our axis
				bot.y.stepper.setDirection(RS_REVERSE);
				bot.y.stepper.setRPM(snap.getByte(1));
				bot.setTimer(bot.y.stepper.getSpeed());

				//tell our axis to go home.
				bot.y.function = func_homereset;
			}
			else if (dest == Z_ADDRESS)
			{
				//configure our axis
				bot.z.stepper.setDirection(RS_REVERSE);
				bot.z.stepper.setRPM(snap.getByte(1));
				bot.setTimer(bot.z.stepper.getSpeed());

				//tell our axis to go home.
				bot.z.function = func_homereset;
			}
			
			//starts our home reset mode.
			bot.startHomeReset();

		break;
	}

	snap.releaseLock();
}

void notifyHomeReset(byte to, byte from)
{
	debug.print(from, DEC);
	debug.println(" at home");
	
	snap.startMessage(from);
	snap.sendMessage(to);
	snap.sendDataByte(CMD_HOMERESET);
	snap.endMessage();
}

void notifyCalibrate(byte to, byte from, unsigned int position)
{
	debug.print("calibrate: ");
	debug.print(from, DEC);
	debug.print(" at ");
	debug.println((int)position, DEC);
	
	snap.startMessage(from);
	snap.sendMessage(to);
	snap.sendDataByte(CMD_CALIBRATE);
	snap.sendDataInt(position);
	snap.endMessage();	
}

void notifySeek(byte to, byte from, unsigned int position)
{
	debug.print("seek: ");
	debug.print(from, DEC);
	debug.print(" at ");
	debug.println((int)position, DEC);

	snap.startMessage(from);
	snap.sendMessage(to);
	snap.sendDataByte(CMD_SEEK);
	snap.sendDataInt(position);
	snap.endMessage();
}

void notifyDDA(byte to, byte from, unsigned int position)
{
	debug.print("dda: ");
	debug.print(from, DEC);
	debug.print(" at ");
	debug.println((int)position, DEC);
	
	snap.startMessage(from);
	snap.sendMessage(to);
	snap.sendDataByte(CMD_DDA);
	snap.sendDataInt(position);
	snap.endMessage();
}

