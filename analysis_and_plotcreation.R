
library(tidyverse)
library(splitstackshape)
library(hms)
library(lubridate)


library(purrr)
library(tools)
library(jsonlite)
library(gghighlight)
library(rjson)
library(scales)


f_round_any = function(x, accuracy, f=round){f(x/ accuracy) * accuracy}

f_time_difference <- function(x){
  q <- as_hms(difftime(x,x[1])) %>%
    as.POSIXct(q, origin = "1970-01-01", "%H:%M:%OS3",tz=UTC)
  
}

f_ms_to_date = function(ms) {
  sec = as.numeric(ms)
  format(as.POSIXct(sec / 1000, origin = "1970-01-01"), "%H:%M:%OS3",tz="UTC")
}

file_name <-"/Users/damianwilliams/Dropbox/Programming/Python/lm35/lm35_newest/lm35_data/lm35_saved_data_1.txt"


all_data<-read.delim(file_name,header = F,sep = "\"")

all_data <- all_data %>%
  select(-c(V1,V2,V4,V6))%>%
  mutate(V3 = gsub("[^0-9.-]", "", V3))%>%
  mutate(V7 = gsub("[^0-9.-]", "", V7))%>%
  mutate(V5 = gsub(":", "", V5,fixed = T))%>%
  mutate(V5 = gsub("[", "", V5,fixed = T))%>%
  mutate(V5 = gsub("],", "", V5,fixed = T))%>%
  rename(Time = V3)%>%
  rename(LM35 = V5)%>%
  rename(Voltage = V7)%>%
  cSplit("LM35",sep=",")%>%
  mutate(Voltage = as.numeric(Voltage))%>%
  mutate(Time = as.numeric(Time))

options(digits.secs=3)
all_data_long <- all_data %>%
  pivot_longer(-Time)%>%
  cSplit("name",sep = "_")%>%
  mutate(Time_date = f_ms_to_date(Time))%>%
  mutate(name_1 = as_factor(name_1))%>%
  mutate(name_2 = as_factor(name_2))%>%
  mutate(reformatted_time = as_datetime((Time/1000),tz="UTC"))%>%
  mutate(name_1 = fct_rev(name_1))

head(all_data_long)

selected_data_period <- all_data_long %>%
filter(between(as_hms(reformatted_time),as_hms("10:57:30"), as_hms("10:59:00")))%>%
mutate(difference = f_time_difference(reformatted_time))%>%
as_tibble()




#Ramp_data_period


ramp_period <- all_data_long %>%
  #filter(between(as_hms(reformatted_time),as_hms("11:10:00"), as_hms("11:30:00")))%>%
  filter(between(as_hms(reformatted_time),as_hms("11:10:00"), as_hms("11:18:00")))%>%
  mutate(difference = f_time_difference(reformatted_time))%>%
  as_tibble()




v_t_plot <- ramp_period %>%
  select(Time,value,name_1,name_2)%>%
  pivot_wider(names_from = c(name_1,name_2),values_from = value)%>%
  mutate(interval = Voltage_NA - lag(Voltage_NA))%>%
filter(interval > 0.1)%>%
  mutate(volt_rounded = f_round_any(Voltage_NA,0.01))%>%
  select(-c(Voltage_NA,Time,interval))%>%
  pivot_longer(-volt_rounded)
  
  
summary_data_from_ESP32 <- v_t_plot %>%
 group_by(volt_rounded)%>%
  summarise(average_t = mean(value))

sensor_reading_esp32 <- summary_data_from_ESP32%>%
  rename(voltage = volt_rounded)%>%
  rename(temperature = average_t)%>%
  mutate(method = "esp32")
  

ggplot(sensor_reading_esp32,aes(voltage,temperature))+
  geom_point(size=1)+
  geom_vline(xintercept =3.3, linetype = 2,color="blue")




WindowsPathName <- "/Users/damianwilliams/Dropbox/Programming/Python/lm35/lm35_newest/lm35/lm35_data.atf"
#setwd(WindowsPathName)

raw_data_digi <- read.delim(WindowsPathName, header = TRUE, sep = "\t",skip=2)

selected_data_digi <- raw_data_digi %>%
  select(-3)%>%
  select(-contains("Path"))%>%
  mutate(voltage=f_round_any(R1S1.Mean..pA.,100))%>%
  select(-contains("Peak"))%>%
  select(-contains("Trace"))%>%
  select(-R1S1.Mean..pA.)%>%
  pivot_longer(-c(File.Name,voltage))


by_sensor_digi <- selected_data_digi %>%
  group_by(voltage,name)%>%
  summarise(average_temp = mean(value)*100)

by_sensor_digi_wide <- by_sensor_digi %>%
  pivot_wider(names_from = "name",values_from = "average_temp")

names(by_sensor_digi_wide)

oldnames = c("R1S2.Mean..V.","R1S3.Mean..V.","R1S4.Mean..V.","R1S5.Mean..V.","R1S6.Mean..V.","R1S7.Mean..V.")
newnames = c("LM35_1","LM35_2","LM35_3","LM35_4","LM35_5","LM35_6")

sensor_reading_digi <- by_sensor_digi_wide %>%
  rename_with(~ newnames[which(oldnames == .x)], .cols = oldnames)%>%
  pivot_longer(-voltage)%>%
  group_by(voltage)%>%
    summarise(temperature = mean(value))%>%
  mutate(voltage = voltage/1000)%>%
  mutate(method = "digidata")

ggplot(sensor_reading_digi,aes(voltage,temperature))+
  geom_point(size=1)+
 geom_vline(xintercept =3.3, linetype = 2,color="blue")+
  geom_vline(xintercept =5, linetype = 2,color="red")+
  annotate("text", x=3.6, y=10, label="3.3 V", angle=90,size=5)+
  annotate("text", x=5.3, y=10, label="5.0 V", angle=90,size=5)+
  labs(y = "Temperature (C)", x="Supply voltage (V)")

ggsave("/Users/damianwilliams/Dropbox/Programming/Python/lm35/lm35_newest/lm35_data/digi_voltage_vs_temp.png"
       ,height = 4,width = 6)




combined_data<-rbind(sensor_reading_digi,sensor_reading_esp32)

ggplot(combined_data,aes(voltage,temperature,color=method))+
  geom_point(size=1)+
  geom_vline(xintercept =3.3, linetype = 1,color="blue")+
  geom_vline(xintercept =5, linetype = 1,color="red")+
  annotate("text", x=3.6, y=10, label="3.3 V", angle=90,size=5)+
  annotate("text", x=5.3, y=10, label="5.0 V", angle=90,size=5)+
  theme(strip.placement = "outside",
        strip.background = element_blank())+
  labs(y = "Temperature C", x="Supply voltage (V)")#+
  #facet_wrap(~method,ncol=1,strip.position="left")+
  #ggtitle("Average temperature readings at different input voltages\nusing an ESP32 or a digitizer")

ggsave("/Users/damianwilliams/Dropbox/Programming/Python/lm35/lm35_newest/lm35_data/digi_esp32_voltage_vs_temp.png"
       ,height = 4,width = 6)





