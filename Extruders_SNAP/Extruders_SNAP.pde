#include <SNAP.h>

#define VERSION_MAJOR 0
#define VERSION_MINOR 1
#define HOST_ADDRESS 0

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

