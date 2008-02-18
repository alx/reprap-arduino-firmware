//Put Defines here
#define stepPinX  4
#define dirPinX   5
#define stepPinY  6
#define dirPinY   7
#define stepPinZ  8
#define dirPinZ   9

const int StepsInInch = 1000; //TODO: Calibrate these
const int StepsInMM   = 50;   //TODO: Calibrate these
const int MAX_SPEED   = 1650; //TODO: Calibrate these

void setup()
{

  //Do startup stuff here
  
  Serial.begin(9600);

  pinMode(stepPinX, OUTPUT);  pinMode(dirPinX, OUTPUT);
  pinMode(stepPinY, OUTPUT);  pinMode(dirPinY, OUTPUT);
  pinMode(stepPinZ, OUTPUT);  pinMode(dirPinZ, OUTPUT);

  Serial.println("---");
  Serial.println("Starting program");  

}
