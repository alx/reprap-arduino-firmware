/*
	SNAP.h - RepRap SNAP Communications library for Arduino

	This library implements easy SNAP based communication with the RepRap host software
	with easy commands to enable receiving, sending, and passing along SNAP messages.

	History:
	* (0.1) Ported from PIC library by Zach Smith.
	* (0.2) Updated and fixed by the guys from Metalab in Austra (kintel and wizard23)
	* (0.3) Rewrote and refactored all code.  Added separate buffers and variables for Rx/Tx by Zach Smith.	
	
	License: GPL v2.0
*/

#ifndef SNAP_h
#define SNAP_h

// include types & constants of Wiring core API
#include "WConstants.h"
#include "HardwareSerial.h"

//how many devices we have on this meta device
#define MAX_DEVICE_COUNT 5		// size of our array to store virtual addresses
#define TX_BUFFER_SIZE 16		// Transmit buffer size.
#define RX_BUFFER_SIZE 16		// Receive buffer size.
#define HOST_ADDRESS 0			// address of the host.

//our sync packet value.
#define SNAP_SYNC 0x54

//The defines below are for error checking and such.
//Bit0 is for serialError-flag for checking if an serial error has occured,
//  if set, we will reset the communication
//Bit1 is set if we are currently transmitting a message, that means bytes of 
//  a message have been put in the transmitBuffer, but the message is not 
//  finished.
//Bit2 is set if we are currently building a send-message
//Bit3 is set if we are busy with the last command and have to abort the message
//Bit4 is set when we have a wrong uartState
//Bit5 is set when we receive a wrong byte
//Bit6 is set if we have to acknowledge a received message
//Bit7 is set if we have received a message for local processing
#define serialErrorBit          B00000001
#define inTransmitMsgBit        B00000010
#define inSendQueueMsgBit       B00000100
#define msgAbortedBit           B00001000
#define wrongStateErrorBit      B00010000
#define wrongByteErrorBit       B00100000
#define ackRequestedBit         B01000000
#define processingLockBit       B10000000

//these are the states for processing a packet.
enum SNAP_states
{
	SNAP_idle = 0x30,
	SNAP_haveSync,
	SNAP_haveHDB2,
	SNAP_haveHDB1,
	SNAP_haveDAB,
	SNAP_readingData,
	SNAP_dataComplete,

	// The *Pass states below represent states where
	// we should just be passing the data on to the next node.
	// This is either because we bailed out, or because the
	// packet wasn't destined for us.
	SNAP_haveHDB2Pass,
	SNAP_haveHDB1Pass,
	SNAP_haveDABPass,
	SNAP_readingDataPass
};

class SNAP
{
	public:
		SNAP();

		void begin(long baud);
		void addDevice(byte b);

		void receivePacket();
		void receiveByte(byte b);
		bool packetReady();
		
		byte getDestination();
		byte getByte(byte index);
		int getInt(byte index); // get 16 bits

		void startMessage(byte to, byte from);
		void sendDataByte(byte c);
		void sendDataInt(int data);
		void sendDataLong(long data);
		void sendMessage();

		void debug();

		void releaseLock();

	private:
		void receiveError();
		bool hasDevice(byte b);
		void transmit(byte c);
		
		//our crc functions.
		byte computeCRC(byte b, byte crc);
		byte computeRxCRC(byte c);
		byte computeTxCRC(byte c);

		//these are variables for the packet we're currently receiving.
		byte rxState;				       // Current SNAP packet state
		byte rxFlags;                      // flags for checking status of the serial-communication
		byte rxHDB1;                       // 1st header byte
		byte rxHDB2;                       // 2nd header byte
		byte rxLength;                     // Length of packet being received
		byte rxDestAddress;                // Destination of packet being received (us)
		byte rxSourceAddress;              // Source of packet being received
		byte rxCRC;                        // Incrementally calculated CRC value
		byte rxBufferIndex;                // Current receive buffer index
		byte rxBuffer[RX_BUFFER_SIZE];     // Receive buffer
           
		//these are the variables for the packet we're currently transmitting.
		byte txHDB2;                      // 2nd header byte (1st header byte doesnt change!)
		byte txLength;                    // transmit packet length
		byte txDestAddress;               // transmit packet destination
		byte txSourceAddress;             // transmit packet source (us)
		byte txCRC;                       // incrementally calculated CRC value
		byte txBuffer[TX_BUFFER_SIZE];    // Last packet data, for auto resending on a NAK

		// the address of our internal device sending message
		byte deviceAddresses[MAX_DEVICE_COUNT];
		byte deviceCount;
};

//global variable declaration.
extern SNAP snap;

#endif
