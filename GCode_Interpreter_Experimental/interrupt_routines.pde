//these routines provide an easy interface for controlling timer1 interrupts

//this handles the timer interrupt event
SIGNAL(SIG_OUTPUT_COMPARE1A)
{
	//increment/decrement our error variable.
	//the manage extruder function will handle the motor control
	if (extruder_direction == EXTRUDER_FORWARD)
		extruder_error--;
	else
		extruder_error++;
}

void enableTimer1Interrupt()
{
	//enable our interrupt!
	TIMSK1 |= (1<<OCIE1A);
}

void disableTimer1Interrupt()
{
	TIMSK1 &= ~(1<<ICIE1);
	TIMSK1 &= ~(1<<OCIE1A);
}

void setTimer1Resolution(byte r)
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

void setTimer1Ceiling(unsigned int c)
{
	OCR1A = c;
}


unsigned int getTimer1Ceiling(unsigned long ticks)
{
	// our slowest speed at our highest resolution ( (2^16-1) * 0.0625 usecs = 4095 usecs)
	if (ticks <= 65535L)
		return (ticks & 0xffff);
	// our slowest speed at our next highest resolution ( (2^16-1) * 0.5 usecs = 32767 usecs)
	else if (ticks <= 524280L)
		return ((ticks / 8) & 0xffff);
	// our slowest speed at our medium resolution ( (2^16-1) * 4 usecs = 262140 usecs)
	else if (ticks <= 4194240L)
		return ((ticks / 64) & 0xffff);
	// our slowest speed at our medium-low resolution ( (2^16-1) * 16 usecs = 1048560 usecs)
	else if (ticks <= 16776960L)
		return (ticks / 256);
	// our slowest speed at our lowest resolution ((2^16-1) * 64 usecs = 4194240 usecs)
	else if (ticks <= 67107840L)
		return (ticks / 1024);
	//its really slow... hopefully we can just get by with super slow.
	else
		return 65535;
}

byte getTimer1Resolution(unsigned long ticks)
{
	// these also represent frequency: 1000000 / ticks / 2 = frequency in hz.
	
	// our slowest speed at our highest resolution ( (2^16-1) * 0.0625 usecs = 4095 usecs (4 millisecond max))
	// range: 8Mhz max - 122hz min
	if (ticks <= 65535L)
		return 0;
	// our slowest speed at our next highest resolution ( (2^16-1) * 0.5 usecs = 32767 usecs (32 millisecond max))
	// range:1Mhz max - 15.26hz min
	else if (ticks <= 524280L)
		return 1;
	// our slowest speed at our medium resolution ( (2^16-1) * 4 usecs = 262140 usecs (0.26 seconds max))
	// range: 125Khz max - 1.9hz min
	else if (ticks <= 4194240L)
		return 2;
	// our slowest speed at our medium-low resolution ( (2^16-1) * 16 usecs = 1048560 usecs (1.04 seconds max))
	// range: 31.25Khz max - 0.475hz min
	else if (ticks <= 16776960L)
		return 3;
	// our slowest speed at our lowest resolution ((2^16-1) * 64 usecs = 4194240 usecs (4.19 seconds max))
	// range: 7.812Khz max - 0.119hz min
	else if (ticks <= 67107840L)
		return 4;
	//its really slow... hopefully we can just get by with super slow.
	else
		return 4;
}

void setTimer1Ticks(unsigned long ticks)
{
	// ticks is the delay between interrupts in 4 microsecond ticks.
	//
	// we break it into 5 different resolutions based on the delay. 
	// then we set the resolution based on the size of the delay.
	// we also then calculate the timer ceiling required. (ie what the counter counts to)
	// the result is the timer counts up to the appropriate time and then fires an interrupt.

	//disableTimer1Interrupt();
	setTimer1Ceiling(getTimer1Ceiling(ticks));
	setTimer1Resolution(getTimer1Resolution(ticks));
}

void setupTimer1Interrupt()
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
	setTimer1Resolution(4);
	setTimer1Ceiling(65535);
}
