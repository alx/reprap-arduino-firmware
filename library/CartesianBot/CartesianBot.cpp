
#include "WConstants.h"
#include "CartesianBot.h"

CartesianBot::CartesianBot(
	char x_id, int x_steps, byte x_dir_pin, byte x_step_pin, byte x_min_pin, byte x_max_pin, byte x_enable_pin,
	char y_id, int y_steps, byte y_dir_pin, byte y_step_pin, byte y_min_pin, byte y_max_pin, byte y_enable_pin,
	char z_id, int z_steps, byte z_dir_pin, byte z_step_pin, byte z_min_pin, byte z_max_pin, byte z_enable_pin
) : x(x_id, x_steps, x_dir_pin, x_step_pin, x_min_pin, x_max_pin, x_enable_pin), y(y_id, y_steps, y_dir_pin, y_step_pin, y_min_pin, y_max_pin, y_enable_pin), z(z_id, z_steps, z_dir_pin, z_step_pin, z_min_pin, z_max_pin, z_enable_pin)
{
	this->setupTimerInterrupt();
	this->disableTimerInterrupt();
	this->clearQueue();
}

byte CartesianBot::getQueueSize()
{
	return this->size;
}

bool CartesianBot::isQueueEmpty()
{
	return (this->size == 0);
}

bool CartesianBot::isQueueFull()
{
	return (this->size == POINT_QUEUE_SIZE);
}

bool CartesianBot::queuePoint(Point &point)
{
	if (this->isQueueFull())
		return false;
		
	//queue up our point (at the old tail spot)!
	this->point_queue[this->tail] = point;
	
	//keep track
	this->size++;

	//move our tail to the next tail location
	this->tail++;
	if (this->tail == POINT_QUEUE_SIZE)
		this->tail = 0;
	
	return true;
}

struct Point CartesianBot::unqueuePoint()
{
	//save our old head.
	byte oldHead = this->head;
	
	//move our head to the head for next time.
	this->head++;
	if (this->head == POINT_QUEUE_SIZE)
		this->head = 0;

	//keep track.
	this->size--;
			
	return this->point_queue[oldHead];
}

void CartesianBot::clearQueue()
{
	this->head = 0;
	this->tail = 0;
	this->size = 0;
}

void CartesianBot::getNextPoint()
{
	Point p;
	
	if (!this->isQueueEmpty())
	{
		p = this->unqueuePoint();

		x.setTarget(p.x);
		y.setTarget(p.y);
		z.setTarget(p.z);
	}
	else
	{
		x.setTarget(x.current);
		y.setTarget(y.current);
		z.setTarget(z.current);
	}
}

void CartesianBot::calculateDDA()
{
	//let us do the maths before stepping.
	this->disableTimerInterrupt();
	
	//what is the biggest one?
	this->max_delta = max(x.delta, y.delta);
	this->max_delta = max(this->max_delta, z.delta);

	//calculate speeds for each axis.
	x.initDDA(this->max_delta);
	y.initDDA(this->max_delta);
	z.initDDA(this->max_delta);
}

bool CartesianBot::atHome()
{
	return (x.atMin() && y.atMin() && z.atMin());
}

void CartesianBot::readState()
{
	x.readState();
	y.readState();
	z.readState();
}

bool CartesianBot::atTarget()
{
	return x.atTarget() && y.atTarget() && z.atTarget();
}

void CartesianBot::setupTimerInterrupt()
{
	//clear the registers
	TCCR1A = 0;
	TCCR1B = 0;
	TCCR1C = 0;
	TIMSK1 = 0;
	
	//waveform generation = 0100 = CTC
	TCCR1B &= ~(1<<WGM13);
	TCCR1B |=  (1<<WGM12);
	TCCR1A &= ~(1<<WGM11); 
	TCCR1A &= ~(1<<WGM10);

	//output mode = 00 (disconnected)
	TCCR1A &= ~(1<<COM1A1); 
	TCCR1A &= ~(1<<COM1A0);
	TCCR1A &= ~(1<<COM1B1); 
	TCCR1A &= ~(1<<COM1B0);

	//start off with a slow frequency.
	this->setTimerResolution(4);
	this->setTimerCeiling(65535);
}

void CartesianBot::enableTimerInterrupt()
{
	//reset our timer to 0 for reliable timing TODO: is this needed?
	//TCNT1 = 0;

	//then enable our interrupt!
	TIMSK1 |= (1<<OCIE1A);
}

void CartesianBot::disableTimerInterrupt()
{
	TIMSK1 &= ~(1<<ICIE1);
	TIMSK1 &= ~(1<<OCIE1A);
}

