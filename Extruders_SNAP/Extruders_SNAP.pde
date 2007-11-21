#include <ThermoplastExtruder.h>
#include <SNAP.h>

#define VERSION_MAJOR 0
#define VERSION_MINOR 1
#define HOST_ADDRESS 0

//
// Extrude commands (marius; names)
//
/*
#define CMD_VERSION             0
#define CMD_FORWARD             1
#define CMD_REVERSE             2
#define CMD_SETPOS              3
#define CMD_GETPOS              4
#define CMD_SEEK                5
#define CMD_MOTOR_OFF           6
#define CMD_ENABLE_ASYNC_NOTIFY 7
#define CMD_MATERIAL_EMPTY      8
#define CMD_SET_HEATER          9
#define CMD_GET_TEMP           10
#define CMD_SET_PWM            50
#define CMD_SET_PRESCALER      51
#define CMD_SET_VREF           52
*/
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

  digitalWrite(8, 1);
}

void receiveCommands()
{
  digitalWrite(9, 1);
  while (Serial.available() > 0) {
    snap.receiveByte(Serial.read());
  }
}



int notImplemented(int cmd)
{
  digitalWrite(DEBUG_LED_PIN, HIGH);
}

  
int currentPos = 0;
int currentHeat = 0;
int requestedHeat = 0;
int temperatureLimit = 0;

void executeCommands()
{
  
digitalWrite(10, 1);
  byte cmd = snap.getByte(0);
	
  switch (cmd) {
      
  case CMD_VERSION:
    snap.sendReply();
    snap.sendDataByte(CMD_VERSION);    // Response type 0
    snap.sendDataByte(VERSION_MAJOR);  // Minor
    snap.sendDataByte(VERSION_MINOR);  // Major
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
    requestedHeat = snap.getInt(1);
    temperatureLimit = snap.getInt(3);
    break;

  case CMD_GETTEMP:
    if (currentHeat < requestedHeat)
      currentHeat++;
    else if (currentHeat > requestedHeat)
      currentHeat--;
      
    snap.sendReply();
    snap.sendDataByte(CMD_GETTEMP); 
    snap.sendDataInt(currentHeat);
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
    // not implemented
    notImplemented(cmd);
    break;
    
  default:
    notImplemented(cmd);
    break;
					
  }
  snap.releaseLock();
}

