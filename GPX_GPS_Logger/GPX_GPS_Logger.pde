#define DEBUG 1
#include <SD.h>
#define TWI_FREQ 400000L
#include <Consumer.h>
#include <Wire.h>
//#include <Fat16.h>
//#include <Fat16util.h> 
#include <GPX.h>
#include <avr/pgmspace.h>

#define   ERROR_LED      14
#define   SDWRITE_LED    0
#define   ENABLED_LED    1
#define   DONE_LED       12

#define   COLLECT_SW     3
#define   NEWSEG_SW      2

#define   WRDELAY        5

Consumer mySensors(2);
GPX myGPX;

//SdCard card;
//Fat16 file;
File file;


//state global
unsigned short state = 0;

int LoadAvailMem(){ // works with ATmega168, ATmega328 and ATmega644
//#if defined(__AVR_ATmega644P__) || defined(__AVR_ATmega644__)
//  int size = 4096;                      // if ATMega644
//#elif defined(__AVR_ATmega328P__)
  int size = 2048;                      // if ATmega328
//#elif defined(__AVR_ATmega168__)
//  int size = 1024;                      // if ATmega168
//#endif
  byte *buf;
  //memset(FreeChar,0,sizeof(FreeChar));
  //memset(message,0,sizeof(message));
  while ((buf = (byte *) malloc(--size)) == NULL);
  free(buf);
  return size;
}

/*
// store error strings in flash to save RAM
// From fat16print example
// http://code.google.com/p/fat16lib/
#define error(s) error_P(PSTR(s))
void error_P(const char* str) {
  PgmPrint("error: ");
  SerialPrintln_P(str);
//  if (card.errorCode) {
    digitalWrite(ERROR_LED, HIGH);
  //  PgmPrint("SD error: ");
  //  Serial.print(card.errorCode, HEX);
  //}
  while(1);
}
*/

void openElement(){
  file.print(myGPX.getOpen());
//  Serial.print(PSTR(_GPX_HEAD));
  delay(WRDELAY);
//  myGPX.setSrc("Venus");
//  Serial.print(myGPX.getTrakOpen());
  file.print(myGPX.getTrakOpen());
  //delay(WRDELAY);
  file.print(myGPX.getInfo());
  delay(WRDELAY);
//  Serial.print(myGPX.getTrakSegOpen());
  file.print(myGPX.getTrakSegOpen());
  file.flush();
  //if (file.writeError || !file.sync()) error ("print or sync");
}

void closeElement(){
  Serial.print(myGPX.getTrakSegClose());
  file.print(myGPX.getTrakSegClose());
  delay(WRDELAY);
  Serial.print(myGPX.getTrakClose());
  file.print(myGPX.getTrakClose());
  delay(WRDELAY);
  Serial.print(myGPX.getClose());
  file.print(myGPX.getClose());
  file.flush();
  //if (file.writeError || !file.sync()) error ("print or sync");
}

void newFile(){
   // create a new file
  Serial.println("newfile");
  char name[] = "PRIN400.GPX";
  for (uint8_t i = 0; i < 100; i++) {
    name[5] = i/10 + '0';
    name[6] = i%10 + '0';
    //if (file.open(name, O_CREAT | O_EXCL | O_WRITE)) break;
    if (!SD.exists(name)) break;
  }
  Serial.println(name);
  file = SD.open(name, O_WRITE | O_CREAT);
  //if (!file.available()) error ("create");
  PgmPrint("Printing to: ");
  Serial.println(name);
  
  // clear write error
  //file.writeError = false; 
}

int querySensor(HardwareSerial* _Serial, int addr){
  char c; 
  //_Serial->print("+++");
  //delay(500);
  //while(_Serial->available()==0);
  //while(_Serial->available()){
  // Serial.print(_Serial->read());
  // Serial.print(":");
  //}
  /*if (_Serial->read()!= 'O')
    return 0;
  if (_Serial->read()!= 'K')
    return 0;
  while(_Serial->available())
    c=_Serial->read();
 */
 // _Serial->print("ATDL");
 // _Serial->print(addr);
 // _Serial->print(",WR,CN\r");
 /*while(_Serial->available()==0);   
 if (_Serial->read()!= 'O')
   return 0;
 if (_Serial->read()!= 'K')
   return 0;
 while(_Serial->available()==0);
 while(_Serial->available())
   c=_Serial->read();*/
 //while(_Serial->available()==0);
 //while(_Serial->available()){
 //  Serial.print(_Serial->read());
 //  Serial.print("-");
 // }
 _Serial->write(48+addr);
 return addr;
}

