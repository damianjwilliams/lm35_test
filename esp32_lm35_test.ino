#include <ArduinoJson.h>

#include <Wire.h> // library for I2C communication 
#include <Adafruit_ADS1X15.h> //Library of external adc
#include "BluetoothSerial.h"
#include <Adafruit_MCP4725.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_I2CDevice.h>

#define SCREEN_WIDTH 128 // OLED display width, in pixels
#define SCREEN_HEIGHT 64 // OLED display height, in pixels
#define OLED_RESET     -1 // Reset pin # (or -1 if sharing Arduino reset pin)
#define SCREEN_ADDRESS 0x3c ///< See datasheet for Address; 0x3D for 128x64, 0x3C for 128x32
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);


char input;
bool enableHeater = false;
int number_data_points=20;
int number_DO = 64;
int current_point_number;
int numberOfDevices; 
byte currentPortNumber;
String temps_together;


Adafruit_MCP4725 dac;
Adafruit_ADS1115 ads2;
Adafruit_ADS1115 ads3;
BluetoothSerial SerialBT;



void setup(void) 
{
Serial.begin (115200);
Wire.begin(2,4);
dac.begin(0x60); 

Serial.println("ADS1115 sensor 1 test!");
bool status2 = ads2.begin(0x48);  
  if (!status2) {
    Serial.println("Could not find  ADS1115 sensor 1, check wiring!");
    while (1);
  }

 
Serial.println("ADS1115 sensor 2 test!");
bool status3 = ads3.begin(0x49);  
  if (!status3) {
    Serial.println("Could not find  ADS1115 sensor 2, check wiring!");
    while (1);
}

ads2.setGain(GAIN_EIGHT); 
ads3.setGain(GAIN_EIGHT);

display.setTextSize(3);             // Normal 1:1 pixel scale
display.setTextColor(SSD1306_WHITE);        // Draw white text
if(!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
  Serial.println(F("SSD1306 allocation failed"));
   for(;;); // Don't proceed, loop forever
 }
// Clear the buffer
  display.clearDisplay();

}
 
void loop(void) {


for (int i=0; i<number_DO; i++) {

  int digital_out = i * number_DO;
  Serial.println(digital_out);  

  for(int j=0;j <number_data_points; j++){

    current_point_number = j*number_data_points;    
    blue_tooth(digital_out); 
    
    }
    
}


}

void  blue_tooth(int DAC_input){

 dac.setVoltage(DAC_input, false);

//1st ADS1115
int16_t adc2_0 = ads2.readADC_SingleEnded(0); 
float temp2_0 = int16ToC(adc2_0);
int16_t adc2_1 = ads2.readADC_SingleEnded(1); 
float temp2_1 = int16ToC(adc2_1);
int16_t adc2_2 = ads2.readADC_SingleEnded(2); 
float temp2_2 = int16ToC(adc2_2);
int16_t adc2_3 = ads2.readADC_SingleEnded(3); 
float temp2_3 = int16ToC(adc2_3);

//2nd ADS1115 
int16_t adc3_0 = ads3.readADC_SingleEnded(0); // read ANO values
float temp3_0 = int16ToC(adc3_0);
int16_t adc3_1 = ads3.readADC_SingleEnded(1); // read ANO values
float temp3_1 = int16ToC(adc3_1);

//For voltmeter
int16_t adc2 = ads3.readADC_SingleEnded(2); // read ANO values
float volts2 = ads3.computeVolts(adc2);
float input_voltage=(volts2*(10000+440))/440;

//OLED display
display.clearDisplay();
display.setCursor(0,0);             // Start at top-left corner
display.println(F("Voltage"));
display.println(input_voltage);
display.display();


//JSON with data
StaticJsonDocument<1000> doc;
JsonArray Temperature_8_Data = doc.createNestedArray("LM35");
Temperature_8_Data.add(temp2_0);
Temperature_8_Data.add(temp2_1);
Temperature_8_Data.add(temp2_2);
Temperature_8_Data.add(temp2_3);
Temperature_8_Data.add(temp3_0);
Temperature_8_Data.add(temp3_1);
JsonArray DAC_Data = doc.createNestedArray("Voltage output");
DAC_Data.add(input_voltage);

//send json over serial
input = Serial.read(); 
serializeJson(doc, Serial);
Serial.println();
 
}


//Covert integer to voltage
float int16ToC(int16_t value)
{
    float voltage = value*0.512;
    voltage /= 32767.0;
    return (voltage)*100 ;
}
