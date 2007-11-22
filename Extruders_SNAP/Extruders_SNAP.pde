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

#define DEBUG_LED_PIN 13

#define EXTRUDER_MOTOR_DIR_PIN    4
#define EXTRUDER_MOTOR_SPEED_PIN  3
#define EXTRUDER_HEATER_PIN       5
#define EXTRUDER_THERMISTOR_PIN   0

SNAP snap;
ThermoplastExtruder extruder(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_MOTOR_SPEED_PIN, EXTRUDER_HEATER_PIN, EXTRUDER_THERMISTOR_PIN);

void setup()
{
  Serial.begin(19200);
  snap.addDevice(8);
  for (byte i=8;i<14;i++) {
    pinMode(i, OUTPUT);
    digitalWrite(i, 0);
  }
  pinMode(DEBUG_LED_PIN, OUTPUT);
}

void loop()
{
  receiveCommands();
  if (snap.packetReady()) executeCommands();

}

void receiveCommands()
{
  while (Serial.available() > 0) {
    snap.receiveByte(Serial.read());
  }
}



int notImplemented(int cmd)
{
  digitalWrite(DEBUG_LED_PIN, HIGH);
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
	
  switch (cmd) {
      
  case CMD_VERSION:
    snap.sendReply();
    snap.sendDataByte(CMD_VERSION);
    snap.sendDataByte(VERSION_MINOR);
    snap.sendDataByte(VERSION_MAJOR);
    snap.endMessage();
    break;

// Extrude speed takes precedence over fan speed
  case CMD_FORWARD:
    extruder.setSpeed(snap.getByte(1));
    break;

  // seems to do the same as Forward
  case CMD_REVERSE:
    // not implemented
    notImplemented(cmd);
    break;

  case CMD_SETPOS:
    // not implemented
    notImplemented(cmd);
    
    currentPos = snap.getInt(1);
    break;

  case CMD_GETPOS:
    // not implemented
    notImplemented(cmd);
    
    //send some Bogus data so the Host software is happy
    snap.sendReply();
    snap.sendDataByte(CMD_GETPOS); 
    snap.sendDataInt(currentPos);
    snap.endMessage();
    break;

  case CMD_SEEK:
    // not implemented
    notImplemented(cmd);
    break;

  case CMD_FREE:
    // Free motor.  There is no torque hold for a DC motor,
    // so all we do is switch off
    extruder.setSpeed(0);
    break;

  case CMD_NOTIFY:
    // not implemented
    notImplemented(cmd);
    break;

  case CMD_ISEMPTY:
    // not implemented
    notImplemented(cmd);
    // We don't know so we say we're ot empty
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
    extruder.setTargetTemp(temperatureLimit1);
    extruder.setHeater(requestedHeat1);
    break;

  case CMD_GETTEMP:
    if (currentHeat < temperatureLimit1)
      currentHeat+=10;
    else if (currentHeat > temperatureLimit1)
      currentHeat--;
      
    snap.sendReply();
    snap.sendDataByte(CMD_GETTEMP); 
    snap.sendDataByte(currentHeat);
    snap.sendDataByte(0);
    snap.endMessage();
    break;

  case CMD_SETCOOLER:
    // not implemented
    notImplemented(cmd);
    break;

// "Hidden" low level commands
  case CMD_PWMPERIOD:
    // not implemented
    notImplemented(cmd);
    break;

  case CMD_PRESCALER:
    // not implemented
    notImplemented(cmd);
    break;

  case CMD_SETVREF:
    // not implemented
    notImplemented(cmd);
    break;

  case CMD_SETTEMPSCALER:
    // not implemented
    notImplemented(cmd);
    break;

  case CMD_GETDEBUGINFO:
    // not implemented
    notImplemented(cmd);
    break;

  case CMD_GETTEMPINFO:
    snap.sendReply();
    snap.sendDataByte(CMD_GETTEMPINFO); 
    snap.sendDataByte(requestedHeat0);
    snap.sendDataByte(requestedHeat1);
    snap.sendDataByte(temperatureLimit0);
    snap.sendDataByte(temperatureLimit1);
    snap.sendDataByte(extruder.getTemp());
    snap.sendDataByte(0);
    snap.endMessage();
    break;
    
  default:
    notImplemented(cmd);
    break;
					
  }
  snap.releaseLock();
}

