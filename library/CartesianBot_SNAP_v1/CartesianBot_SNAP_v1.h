/*
	CartesianBot_SNAP_v1.h - Cartesian Bot SNAP Communications library for Arduino

	This library implements/emulates v1 of the RepRap LinearAxis communications protocol.
	Technically, the protocol was designed around the idea of one board per axis, each with
	its own address and microcontroller.  This library emulates 3 of these boards: X, Y, and Z
	on one Arduino.
	
	More information on the protocol here: http://reprap.org/bin/view/Main/StepperMotorController

	Memory Usage Estimate: 11 bytes + CartesianBot

	History:
	* (0.1) Created intial library by Zach Smith.
    * (0.2) Optimized library for better performance by Zach Smith.
	* (0.3) Rewrote and refactored all code.  Fixed major interrupt bug by Zach Smith.
    * (0.4) Changed timer/speed setting to properly emulate PICs. Also fixed forward/reverse commands by Zach Smith.

	License: GPL v2.0
*/

#ifndef CARTESIAN_BOT_SNAP_V1_H
#define CARTESIAN_BOT_SNAP_V1_H

//all our includes.
#include <SNAP.h>
#include <RepStepper.h>
#include <LinearAxis.h>
#include <CartesianBot.h>

//this guy actually processes the v1 SNAP commands.
void setup_cartesian_bot_snap_v1();
void process_cartesian_bot_snap_commands_v1();
void cartesian_bot_snap_v1_loop();

//these are our functions for handling the interrupt.
void interruptDDA();
void interruptSeek();
void interruptHomeReset();
void interruptFindMin();
void interruptFindMax();
void interruptRun();

//notification functions to let the host know whats up.
void notifyHomeReset(byte to, byte from);
void notifyCalibrate(byte to, byte from, int position);
void notifySeek(byte to, byte from, int position);
void notifyDDA(byte to, byte from, int position);

extern CartesianBot bot;

//
// Version information
//
#define VERSION_MAJOR 1
#define VERSION_MINOR 0
#define HOST_ADDRESS 0
#define DEVICE_TYPE 0

//
// Linear Axis commands
//
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
#define CMD_DEVICE_TYPE 255


// Addresses for our linear axes.
#define X_ADDRESS 2
#define Y_ADDRESS 3
#define Z_ADDRESS 4

//modes for the cartesian bot.
#define MODE_PAUSE 0
#define MODE_SEEK 1
#define MODE_DDA 2
#define MODE_HOMERESET 3
#define MODE_FIND_MIN 4
#define MODE_FIND_MAX 5
#define MODE_RUN 6

// sync mode declarations
#define sync_none 0
#define sync_seek 1
#define sync_inc  2
#define sync_dec  3

// Making this inline saves about 30 bytes (AB)...

inline unsigned long picTimerSimulate(unsigned char fromSnap)
{
	return (256 - fromSnap) * 4096UL; 
}

#endif
