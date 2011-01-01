
/* 
 * SensorProcessor -- SensorProcessor.pde
 * Created by: Ryan M Sutton
 *  
 * Summary:  Uses TinyGPS and Wire Lib to collect GPS data and send it to
             the main processor on the I2C bus.
 *
 * Hardware: I2C connection to MainProcessor on pins 4 & 5
 *           GPS on ping 8 @ 9600 baud
 *           
 *
 * Copyright (c) 2010, Ryan M Sutton
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the Ryan M Sutton nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL Ryan M Sutton BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
*/

#include <TinyGPS.h>

#include <NewSoftSerial.h>


// Wire Slave Sender


#include <Wire.h>
#define TWI_FREQ 400000L
#define BUFMAX    100

int buffRead=0;
int buffWrite=0;
boolean buffInvert=false;
long buffer[BUFMAX];
byte buffType[BUFMAX];

int lastmill=0;
int start=0;
int now=0;
NewSoftSerial nss(8, 9);
TinyGPS gps;
char c;
void setup()
{
  Serial.begin(9600);
  nss.begin(9600);
  pinMode(13, OUTPUT);
  Wire.begin(2);                // join i2c bus with address #2
  Wire.onRequest(requestEvent); // register event
}

void loop()
{
  
  //int c=Serial.read();
  if (nss.available()){
    //Serial.print(".");
    //buffer[buffWrite] =nss.read(); 
    c=nss.read();
    //Serial.print(c);
    digitalWrite(13, LOW);
    if (gps.encode(c)){
      long lat, lon;
      float flat, flon;
      unsigned long age, date, time, chars;
      int year;
      byte month, day, hour, minute, second, hundredths;
      unsigned short sentences, failed;
      digitalWrite(13, HIGH);
      Serial.println("READ");
      gps.get_position(&lat, &lon, &age);
      buffType[buffWrite] = 0x1;
      buffer[buffWrite++] = lat;
      if (buffWrite==BUFMAX){
       buffWrite=0; 
       buffInvert=true;
      }
      buffType[buffWrite] = 0x2;
      buffer[buffWrite++] = lon;
      if (buffWrite==BUFMAX){
       buffWrite=0; 
       buffInvert=true;
      }
      buffType[buffWrite] = 0x3;
      buffer[buffWrite++] = gps.altitude();
      if (buffWrite==BUFMAX){
       buffWrite=0; 
       buffInvert=true;
      }
    //if (buffer[buffWrite] == '\n'){
      now = millis();
      //Serial.print(buffInvert,DEC);
      //Serial.print(",");
      //Serial.print(now-lastmill);
      //Serial.print(buffWrite);
      //Serial.print(",");
      //Serial.println(buffRead);
      lastmill=now;
      start=buffWrite;
    }
  
  }
  digitalWrite(13, LOW);
  if (nss.overflow()){
    digitalWrite(13, HIGH);
    Serial.print("!");
  }
  //delay(10);
}

// function that executes whenever data is requested by master
// this function is registered as an event, see setup()
void requestEvent()
{
  byte BTS=0;
  byte answer[6];
  
  //if buffer data is valid send next item
  if (((buffWrite >buffRead)&&!buffInvert)||((buffWrite <=buffRead)&&buffInvert)){
   Serial.println(buffer[buffRead],HEX);
   
   //build responce
   answer[4] = buffType[buffRead];
   answer[3] = buffer[buffRead] & 0xFF;
   answer[2] = (buffer[buffRead]>>8)&0xFF; 
   answer[1] = (buffer[buffRead]>>16)&0xFF;
   answer[0] = (buffer[buffRead]>>24)&0xFF;
   
   //compute checksum
   answer[5] = answer[0] ^ answer[1] ^ answer[2] ^ answer[3] ^ answer[4];

   //send responce
   Wire.send(answer,6);
   Serial.println(answer[0],HEX);
   Serial.println(answer[1],HEX);
   Serial.println(answer[2],HEX);
   Serial.println(answer[3],HEX);
   Serial.println(answer[4],HEX);
   Serial.println(answer[5],HEX);
   //Wire.send(BTS); 
   //Serial.println("---");
//  Serial.print(buffer[buffRead]);
//  Serial.print(",");
//  Serial.println(nss.overflow());
  if (buffRead++ == BUFMAX){
    buffRead=0;
    buffInvert=false;
  }
 }else{ //if not send error
   Wire.send(0xFF);
   
   Serial.print("*");
   /*Serial.print(buffInvert,DEC);
      Serial.print(",");
      //Serial.print(now-lastmill);
      Serial.print(buffWrite);
      Serial.print(",");
      Serial.println(buffRead);
 */}
  
}
