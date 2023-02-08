# lm35_test
Testing whether LM35 temperature sensors can be powered using 3.3 V.

LM35 is a low-cost analog temperature sensor which, according to the specification sheet, works with a supply voltage between 4 and 30 V. Many microcontroller boards (such as an ESP32) have a 3.3 V output so it would be advantageous to be able to use LM35 with this supply voltage. 
The [YouTube video](https://youtu.be/ar3s9zYWvNs) demonstrates that the LM35 can work with supply voltage of 3.3 V from an ESP32. It also shows that the sensor does not work at voltages less than ~ 3.1 V and but stable at higher supply voltages. 

To test the different LM35 supply voltages with the ESP32, six sensors were read via an ADS1115 ADC. This improved the resolution of the temperature readings when compared to the ADC embedded in the microcontroller. 3.3 V was delivered to the LM35 from the ESP32 3.3 power pin.  The 5 V supply was obtained from the EN pin (so was really 5 V used to power the ESP32 from the computer).

To provide the variable supply voltage, a LM358 operational amplifier was used to amplify 0 – 3.3 V input to a 0 – 10 V output. The input voltage was controlled by from the ESP32 using MCP4725 DAC (and a 12 V power supply). The output voltage was monitored using the ESP32 via a voltage divider and one of the channels of the ADS1115. Temperature/input data was transferred via the serial port to a computer running Python.

To confirm the data obtained from the ESP32, a Digidata 1550B digitizer was used to generate a variable supply voltage and read the temperature from the LM35s. This digitizer is typically used to measure electrical activity in neurons and contains very high quality components including a 16-bit DAC to provide the 0 – 10 V supply voltage, and a 16-bit ADC to read the LM35 output. The LM35 supply voltage was delivered as 5 s steps which incrementally increased by 100 mV until a final voltage of 10 V was reached. 

This repository contains the scripts used to acquire and analyse the data.

***esp32_lm35_test.ino*** is the ardunino code for the ESP32

***esp32_data_saving.py*** is the python script that creates the real-time scrolling plots which show the supply voltage and temperature reading. The script also saves the data.

 ***ESP32_lm35_data.txt*** is the data tranmitted from the ESP32 using serial communication using a json format and is saved a single text file.
 
 ***clean_up_sed_commands*** are commands needed to clean up the ESP32_lm35_data.txt and remove characters that prevent the file to be successfully imported to R. 
 
 ***analysis_and_plot_creation.R*** is the R script used to create the main plots to visualize the data.
 
 ***Digidata_output_data*** folder contains the .abf raw files generated from the Digidata. The first round of quantification was carried out using Clampfit anaysis program to create the ***Digidata_lm35_data_1.atf*** file.
 
 ***Digidata_plot_creation.ipf*** is an Igor Pro script that was used to create the Digidata plots used as frames within the YouTube video. 




