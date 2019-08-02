//
//  BTUUIDs.swift
//  iTag
//
//  Created by Jacek on 02/08/2019.
//  Copyright © 2019 issd. All rights reserved.
//

import CoreBluetooth

struct BTUUIDs {
    static let buttonClicked = CBUUID(string: "0000ffe1-0000-1000-8000-00805f9b34fb")
    static let buttonService = CBUUID(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
    
    static let alertLevel = CBUUID(string: "2A06")
    static let batteryLevel = CBUUID(string: "2A19")
    static let infoBatteryService = CBUUID(string: "180F")
    static let infoImmediateAlert = CBUUID(string: "1802")
}
