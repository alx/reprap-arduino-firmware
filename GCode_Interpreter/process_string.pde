//Read the string and execute instructions
void process_string(char instruction[], int size)
{
	FloatPoint fp;
	fp.x = 0.0;
	fp.y = 0.0;
	fp.z = 0.0;

	//vars for our feedrate calculations
	float feedrate = 0.0;
	long micros = 0;
	
	//special code?
	byte code = 0;
	
	//what line are we at?
	long line = -1;
	if (has_command('N', instruction, size))
		line = (long)search_string('N', instruction, size);
	
/*
	Serial.print("line: ");
	Serial.println(line);
	Serial.println(instruction);
*/		
	//did we get a gcode?
	if (has_command('G', instruction, size))
	{
		//which one?
		code = (int)search_string('G', instruction, size);
		
		//do something!		
		switch (code)
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

				//set our target.
				if(abs_mode)
				{
					if (!has_command('X', instruction, size))
						fp.x = current_units.x;
					if (!has_command('Y', instruction, size))
						fp.y = current_units.y;
					if (!has_command('Z', instruction, size))
						fp.z = current_units.z;
						
					set_target(fp.x, fp.y, fp.z);
				}
				else
				{
					set_target(current_units.x + fp.x, current_units.y + fp.y, current_units.z + fp.z);
				}

				//figure out our max speed.
				micros = getMaxSpeed();

				//adjust if we have a specific feedrate.
				if (code == 1)
				{
					//how fast do we move?
					feedrate = search_string('F', instruction, size);
					if (feedrate > 0)
						micros = calculate_feedrate_delay(feedrate);
				}

				//finally move.
				dda_move(micros);
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
				
				calculate_deltas();
			break;

			//mm for Units    
			case 21:
				x_units = X_STEPS_PER_MM;
				y_units = Y_STEPS_PER_MM;
				z_units = Z_STEPS_PER_MM;
				
				calculate_deltas();
			break;

			//go home.
			case 28:
				set_target(0.0, 0.0, 0.0);
				dda_move(getMaxSpeed());
			break;

			//go home via an intermediate point.
			case 30:
				fp.x = search_string('X', instruction, size);
				fp.y = search_string('Y', instruction, size);
				fp.z = search_string('Z', instruction, size);

				//set our target.
				if(abs_mode)
				{
					if (!has_command('X', instruction, size))
						fp.x = current_units.x;
					if (!has_command('Y', instruction, size))
						fp.y = current_units.y;
					if (!has_command('Z', instruction, size))
						fp.z = current_units.z;
						
					set_target(fp.x, fp.y, fp.z);
				}
				else
					set_target(current_units.x + fp.x, current_units.y + fp.y, current_units.z + fp.z);
				
				//go there.
				dda_move(getMaxSpeed());

				//go home.
				set_target(0.0, 0.0, 0.0);
				dda_move(getMaxSpeed());
			break;

			//Absolute Positioning
			case 90:
				abs_mode = true;
			break;

			//Incremental Positioning    
			case 91:
				abs_mode = false;
			break;

			//Set as home    
			case 92:
				set_position(0.0, 0.0, 0.0);
			break;

/*
			//Inverse Time Feed Mode
			case 93:

			break;  //TODO: add this

			//Feed per Minute Mode
			case 94:

			break;  //TODO: add this
*/

			default:
				Serial.print("huh? G"); 
				Serial.println(code);      
		}		
	}
	
	//find us an m code.
	if (has_command('M', instruction, size))
	{
		code = search_string('M', instruction, size);
		switch (code)
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
					Serial.print("T:");
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
				Serial.print("T:");
				Serial.println(extruder.getTemperature());
			break;
			
			//turn fan on
			case 106:
				extruder.setCooler(255);
			break;

			//turn fan off
			case 107:
				extruder.setCooler(0);
			break;

			default:
				Serial.print("Huh? M");
				Serial.println(code);
		}		
	}
	
	//tell our host we're done.
	Serial.print("ok:");
	Serial.println(line, DEC);
}

//look for the number that appears after the char key and return it
double search_string(char key, char instruction[], int string_size)
{
	char temp[10] = "";

	for (byte i=0; i<string_size; i++)
	{
		if (instruction[i] == key)
		{
			i++;      
			int k = 0;
			while (i < string_size && k < 10)
			{
				if (instruction[i] == 0 || instruction[i] == ' ')
					break;

				temp[k] = instruction[i];
				i++;
				k++;
			}
			return strtod(temp, NULL);
		}
	}
	
	return 0;
}

//look for the command if it exists.
bool has_command(char key, char instruction[], int string_size)
{
	for (byte i=0; i<string_size; i++)
	{
		if (instruction[i] == key)
			return true;
	}
	
	return false;
}
