//
//  BLEManager.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/24/26.
//

import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var connectedDevice: BluetoothDevice?
    @Published var statusMessage = "Initializing Bluetooth..."
    @Published var receivedData: [String] = []
    @Published var latestValue: String = ""
    @Published var lastError: String?
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private let firebaseService = FirebaseService.shared
    
    // Connection time tracking
    private var connectionStartTime: Date?
    private var totalConnectionTime: TimeInterval = 0
    
    private let targetServiceUUID: CBUUID? = CBUUID(string: "abcd")  // Example: CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    private let targetCharacteristicUUID: CBUUID? = CBUUID(string: "1234")// Example: CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth is not ready"
            return
        }
        
        discoveredDevices.removeAll()
        isScanning = true
        statusMessage = "Scanning for devices..."
        
        // Scan for all peripherals or specific service UUID
        if let serviceUUID = targetServiceUUID {
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
        
        // Auto-stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.isScanning == true {
                self?.stopScanning()
            }
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if discoveredDevices.isEmpty {
            statusMessage = "No devices found"
        } else {
            statusMessage = "Scan complete"
        }
    }
    
    func connect(to device: BluetoothDevice) {
        stopScanning()
        statusMessage = "Connecting to \(device.name)..."
        connectedPeripheral = device.peripheral
        device.peripheral.delegate = self
        centralManager.connect(device.peripheral, options: nil)
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
        statusMessage = "Disconnecting..."
    }
    
    func sendData(_ data: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic,
              let data = data.data(using: .utf8) else {
            print("Cannot send data - not connected or no characteristic")
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth is ready"
        case .poweredOff:
            statusMessage = "Bluetooth is off - Please turn it on"
            isScanning = false
        case .unauthorized:
            statusMessage = "Bluetooth access denied"
        case .unsupported:
            statusMessage = "Bluetooth not supported on this device"
        case .resetting:
            statusMessage = "Bluetooth is resetting..."
        case .unknown:
            statusMessage = "Bluetooth state unknown"
        @unknown default:
            statusMessage = "Unknown Bluetooth state"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown Device"
        
        // Filter out devices with very weak signals
        guard RSSI.intValue > -200 else { return }
        
        let device = BluetoothDevice(
            id: peripheral.identifier,
            name: name,
            rssi: RSSI.intValue,
            peripheral: peripheral
        )
        
        // Avoid duplicates
        if !discoveredDevices.contains(where: { $0.id == device.id }) {
            discoveredDevices.append(device)
            discoveredDevices.sort { $0.rssi > $1.rssi } // Sort by signal strength
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusMessage = "Connected! Discovering services..."
        
        // Start tracking connection time
        connectionStartTime = Date()
        
        // Discover services
        if let serviceUUID = targetServiceUUID {
            peripheral.discoverServices([serviceUUID])
        } else {
            peripheral.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedDevice = nil
        connectedPeripheral = nil
        targetCharacteristic = nil
        
        // Calculate and save connection duration
        if let startTime = connectionStartTime {
            let sessionDuration = Date().timeIntervalSince(startTime)
            totalConnectionTime += sessionDuration
            
            print("Session duration: \(sessionDuration) seconds")
            print("Total connection time: \(totalConnectionTime) seconds")
            
            // Save session to Firebase
            Task {
                do {
                    try await firebaseService.saveSession(duration: sessionDuration)
                    print("Session saved to Firebase")
                } catch {
                    print("Failed to save session: \(error.localizedDescription)")
                }
            }
            
            connectionStartTime = nil
        }
        
        if let error = error {
            statusMessage = "Disconnected: \(error.localizedDescription)"
        } else {
            statusMessage = "Disconnected"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
        isConnected = false
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            statusMessage = "Error discovering services: \(error.localizedDescription)"
            return
        }
        
        guard let services = peripheral.services else { return }
        
        statusMessage = "Found \(services.count) service(s). Discovering characteristics..."
        
        // Discover characteristics for all services
        for service in services {
            if let charUUID = targetCharacteristicUUID {
                peripheral.discoverCharacteristics([charUUID], for: service)
            } else {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            statusMessage = "Error discovering characteristics: \(error.localizedDescription)"
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            // Subscribe to notifications if the characteristic supports it
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                targetCharacteristic = characteristic
                statusMessage = "Ready to receive data"
            }
            
            // Read the characteristic if it supports reading
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            
            // Store writable characteristic for sending data
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                if targetCharacteristic == nil {
                    targetCharacteristic = characteristic
                }
            }
        }
        
        if targetCharacteristic == nil {
            statusMessage = "Connected but no compatible characteristic found"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else { return }
        
        // Try to decode as string
        if let stringValue = String(data: data, encoding: .utf8) {
            // Clean the string
            let cleanedValue = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            latestValue = cleanedValue
            receivedData.append(cleanedValue)
            
            print("=== Received from ESP32 ===")
            print("Raw: \(stringValue)")
            print("Cleaned: \(cleanedValue)")
            print("Length: \(cleanedValue.count) characters")
            print("===========================")
            
            statusMessage = "Received data"
            
            // Try to parse as JSON and save to Firebase
            parseAndSaveShot(jsonString: cleanedValue)
            
            // Keep only last 100 values to prevent memory issues
            if receivedData.count > 100 {
                receivedData.removeFirst()
            }
        } else {
            // If not a string, show as hex
            let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            latestValue = hexString
            receivedData.append(hexString)
            statusMessage = "Received (hex): \(hexString)"
            print("Received non-UTF8 data: \(hexString)")
        }
    }
    
    private func parseAndSaveShot(jsonString: String) {
        // Clean up the JSON string (remove whitespace, newlines, null terminators)
        var cleanedString = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\0", with: "")  // Remove null terminators
            .replacingOccurrences(of: "\r", with: "")  // Remove carriage returns
        
        // If the string is wrapped in quotes, unwrap it
        if cleanedString.hasPrefix("\"") && cleanedString.hasSuffix("\"") {
            cleanedString = String(cleanedString.dropFirst().dropLast())
            // Unescape any escaped quotes
            cleanedString = cleanedString.replacingOccurrences(of: "\\\"", with: "\"")
        }
        
        // Only try to parse if it looks like JSON (starts with { and ends with })
        guard cleanedString.hasPrefix("{") && cleanedString.hasSuffix("}") else {
            print("Ignoring non-JSON data: \(cleanedString)")
            return
        }
        
        // Check if it contains shot-related keys before parsing
        guard cleanedString.contains("shot_type") || cleanedString.contains("speed") || cleanedString.contains("spin") else {
            print("Ignoring JSON without shot data: \(cleanedString)")
            return
        }
        
        print("Processing JSON string: \(cleanedString)")
        
        // Manual parsing as fallback if it's a formatted string
        if let shot = manualParseShotString(cleanedString) {
            print("Successfully parsed using manual parser")
            saveShot(shot)
            return
        }
        
        // Try standard JSON decoding
        guard let jsonData = cleanedString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let shot = try decoder.decode(ShotItem.self, from: jsonData)
            print("Successfully parsed using JSON decoder")
            saveShot(shot)
            lastError = nil  // Clear any previous errors on success
        } catch {
            // Only log detailed errors in debug, don't show to user for non-shot data
            print("Could not parse as shot data: \(error)")
            print("Received: \(cleanedString)")
            // Don't set lastError here - this is normal for non-shot data
        }
    }
    
    // Manual parser for string-formatted JSON from ESP32
    private func manualParseShotString(_ string: String) -> ShotItem? {
        // Try to extract values using simple string parsing
        // Expected format: {"shot_type":"Forehand","speed":65.5,"spin":2500.0,"spin_type":"topspin"}
        
        var shotType: String?
        var speed: Float?
        var spin: Float?
        var spinType: String?
        
        // Split by comma but be careful with quoted strings
        let components = extractKeyValuePairs(from: string)
        
        for (key, value) in components {
            switch key {
            case "shot_type":
                shotType = value
            case "speed":
                speed = Float(value)
            case "spin":
                spin = Float(value)
            case "spin_type":
                spinType = value
            default:
                break
            }
        }
        
        if let shotType = shotType,
           let speed = speed,
           let spin = spin,
           let spinType = spinType {
            return ShotItem(
                shot_type: shotType,
                speed: speed,
                spin: spin,
                spin_type: spinType
            )
        }
        
        return nil
    }
    
    // Extract key-value pairs from JSON-like string
    private func extractKeyValuePairs(from string: String) -> [(key: String, value: String)] {
        var pairs: [(String, String)] = []
        
        // Remove braces
        let cleaned = string
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split by comma first to get individual pairs
        let components = cleaned.components(separatedBy: ",")
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Split by colon to get key and value
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let keyPart = trimmed[..<colonIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                let valuePart = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Extract key (remove quotes if present)
                let key = keyPart.replacingOccurrences(of: "\"", with: "")
                
                // Extract value (remove quotes if present)
                let value = valuePart.replacingOccurrences(of: "\"", with: "")
                
                if !key.isEmpty && !value.isEmpty {
                    pairs.append((key, value))
                    print("Extracted pair: \(key) = \(value)")
                }
            }
        }
        
        return pairs
    }
    
    // Helper to save shot to Firebase
    private func saveShot(_ shot: ShotItem) {
        Task {
            do {
                try await firebaseService.addShot(shot)
                await MainActor.run {
                    self.lastError = nil
                    self.statusMessage = "Shot saved!"
                    print("Shot saved: \(shot.shot_type) at \(shot.speed) speed")
                }
            } catch {
                await MainActor.run {
                    self.lastError = "Failed to save: \(error.localizedDescription)"
                    print(self.lastError ?? "")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing characteristic: \(error.localizedDescription)")
        } else {
            print("Data sent successfully")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("Notifications enabled for characteristic: \(characteristic.uuid)")
        } else {
            print("Notifications disabled for characteristic: \(characteristic.uuid)")
        }
    }
}

