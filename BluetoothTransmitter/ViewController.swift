//
//  ViewController.swift
//  BluetoothTransmitter
//
//  Created by Nathan Birkholz on 6/1/17.
//  Copyright © 2017 natebirkholz. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController, CBPeripheralManagerDelegate {

    var statusLabel: NSTextView!
    var subscriberLabel: NSTextView!
    var buttonLabel: NSTextView!
    var button: NSButton!
    var myServiceUUID = CBUUID(string: "D701F42C-49E1-48E9-B6E2-3862FEB2F550")
    var myCharacteristic: CBCharacteristic!
    var bluetoothController : CBPeripheralManager!
    var subscriber: CBCentral!
    var dateFormatter = DateFormatter()
    var timer: Timer?
    let redColor = NSColor.red.withAlphaComponent(0.33)
    let greenColor = NSColor.green.withAlphaComponent(0.33)

    override func viewDidLoad() {
        super.viewDidLoad()

        statusLabel = NSTextView(frame: NSRect(x: 20, y: 20, width: 120, height: 24))
        statusLabel.isEditable = false
        statusLabel.string = "On hold..."
        statusLabel.backgroundColor = redColor
        view.addSubview(statusLabel)

        subscriberLabel = NSTextView(frame: NSRect(x: 20, y: 60, width: 120, height: 24))
        subscriberLabel.isEditable = false
        subscriberLabel.string = "No subscriber..."
        subscriberLabel.backgroundColor = redColor
        view.addSubview(subscriberLabel)

        button = NSButton()
        button.title = "SEND"
        button.action = #selector(buttonClicked)
        button.target = self
        button.frame.origin = NSPoint(x: 20, y: 100)
        button.sizeToFit()
        button.isEnabled = false
        view.addSubview(button)

        buttonLabel = NSTextView(frame: NSRect(x: button.frame.maxX + 4, y: button.frame.origin.y - 4, width: 600, height: 24))
        buttonLabel.isEditable = false
        buttonLabel.backgroundColor = NSColor.clear
        buttonLabel.string = "(Send button enabled when there is a subscriber.)"
        view.addSubview(buttonLabel)

        dateFormatter.dateFormat = "HH:mm:ss"
        bluetoothController = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        let advertisement = [CBAdvertisementDataServiceUUIDsKey: [myServiceUUID]]
        bluetoothController.startAdvertising(advertisement)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        myCharacteristic = CBMutableCharacteristic(type: myServiceUUID, properties: [CBCharacteristicProperties.read, CBCharacteristicProperties.notify], value: nil, permissions: CBAttributePermissions.readable)
        let myService = CBMutableService(type: myServiceUUID, primary: true)
        myService.characteristics = [myCharacteristic]
        bluetoothController.add(myService)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print(error)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        subscriberLabel.backgroundColor = greenColor
        subscriberLabel.string = "Subscribed!"
        subscriber = central
        button.isEnabled = true
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("--- !! unsubscribe !! ---")
        // Stop pushing data and set labels appropriately
        timer?.invalidate()
        timer = nil
        statusLabel.string = "On hold..."
        statusLabel.backgroundColor = redColor
        subscriberLabel.string = "No subscriber..."
        subscriberLabel.backgroundColor = redColor
        button.isEnabled = false
    }

    func repeatTimestamp() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [unowned self] (timerRef) in
            guard let maybeTimer = self.timer, maybeTimer.isValid else { return }
            let datum = Date()
            let stringFromDate = self.dateFormatter.string(from: datum)
            let data = stringFromDate.data(using: .utf8)
            let myService = CBMutableService(type: self.myServiceUUID, primary: true)
            myService.characteristics = [self.myCharacteristic]

            let didSend = self.bluetoothController.updateValue(data!, for: self.myCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: [self.subscriber])
            print("timed at \(stringFromDate), didSend: \(didSend)")
        }
    }

    func buttonClicked() {
        if timer == nil {
            // Start pushing data. Also update label color to green to indicate running
            repeatTimestamp()
            statusLabel.string = "Transmitting..."
            statusLabel.backgroundColor = greenColor

        } else {
            // Stop pushing data and set label color
            timer?.invalidate()
            timer = nil
            statusLabel.string = "On hold..."
            statusLabel.backgroundColor = redColor
        }
    }
}

