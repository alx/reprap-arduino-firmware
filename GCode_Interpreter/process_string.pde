//Read the string and execute instructions
void process_string(char instruction[], int size)
{
  int distanceX = 0; //TODO: struct?
  int distanceY = 0; 
  int distanceZ = 0;

  static int currentX = 0;
  static int currentY = 0;
  static int currentZ = 0;

  static int speed = 1650;           //default speed
  static int units = StepsInInch;    //default to inches for units
  static boolean abs_mode = false;   //0 = incremental; 1 = absolute

  char temp_word[2] = {instruction[1], instruction[2]};
  int word = -1;

  Serial.println("processing string...");  
  Serial.println(instruction);    
  if (instruction[0] == 'G')
    word = atoi(temp_word);

  switch (word) {

  //Rapid Positioning
  case 00:

     distanceX = (int)(search_string('X', instruction, size) * units);
     distanceY = (int)(search_string('Y', instruction, size) * units);
     distanceZ = (int)(search_string('Z', instruction, size) * units);
            
     if(abs_mode)
         moveXYZ(distanceX-currentX,distanceY-currentY,distanceZ-currentZ,MAX_SPEED);
     else moveXYZ(distanceX,distanceY,distanceZ,MAX_SPEED);
     break;    
    
  //Linear Interpolation
  case 01:

     distanceX = (int)(search_string('X', instruction, size) * units);
     distanceY = (int)(search_string('Y', instruction, size) * units);
     distanceZ = (int)(search_string('Z', instruction, size) * units);
     if  (search_string('F', instruction, size))
         speed = (int)(search_string('F', instruction, size));  //TODO: units of speed
         
     if (abs_mode)        
         moveXYZ(distanceX-currentX,distanceY-currentY,distanceZ-currentZ,speed);     
     else moveXYZ(distanceX,distanceY,distanceZ,speed);
     break;

  //Dwell
  case 04:
     dwell(search_string('P', instruction, size));
     break;

  //Inches for Units
  case 20:
    units = StepsInInch; //inches
    break;

  //mm for Units    
  case 21:
    units = StepsInMM; //mm
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
  currentX = distanceX;
  currentY = distanceY;
  currentZ = distanceZ;  

  if  ((word == 0) | (word == 1))
  {
      Serial.print("X distance: "); Serial.println(distanceX); 
      Serial.print("Y distance: "); Serial.println(distanceY); 
      Serial.print("Z distance: "); Serial.println(distanceZ); 
      Serial.print("X current : "); Serial.println(currentX); 
      Serial.print("Y current : "); Serial.println(currentY);     
      Serial.print("Z current : "); Serial.println(currentZ); 
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
        while (instruction[i] != (' '|NULL))
        {
          temp[k] = instruction[i];
          i++; k++;
        }
        return strtod(temp, NULL);
      }
    }  
  return 0;
}
