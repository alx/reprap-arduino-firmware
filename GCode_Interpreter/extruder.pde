//
// Start of temperature lookup table
//
#define NUMTEMPS  20
short temptable[NUMTEMPS][2] = {
// { adc ,  temp }
   { 1 ,  929 } ,
   { 54 ,  266 } ,
   { 107 ,  217 } ,
   { 160 ,  190 } ,
   { 213 ,  172 } ,
   { 266 ,  158 } ,
   { 319 ,  146 } ,
   { 372 ,  136 } ,
   { 425 ,  127 } ,
   { 478 ,  119 } ,
   { 531 ,  111 } ,
   { 584 ,  103 } ,
   { 637 ,  96 } ,
   { 690 ,  88 } ,
   { 743 ,  80 } ,
   { 796 ,  71 } ,
   { 849 ,  62 } ,
   { 902 ,  50 } ,
   { 955 ,  34 } ,
   { 1008 ,  2 }
};
//
// End of temperature lookup table
//

//these our the default values for the extruder.
int extruder_speed = 128;
int extruder_target_celsius = 0;
int extruder_max_celsius = 0;
byte extruder_heater_low = 64;
byte extruder_heater_high = 255;

void init_extruder()
{
	//default to room temp.
	extruder_set_temperature(21);
	
	pinMode(EXTRUDER_MOTOR_DIR_PIN, OUTPUT);
	pinMode(EXTRUDER_MOTOR_SPEED_PIN, OUTPUT);
	pinMode(EXTRUDER_HEATER_PIN, OUTPUT);
}

void extruder_set_direction(byte direction)
{
	digitalWrite(EXTRUDER_MOTOR_DIR_PIN, direction);
}

void extruder_set_speed(byte speed)
{
	analogWrite(EXTRUDER_MOTOR_DIR_PIN, speed);
}

void extruder_set_cooler(byte speed)
{
	analogWrite(EXTRUDER_FAN_PIN, speed);
}

void extruder_set_temperature(int temp)
{
	extruder_target_celsius = temp;
	extruder_max_celsius = (int)((float)temp * 1.1);
}

/**
*  Samples the temperature and converts it to degrees celsius.
*  Returns degrees celsius.
*/
int extruder_get_temperature()
{
	int raw = analogRead(EXTRUDER_THERMISTOR_PIN);
	
	int celsius = 0;
	byte i;
	
	for (i=1; i<NUMTEMPS; i++)
	{
		if (temptable[i][0] > raw)
		{
			celsius  = temptable[i-1][1] + 
				(raw - temptable[i-1][0]) * 
				(temptable[i][1] - temptable[i-1][1]) /
				(temptable[i][0] - temptable[i-1][0]);
			
			if (celsius > 255)
				celsius = 255; 

			break;
		}
	}

	// Overflow: We just clamp to 0 degrees celsius
	if (i == NUMTEMPS)
		celsius = 0;
		
	return celsius;
}

/*!
  Manages motor and heater based on measured temperature:
  o If temp is too low, don't start the motor
  o Adjust the heater power to keep the temperature at the target
 */
void extruder_manage_temperature()
{
	//make sure we know what our temp is.
	int current_celsius = extruder_get_temperature();

	//put the heater into high mode if we're not at our target.
	if (current_celsius < extruder_target_celsius)
		analogWrite(EXTRUDER_HEATER_PIN, extruder_heater_high);
	//put the heater on low if we're at our target.
	else if (current_celsius < extruder_max_celsius)
		analogWrite(EXTRUDER_HEATER_PIN, extruder_heater_low);
	//turn the heater off if we're above our max.
	else
		analogWrite(EXTRUDER_HEATER_PIN, 0);
}
