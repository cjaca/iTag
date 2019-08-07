//
//  DeviceVC.swift
//  iTag
//
//  Created by Jacek on 02/08/2019.
//  Copyright © 2019 issd. All rights reserved.
//

import UIKit
import UserNotifications

class DeviceVC: UIViewController {
    enum ViewState: Int {
        case disconnected
        case connected
        case ready
    }
    
    var device: BTDevice? {
        didSet{
            navigationItem.title = device?.name ?? "Device"
            device?.delegate = self
        }
    }
    
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var batteryStatusLabel: UILabel!
    @IBOutlet weak var alarmSwitch: UISwitch!
    @IBOutlet weak var metersLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minimumRangeBigLabel: UILabel!
    @IBOutlet weak var maximumRangeBigLabel: UILabel!
    @IBOutlet weak var minStepper: UIStepper!
    @IBOutlet weak var maxStepper: UIStepper!
    @IBOutlet weak var rangeAlarmSwitch: UISwitch!
    @IBOutlet weak var buttonCounter: UILabel!
    var _minRange: Int = 0
    var _maxRange: Int = 20
    var buttonClicked: Int = 0
    
    var rssiArray = Array<Int>()
    

    var viewState: ViewState = .disconnected {
        didSet{
            switch viewState{
            case .disconnected:
                statusLabel.text = "Disconnected"
                alarmSwitch.isEnabled = false
                alarmSwitch.isOn = false
                batteryStatusLabel.isHidden = true
                disconnectButton.isHidden = true
                rangeAlarmSwitch.isEnabled = false
            case .connected:
                statusLabel.text = "Probing..."
                alarmSwitch.isEnabled = false
                alarmSwitch.isOn = false
                batteryStatusLabel.isHidden = true
                disconnectButton.isHidden = true
                rangeAlarmSwitch.isEnabled = false
            case .ready:
                statusLabel.text = "Ready"
                alarmSwitch.isEnabled = true
                alarmSwitch.isOn = false
                batteryStatusLabel.isHidden = false
                disconnectButton.isHidden = false
                rangeAlarmSwitch.isEnabled = true
                
                if let b = device?.alarm {
                    alarmSwitch.isOn = b
                }
            }
        }
    }
    
    deinit {
        device?.disconnect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        viewState = .disconnected
        rangeAlarmSwitch.isOn = false
        rangeAlarmChanged(self)
    }
    
    @IBAction func alarmChanged(_ sender: Any) {
        device?.alarm = alarmSwitch.isOn
    }
    
    @IBAction func rangeAlarmChanged(_ sender: Any) {
        minStepper.isEnabled = rangeAlarmSwitch.isOn
        maxStepper.isEnabled = rangeAlarmSwitch.isOn
        minLabel.isEnabled = rangeAlarmSwitch.isOn
        maxLabel.isEnabled = rangeAlarmSwitch.isOn
        minimumRangeBigLabel.isEnabled = rangeAlarmSwitch.isOn
        maximumRangeBigLabel.isEnabled = rangeAlarmSwitch.isOn
    }
    
    @IBAction func minStepperClicked(_ sender: Any) {
        let newValue = Int(minStepper.value)
        if newValue < self.maxRange {
            self.minRange = newValue
            maxStepper.minimumValue = Double(newValue) + 1
        }
        print(newValue)
    }
    
    @IBAction func maxStepperClicked(_ sender: Any) {
        let newValue = Int(maxStepper.value)
        if newValue > self.minRange {
            self.maxRange = newValue
            minStepper.maximumValue = Double(newValue) - 1
        }
        print(newValue)
    }
    
    
}

extension DeviceVC: BTDeviceDelegate {
    func deviceConnected() {
        viewState = .connected
    }
    
    func deviceReady() {
        viewState = .ready
        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(checkRssi), userInfo: nil, repeats: true)
    }
    
    @objc func checkRssi() {
        device?.checkRssi()
    }
    
    func deviceDisconnected() {
        viewState = .disconnected
        Timer.cancelPreviousPerformRequests(withTarget: #selector(checkRssi))
    }
    
    func deviceButtonClicked() {
        print(" ------------ ITAG BUTTON CLICKED ----------")
        buttonClicked += 1
        buttonCounter.text = String(buttonClicked)
        if UIApplication.shared.applicationState == .background {
            let content = UNMutableNotificationContent()
            content.title = "ITAG"
            content.body = "Button clicked"
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("DeviceVC: failed to deliver notification \(error)")
                }
            }
        }
    }
    
    
    func deviceBatteryChanged(value: Int) {
        batteryStatusLabel.text = String(value) + " %"
    }
    

    func deviceRSSIChanged(rssi: Int) {
        
        if rssiArray.count == 10 {
        
            var avarage: Double = 0
            for rssi in rssiArray {
                avarage += Double(rssi)
            }
            avarage = avarage / 10
            
            let distance = calculateDistance(avarageRssi: avarage)
            
            metersLabel.text = "\(distance.rounded(digits: 2)) m"
            rangeAlarm(range: Int(distance))
            rssiArray.removeAll()
        } else {
            rssiArray.append(rssi)
        }
    }
    
    func calculateDistance(avarageRssi: Double) -> Double {
        let rssi: Double = Double(avarageRssi)
        let txPower: Double = -60 //hard coded power value. Usually ranges between -59 to -65
        
        if (rssi == 0) {
            return -1.0;
        }
        
        let ratio = rssi*1.0/txPower;
        if (ratio < 1.0) {
            return pow(ratio,10);
        }
        else {
            let distance =  (0.89976)*pow(ratio,7.7095) + 0.111;
            return distance;
        }
    }
    
}

extension DeviceVC {
    var minRange: Int {
        get{
            return _minRange
        }
        set {
            _minRange = newValue
            minLabel.text = "\(_minRange)"
            
        }
    }
    
    var maxRange: Int {
        get{
            return _maxRange
        }
        set {
            _maxRange = newValue
            maxLabel.text = "\(_maxRange)"
        }
    }
    
    func rangeAlarm(range: Int) {
        if rangeAlarmSwitch.isOn {
            if range < minRange || range > maxRange {
                alarmSwitch.isOn = true
                device?.alarm = true
            }
        }
    }
    
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension Double {
    func rounded(digits: Int) -> Double {
        let multiplier = pow(10.0, Double(digits))
        return (self * multiplier).rounded() / multiplier
    }
}
