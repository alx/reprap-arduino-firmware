void dwell(int time)
{
	delay(time); 
}

void move(int steppin, int dirpin, int distance, int dir, int speed)
{
	digitalWrite(dirpin, dir);
	delayMicroseconds(10);
	for (int i=0; i<distance; i++)
	{
		digitalWrite(steppin, HIGH);
		delayMicroseconds(10);
		digitalWrite(steppin, LOW);
		delayMicroseconds(speed);        
	}
}

//TODO: look into interupts for moving multiple axis
void moveXYZ(int distanceX, int distanceY, int distanceZ, int speed)
{
	int dirX; int dirY; int dirZ;

	(distanceX < 0)?(dirX=0):(dirX=1);
	(distanceY < 0)?(dirY=0):(dirY=1);
	(distanceZ < 0)?(dirZ=0):(dirZ=1);  

	distanceX = abs(distanceX);
	distanceY = abs(distanceY);
	distanceZ = abs(distanceZ);

	int slopeX = distanceX;
	int slopeY = distanceY;
	int slopeZ = distanceZ;  //TODO: add z slope

	for (int i = slopeX * slopeY; i > 1; i--)
	{
		if ((slopeX % i == 0) && (slopeY % i == 0))
		{
			slopeX /= i;
			slopeY /= i;
		}
	}

	while (distanceX > 0 | distanceY > 0 | distanceZ > 0)
	{
		move(X_STEP_PIN, X_DIR_PIN, slopeX, dirX, speed);
		move(Y_STEP_PIN, Y_DIR_PIN, slopeY, dirY, speed);
		move(Z_STEP_PIN, Z_DIR_PIN, slopeZ, dirZ, speed);
		distanceX -= slopeX;
		distanceY -= slopeY;
		distanceZ -= slopeZ;
	} 
}
