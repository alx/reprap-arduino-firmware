//init our variables
long max_delta;
long x_counter;
long y_counter;
long z_counter;
bool x_can_step;
bool y_can_step;
bool z_can_step;
int milli_delay;

void init_steppers()
{
	//init our points.
	current_units.x = 0.0;
	current_units.y = 0.0;
	current_units.z = 0.0;
	target_units.x = 0.0;
	target_units.y = 0.0;
	target_units.z = 0.0;
	
	pinMode(X_STEP_PIN, OUTPUT);
	pinMode(X_DIR_PIN, OUTPUT);
	pinMode(X_ENABLE_PIN, OUTPUT);
	pinMode(X_MIN_PIN, INPUT);
	pinMode(X_MAX_PIN, INPUT);
	
	pinMode(Y_STEP_PIN, OUTPUT);
	pinMode(Y_DIR_PIN, OUTPUT);
	pinMode(Y_ENABLE_PIN, OUTPUT);
	pinMode(Y_MIN_PIN, INPUT);
	pinMode(Y_MAX_PIN, INPUT);
	
	pinMode(Z_STEP_PIN, OUTPUT);
	pinMode(Z_DIR_PIN, OUTPUT);
	pinMode(Z_ENABLE_PIN, OUTPUT);
	pinMode(Z_MIN_PIN, INPUT);
	pinMode(Z_MAX_PIN, INPUT);
	
	//figure our stuff.
	calculate_deltas();
}

void dda_move(long micro_delay)
{
	//enable our steppers
	digitalWrite(X_ENABLE_PIN, HIGH);
	digitalWrite(Y_ENABLE_PIN, HIGH);
	digitalWrite(Z_ENABLE_PIN, HIGH);
	
	//figure out our deltas
	max_delta = max(delta_steps.x, delta_steps.y);
	max_delta = max(delta_steps.z, max_delta);

	//init stuff.
	long x_counter = -max_delta/2;
	long y_counter = -max_delta/2;
	long z_counter = -max_delta/2;
	
	//our step flags
	bool x_can_step = 0;
	bool y_can_step = 0;
	bool z_can_step = 0;
	
	if (micro_delay >= 16383)
		milli_delay = micro_delay / 1000;
	else
		milli_delay = 0;

/*	
	Serial.print("max:");
	Serial.println(max_delta, DEC);
	Serial.print("xd:");
	Serial.println(delta_steps.x, DEC);
	Serial.print("yd:");
	Serial.println(delta_steps.y, DEC);
	Serial.print("zd:");
	Serial.println(delta_steps.z, DEC);
	
	Serial.print("msec:");
	Serial.println(millis, DEC);
	Serial.print("usec:");
	Serial.println(micro_delay, DEC);
*/
	//do our DDA line!
	do
	{
		x_can_step = can_step(X_MIN_PIN, X_MAX_PIN, current_steps.x, target_steps.x, x_direction);
		y_can_step = can_step(Y_MIN_PIN, Y_MAX_PIN, current_steps.y, target_steps.y, y_direction);
		z_can_step = can_step(Z_MIN_PIN, Z_MAX_PIN, current_steps.z, target_steps.z, z_direction);

		if (x_can_step)
		{
			x_counter += delta_steps.x;
			
			if (x_counter > 0)
			{
				do_step(X_STEP_PIN);
				x_counter -= max_delta;
				
				if (x_direction)
					current_steps.x++;
				else
					current_steps.x--;
			}
		}

		if (y_can_step)
		{
			y_counter += delta_steps.y;
			
			if (y_counter > 0)
			{
				do_step(Y_STEP_PIN);
				y_counter -= max_delta;

				if (y_direction)
					current_steps.y++;
				else
					current_steps.y--;
			}
		}
		
		if (z_can_step)
		{
			z_counter += delta_steps.z;
			
			if (z_counter > 0)
			{
				do_step(Z_STEP_PIN);
				z_counter -= max_delta;
				
				if (z_direction)
					current_steps.z++;
				else
					current_steps.z--;
			}
		}
		
		extruder_manage_temperature();
				
		//wait for next step.
		if (milli_delay > 0)
			delay(milli_delay);			
		else
			delayMicroseconds(micro_delay);
	}
	while (x_can_step || y_can_step || z_can_step);
	
	//set our points to be the same
	current_units.x = target_units.x;
	current_units.y = target_units.y;
	current_units.z = target_units.z;
	calculate_deltas();
}

bool can_step(byte min_pin, byte max_pin, long current, long target, byte direction)
{
	//stop us if we're on target
	if (target == current)
		return false;
	//stop us if we're at home and still going 
	else if (read_switch(min_pin) && !direction)
		return false;
	//stop us if we're at max and still going
	else if (read_switch(max_pin) && direction)
		return false;

	//default to being able to step
	return true;
}

void do_step(byte step_pin)
{
	digitalWrite(step_pin, HIGH);
	delayMicroseconds(5);
	digitalWrite(step_pin, LOW);
}

bool read_switch(byte pin)
{
	//dual read as crude debounce
	
	if ( SENSORS_INVERTING )
		return !digitalRead(pin) && !digitalRead(pin);
	else
		return digitalRead(pin) && digitalRead(pin);
}

void set_target(float x, float y, float z)
{
	target.x = x;
	target.y = y;
	target.z = z;
	
	calculate_deltas();
}

void set_position(float x, float y, float z)
{
	current.x = x;
	current.y = y;
	current.z = z;
	
	calculate_deltas();
}

void calculate_deltas()
{
	//figure our deltas.
	delta.x = abs(target.x - current.x);
	delta.y = abs(target.y - current.y);
	delta.z = abs(target.z - current.z);
	
	//what is our direction
	x_direction = (target_units.x >= current_units.x);
	y_direction = (target_units.y >= current_units.y);
	z_direction = (target_units.z >= current_units.z);

	//set our direction pins as well
	digitalWrite(X_DIR_PIN, x_direction);
	digitalWrite(Y_DIR_PIN, y_direction);
	digitalWrite(Z_DIR_PIN, z_direction);
}

void disable_steppers()
{
	//enable our steppers
	digitalWrite(X_ENABLE_PIN, LOW);
	digitalWrite(Y_ENABLE_PIN, LOW);
	digitalWrite(Z_ENABLE_PIN, LOW);
}
