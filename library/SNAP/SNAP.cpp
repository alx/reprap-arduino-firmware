
#include "SNAP.h"
#include "WConstants.h"

SNAP::SNAP()
{
	//init our rx values
	this->rxState = SNAP_idle;
	this->rxFlags = 0;
	this->rxHDB1 = 0;
	this->rxHDB2 = 0;
	this->rxLength = 0;
	this->rxDestAddress = 0;
	this->rxSourceAddress = 0;
	this->rxCRC = 0;
	this->rxBufferIndex = 0;
	
	//clear our rx buffer.
	for (byte i=0; i<RX_BUFFER_SIZE; i++)
		this->rxBuffer[i] = 0;
		
	//init our tx values
	this->txDestAddress = 0;
	this->txSourceAddress = 0;
	this->txLength = 0;
	this->txHDB2 = 0;
	this->txCRC = 0;
	
	//clear our tx buffer.
	for (byte i=0; i<TX_BUFFER_SIZE; i++)
		this->txBuffer[i] = 0;
	
	//init our device count.
	this->deviceCount = 0;
}

void SNAP::begin(long baud)
{
	Serial.begin(baud);
}

void SNAP::receivePacket()
{
	byte cmd;

	while (Serial.available() > 0 && !this->packetReady())
	{
		cmd = Serial.read();
		this->receiveByte(cmd);
	}
}

