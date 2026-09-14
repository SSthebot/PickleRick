# PickleRick

We all love playing pickleball and wanted to create a smart pickleball paddle.

## What It Does

The Smart Pickleball Paddle uses embedded sensors to collect motion data during gameplay and calculate performance metrics, including:

* **Swing Speed**
* **RPM**
* **Spin Type**
* **Shot Detection**

Performance data is transmitted from the paddle to our native iOS application through **Bluetooth Low Energy (BLE)**, allowing players to view their shot metrics in real time.

## How We Built It

### Hardware

* **ESP32 Microcontroller** — Processes sensor data and handles Bluetooth communication.
* **MPU9250 9-DOF IMU** — Uses accelerometer and gyroscope data to measure paddle movement and rotation.
* **Custom Pickleball Paddle** — Integrates the electronics directly into the paddle.
* **3D-Printed Enclosure** — Houses and secures the electronics to the back of the paddle.
* **NimBLE** — Provides efficient BLE communication between the ESP32 and mobile application.

### Software

* **SwiftUI** — Built a native iOS application for real-time performance visualization.
* **MVVM Architecture** — Separates UI, application logic, and data to create a scalable and maintainable codebase.
* **CoreBluetooth** — Handles BLE communication between the iPhone and ESP32.
* **Firebase Firestore** — Stores user profiles, shot history, and performance statistics.
* **Firebase Authentication** — Provides secure user authentication and account management.
# Video Demo 

https://github.com/user-attachments/assets/1b40ad68-ff87-4cbf-9a1e-294e5aae1371


# Picture of the Paddle

<img width="447" height="552" alt="Screenshot 2026-09-14 at 12 58 35 AM" src="https://github.com/user-attachments/assets/eec2bac8-0e98-4ffb-a1e5-4abfee3d8cb9" />
