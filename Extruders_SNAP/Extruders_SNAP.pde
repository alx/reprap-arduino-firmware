#include <SNAP.h>

#define VERSION_MAJOR 0
#define VERSION_MINOR 1
#define HOST_ADDRESS 0

//
// Extruder commands
//
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

SNAP snap;

void setup()
{
  Serial.begin(19200);
  snap.addDevice(8);
  for (byte i=8;i<14;i++) {
    pinMode(i, OUTPUT);
    digitalWrite(i, 0);
  }
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

void executeCommands()
{
  
digitalWrite(10, 1);
  byte cmd = snap.getByte(0);
	
  switch (cmd) {
  case CMD_VERSION:
    digitalWrite(11, 1);
    snap.sendReply();
    snap.sendDataByte(CMD_VERSION);    // Response type 0
    snap.sendDataByte(VERSION_MAJOR);  // Minor
    snap.sendDataByte(VERSION_MINOR);  // Major
    snap.endMessage();
    break;
  }
  snap.releaseLock();
}

