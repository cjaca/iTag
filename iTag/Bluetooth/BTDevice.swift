//
//  BTDevice.swift
//  iTag
//
//  Created by Jacek on 02/08/2019.
//  Copyright © 2019 issd. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BTDeviceDelegate: class {
    func deviceConnected()
    func deviceReady()
    func deviceDisconnected()
    func deviceButtonClicked()
    func deviceBatteryChanged(value: Int)
    func deviceRSSIChanged(rssi: Int)
}

class BTDevice: NSObject {
    private let peripheral: CBPeripheral
    private let manager: CBCentralManager
    private var buttonChar: CBCharacteristic?
    private var alarmChar: CBCharacteristic?
    private var batteryChar: CBCharacteristic?
    private var _batteryLevel: Int = 0
    private var _button: Int = 0
    private var _alarm: Bool = false
    
    
    weak var delegate: BTDeviceDelegate?
    
    var button: Int {
        get {
            return _button
        }
        set {
            guard _button != newValue else {return}
            
            _button = newValue
            if let char = buttonChar{
                peripheral.writeValue(Data(_: [UInt8(_button)]), for: char, type: .withResponse)
            }
        }
    }
    
    var name: String {
        return peripheral.name ?? "Unknown device"
    }
    
    var alarm: Bool {
        get {
            return _alarm
        }
        set {
            guard _alarm != newValue else { return }
            
            _alarm = newValue
            if let char = alarmChar {
                peripheral.writeValue(Data(bytes: [_alarm ? 0x02 : 0x00]), for: char, type: .withResponse)
            }
        }
    }
    
    init(peripheral: CBPeripheral, manager: CBCentralManager){
        self.peripheral = peripheral
        self.manager = manager
        super.init()
        self.peripheral.delegate = self
    }
    
    func connect() {
        manager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        manager.cancelPeripheralConnection(peripheral)
    }
    
    @objc func checkRssi(){
        peripheral.readRSSI()
    }
}

extension BTDevice {
    //these are called from BTManager, do not call directly
    
    func connectedCallback() {
        peripheral.discoverServices([BTUUIDs.buttonService, BTUUIDs.infoBatteryService, BTUUIDs.infoImmediateAlert])
        delegate?.deviceConnected()
    }
    
    func disconnectedCallback(){
        delegate?.deviceDisconnected()
    }
    
    func errorCallback(error: Error?){
        print("Device: error \(String(describing: error))")
    }
}

extension BTDevice: CBPeripheralDelegate{
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Device: discovered services")
        peripheral.services?.forEach {
            print(" \($0)")
            if $0.uuid == BTUUIDs.buttonService {
                peripheral.discoverCharacteristics([BTUUIDs.buttonClicked], for: $0)
            } else if $0.uuid == BTUUIDs.infoBatteryService {
                peripheral.discoverCharacteristics([BTUUIDs.batteryLevel], for: $0)
            } else if $0.uuid == BTUUIDs.infoImmediateAlert  {
                peripheral.discoverCharacteristics([BTUUIDs.alertLevel], for: $0)
            } else {
                peripheral.discoverCharacteristics(nil, for: $0)
            }
        }
        print()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Device: discovered characteristiscs")
        service.characteristics?.forEach {
            print("  \($0)")
            
            if $0.uuid == BTUUIDs.buttonClicked {
                print("Button characteristics ☝️")
                self.buttonChar = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            } else if $0.uuid == BTUUIDs.batteryLevel {
                print("Battery characteristics ☝️")
                self.batteryChar = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            } else if $0.uuid == BTUUIDs.alertLevel {
                print("Alarm characteristics ☝️")
                self.alarmChar = $0
                peripheral.readValue(for: $0)
            }
        }
        print()
        
        delegate?.deviceReady()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Device: updated value for \(characteristic)")
        
        if characteristic.uuid == buttonChar?.uuid, let b = characteristic.value?.parseInt() {
            _button = Int(b)
            peripheral.readRSSI()
            delegate?.deviceButtonClicked()
        }
        
        if characteristic.uuid == batteryChar?.uuid, let c = characteristic.value?.parseInt() {
            _batteryLevel = Int(c)
            delegate?.deviceBatteryChanged(value: _batteryLevel)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        delegate?.deviceRSSIChanged(rssi: Int(RSSI))
        print("\(Int(RSSI))")
    }
}