void SNAP::receiveByte(byte c)
{
	if (this->rxFlags & serialErrorBit)
	{
		this->receiveError();
		return;
	}

  
	switch (this->rxState)
	{
		case SNAP_idle:
			// In the idle state, we wait for a sync byte.  If none is
			// received, we remain in this state.
			if (c == SNAP_SYNC)
			{
				this->rxState = SNAP_haveSync;
				this->rxFlags &= ~msgAbortedBit; //clear
				
				//this->debug();
				//Serial.println("sync");
				
			}
			//pass it along anyway.
			else
				this->transmit(c);
		break;

  		case SNAP_haveSync:
			// In this state we are waiting for header definition bytes. First
			// HDB2.  We currently insist that all packets meet our expected
			// format which is 1 byte destination address, 1 byte source
			// address, and no protocol specific bytes.  The ACK/NAK bits may
			// be anything.
			this->rxHDB2 = c;
			if ((c & B11111100) != B01010000)
			{
				// Unsupported header.  Drop it an reset
				this->rxFlags |= serialErrorBit;  //set serialError
				this->rxFlags |= wrongByteErrorBit; 
				this->receiveError();
			}
			// All is well
			else
			{
				//do we want ack?
				if ((c & B00000011) == B00000001)
					this->rxFlags |= ackRequestedBit;  //set ackRequested-Bit
				else
					this->rxFlags &= ~ackRequestedBit; //clear
				this->rxCRC = 0;
				
				this->computeRxCRC(c);

				this->rxState = SNAP_haveHDB2;
				
				//this->debug();
				//Serial.println("hdb2");	
			}
		break;

		case SNAP_haveHDB2:
			// For HDB1, we insist on high bits are 0011 and low bits are the length 
			// of the payload.
			this->rxHDB1 = c;
			if ((c & B11110000) != B00110000)
			{
				this->rxFlags |= serialErrorBit;  //set serialError
				this->rxFlags |= wrongByteErrorBit; 
				this->receiveError();
			}
			else
			{
				// FIXME: This doesn't correspond to the SNAP specs since the length
				// should become non-linear after 8 bytes. The original reprap code
				// does the same thing though. kintel 20071120.
				this->rxLength = c & 0x0f;
				
				if (this->rxLength > RX_BUFFER_SIZE)
					this->rxLength = RX_BUFFER_SIZE;

				this->computeRxCRC(c);
				
				this->rxState = SNAP_haveHDB1;
				
				//this->debug();
				//Serial.println("hdb1");	
			}
		break;

		case SNAP_haveHDB1:
			// We should be reading the destination address now
			if (!this->hasDevice(c))
			{
				//this->debug();
				//Serial.print("no device:");
				//Serial.println(c);
				
				this->transmit(SNAP_SYNC);
				this->transmit(this->rxHDB2);
				this->transmit(this->rxHDB1);
				this->transmit(c);
				this->rxState = SNAP_haveDABPass;
				this->rxFlags &= ~ackRequestedBit; //clear
				this->rxFlags |= inTransmitMsgBit; 
			}
			else
			{
				//save our address, as we may have multiple addresses on one arduino.
				this->rxDestAddress = c;
                       
				this->computeRxCRC(c);
				this->rxState = SNAP_haveDAB;
				
				//this->debug();
				//Serial.println("got dest");	
			}
		break;

		case SNAP_haveDAB:
			// We should be reading the source address now
			if (this->hasDevice(c))
			{
				// If we receive a packet from ourselves, that means it went
				// around the ring and was never picked up, ie the device we
				// sent to is off-line or unavailable.

				// FIXME: Deal with this situation
				this->receiveError();
			}
          
	    	/*
			// this may not be required.... we check this flag before accepting new packets...
			if (this->rxFlags & processingLockBit)
			{
				this->rxCRC = 0;

				//we have not finished the last order, reject (send a NAK)
				this->transmit(SNAP_SYNC);     
				this->transmit(computeRxCRC(B01010011));        //HDB2: NAK
				this->transmit(computeRxCRC(B00110000));        // HDB1: 0 bytes, with 8 bit CRC
				this->transmit(computeRxCRC(this->rxSourceAddress));        // Return to sender
				this->transmit(computeRxCRC(this->rxDestAddress));        // From us
				this->transmit(this->rxCRC);  // CRC

				this->rxFlags &= ~ackRequestedBit; //clear
				this->rxFlags |= msgAbortedBit; //set

				this->rxState = SNAP_idle;
			}
			*/

			this->rxSourceAddress = c;
			this->rxBufferIndex = 0;
			this->computeRxCRC(c);
			
			//this->debug();
			//Serial.println("got source");	

			this->rxState = SNAP_readingData;
		break;

		case SNAP_readingData:
			rxBuffer[rxBufferIndex] = c;
			rxBufferIndex++;

			this->computeRxCRC(c);

			if (rxBufferIndex == this->rxLength)
				this->rxState = SNAP_dataComplete;
		break;

		case SNAP_dataComplete:
			// We should be receiving a CRC after data, and it
			// should match what we have already computed
			{
				//this->debug();
				//Serial.println("data done");	
				
				byte hdb2 = B01010000; // 1 byte addresses

				if (c == this->rxCRC)
				{
					// All is good, so process the command.  Rather than calling the
					// appropriate function directly, we just set a flag to say
					// something is ready for processing.  Then in the main loop we
					// detect this and process the command.  This allows further
					// comms processing (such as passing other tokens around the
					// ring) while we're actioning the command.

					hdb2 |= B00000010;
					this->rxFlags |= processingLockBit;  //set processingLockBit
				}
				// CRC mismatch, so we will NAK the packet
				else
					hdb2 |= B00000011;
                 
				// Send ACK or NAK back to source
				if (this->rxFlags & ackRequestedBit)
				{
					this->transmit(SNAP_SYNC);
					this->rxCRC = 0;
					this->transmit(this->computeRxCRC(hdb2));
					this->transmit(this->computeRxCRC(B00110000));        // HDB1: 0 bytes, with 8 bit CRC
					this->transmit(this->computeRxCRC(this->rxSourceAddress));        // Return to sender
					this->transmit(this->computeRxCRC(this->rxDestAddress));        // From us
					this->transmit(this->rxCRC);                                          // CRC
					this->rxFlags &= ~ackRequestedBit;                        // clear
				}
			}
         
			this->rxState = SNAP_idle;
		break;

		case SNAP_haveDABPass:
			//this->debug();
			//Serial.println("dab pass");
		
			this->transmit(c);  // We will be reading source addr; pass it on

			// Increment data length by 1 so that we just copy the CRC
			// at the end as well.
			this->rxLength++;

			this->rxState = SNAP_readingDataPass;
		break;

		case SNAP_readingDataPass:

//			this->debug();
//			Serial.println("data pass");

			this->transmit(c);  // This is a data byte; pass it on
			if (this->rxLength > 1)
				this->rxLength--;
			else
			{
				//init our rx values
				this->rxState = SNAP_idle;
				this->rxFlags = 0;
				this->rxHDB1 = 0;
				this->rxHDB2 = 0;
				this->rxLength = 0;
				this->rxDestAddress = 0;
				this->rxSourceAddress = 0;
				this->rxCRC = 0;
				this->rxBufferIndex = 0;

				//clear our rx buffer.
				for (byte i=0; i<RX_BUFFER_SIZE; i++)
					this->rxBuffer[i] = 0;
			}
		break;
                        
		default:
			//this->debug();
			//Serial.println("no state!");
		
			this->rxFlags |= serialErrorBit;  //set serialError
			this->rxFlags |= wrongStateErrorBit;  
			this->receiveError();
	}
}

void SNAP::receiveError()
{
	//init our rx values
	this->rxState = SNAP_idle;
	this->rxFlags = 0;
	this->rxHDB1 = 0;
	this->rxHDB2 = 0;
	this->rxLength = 0;
	this->rxDestAddress = 0;
	this->rxSourceAddress = 0;
	this->rxCRC = 0;
	this->rxBufferIndex = 0;
	
	//clear our rx buffer.
	for (byte i=0; i<RX_BUFFER_SIZE; i++)
		this->rxBuffer[i] = 0;
		
	//this->debug();
	//Serial.println("error");	
}

