# Creates a C code lookup table for doing ADC to temperature conversion
# on a microcontroller
# based on: http://hydraraptor.blogspot.com/2007/10/measuring-temperature-easy-way.html

from math import *

class Thermistor:
   "Class to do the thermistor maths"
   def __init__(self, r0, t0, beta, r1, r2):
       self.r0 = r0                        # stated resistance, e.g. 10K
       self.t0 = t0 + 273.15               # temperature at stated resistance, e.g. 25C
       self.beta = beta                    # stated beta, e.g. 3500
       self.vadc = 5.0                     # ADC reference
       self.vcc = 5.0                      # supply voltage to potential divider
       self.vs = r1 * self.vcc / (r1 + r2) # effective bias voltage
       self.rs = r1 * r2 / (r1 + r2)       # effective bias impedance
       self.k = r0 * exp(-beta / self.t0)  # constant part of calculation

   def temp(self,adc):
       "Convert ADC reading into a temperature in Celcius"
       v = adc * self.vadc / 1024          # convert the 10 bit ADC value to a voltage
       r = self.rs * v / (self.vs - v)     # resistance of thermistor
       return (self.beta / log(r / self.k)) - 273.15        # temperature

   def setting(self, t):
       "Convert a temperature into a ADC value"
       r = self.r0 * exp(self.beta * (1 / (t + 273.15) - 1 / self.t0)) # resistance of the thermistor
       v = self.vs * r / (self.rs + r)     # the voltage at the potential divider
       return round(v / self.vadc * 1024)  # the ADC reading
       
t = Thermistor(10000, 25, 3947, 1000000, 1000)

adcs = [1, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 130,  150, 190, 220,  250, 300]
first = 1

print "#define NUMTEMPS ", len(adcs)

print "short temptable[NUMTEMPS][2] = {"
print "// { adc ,  temp }"    
for adc in adcs:
	if first==1:
		first = 0
	else:
		print ","
	print "   {", adc, ", ", int(t.temp(adc)), "}",
print
print "};"
	
	
	
#print t.setting(250)
#print t.temp(200)
