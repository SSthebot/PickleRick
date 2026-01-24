//
//  BluetoothDevice.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/24/26.
//

import Foundation
import CoreBluetooth

struct BluetoothDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral
    
    static func == (lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
        lhs.id == rhs.id
    }
}