void SNAP::addDevice(byte c)
{
	if (this->deviceCount >= MAX_DEVICE_COUNT)
		return;
            
	this->deviceAddresses[this->deviceCount] = c;
	this->deviceCount++;
}

void SNAP::startMessage(byte to, byte from)
{
	//this->debug();
	//Serial.println("msg start");
	
	//initialize our addresses.
	this->txDestAddress = to;
	this->txSourceAddress = from;

	//initalize our variables.
	this->txLength = 0;
	this->txHDB2 = 0;
	this->txCRC = 0;
	
	//clear our buffer.
	for (byte i=0; i<TX_BUFFER_SIZE; i++)
		this->txBuffer[i] = 0;
}

/*!
  High level routine that queues a byte during construction of a packet.
*/
void SNAP::sendDataByte(byte c)
{
	// Put byte into packet sending buffer.  Don't calculated CRCs
	// yet as we don't have complete information.

	// Drop if trying to send too much
	if (this->txLength >= TX_BUFFER_SIZE)
		return;

	this->txBuffer[this->txLength] = c;
	this->txLength++;
}

void SNAP::sendDataInt(int i)
{
	this->sendDataByte(i & 0xff);
	this->sendDataByte(i >> 8);
}

void SNAP::sendDataLong(long i)
{
	this->sendDataByte(i & 0xff);
	this->sendDataByte(i >> 8);
	this->sendDataByte(i >> 16);
	this->sendDataByte(i >> 24);
}


/*!
  Create headers and synchronously transmit the message.
*/
void SNAP::sendMessage()
{
	//this->debug();
	//Serial.println("sendmsg");
	
	this->txCRC = 0;

	//here is our header.
	this->transmit(SNAP_SYNC);
	this->transmit(this->computeTxCRC(B01010001));                   // HDB2 - Request ACK

	// FIXME: This doesn't correspond to the SNAP specs since the length
	// should become non-linear after 8 bytes. The original reprap code
	// does the same thing though. kintel 20071120.
	this->transmit(this->computeTxCRC(B00110000 | this->txLength));  // HDB1 
	this->transmit(this->computeTxCRC(this->txDestAddress));         // Destination
	this->transmit(this->computeTxCRC(this->txSourceAddress));           // Source (us)

	//payload.
	for (byte i=0; i<this->txLength; i++)
		this->transmit(this->computeTxCRC(this->txBuffer[i]));

	this->transmit(this->txCRC);
}

bool SNAP::packetReady()
{	
	return (this->rxFlags & processingLockBit);
}

/*!
  Must be manually called by the main loop when the message payload
  has been consumed.
*/
void SNAP::releaseLock()
{
	//init our rx values
	this->rxState = SNAP_idle;
	this->rxFlags = 0;
	this->rxHDB1 = 0;
	this->rxHDB2 = 0;
	this->rxLength = 0;
	this->rxDestAddress = 0;
	this->rxSourceAddress = 0;
	this->rxCRC = 0;
	this->rxBufferIndex = 0;
	
	//clear our rx buffer.
	for (byte i=0; i<RX_BUFFER_SIZE; i++)
		this->rxBuffer[i] = 0;
}

bool SNAP::hasDevice(byte c)
{
	for (int i=0; i<this->deviceCount; i++)
	{
		if (this->deviceAddresses[i] == c)
			return true;
	}

	return false;
}

void SNAP::debug()
{
	Serial.print('d');
}

void SNAP::transmit(byte c)
{
  Serial.print(c, BYTE);
}

/*!
  Incrementally adds b to crc computation and updates crc.
  returns \c.
*/
byte SNAP::computeCRC(byte b, byte crc)
{
	byte i = b ^ crc;

	crc = 0;

	if (i & 1) crc ^= 0x5e;
	if (i & 2) crc ^= 0xbc;
	if (i & 4) crc ^= 0x61;
	if (i & 8) crc ^= 0xc2;
	if (i & 0x10) crc ^= 0x9d;
	if (i & 0x20) crc ^= 0x23;
	if (i & 0x40) crc ^= 0x46;
	if (i & 0x80) crc ^= 0x8c;

	return crc;
}

byte SNAP::computeRxCRC(byte b)
{
	this->rxCRC = this->computeCRC(b, this->rxCRC);
	
	return b;
}

byte SNAP::computeTxCRC(byte b)
{
	this->txCRC = this->computeCRC(b, this->txCRC);

	return b;
}

byte SNAP::getDestination()
{
	return this->rxDestAddress;
}

byte SNAP::getByte(byte index)
{
	return this->rxBuffer[index];
}

int SNAP::getInt(byte index)
{
	return (this->rxBuffer[index+1] << 8) + this->rxBuffer[index];
}

// Preinstantiate Objects
SNAP snap = SNAP();
