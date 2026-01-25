#include <Wire.h>
#include <Preferences.h>
#include <math.h>
#include <NimBLEDevice.h> 
#include "MPU9250.h" 

// --- YOUR CALIBRATION ---
const float CALIBRATION_FACTOR = 1.62; 
const float GRAVITY_OFFSET = 1.0;
bool isServe = false;

// --- CONFIGURATION ---
#define SPIN_MULTIPLIER 2.0 

// --- TRIGGER SETTINGS ---
const float JERK_THRESHOLD = 1.4; 

// --- BLE CONFIGURATION ---
#define SERVICE_UUID        "abcd" 
#define CHARACTERISTIC_UUID "1234"

// --- GLOBAL OBJECTS ---
MPU9250 IMU; 
Preferences preferences;
NimBLECharacteristic* pCharacteristic = NULL; 
volatile bool deviceConnected = false; 

// --- STATE VARIABLES ---
float previousMag = 0.0;     
unsigned long lastHitTime = 0;

// --- BLE CALLBACKS ---
class MyServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo) override { 
      deviceConnected = true; 
      Serial.println(">> CONNECTED");
      pServer->updateConnParams(connInfo.getAddress(), 6, 6, 0, 500);
    };
    void onDisconnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo, int reason) override { 
      deviceConnected = false;
      Serial.println(">> DISCONNECTED");
      NimBLEDevice::startAdvertising(); 
    }
};

void setup() {
  // 1. Serial Init
  pinMode(5, INPUT_PULLDOWN);
  Serial.begin(115200);
  while (!Serial) { delay(10); } 
  delay(1000); 

  Serial.println("--- BOOT START ---");

  // 2. BLE INITIALIZATION
  NimBLEDevice::init("PickleballTrainer"); 
  NimBLEServer* pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  NimBLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  pService->start();
  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setName("PickleballTrainer"); 
  pAdvertising->enableScanResponse(true);     
  pAdvertising->start();
  
  Serial.println("Step 1: BLE Started");

  // 3. HARDWARE SETUP
  Wire.begin();
  Wire.setClock(400000); 
  
  Serial.println("Step 2: Connecting to IMU...");
  
  if (!IMU.setup(0x68)) { 
    Serial.println("********************************");
    Serial.println("ERROR: IMU CONNECTION FAILED!");
    Serial.println("Check: 1. Wiring (SDA=21, SCL=22)");
    Serial.println("       2. Address (Try changing 0x68 to 0x69)");
    Serial.println("********************************");
    while (1) { delay(1000); } 
  }
  
  Serial.println("Step 3: IMU Connected Successfully");
  Serial.println("--- READY: JERK DETECTION ACTIVE ---");
}

void loop() {
  // Check Serve Button
  if (digitalRead(5) == LOW) {
    if (isServe) {
      isServe = false;
    }
    else {
      isServe = true;
    }
  }

  if (IMU.update()) {
    // 1. Get Current Force
    float ax = IMU.getAccX();
    float ay = IMU.getAccY();
    float az = IMU.getAccZ();
    float currentMag = sqrt(ax*ax + ay*ay + az*az);

    // 2. CALCULATE JERK
    float jerk = currentMag - previousMag;
    previousMag = currentMag;

    // 3. TRIGGER
    if (jerk > JERK_THRESHOLD && (millis() - lastHitTime > 500)) {
      lastHitTime = millis();
      
      // --- CAPTURE PEAK DATA ---
      float maxForce = currentMag;
      float gyroAtPeak = IMU.getGyroY();
      float shearForceAtPeak = ay; 
      
      unsigned long peakStart = millis();
      while (millis() - peakStart < 60) { 
         if (IMU.update()) {
            float nX = IMU.getAccX();
            float nY = IMU.getAccY();
            float nZ = IMU.getAccZ();
            float nMag = sqrt(nX*nX + nY*nY + nZ*nZ);
            
            if (nMag > maxForce) {
               maxForce = nMag;
               gyroAtPeak = IMU.getGyroY();
               shearForceAtPeak = nY; 
            }
         }
      }
      processHit(maxForce, gyroAtPeak, shearForceAtPeak);
      
      // Reset Serve flag after the hit is processed
      isServe = false; 
    }
    delay(10); 
  }
}

// --- PROCESS HIT: Calculate "Brush Ratio" ---
void processHit(float peakForceG, float gyroY, float shearForceG) {
  
  // 1. SPEED CALCULATION
  float adjustedForce = peakForceG - GRAVITY_OFFSET;
  if (adjustedForce < 0) adjustedForce = 0;
  float mph = adjustedForce * CALIBRATION_FACTOR;
  if (mph > 85.0) mph = 85.0; 

  // 2. SPIN LOGIC
  float baseRPM = (abs(gyroY) / 360.0) * 60.0;
  
  // Brush Ratio (Shear vs Normal)
  float brushRatio = abs(shearForceG) / peakForceG;
  
  float physicsMultiplier = 1.0;
  if (brushRatio > 0.3) physicsMultiplier = 1.5; // Heavy Grip
  else if (brushRatio < 0.1) physicsMultiplier = 0.8; // Glancing/Slipping

  float finalRPM = baseRPM * SPIN_MULTIPLIER * physicsMultiplier;

  // 3. SPIN TYPE
  String spinType = "Flat";
  if (gyroY > 50) spinType = "Topspin";
  else if (gyroY < -50) spinType = "Backspin";

  // --- OUTPUT ---
  Serial.println("\n--- IMPACT DETECTED ---");
  Serial.print("Shot Type: "); Serial.println(isServe ? "SERVE" : "Ground Stroke");
  Serial.print("Speed:     "); Serial.print(mph, 1); Serial.println(" MPH");
  Serial.print("Friction:  "); Serial.print(brushRatio * 100, 0); Serial.println("%");
  Serial.print("Spin:      "); Serial.print(finalRPM, 0); Serial.println(" RPM");
  Serial.println("-----------------------");

  if (deviceConnected) {
    String json = "{\"shot_type\":\""; 
    if (isServe) {
      json += "Serve";
    }
    else {
      json += "Ground Stroke";
    }
    json += "\",\"speed\":";
    json += String(mph, 1);
    json += ",\"spin\":";
    json += String(finalRPM, 0);
    json += ",\"spin_type\":\"";
    json += spinType;
    json += "\"}";
    pCharacteristic->setValue(json.c_str());
    pCharacteristic->notify();
  }
}