/******************
*  Definitions
******************/
#define POINT_QUEUE_SIZE 64

/******************
* digital i/o
******************/
//x axis stuff.
byte x_home_pin = 2;
byte x_dir_pin = 7;
byte x_step_pin = 8;

//y axis stuff
byte y_home_pin = 3;
byte y_dir_pin = 9;
byte y_step_pin = 10;

//z axis stuff
byte z_home_pin = 11;
byte z_dir_pin = 12;
byte z_step_pin = 13;

//for our extruder
byte extruder_motor_dir_pin = 4;
byte extruder_motor_speed_pin = 5;
byte extruder_heater_pin = 6;

/******************
* analog inputs
******************/
byte extruder_thermistor_pin = 0;
byte x_encoder_pin = 1;
byte y_encoder_pin = 2;
byte z_encoder_pin = 3;
byte extruder_motor_encoder_pin = 4;

//our analog sensor values.
int thermistor_reading = 0;
int x_encoder_reading = 0;
int y_encoder_reading = 0;
int z_encoder_reading = 0;
int extruder_motor_encoder_reading = 0;

//information on our axes
int x_position = 0;
int y_position = 0;
int z_position = 0;

//our endstop variables
bool x_at_home = 0;
bool y_at_home = 0;
bool z_at_home = 0;

//what direction are we going?
bool x_direction = HIGH;
bool y_direction = HIGH;
bool z_direction = HIGH;

//our extruder info
bool extruder_direction = HIGH;
byte extruder_speed = 0;
byte extruder_heater_pwm = 0;
byte target_thermistor_value = 0;

//this is for tracking to a point.
byte point_index = 0;
Point point_queue[POINT_QUEUE_SIZE];
Point target_point;

void setup()
{
	//these inputs are our limit switches
	pinMode(x_home_pin, INPUT);
	pinMode(y_home_pin, INPUT);
	pinMode(z_home_pin, INPUT);
	
	//these outputs control the direction of our steppers
	pinMode(x_dir_pin, OUTPUT);
	pinMode(y_dir_pin, OUTPUT);
	pinMode(z_dir_pin, OUTPUT);

	//these outputs are how we step our steppers
	pinMode(x_step_pin, OUTPUT);
	pinMode(y_step_pin, OUTPUT);
	pinMode(z_step_pin, OUTPUT);
	
	//these outputs control our extruder
	pinMode(extruder_motor_dir_pin, OUTPUT);
	pinMode(extruder_motor_speed_pin, OUTPUT);
	pinMode(extruder_heater_pin, OUTPUT);	

	Serial.begin(57600);
}

void loop()
{
	Serial.println("RepDuino v1.0 started up.");
	
	while (1)
	{
		receiveCommands();
		readSensors();
		updateStatus();
		executeCommands();
	}
}

void function receiveCommands()
{
	int incoming;
	
	while (Serial.available() > 1)
	{
		incoming = Serial.read();
		
		//get our version
		if (incoming == 'A')
			printVersion();
		//queue point
		else if (incoming == 'B')
			queuePoint();
		//abort our print!
		else if (incoming == 'C')
			abortPrint();
		//set our heater temperature
		else if (incoming == 'D')
			readExtruderTemperature();
		//take me home, country roads!
		else if (incoming == 'E')
			goHome();
		//set our extruder speed
		else if (incoming == 'F')
			readExtruderSettings();
		//what did you say to me?!?
		else
		{
			Serial.print("Command not understood: ");
			Serial.println(incoming);
		}
	}
}

void function readSensors()
{
	//just read in all our sensor data... make it easy.
	thermistor_reading = analogRead(extruder_thermistor_pin);
	x_encoder_reading = analogRead(x_encoder_pin);
	y_encoder_reading = analogRead(y_encoder_pin);
	z_encoder_reading = analogRead(z_encoder_pin);
	extruder_motor_encoder_reading = analogRead(extruder_motor_encoder_pin);
	
	//also check our endstops as well
	x_at_home = digitalRead(x_home_pin);
	y_at_home = digitalRead(y_home_pin);
	z_at_home = digitalRead(z_home_pin);
}

void function updateStatus()
{
	//let them know its our status line.
	//Serial.print('Status:');
	
	//our analog readings.
	Serial.print("T:");
	Serial.print(thermistor_reading);
	Serial.print('Xe:');
	Serial.print(x_encoder_reading);
	Serial.print('Ye:');
	Serial.print(y_encoder_reading);
	Serial.print('Ze:');
	Serial.print(z_encoder_reading);
	Serial.print('Ee:');
	Serial.print(extruder_motor_encoder_reading);

	//our current position and such
	Serial.print('Xp:');
	Serial.print(x_position);
	Serial.print('Yp:');
	Serial.print(y_position);
	Serial.print('Zp:');
	Serial.print(z_position);

	//are we at our limit?
	Serial.print('Xmin:');
	Serial.print(x_at_home);
	Serial.print('Ymin:');
	Serial.print(y_at_home);
	Serial.print('Zmin:');
	Serial.print(z_at_home);

	//what direction?
	Serial.print('Xdir:');
	Serial.print(x_direction);
	Serial.print('Ydir:');
	Serial.print(y_direction);
	Serial.print('Zdir:');
	Serial.print(z_direction);

	//what about our extruder?
	Serial.print('Edir:');
	Serial.print(extruder_direction);
	Serial.print('Espeed:');
	Serial.print(extruder_speed);
	Serial.print('Heater:');
	Serial.print(extruder_heater_pwm);
	Serial.print();
	
	//end our data transmission
	Serial.println('!');
}

void function executeCommands()
{
}

void function printVersion()
{
	Serial.println("RepDuino v1.0");
}

void function queuePoint()
{
	if(point_index < (POINT_QUEUE_SIZE - 1))
	{
		//read in our points.
		point_queue[point_index]->x = readInt();
		point_queue[point_index]->y = readInt();
		point_queue[point_index]->z = readInt();
		
		//move our pointer forward.
		point_index++;
	}
	else
		Serial.println("Point queue is full!");
}

int function readInt()
{
	int tmp;

	//read in an integer.
	tmp = Serial.read();
	tmp = tmp << 8;
	tmp |= Serial.read();
	
	return tmp;
}

void function abortPrint()
{
	//set temp to 0
	//turn off all motors
}

void function readExtruderTemperature()
{
	setExtruderTemperature(Serial.read());
}

void function setExtruderTemperature(byte temp)
{
	target_thermistor_value = temp;
}

void function goHome()
{
	//clear our queue, and tell it to go home.
	//the endstops will take care of the rest. (hopefully)
	point_index = 0;
	point_queue[0]->x = -100;
	point_queue[0]->y = -100;
	point_queue[0]->z = -100;
}

void function readExtruderSettings()
{
	setExtruderDirection(Serial.read());
	setExtruderSpeed(Serial.read());
}

void function setExtruderDirection(bool dir)
{
	extruder_direction = dir;
}

void function setExtruderSpeed(byte speed)
{
	extruder_speed = speed;	
}