void setup() {
  // Setup serial port
  Serial.begin(115200);
  Serial1.begin(115200);
  //Serial.begin(19200);
  Wire.begin();
  
  //setup pins & init to low
  pinMode(ERROR_LED, OUTPUT);
  pinMode(SDWRITE_LED, OUTPUT);
  pinMode(ENABLED_LED, OUTPUT);
  pinMode(DONE_LED, OUTPUT);
  pinMode(COLLECT_SW, INPUT);
  digitalWrite(ERROR_LED, LOW);
  digitalWrite(SDWRITE_LED, LOW);
  digitalWrite(ENABLED_LED, LOW);
  digitalWrite(DONE_LED, LOW);
 
  // see if the card is present and can be initialized:
  if (!SD.begin()) {
    Serial.println("Card failed, or not present");
    // don't do anything more:
    return;
  }
  Serial.println("card initialized.");
  // initialize the SD card
  // from fat16print example
  // http://code.google.com/p/fat16lib/
  //if (!card.init()) error("card.init");
  //if (!Fat16::init(&card)) error("Fat16::init");
}

unsigned int now=0;
void loop(){
  //decide if we need to open or close the GPX element
  if ((state == 0 )&&(digitalRead(COLLECT_SW)==LOW)){
    newFile();
    openElement();
    state=1;
    digitalWrite(ENABLED_LED, HIGH);
    digitalWrite(DONE_LED, LOW);
  }
  if ((state == 1 )&&(digitalRead(COLLECT_SW)==HIGH)){
    closeElement();
    state=0;
    file.close();
    digitalWrite(ENABLED_LED, LOW);
    digitalWrite(DONE_LED, HIGH);
  }
  if ((state == 1 )&&(digitalRead(NEWSEG_SW)==LOW)){
    //Serial.print(myGPX.getTrakSegClose());
    file.print(myGPX.getTrakSegClose());
    file.print(myGPX.getTrakClose());
    state=3;
  }
  if ((state == 3 )&&(digitalRead(NEWSEG_SW)==HIGH)){
    Serial.print(myGPX.getTrakSegOpen());
    file.print(myGPX.getTrakOpen());
    file.print(myGPX.getTrakSegOpen());
    state=1;
  }
  //state=1;
  while (Serial1.available()){
    char c;
    c = Serial1.read();
    Serial.print(c);
  } 
  //Serial.println(LoadAvailMem());
  digitalWrite(SDWRITE_LED, LOW);
  
  if (mySensors.getUpdate()){
    //Serial.println(LoadAvailMem());
    //Serial.println(now);
    now = millis();
    //Serial.println(now);
    if (state==1){
      //Serial.println(LoadAvailMem());
      long *lat,*lon;
      unsigned long *tmp;
      char* stmp;
    
      // Lat/Lon
      lat = (long*)malloc(sizeof(long));
      lon = (long*)malloc(sizeof(long));
      *lat = mySensors.getValue(0x1);
      *lat = (*lat<<16)|mySensors.getValue(0x2);
      *lon = mySensors.getValue(0x3);
      *lon = (*lon<<16)|mySensors.getValue(0x4);
      //Serial.println(*lat);
      //Serial.println(*lon);
      stmp=(char*)malloc(sizeof(char)*60);
      if (myGPX.getPtOpen(stmp,lon,lat)){
       file.print(stmp);
       //Serial.print(stmp); 
      }
      free(stmp);
      free(lat);
      free(lon);
      //delay(WRDELAY);
     
      //Elevation
      stmp=(char*)malloc(sizeof(char)*30);
      lat = (long*)malloc(sizeof(long));
      *lat = mySensors.getValue(0xF);
      *lat = (*lat<<16)|mySensors.getValue(0x5);
      Serial.println(*lat);
      if (myGPX.getLongParm(stmp,"ele",*lat)){
      //Serial.println(stmp);
      file.print(stmp);
      }
      free(stmp);
      free(lat);
      //Serial.println(myGPX.getLongParm("ele",mySensors.getValue(0x5)));
      //file.print(myGPX.getLongParm("ele",mySensors.getValue(0x5)));
      //if (file.writeError || !file.sync()) error ("print or sync");
      //file.flush();
      //delay(WRDELAY);

      //Date/Time
      
      tmp = (unsigned long*)malloc(sizeof(unsigned long));
      *tmp = mySensors.getValue(0x6);
      *tmp = (*tmp<<16)|mySensors.getValue(0x7);
      //Serial.println(*tmp, HEX );
      byte M=0,D=0,Y=0,h=0,m=0,s=0,c=0; 
      if ((*tmp>010100)&&(*tmp<319999)) {
        D = byte(*tmp/10000);
        M = byte(*tmp/100%100);
        Y = byte(*tmp%100);
      }
      *tmp = mySensors.getValue(0x8);
      *tmp = (*tmp<<16)|mySensors.getValue(0x9);
      if ((*tmp>0)&&(*tmp<24000000)) {
        h = byte(*tmp/1000000);
        m = byte(*tmp/10000%100);
        s = byte(*tmp/100%100);
        c = byte(*tmp%100);
      }
     
      stmp=(char*)malloc(sizeof(char)*70);
      //buildISODateTime(st,M,D,Y,h,m,s,c);
      sprintf_P(stmp,PSTR("<time>20%2.i-%0.2i-%0.2iT%0.2i:%0.2i:%0.2i.%0.2i+00:00</time>"),Y,M,D,h,m,s,c);
      Serial.println(stmp);
      file.print(stmp);
      //free(stmp);
      //delay(WRDELAY);

      //Speed
      
      //tmp = (unsigned long*)malloc(sizeof(unsigned long));
      *tmp = mySensors.getValue(0xA);
      *tmp = (*tmp<<16)|mySensors.getValue(0xB);
      
      file.print("<extensions>");
      //file.print(myGPX.getLongParm("speed",*tmp));
      if (myGPX.getLongParm(stmp,"speed",*tmp)){
        file.print(stmp);
        //Serial.print(stmp);
      }
      long itmp=0;
      itmp = mySensors.getValue(0xC);
      if (myGPX.getIntParm(stmp,"accelx",itmp)){
        file.print(stmp);
        //Serial.print(stmp);
      }
      itmp = (long)mySensors.getValue(0xD);
      if (myGPX.getIntParm(stmp,"accely",itmp)){
        file.print(stmp);
        //Serial.print(stmp);
      }
      itmp = (long)mySensors.getValue(0xE);
      if (myGPX.getIntParm(stmp,"accelz",itmp)){
        file.print(stmp);
        //Serial.print(stmp);
      }
      //if (file.writeError || !file.sync()) error ("print or sync");
      file.print("</extensions>");
      //delay(WRDELAY);
      free(stmp);
      free(tmp);
      
      //Serial.print(myGPX.getPtClose(GPX_TRKPT));
      file.println(myGPX.getPtClose(GPX_TRKPT));
      //Serial.println(millis()-now);
      digitalWrite(SDWRITE_LED, HIGH);
      //if (file.writeError || !file.sync()) error ("print or sync");
      file.flush();
    }
  }
  delay(10);
/*      while( Serial1.available()){
        byte d = Serial.read();
      }
      Serial.println(querySensor(&Serial1,1));
      if ((mySensors.getUpdate(&Serial1)>2)){
        Serial.println(mySensors.getValue(0xC));
        Serial.println(mySensors.getValue(0xD));
        Serial.println(mySensors.getValue(0xE));
      }
      while( Serial1.available()){
        byte d = Serial.read();
      }
      Serial.println(querySensor(&Serial1,2));
      if ((mySensors.getUpdate(&Serial1)>2)){
        Serial.println(mySensors.getValue(0xC));
        Serial.println(mySensors.getValue(0xD));
        Serial.println(mySensors.getValue(0xE));
      }
*/
}
