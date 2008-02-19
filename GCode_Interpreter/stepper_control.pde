void dwell(int time)
{
	delay(time); 
}

void ddaMove()
{
	int delay;
	int max_delta = 0;
	
	if (z.delta != 0)
		delay = z.stepper.getMicros();
	else
		delay = min(x.stepper.getMicros(), y.stepper.getMicros());
	
	//figure out our deltas
	max_delta = max(x.delta, max_delta);
	max_delta = max(y.delta, max_delta);
	max_delta = max(z.delta, max_delta);

	//init stuff.
	x.initDDA(max_delta);
	y.initDDA(max_delta);
	z.initDDA(max_delta);
	
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
			
		delayMicroseconds(delay);
	}
	while (x.can_step || y.can_step || z.can_step);
}
