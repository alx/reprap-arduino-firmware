// Arduino G-code Interpreter
// v1.0 by Mike Ellery (mellery@gmail.com)

//TODO: Add limit switch support
//TODO: Add a HOME position

void loop()
{
	char word[256] = "";  //TODO: magic numbers are bad
	int serial_count;

	if (Serial.available() > 0)
	{
		serial_count = 0;
		while(Serial.available() > 0)
		{
			word[serial_count] = Serial.read();
			delayMicroseconds(1000);  //TODO: is there a better way to wait for serial?
			serial_count++;
		}
		word[serial_count] = ' '; //TODO: kinda hacky

		Serial.print("Recieved: ");
		Serial.println(word);

		process_string(word, sizeof(word));

		Serial.print("done");
	}
}
