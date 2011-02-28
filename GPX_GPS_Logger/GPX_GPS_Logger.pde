#include <Consumer.h>

#include <Wire.h>

#include <Fat16.h>
#include <Fat16util.h> 

#include <GPX.h>
#include <avr/pgmspace.h>

#define   ERROR_LED      2
#define   SDWRITE_LED    3
#define   ENABLED_LED    4
#define   DONE_LED       5

#define   COLLECT_SW     6
#define   NEWSEG_SW      7

#define   WRDELAY        10


Consumer mySensors(2);
GPX myGPX;

SdCard card;
Fat16 file;

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


// store error strings in flash to save RAM
// From fat16print example
// http://code.google.com/p/fat16lib/
#define error(s) error_P(PSTR(s))
void error_P(const char* str) {
  PgmPrint("error: ");
  SerialPrintln_P(str);
  if (card.errorCode) {
    digitalWrite(ERROR_LED, HIGH);
    PgmPrint("SD error: ");
    Serial.print(card.errorCode, HEX);
  }
  while(1);
}


void openElement(){
  file.print(myGPX.getOpen());
  Serial.print(PSTR(_GPX_HEAD));
  delay(WRDELAY);
//  myGPX.setSrc("Venus");
  Serial.print(myGPX.getTrakOpen());
  file.print(myGPX.getTrakOpen());
  delay(WRDELAY);
  //file.print(myGPX.getInfo());
  //delay(WRDELAY);
  Serial.print(myGPX.getTrakSegOpen());
  file.print(myGPX.getTrakSegOpen());
  if (file.writeError || !file.sync()) error ("print or sync");
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
  if (file.writeError || !file.sync()) error ("print or sync");
}

void newFile(){
   // create a new file
  char name[] = "PRIN400.TXT";
  for (uint8_t i = 0; i < 100; i++) {
    name[5] = i/10 + '0';
    name[6] = i%10 + '0';
    if (file.open(name, O_CREAT | O_EXCL | O_WRITE)) break;
  }
  if (!file.isOpen()) error ("create");
  PgmPrint("Printing to: ");
  Serial.println(name);
  
  // clear write error
  file.writeError = false; 
}

void setup() {
  // Setup serial port
  Serial.begin(9600);
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
 
  // initialize the SD card
  // from fat16print example
  // http://code.google.com/p/fat16lib/
  if (!card.init()) error("card.init");
  if (!Fat16::init(&card)) error("Fat16::init");
  
  // create a new file
  /*char name[] = "PRIN400.TXT";
  for (uint8_t i = 0; i < 100; i++) {
    name[5] = i/10 + '0';
    name[6] = i%10 + '0';
    if (file.open(name, O_CREAT | O_EXCL | O_WRITE)) break;
  }
  if (!file.isOpen()) error ("create");
  PgmPrint("Printing to: ");
  Serial.println(name);
  
  // clear write error
  file.writeError = false;
  */
  //newFile();
}

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
  if ((state == 1 )&&(digitalRead(NEWSEG_SW)==HIGH)){
    Serial.print(myGPX.getTrakSegClose());
    file.print(myGPX.getTrakSegClose());
    state=3;
  }
  if ((state == 3 )&&(digitalRead(NEWSEG_SW)==LOW)){
    Serial.print(myGPX.getTrakSegOpen());
    file.print(myGPX.getTrakSegOpen());
    state=1;
  }
  
  digitalWrite(SDWRITE_LED, LOW);
  if (mySensors.getUpdate()){
   
    if (state==1){
      Serial.println(LoadAvailMem());
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
      Serial.println(*lat);
      Serial.println(*lon);
      stmp=(char*)malloc(sizeof(char)*40);
      if (myGPX.getPtOpen(stmp,lon,lat)){
       file.print(stmp);
       Serial.print(stmp); 
      }
      //Serial.print(myGPX.getPtOpen(GPX_TRKPT,*lon,*lat));
      //file.print(myGPX.getPtOpen(GPX_TRKPT,*lon,*lat));
      //if (file.writeError || !file.sync()) error ("print or sync");
      //delay(WRDELAY);
      free(stmp);
      free(lat);
      free(lon);
     
      //Elevation
      Serial.println(myGPX.getLongParm("ele",mySensors.getValue(0x5)));
      file.print(myGPX.getLongParm("ele",mySensors.getValue(0x5)));
      //if (file.writeError || !file.sync()) error ("print or sync");
      //delay(WRDELAY);

      //Date/Time
      tmp = (unsigned long*)malloc(sizeof(unsigned long));
      *tmp = mySensors.getValue(0x6);
      *tmp = (*tmp<<16)|mySensors.getValue(0x7);
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
     
      stmp=(char*)malloc(sizeof(char)*42);
      //buildISODateTime(st,M,D,Y,h,m,s,c);
      sprintf_P(stmp,PSTR("<time>20%2.i-%0.2i-%0.2iT%0.2i:%0.2i:%0.2i.%0.2i+00:00</time>"),Y,M,D,h,m,s,c);
      Serial.println(stmp);
      file.print(stmp);
      free(stmp);

      //Speed
      //tmp = (unsigned long*)malloc(sizeof(unsigned long));
      *tmp = mySensors.getValue(10);
      *tmp = (*tmp<<16)|mySensors.getValue(11);
      Serial.println(myGPX.getLongParm("desc",*tmp));
      file.print(myGPX.getLongParm("desc",*tmp));
      //if (file.writeError || !file.sync()) error ("print or sync");
      //delay(WRDELAY);
      free(tmp);
      
      Serial.print(myGPX.getPtClose(GPX_TRKPT));
      file.print(myGPX.getPtClose(GPX_TRKPT));
     
      digitalWrite(SDWRITE_LED, HIGH);
      if (file.writeError || !file.sync()) error ("print or sync");
 
    }
  }
  delay(200);
}
