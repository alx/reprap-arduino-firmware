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

#define EXTRUDER_FORWARD true
#define EXTRUDER_REVERSE false

//these our the default values for the extruder.
int extruder_speed = 128;
int extruder_target_celsius = 0;
int extruder_max_celsius = 0;
byte extruder_heater_low = 64;
byte extruder_heater_high = 255;

//this is for doing encoder based extruder control
int extruder_rpm = 0;
long extruder_delay = 0;
int extruder_error = 0;
bool extruder_direction = EXTRUDER_FORWARD;

#ifdef EXTRUDER_ENCODER_ENABLED	
	void extruder_read_quadrature()
	{
		// found a low-to-high on channel A
		if (digitalRead(EXTRUDER_ENCODER_A_PIN) == HIGH)
		{   
			// check channel B to see which way
			if (digitalRead(EXTRUDER_ENCODER_B_PIN) == LOW)
				extruder_error--; // CCW
			else
				extruder_error++; //CW
		}
		// found a high-to-low on channel A
		else
		{
			// check channel B to see which way
			if (digitalRead(EXTRUDER_ENCODER_B_PIN) == LOW)
				extruder_error++; //CW
			else
				extruder_error--; //CCW
		}
	}
#endif

void init_extruder()
{
	//default to room temp.
	extruder_set_temperature(21);
	
	//setup our 
	pinMode(EXTRUDER_MOTOR_DIR_PIN, OUTPUT);
	pinMode(EXTRUDER_MOTOR_SPEED_PIN, OUTPUT);
	pinMode(EXTRUDER_HEATER_PIN, OUTPUT);
	pinMode(EXTRUDER_FAN_PIN, OUTPUT);
	
#ifdef EXTRUDER_ENCODER_ENABLED	
	//setup our encoder interrupt stuff.
	//these pins are inputs
	pinMode(EXTRUDER_ENCODER_A_PIN, INPUT);
	pinMode(EXTRUDER_ENCODER_B_PIN, INPUT);

	//turn on internal pullups
	digitalWrite(EXTRUDER_ENCODER_A_PIN, HIGH);
	digitalWrite(EXTRUDER_ENCODER_A_PIN, HIGH);
	
	//attach our interrupt handler
	attachInterrupt(0, extruder_read_quadrature, CHANGE);

	//setup our timer interrupt stuff
	setupTimer1Interrupt();
#endif

}

void extruder_set_direction(bool direction)
{
	extruder_direction = direction;
	digitalWrite(EXTRUDER_MOTOR_DIR_PIN, direction);
}

void extruder_set_speed(byte speed)
{
	analogWrite(EXTRUDER_MOTOR_SPEED_PIN, speed);
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
	if (EXTRUDER_THERMISTOR_PIN > -1)
		return extruder_read_thermistor();
	else if (EXTRUDER_THERMOCOUPLE_PIN > -1)
		return extruder_read_thermocouple();
}

/*
* This function gives us the temperature from the thermistor in Celsius
*/
int extruder_read_thermistor()
{
	int raw = extruder_sample_temperature(EXTRUDER_THERMISTOR_PIN);

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

/*
* This function gives us the temperature from the thermocouple in Celsius
*/
int extruder_read_thermocouple()
{
	return ( 5.0 * extruder_sample_temperature(EXTRUDER_THERMOCOUPLE_PIN) * 100.0) / 1024.0;
}

/*
* This function gives us an averaged sample of the analog temperature pin.
*/
int extruder_sample_temperature(byte pin)
{
	int raw = 0;
	
	//read in a certain number of samples
	for (byte i=0; i<TEMPERATURE_SAMPLES; i++)
		raw += analogRead(pin);
		
	//average the samples
	raw = raw/TEMPERATURE_SAMPLES;

	//send it back.
	return raw;
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

#ifdef EXTRUDER_ENCODER_ENABLED
	//this handles the timer interrupt code
	SIGNAL(SIG_OUTPUT_COMPARE1A)
	{
		//increment/decrement our error variable.
		//the manage extruder function will handle the motor control
		if (extruder_direction)
			extruder_error--;
		else
			extruder_error++;
	}

	void extruder_manage_speed()
	{
		//calculate our speed.
		int speed = abs(extruder_error) / 4;
		speed = max(speed, 1);
		speed = min(speed, 255);

		//figure out which direction to move the motor
		if (extruder_error > 0)
			digitalWrite(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_FORWARD);
		else if (extruder_error < 0)
			digitalWrite(EXTRUDER_MOTOR_DIR_PIN, EXTRUDER_REVERSE);

		//send us off at that speed!
		if (extruder_error != 0)
			analogWrite(EXTRUDER_MOTOR_SPEED_PIN, speed);
	}
#endif
