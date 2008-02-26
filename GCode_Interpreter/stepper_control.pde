
void ddaMove(long micro_delay)
{
	long max_delta = 0;
	long x_counter = 0;
	long y_counter = 0;
	long z_counter = 0;
	
	//figure out our deltas
	max_delta = max(x.delta, max_delta);
	max_delta = max(y.delta, max_delta);
	max_delta = max(z.delta, max_delta);

	//init stuff.
	x_counter = -max_delta/2;
	y_counter = -max_delta/2;
	z_counter = -max_delta/2;
	
	//do our DDA line!
	do
	{
		extruder.manageTemperature();
		x.readState();
		y.readState();
		z.readState();

		if (x.can_step)
		{
			x_counter += x.delta;
			if (x_counter > 0)
			{
				x.doStep();
				x_counter -= max_delta;
			}
		}
		
		if (y.can_step)
		{
			y_counter += y.delta;
			if (y_counter > 0)
			{
				y.doStep();
				y_counter -= max_delta;
			}
		}
		
		if (z.can_step)
		{
			z_counter += z.delta;
			if (z_counter > 0)
			{
				z.doStep();
				z_counter -= max_delta;
			}
		}
		
		delayMicroseconds(micro_delay);
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
