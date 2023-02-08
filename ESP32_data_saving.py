import serial
import time
import json
from itertools import chain
import numpy as np
import pyqtgraph as pg

# Serial port parameters
serial_speed = 115200
ser = serial.Serial('/dev/cu.usbserial-0001',baudrate=115200,timeout=1)
#ser = serial.Serial('COM4',baudrate=115200,timeout=1)




data_2d = np.zeros((500,6))
input_v = np.zeros(500)

win = pg.GraphicsLayoutWidget(show=True)
win.setWindowTitle('pyqtgraph example: Scrolling Plots')
p2 = win.addPlot()
win.nextRow()
p3 = win.addPlot()
#p2.setYRange(0, 25, padding=0)
p2.setMouseEnabled(x=None,y=None)
p2.setLabel(axis='left', text='Temperature (C)')
p2.setLabel(axis='bottom', text='Point number')
p2.hideAxis('bottom')

p2.setMouseEnabled(x=None,y=None)
p3.setLabel(axis='left', text='Voltage (V)')
p3.setYRange(0, 11, padding=0)


ptr1 = 0

curves_2d = [p2.plot(pen=idx,width=5) for idx, n in enumerate(data_2d.T)]

curve1 = p3.plot(input_v)



def plot_data(json_input):
    global data_2d,input_v,save_name
    esp32_json = json.loads(json_input)

    current_time = str(time.time_ns() // 1000000)
    json_string = [current_time,str(json.dumps(esp32_json))]

    print("*****")
    print(json_string)
    print("*****")




    # print(esp32_json)
    values_esp32 = list(esp32_json.values())
    list_esp32 = list(chain.from_iterable(values_esp32))
    temp_val = list_esp32[-1]
    print(f' voltage {temp_val}')
    list_esp32 = list_esp32[:-1]
    average_temp = sum(list_esp32) / len(list_esp32)



    save_name = "/Users/damianwilliams/Desktop/lm35_data/lm35_saved_data.txt"
    with open(save_name, 'a') as f:
        f.write(str(json_string))


    input_v[:-1] = input_v[1:]
    input_v[-1] = temp_val
    curve1.setData(input_v)

    print(list_esp32)
    print(len(list_esp32))

    data_2d = np.vstack((data_2d, list_esp32))

    #data_2d = data_2d[:, :-1]
    #data_2d = data_2d[-1:, :]
    #print(data_2d)
    #print("*****")
    data_2d = np.delete(data_2d, (0), axis=0)


    for idx, n in enumerate(data_2d.T):
        # print(enumerate(data_2d))
        # print(n)
        plot_yes = (data_2d[:, idx])
        # print(plot_yes)
        # print("***")
        # plot_yes = (data_2d[:, idx])
        curves_2d[idx].setData(plot_yes)

    #print("{:.1f}".format(temp_val))



    p3.setTitle("Voltage: " + str("{:.2f}".format(temp_val)) + " V")
    p2.setTitle("Temperature: " + str("{:.2f}".format(average_temp)) + " C")





    pg.QtWidgets.QApplication.processEvents()


if ser.isOpen():
    #print("fd")

    while True:
        ser.flushInput()
        ser.write(b'R')
        time.sleep(0.2)

        try:
            line = ser.readline()
            #line = ser.readline().decode().strip()
            #print(line)
            #print("** ** **" )
            #print(line)
            line = line.decode("utf-8")
            #print("** ** **" )
            #print(line)

            try:

                orig_json = json.loads(line)

                check_list = list(orig_json.values())
                list_length_check = list(chain.from_iterable(check_list))

                if(len(list_length_check)==7):
                    print(line)
                    plot_data(line)




            except:
                print("String could not be converted to JSON")

        except:
            print("invalid")
