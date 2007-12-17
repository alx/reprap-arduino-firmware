/*
  Extruder_SNAP.pde - RepRap Thermoplastic Extruder firmware for Arduino

  Main firmware for the extruder (heater, motor and temp. sensor)

  History:
  * Created intial version (0.1) by Philipp Tiefenbacher and Marius Kintel

*/

#include <ThermoplastExtruder.h>
#include <SNAP.h>

#define VERSION_MAJOR 0
#define VERSION_MINOR 2
#define HOST_ADDRESS 0
//
// Extrude commands
//
#define CMD_VERSION       0
#define CMD_FORWARD       1
#define CMD_REVERSE       2
#define CMD_SETPOS        3
#define CMD_GETPOS        4
#define CMD_SEEK          5
#define CMD_FREE          6
#define CMD_NOTIFY        7
#define CMD_ISEMPTY       8
#define CMD_SETHEAT       9
#define CMD_GETTEMP       10
#define CMD_SETCOOLER     11
#define CMD_PWMPERIOD     50
#define CMD_PRESCALER     51
#define CMD_SETVREF       52
#define CMD_SETTEMPSCALER 53
#define CMD_GETDEBUGINFO  54
#define CMD_GETTEMPINFO   55

#define EXTRUDER_MOTOR_SPEED_PIN  3
#define EXTRUDER_MOTOR_DIR_PIN    4
#define EXTRUDER_HEATER_PIN       5
#define EXTRUDER_THERMISTOR_PIN   0

SNAP snap;
ThermoplastExtruder extruder(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_MOTOR_SPEED_PIN, EXTRUDER_HEATER_PIN, EXTRUDER_THERMISTOR_PIN);

//uncomment this define to enable the debug mode.
#define DEBUG_MODE
#ifdef DEBUG_MODE
	#include <SoftwareSerial.h>
	#define DEBUG_RX_PIN 10
	#define DEBUG_TX_PIN 11
	SoftwareSerial debug = SoftwareSerial(DEBUG_RX_PIN, DEBUG_TX_PIN);
#endif

void setup()
{
	Serial.begin(19200);

	snap.addDevice(8);

	for (byte i=8;i<14;i++)
	{
		pinMode(i, OUTPUT);
		digitalWrite(i, 0);
	}
	
	#ifdef DEBUG_MODE
		pinMode(DEBUG_RX_PIN, INPUT);
		pinMode(DEBUG_TX_PIN, OUTPUT);
		debug.begin(4800);
		debug.println("Debug active.");
	#endif
}

void loop()
{
	//process our commands
	snap.receivePacket();
	if (snap.packetReady())
		executeCommands();

	//manage our temperature
	extruder.manageTemperature();
}
  
int currentPos = 0;
byte currentHeat = 0;
byte requestedHeat0 = 0;
byte requestedHeat1 = 0;
byte temperatureLimit0 = 0;
byte temperatureLimit1 = 0;

void executeCommands()
{
	byte cmd = snap.getByte(0);

	switch (cmd)
	{
		case CMD_VERSION:
			snap.sendReply();
			snap.sendDataByte(CMD_VERSION);
			snap.sendDataByte(VERSION_MINOR);
			snap.sendDataByte(VERSION_MAJOR);
			snap.endMessage();
		break;

		// Extrude speed takes precedence over fan speed
		case CMD_FORWARD:
			extruder.setDirection(1);
			extruder.setSpeed(snap.getByte(1));
		break;

		// seems to do the same as Forward
		case CMD_REVERSE:
			extruder.setDirection(0);
			extruder.setSpeed(snap.getByte(1));
		break;

		case CMD_SETPOS:
			currentPos = snap.getInt(1);
		break;

		case CMD_GETPOS:
			//send some Bogus data so the Host software is happy
			snap.sendReply();
			snap.sendDataByte(CMD_GETPOS); 
			snap.sendDataInt(currentPos);
			snap.endMessage();
		break;

		case CMD_SEEK:
			debug.println("n/i: seek");
		break;

		case CMD_FREE:
			// Free motor.  There is no torque hold for a DC motor,
			// so all we do is switch off
			extruder.setSpeed(0);
		break;

		case CMD_NOTIFY:
			debug.println("n/i: notify");
		break;

		case CMD_ISEMPTY:
			// We don't know so we say we're not empty
			snap.sendReply();
			snap.sendDataByte(CMD_ISEMPTY); 
			snap.sendDataByte(0);  
			snap.endMessage();
		break;

		case CMD_SETHEAT:
			requestedHeat0 = snap.getByte(1);
			requestedHeat1 = snap.getByte(2);
			temperatureLimit0 = snap.getByte(3);
			temperatureLimit1 = snap.getByte(4);
			extruder.setTargetTemperature(temperatureLimit1);
			extruder.setHeater(requestedHeat1);

			debug.print("requestedHeat0: ");
			debug.println(requestedHeat0);
			debug.print("requestedHeat1: ");
			debug.println(requestedHeat1);
			debug.print("temperatureLimit0: ");
			debug.println(temperatureLimit0);
			debug.print("temperatureLimit1: ");
			debug.println(temperatureLimit1);
		break;

		case CMD_GETTEMP:
			debug.print("temp: ");
			debug.println(extruder.getTemperature(), DEC);
			debug.print("raw: ");
			debug.println(extruder.getRawTemperature(), DEC);
			snap.sendReply();
			snap.sendDataByte(CMD_GETTEMP); 
			snap.sendDataByte(extruder.getTemperature());
			snap.sendDataByte(0);
			snap.endMessage();
		break;

		case CMD_SETCOOLER:
			debug.println("n/i: set cooler");
		break;

		// "Hidden" low level commands
		case CMD_PWMPERIOD:
			debug.println("n/i: pwm period");
		break;

		case CMD_PRESCALER:
			debug.println("n/i: prescaler");
		break;

		case CMD_SETVREF:
			debug.println("n/i: set vref");
		break;

		case CMD_SETTEMPSCALER:
			debug.println("n/i: set temp scaler");
		break;

		case CMD_GETDEBUGINFO:
			debug.println("n/i: get debug info");
		break;

		case CMD_GETTEMPINFO:
			snap.sendReply();
			snap.sendDataByte(CMD_GETTEMPINFO); 
			snap.sendDataByte(requestedHeat0);
			snap.sendDataByte(requestedHeat1);
			snap.sendDataByte(temperatureLimit0);
			snap.sendDataByte(temperatureLimit1);
			snap.sendDataByte(extruder.getTemperature());
			snap.sendDataByte(0);
			snap.endMessage();
		break;
	}
	snap.releaseLock();
}
