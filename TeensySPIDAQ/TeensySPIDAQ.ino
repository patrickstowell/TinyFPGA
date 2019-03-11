#include <SPI.h>
int INPUTPIN = 5;

void setup (void)
{
  Serial.begin (115200);
  
  pinMode(SS, OUTPUT);
  pinMode(INPUTPIN, INPUT_PULLUP);

  SPI.begin ();
  SPI.setClockDivider(SPI_CLOCK_DIV32);

  
      writeDAQAddress(0, 2);
      writeDAQAddress(0, 0);
}

uint16_t a, b;

uint16_t transferAndWait (const uint16_t what)
{
  digitalWrite(SS, LOW);
  delayMicroseconds(1);
  uint16_t reader = SPI.transfer16(what);
  digitalWrite(SS, HIGH);
  delayMicroseconds(1);
  digitalWrite(SS, LOW);
  reader = SPI.transfer16(what);
  digitalWrite(SS, HIGH);
  delayMicroseconds(1);
  return reader;
}


uint16_t writeDAQAddress (const uint16_t address, const uint16_t value) 
{
  // Send read command
  digitalWrite(SS, LOW);
  delayMicroseconds(1);
  uint16_t error = SPI.transfer16(777);
  delayMicroseconds(1);
  digitalWrite(SS, HIGH);

  // Send read command
  digitalWrite(SS, LOW);
  delayMicroseconds(1);
  error = SPI.transfer16(address);
//  Serial.println(error);
  delayMicroseconds(1);
  digitalWrite(SS, HIGH);

  // Send confirmation command
  digitalWrite(SS, LOW);
  delayMicroseconds(1);
  uint16_t confirmation = SPI.transfer16(value);
//  Serial.println(confirmation);
  delayMicroseconds(1);
  digitalWrite(SS, HIGH);

  digitalWrite(SS, LOW);
  delayMicroseconds(1);
  uint16_t transferred = SPI.transfer16(0);
//  Serial.println(transferred);
  delayMicroseconds(1);
  digitalWrite(SS, HIGH);
  
  return confirmation;
}

uint16_t readDAQAddress (const uint16_t address) 
{
  // Send read command
  digitalWrite(SS, LOW);
   delayMicroseconds(1);
  uint16_t error = SPI.transfer16(699);
   delayMicroseconds(1);
  digitalWrite(SS, HIGH);

  // Send read command
  digitalWrite(SS, LOW);
   delayMicroseconds(1);
  error = SPI.transfer16(address);
   delayMicroseconds(1);
  digitalWrite(SS, HIGH);

  // Send confirmation command
  digitalWrite(SS, LOW);
   delayMicroseconds(1);
  uint16_t confirmation = SPI.transfer16(address);
   delayMicroseconds(1);
  digitalWrite(SS, HIGH);

  return confirmation;
}

uint16_t counter = 0;
int lasttime = 0;
int startval = 0;
int endval = 0;
void loop (void)
{

//    int curtime = millis();
//    if (curtime - lasttime - 1000 > 1000) {
//      float daqpersec = (float(counter) * 1000.0 / float(curtime - lasttime - 1000.0));
//      lasttime = curtime;
////      counter = 0;
//      Serial.print("DAQ PER SEC ");
//      Serial.println(counter);
//      counter=0;
//      delay(50);
      startval = micros();
      
      
//    }
//    Serial.println(digitalRead(INPUTPIN));
    if (digitalRead(INPUTPIN) > 0){
      
      counter++;
//      Serial.println("Recieving Transmission");

       uint16_t returned;
//        startval = micros();
//      
      for (uint16_t i = 0; i < 16; i++){
        returned = readDAQAddress(i);
      Serial.print(i);
      Serial.print(" ----> ");
      Serial.println(returned);
      }
      endval = micros();
      Serial.println(endval - startval);

//      returned = writeDAQAddress(0, 1);
    }

    
//    delay(500);      
}
