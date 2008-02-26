//Read the string and execute instructions
void process_string(char instruction[], int size)
{
	FloatPoint fp;
	fp.x = 0.0;
	fp.y = 0.0;
	fp.z = 0.0;

	LongPoint lp;
	lp.x = 0.0;
	lp.y = 0.0;
	lp.z = 0.0;

	//vars for our feedrate calculations
	float feedrate = 0.0;
	float distance = 0.0;
	long micros = 0;
	long master_steps = 0;
	
	//special mcode?
	int m_code = 0;
	
	//which mode are we in?
	static boolean abs_mode = false;   //0 = incremental; 1 = absolute

	//what is your command?
	char temp_word[2] = {instruction[1], instruction[2]};
	int word = -1;
	
	//did we get a GCode
	if (instruction[0] == 'G')
		word = atoi(temp_word);

	switch (word)
	{
		//Rapid Positioning
		//Linear Interpolation
		//these are basically the same thing.
		case 0:
		case 1:
		
			//load it as raw units.
			fp.x = search_string('X', instruction, size);
			fp.y = search_string('Y', instruction, size);
			fp.z = search_string('Z', instruction, size);
			
			
			//convert to steps.
			lp.x = (long)(fp.x * x_units);
			lp.y = (long)(fp.y * y_units);
			lp.z = (long)(fp.z * z_units);

			//set our target.
			if(abs_mode)
			{
				x.setTarget(lp.x);
				y.setTarget(lp.y);	
				z.setTarget(lp.z);
	
				target.x = fp.x;
				target.y = fp.y;
				target.z = fp.z;
				
				delta.x = abs(target.x - current.x);
				delta.y = abs(target.x - current.x);
				delta.z = abs(target.x - current.x);
			}
			else
			{
				x.setTarget(x.current + lp.x);
				y.setTarget(y.current + lp.y);
				z.setTarget(z.current + lp.z);

				target.x = abs(target.x - current.x);
				target.y = abs(target.x - current.x);
				target.z = abs(target.x - current.x);

				delta.x = fp.x;
				delta.y = fp.y;
				delta.z = fp.z;
			}
			
			//figure out our max speed.
			micros = getMaxSpeed();

			//adjust if we have a specific feedrate.
			if (word == 1)
			{
				//how fast do we move?
				feedrate = search_string('F', instruction, size);

				Serial.print("feedrate:");
				Serial.println((int)(feedrate * 100), DEC);

				Serial.print("x:");
				Serial.println((int)(delta.x * 100), DEC);
				Serial.print("y:");
				Serial.println((int)(delta.y * 100), DEC);
				Serial.print("z:");
				Serial.println((int)(delta.z * 100), DEC);


				if (feedrate > 0)
				{
					//how long is our line length?
					distance = sqrt(delta.x*delta.x + delta.y*delta.y + delta.z*delta.z);

					//find the dominant axis units.
					if (x.delta > y.delta)
					{
						if (z.delta > x.delta)
							master_steps = delta.z * z_units;
						else
							master_steps = delta.x * x_units;
					}
					else
					{
						if (z.delta > y.delta)
							master_steps = delta.z * z_units;
						else
							master_steps = delta.y * y_units;
					}
					
					//calculate delay in microseconds.  this is sort of tricky, but not too bad.
					//the formula has been condensed to save space.  here it is in english:
					// micros = 60,000,000
					// step_delay = total_ticks_in_move / steps_per_unit
					// step_delay = processor ticks between steps
					// total_ticks_in_move = minutes_in_move * ticks_per_minute
					// minutes_in_move = distance / feedrate
					
					//we want the slowest speed (biggest delay) incase too big of a feedrate is specified
					micros = max(micros, ((distance / feedrate * 60000000.0) / master_steps));
				}
			}
			
			Serial.print("delay:");
			Serial.println(micros);

			//finally move.
			ddaMove(micros);
			
			//set our points to be the same
			current.x = target.x;
			current.y = target.y;
			current.z = target.z;
		break;

		//Dwell
		case 4:
			delay((int)search_string('P', instruction, size));
		break;

		//Inches for Units
		case 20:
			x_units = X_STEPS_PER_INCH;
			y_units = Y_STEPS_PER_INCH;
			z_units = Z_STEPS_PER_INCH;
		break;

		//mm for Units    
		case 21:
			x_units = X_STEPS_PER_MM;
			y_units = Y_STEPS_PER_MM;
			z_units = Z_STEPS_PER_MM;
		break; 
		
		//go home.
		case 28:
			x.setTarget(0);
			y.setTarget(0);
			z.setTarget(0);
			
			ddaMove(getMaxSpeed());
			
			current.x = 0.0;
			current.y = 0.0;
			current.z = 0.0;
		break;
		
		//go home via an intermediate point.
		case 30:
			lp.x = (long)(search_string('X', instruction, size) * x_units);
			lp.y = (long)(search_string('Y', instruction, size) * y_units);
			lp.z = (long)(search_string('Z', instruction, size) * z_units);

			if(abs_mode)
			{
				x.setTarget(lp.x);
				y.setTarget(lp.y);
				z.setTarget(lp.z);
			}
			else
			{
				x.setTarget(x.current + lp.x);
				y.setTarget(y.current + lp.y);
				z.setTarget(z.current + lp.z);
			}
			
			ddaMove(getMaxSpeed());

			x.setTarget(0);
			y.setTarget(0);
			z.setTarget(0);
			
			ddaMove(getMaxSpeed());
			
			//update our current units.
			current.x = 0.0;
			current.y = 0.0;
			current.z = 0.0;
			
		break;
			
		//Absolute Positioning
		case 90:
			Serial.println("WARN: absolute mode not tested yet");  
			abs_mode = true;
		break;

		//Incremental Positioning    
		case 91:
			abs_mode = false;
		break;

		//Set as home    
		case 92:
			x.setPosition(0);
			y.setPosition(0);
			z.setPosition(0);
			
			//update our current units.
			current.x = 0.0;
			current.y = 0.0;
			current.z = 0.0;
		break;

		//Inverse Time Feed Mode
		case 93:
		
		break;  //TODO: add this

		//Feed per Minute Mode
		case 94:
		
		break;  //TODO: add this

		default:
			Serial.print("WARN: unknown instruction - "); 
			Serial.println(instruction);      
	}
	
	//find us an m code.
	m_code = search_string('M', instruction, size);
	switch (m_code)
	{
		//TODO: this is a bug because search_string returns 0.  gotta fix that.
		case 0:
			true;
		break;
/*
		case 0:
			//todo: stop program
		break;
		
		case 1:
			//todo: optional stop
		break;
		
		case 2:
			//todo: program end
		break;
*/		
		//turn fan on
		case 7:
			extruder.setCooler(255);
		break;
		
		//turn fan off
		case 9:
			extruder.setCooler(0);
		break;
		
		//set max extruder speed, 0-255 PWM
		case 100:
			extruder_speed = (int)(search_string('P', instruction, size));
		break;
		
		//turn extruder on, forward
		case 101:
			//warmup 	
			while (extruder.getTemperature() < extruder.target_celsius)
			{
				extruder.manageTemperature();
				Serial.print("Temp:");
				Serial.println(extruder.getTemperature());
				delay(1000);	
			}
			extruder.setDirection(1);
			extruder.setSpeed(extruder_speed);
		break;

		//turn extruder on, reverse
		case 102:
			extruder.setDirection(0);
			extruder.setSpeed(extruder_speed);
		break;

		//turn extruder off
		case 103:
			extruder.setSpeed(0);
		break;
		
		//custom code for temperature control
		case 104:
			extruder.setTemperature((int)search_string('P', instruction, size));
		break;
		
		//custom code for temperature reading
		case 105:
			Serial.print("Temp:");
			Serial.println(extruder.getTemperature());
		break;
		
		default:
			Serial.print("WARN: Unknown code M");
			Serial.println(m_code);
	}
  
	instruction = NULL;
}

//-------------------------
//look for the number that appears after the char key and return it
double search_string(char key, char instruction[], int string_size)
{
	char temp[10] = "";

	for (int i=0; i<string_size; i++)
	{
		if (instruction[i] == key)
		{
			i++;      
			int k = 0;
			while (instruction[i] != (' ' | NULL))
			{
				temp[k] = instruction[i];
				i++;
				k++;
			}
			return strtod(temp, NULL);
		}
	}
	
	return 0;
}
