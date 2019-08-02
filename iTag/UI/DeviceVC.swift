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

    var viewState: ViewState = .disconnected {
        didSet{
            switch viewState{
            case .disconnected:
                statusLabel.text = "Disconnected"
                alarmSwitch.isEnabled = false
                alarmSwitch.isOn = false
                batteryStatusLabel.isHidden = true
                disconnectButton.isHidden = true
            case .connected:
                statusLabel.text = "Probing..."
                alarmSwitch.isEnabled = false
                alarmSwitch.isOn = false
                batteryStatusLabel.isHidden = true
                disconnectButton.isHidden = true
            case .ready:
                statusLabel.text = "Ready"
                alarmSwitch.isEnabled = true
                alarmSwitch.isOn = false
                batteryStatusLabel.isHidden = false
                disconnectButton.isHidden = false
                
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
    }
    
    @IBAction func alarmChanged(_ sender: Any) {
        device?.alarm = alarmSwitch.isOn
    }
    
    
}

extension DeviceVC: BTDeviceDelegate {
    func deviceConnected() {
        viewState = .connected
    }
    
    func deviceReady() {
        viewState = .ready
    }
    
    func deviceDisconnected() {
        viewState = .disconnected
    }
    
    func deviceButtonClicked() {
        print(" ------------ ITAG BUTTON CLICKED ----------")
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
        batteryStatusLabel.text = String(value)
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
