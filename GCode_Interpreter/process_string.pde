//Read the string and execute instructions
void process_string(char instruction[], int size)
{
	Point p;
	p.x = 0.0;
	p.y = 0.0;
	p.z = 0.0;

	//what is our speed?
	int feedrate = 0;
	int m_code = 0;
	
	//which mode are we in?
	static boolean abs_mode = false;   //0 = incremental; 1 = absolute

	//a bit of debug info.
	//Serial.print("Got:");  
	//Serial.println(instruction);    

	//what is your command?
	char temp_word[2] = {instruction[1], instruction[2]};
	int word = -1;
	
	if (instruction[0] == 'G')
		word = atoi(temp_word);

	switch (word)
	{
		//Rapid Positioning
		//Linear Interpolation
		//these are basically the same thing.
		case 0:
		case 1:
			p.x = (long)(search_string('X', instruction, size) * x_units);
			p.y = (long)(search_string('Y', instruction, size) * y_units);
			p.z = (long)(search_string('Z', instruction, size) * z_units);
  
			//TODO: units of speed
			if (word == 1)
			{
				if (search_string('F', instruction, size))
					feedrate = (int)(search_string('F', instruction, size));
			}

			if(abs_mode)
			{
				x.setTarget(p.x);
				y.setTarget(p.y);	
				z.setTarget(p.z);
			}
			else
			{
				x.setTarget(x.current + p.x);
				y.setTarget(y.current + p.y);
				z.setTarget(z.current + p.z);
			}

			ddaMove();

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
			
			ddaMove();
		break;
		
		//go home via an intermediate point.
		case 30:
			p.x = (long)(search_string('X', instruction, size) * x_units);
			p.y = (long)(search_string('Y', instruction, size) * y_units);
			p.z = (long)(search_string('Z', instruction, size) * z_units);

			if(abs_mode)
			{
				x.setTarget(p.x);
				y.setTarget(p.y);
				z.setTarget(p.z);
			}
			else
			{
				x.setTarget(x.current + p.x);
				y.setTarget(y.current + p.y);
				z.setTarget(z.current + p.z);
			}
			
			ddaMove();

			x.setTarget(0);
			y.setTarget(0);
			z.setTarget(0);
			
			ddaMove();
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