void CartesianBot::setTimerResolution(byte r)
{
	//here's how you figure out the tick size:
	// 1000000 / ((16000000 / prescaler))
	// 1000000 = microseconds in 1 second
	// 16000000 = cycles in 1 second
	// prescaler = your prescaler

	// no prescaler == 0.0625 usec tick
	if (r == 0)
	{
		// 001 = clk/1
		TCCR1B &= ~(1<<CS12);
		TCCR1B &= ~(1<<CS11);
		TCCR1B |=  (1<<CS10);
	}	
	// prescale of /8 == 0.5 usec tick
	else if (r == 1)
	{
		// 010 = clk/8
		TCCR1B &= ~(1<<CS12);
		TCCR1B |=  (1<<CS11);
		TCCR1B &= ~(1<<CS10);
	}
	// prescale of /64 == 4 usec tick
	else if (r == 2)
	{
		// 011 = clk/64
		TCCR1B &= ~(1<<CS12);
		TCCR1B |=  (1<<CS11);
		TCCR1B |=  (1<<CS10);
	}
	// prescale of /256 == 16 usec tick
	else if (r == 3)
	{
		// 100 = clk/256
		TCCR1B |=  (1<<CS12);
		TCCR1B &= ~(1<<CS11);
		TCCR1B &= ~(1<<CS10);
	}
	// prescale of /1024 == 64 usec tick
	else
	{
		// 101 = clk/1024
		TCCR1B |=  (1<<CS12);
		TCCR1B &= ~(1<<CS11);
		TCCR1B |=  (1<<CS10);
	}
}

void CartesianBot::setTimerCeiling(unsigned int c)
{
	OCR1A = c;
}

void CartesianBot::setTimer(unsigned long delay)
{
	// delay is the delay between steps in 4 microsecond ticks.
	//
	// we break it into 5 different resolutions based on the delay. 
	// then we set the resolution based on the size of the delay.
	// we also then calculate the timer ceiling required. (ie what the counter counts to)
	// the result is the timer counts up to the appropriate time and then fires an interrupt.

	this->disableTimerInterrupt();
	this->setTimerCeiling(this->getTimerCeiling(delay));
	this->setTimerResolution(this->getTimerResolution(delay));
	//this->enableTimerInterrupt();
}

unsigned int CartesianBot::getTimerCeiling(unsigned long delay)
{
	// our slowest speed at our highest resolution ( (2^16-1) * 0.0625 usecs = 4095 usecs)
	if (delay <= 65535L)
		return (delay & 0xffff);
	// our slowest speed at our next highest resolution ( (2^16-1) * 0.5 usecs = 32767 usecs)
	else if (delay <= 524280L)
		return ((delay / 8) & 0xffff);
	// our slowest speed at our medium resolution ( (2^16-1) * 4 usecs = 262140 usecs)
	else if (delay <= 4194240L)
		return ((delay / 64) & 0xffff);
	// our slowest speed at our medium-low resolution ( (2^16-1) * 16 usecs = 1048560 usecs)
	else if (delay <= 16776960L)
		return (delay / 256);
	// our slowest speed at our lowest resolution ((2^16-1) * 64 usecs = 4194240 usecs)
	else if (delay <= 67107840L)
		return (delay / 1024);
	//its really slow... hopefully we can just get by with super slow.
	else
		return 65535;
}

byte CartesianBot::getTimerResolution(unsigned long delay)
{
	// these also represent frequency: 1000000 / delay / 2 = frequency in hz.
	
	// our slowest speed at our highest resolution ( (2^16-1) * 0.0625 usecs = 4095 usecs (4 millisecond max))
	// range: 8Mhz max - 122hz min
	if (delay <= 65535L)
		return 0;
	// our slowest speed at our next highest resolution ( (2^16-1) * 0.5 usecs = 32767 usecs (32 millisecond max))
	// range:1Mhz max - 15.26hz min
	else if (delay <= 524280L)
		return 1;
	// our slowest speed at our medium resolution ( (2^16-1) * 4 usecs = 262140 usecs (0.26 seconds max))
	// range: 125Khz max - 1.9hz min
	else if (delay <= 4194240L)
		return 2;
	// our slowest speed at our medium-low resolution ( (2^16-1) * 16 usecs = 1048560 usecs (1.04 seconds max))
	// range: 31.25Khz max - 0.475hz min
	else if (delay <= 16776960L)
		return 3;
	// our slowest speed at our lowest resolution ((2^16-1) * 64 usecs = 4194240 usecs (4.19 seconds max))
	// range: 7.812Khz max - 0.119hz min
	else if (delay <= 67107840L)
		return 4;
	//its really slow... hopefully we can just get by with super slow.
	else
		return 4;
}
