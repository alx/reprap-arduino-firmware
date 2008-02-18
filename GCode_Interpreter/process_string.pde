//Read the string and execute instructions
void process_string(char instruction[], int size)
{
	Point p;
	p.x = 0;
	p.y = 0;
	p.z = 0;

	//what is our speed?
	int feedrate = 0;
	
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
		case 00:
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

			seekMove();

		break;    

		//Linear Interpolation
		case 01:

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
		case 04:
			dwell(search_string('P', instruction, size));
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

		//Absolute Positioning
		case 91:
			Serial.println("WARN: absolute mode not tested yet");  
			abs_mode = true;
		break;

		//Incremental Positioning    
		case 92:
			abs_mode = false;
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
  
	instruction = NULL;

	if  ((word == 0) | (word == 1))
	{
		Serial.print("X distance: ");
		Serial.println(p.x); 
		Serial.print("Y distance: ");
		Serial.println(p.y);     
		Serial.print("Z distance: ");
		Serial.println(p.z);
		Serial.print("X current: ");
		Serial.println(x.current); 
		Serial.print("Y current: ");
		Serial.println(y.current);     
		Serial.print("Z current: ");
		Serial.println(z.current); 
	}
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
