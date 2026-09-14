We all love playing pickleball and wanted to create a smart pickleball paddle.

What It Does
It calculates different metrics such as speed, RPM, and spin type using sensors and displays them on an app that we built via Bluetooth connection.

How We Built It
Hardware
Embedded IMU sensors (accelerometer + gyroscope) into a custom pickleball paddle
ESP32 microcontroller to process sensor data and send it via Nimble Bluetooth library
3D printed case to hold breadboard to the back of the pickleball paddle
Software
Used MVVM design pattern to ensure scalable and maintainable code structure
Native iOS app built with SwiftUI for real-time data visualization
Bluetooth Low Energy integration using CoreBluetooth framework for paddle to phone connectivity
Firebase Firestore database to store all user data(UserId, ShotId, UserStatsId), Firebase Auth for login authentication
