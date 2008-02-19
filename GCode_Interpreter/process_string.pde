//Read the string and execute instructions
void process_string(char instruction[], int size)
{
	Point p;
	p.x = 0;
	p.y = 0;
	p.z = 0;

	//what is our speed?
	int feedrate = 0;
	int m_code = 0;
	
	//which mode are we in?
	static boolean abs_mode = false;   //0 = incremental; 1 = absolute

	//a bit of debug info.
	Serial.print("Got:");  
	Serial.println(instruction);    

	//what is your command?
	char temp_word[2] = {instruction[1], instruction[2]};
	int word = -1;
	
	if (instruction[0] == 'G')
		word = atoi(temp_word);

	switch (word)
	{
		//Rapid Positioning
		case 0:
			p.x = (int)(search_string('X', instruction, size) * x_units);
			p.y = (int)(search_string('Y', instruction, size) * y_units);
			p.z = (int)(search_string('Z', instruction, size) * z_units);
  
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

		//Linear Interpolation
		case 1:

			p.x = (int)(search_string('X', instruction, size) * x_units);
			p.y = (int)(search_string('Y', instruction, size) * y_units);
			p.z = (int)(search_string('Z', instruction, size) * z_units);
			
			//TODO: units of speed
			if (search_string('F', instruction, size))
				feedrate = (int)(search_string('F', instruction, size));
				
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
			dwell(search_string('P', instruction, size));
		break;
		
		//custom code for temperature control
		case 6:
			extruder.setTemperature((int)search_string('P', instruction, size));
		break;
		
		//custom code for temperature reading
		case 7:
			Serial.print("Temp:");
			Serial.println(extruder.getTemperature());
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
			p.x = (int)(search_string('X', instruction, size) * x_units);
			p.y = (int)(search_string('Y', instruction, size) * y_units);
			p.z = (int)(search_string('Z', instruction, size) * z_units);

			x.setTarget(p.x);
			y.setTarget(p.y);
			z.setTarget(p.z);
			
			ddaMove();

			x.setTarget(0);
			y.setTarget(0);
			z.setTarget(0);
			
			ddaMove();
		break;
			
		//spindle max speed.
		case 50:
			max_spindle_speed = (int)(search_string('S', instruction, size));
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
		case 0:
			//todo: stop program
		break;
		
		case 1:
			//todo: optional stop
		break;
		
		case 2:
			//todo: program end
		break;
		
		//turn spindle on, CW
		case 3:
		
			//warmup
			while (extruder.getTemperature() < extruder.target_celsius)
				delayMicroseconds(5);
		
			extruder.setDirection(1);
			extruder.setSpeed(max_spindle_speed);
			Serial.println("extruder CW");
		break;
		
		//turn spindle on, CCW
		case 4:
			extruder.setDirection(0);
			extruder.setSpeed(max_spindle_speed);
			Serial.println("extruder CCW");
		break;
		
		//turn spindle off
		case 5:
			extruder.setSpeed(0);
			Serial.println("extruder off");
		break;
		
		case 7:
			extruder.setCooler(255);
		break;
		
		case 9:
			extruder.setCooler(0);
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
