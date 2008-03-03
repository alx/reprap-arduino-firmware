
void ddaMove(long micro_delay)
{
	//init our variables
	long millis = micro_delay/1000;
	long max_delta = 0;
	
	//figure out our deltas
	max_delta = max(x.delta, max_delta);
	max_delta = max(y.delta, max_delta);
	max_delta = max(z.delta, max_delta);

	//init stuff.
	x.counter = -max_delta/2;
	y.counter = -max_delta/2;
	z.counter = -max_delta/2;
	
	//do our DDA line!
	do
	{
		extruder.manageTemperature();
		x.readState();
		y.readState();
		z.readState();

		if (x.can_step)
			x.ddaStep(max_delta);
		
		if (y.can_step)
			y.ddaStep(max_delta);
		
		if (z.can_step)
			z.ddaStep(max_delta);
		
		if (micro_delay <= 16383)
			delayMicroseconds(micro_delay);
		else
			delay(millis);
	}
	while (x.can_step || y.can_step || z.can_step);
}

long getMaxSpeed()
{
	//calculate our speed. assume we're moving at max first.
	if (z.delta != 0)
		return z.stepper.getMicros();
	else
		return min(x.stepper.getMicros(), y.stepper.getMicros());
}
