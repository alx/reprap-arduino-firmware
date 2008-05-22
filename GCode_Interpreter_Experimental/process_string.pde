// our point structure to make things nice.
struct LongPoint {
	long x;
	long y;
 	long z;
};

struct FloatPoint {
	float x;
	float y;
 	float z;
};

FloatPoint current_units;
FloatPoint target_units;
FloatPoint delta_units;

FloatPoint current_steps;
FloatPoint target_steps;
FloatPoint delta_steps;

boolean abs_mode = false;   //0 = incremental; 1 = absolute

//default to inches for units
float x_units = X_STEPS_PER_INCH;
float y_units = Y_STEPS_PER_INCH;
float z_units = Z_STEPS_PER_INCH;
float curve_section = CURVE_SECTION_INCHES;

//our direction vars
byte x_direction = 1;
byte y_direction = 1;
byte z_direction = 1;

//init our string processing
void init_process_string()
{
	//init our command
	for (byte i=0; i<COMMAND_SIZE; i++)
		word[i] = 0;
	serial_count = 0;
}

//our feedrate variables.
float feedrate = 0.0;
long feedrate_micros = 0;

//Read the string and execute instructions
void process_string(char instruction[], int size)
{
	//the character / means delete block... used for comments and stuff.
	if (instruction[0] == '/')
	{
		Serial.println("ok");
		return;
	}

	//init baby!
	FloatPoint fp;
	fp.x = 0.0;
	fp.y = 0.0;
	fp.z = 0.0;

	byte code = 0;;
	
//what line are we at?
//	long line = -1;
//	if (has_command('N', instruction, size))
//		line = (long)search_string('N', instruction, size);
	
/*
	Serial.print("line: ");
	Serial.println(line);
	Serial.println(instruction);
*/		
	//did we get a gcode?
	if (
		has_command('G', instruction, size) ||
		has_command('X', instruction, size) ||
		has_command('Y', instruction, size) ||
		has_command('Z', instruction, size)
	)
	{
		//which one?
		code = (int)search_string('G', instruction, size);
		
		// Get co-ordinates if required by the code type given
		switch (code)
		{
			case 0:
			case 1:
			case 2:
			case 3:
				if(abs_mode)
				{
					//we do it like this to save time. makes curves better.
					//eg. if only x and y are specified, we dont have to waste time looking up z.
					if (has_command('X', instruction, size))
						fp.x = search_string('X', instruction, size);
					else
						fp.x = current_units.x;
				
					if (has_command('Y', instruction, size))
						fp.y = search_string('Y', instruction, size);
					else
						fp.y = current_units.y;
				
					if (has_command('Z', instruction, size))
						fp.z = search_string('Z', instruction, size);
					else
						fp.z = current_units.z;
				}
				else
				{
					fp.x = search_string('X', instruction, size) + current_units.x;
					fp.y = search_string('Y', instruction, size) + current_units.y;
					fp.z = search_string('Z', instruction, size) + current_units.z;
				}
			break;
		}

		//do something!
		switch (code)
		{
			//Rapid Positioning
			//Linear Interpolation
			//these are basically the same thing.
			case 0:
			case 1:
				//set our target.
				set_target(fp.x, fp.y, fp.z);

				//do we have a set speed?
				if (has_command('G', instruction, size))
				{
					//adjust if we have a specific feedrate.
					if (code == 1)
					{
						//how fast do we move?
						feedrate = search_string('F', instruction, size);
						if (feedrate > 0)
							feedrate_micros = calculate_feedrate_delay(feedrate);
						//nope, no feedrate
						else
							feedrate_micros = getMaxSpeed();
					}
					//use our max for normal moves.
					else
						feedrate_micros = getMaxSpeed();
				}
				//nope, just coordinates!
				else
				{
					//do we have a feedrate yet?
					if (feedrate > 0)
						feedrate_micros = calculate_feedrate_delay(feedrate);
					//nope, no feedrate
					else
						feedrate_micros = getMaxSpeed();
				}

				//finally move.
				dda_move(feedrate_micros);
			break;
			
			//Clockwise arc
			case 2:
			//Counterclockwise arc
			case 3:
				FloatPoint cent;

				// Centre coordinates are always relative
				cent.x = search_string('I', instruction, size) + current_units.x;
				cent.y = search_string('J', instruction, size) + current_units.y;
				float angleA, angleB, angle, radius, length, aX, aY, bX, bY;

				aX = (current_units.x - cent.x);
				aY = (current_units.y - cent.y);
				bX = (fp.x - cent.x);
				bY = (fp.y - cent.y);
				
				if (code == 2) { // Clockwise
					angleA = atan2(bY, bX);
					angleB = atan2(aY, aX);
				} else { // Counterclockwise
					angleA = atan2(aY, aX);
					angleB = atan2(bY, bX);
				}

				// Make sure angleB is always greater than angleA
				// and if not add 2PI so that it is (this also takes
				// care of the special case of angleA == angleB,
				// ie we want a complete circle)
				if (angleB <= angleA) angleB += 2 * M_PI;
				angle = angleB - angleA;

				radius = sqrt(aX * aX + aY * aY);
				length = radius * angle;
				int steps, s, step;
				steps = (int) ceil(length / curve_section);

				FloatPoint newPoint;
				for (s = 1; s <= steps; s++) {
					step = (code == 3) ? s : steps - s; // Work backwards for CW
					newPoint.x = cent.x + radius * cos(angleA + angle * ((float) step / steps));
					newPoint.y = cent.y + radius * sin(angleA + angle * ((float) step / steps));
					set_target(newPoint.x, newPoint.y, fp.z);

					// Need to calculate rate for each section of curve
					if (feedrate > 0)
						feedrate_micros = calculate_feedrate_delay(feedrate);
					else
						feedrate_micros = getMaxSpeed();

					// Make step
					dda_move(feedrate_micros);
				}
	
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
				curve_section = CURVE_SECTION_INCHES;
				
				calculate_deltas();
			break;

			//mm for Units
			case 21:
				x_units = X_STEPS_PER_MM;
				y_units = Y_STEPS_PER_MM;
				z_units = Z_STEPS_PER_MM;
				curve_section = CURVE_SECTION_MM;
				
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
				Serial.println(code,DEC);
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
				extruder_rpm = (int)search_string('P', instruction, size);
				extruder_delay = (960000000UL / EXTRUDER_ENCODER_STEPS) / extruder_rpm;
				setTimer1Ticks(extruder_delay);
			break;

			//turn extruder on, forward
			case 101:
				extruder_set_direction(1);
				enableTimer1Interrupt();
			break;

			//turn extruder on, reverse
			case 102:
				extruder_set_direction(0);
				enableTimer1Interrupt();
			break;

			//turn extruder off
			case 103:
				disableTimer1Interrupt();
			break;

			//custom code for temperature control
			case 104:
				extruder_set_temperature((int)search_string('P', instruction, size));

				//warmup if we're too cold.
				while (extruder_get_temperature() < extruder_target_celsius)
				{
					extruder_manage_temperature();
					Serial.print("T:");
					Serial.println(extruder_get_temperature());
					delay(1000);	
				}
				
			break;

			//custom code for temperature reading
			case 105:
				Serial.print("T:");
				Serial.println(extruder_get_temperature());
			break;
			
			//turn fan on
			case 106:
				extruder_set_cooler(255);
			break;

			//turn fan off
			case 107:
				extruder_set_cooler(0);
			break;

			default:
				Serial.print("Huh? M");
				Serial.println(code);
		}		
	}
	
	//tell our host we're done.
	Serial.println("ok");
//	Serial.println(line, DEC);
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
