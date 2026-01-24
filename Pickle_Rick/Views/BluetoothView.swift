//
//  BluetoothView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import SwiftUI

struct BluetoothView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Status section
                VStack(spacing: 12) {
                    Image(systemName: bleManager.isConnected ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 80))
                        .foregroundColor(bleManager.isConnected ? .green : .blue)
                        .padding()
                    
                    Text(bleManager.statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if let error = bleManager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    if bleManager.isScanning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                
                // Main action button
                Button(action: {
                    if bleManager.isConnected {
                        bleManager.disconnect()
                    } else if bleManager.isScanning {
                        bleManager.stopScanning()
                    } else {
                        bleManager.startScanning()
                    }
                }) {
                    Text(bleManager.isConnected ? "Disconnect" : bleManager.isScanning ? "Stop Scanning" : "Scan for Devices")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(bleManager.isConnected ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Device list (only show when scanning or devices found)
                if !bleManager.discoveredDevices.isEmpty {
                    List {
                        Section(header: Text("Available Devices")) {
                            ForEach(bleManager.discoveredDevices) { device in
                                Button(action: {
                                    bleManager.connect(to: device)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(device.name)
                                                .font(.headline)
                                            Text("Signal: \(device.rssi) dBm")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if bleManager.connectedDevice?.id == device.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .disabled(bleManager.isConnected && bleManager.connectedDevice?.id != device.id)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Connect")
        }
    }
}

#Preview {
    BluetoothView()
}
