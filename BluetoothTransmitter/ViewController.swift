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

    var label: NSTextView!
    var button: NSButton!
    var myServiceUUID = CBUUID(string: "D701F42C-49E1-48E9-B6E2-3862FEB2F550")
    var myCharacteristic: CBCharacteristic!
    var bluetoothController : CBPeripheralManager!
    var subscriber: CBCentral!
    var dateFormatter = DateFormatter()
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        let text = NSTextView(frame: NSRect(x: 20, y: 20, width: 200, height: 24))
        text.isEditable = false
        text.string = "On hold..."
        text.backgroundColor = NSColor.red.withAlphaComponent(0.33)
        label = text
        view.addSubview(text)

        let buttonFor = NSButton()
        buttonFor.title = "SEND"
        buttonFor.action = #selector(buttonClicked)
        buttonFor.target = self
        buttonFor.frame.origin = NSPoint(x: 20, y: 60)
        buttonFor.sizeToFit()
        buttonFor.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.33).cgColor
        view.addSubview(buttonFor)
        button = buttonFor

        dateFormatter.dateFormat = "HH:mm:ss"
        bluetoothController = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        let thisData = [CBAdvertisementDataServiceUUIDsKey: [myServiceUUID]]
        bluetoothController.startAdvertising(thisData)
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
        subscriber = central
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("--- !! unsubscribe !! ---")
        // Stop pushing data and set button color appropriately
        timer?.invalidate()
        timer = nil
        label.string = "On hold..."
        label.backgroundColor = NSColor.red.withAlphaComponent(0.33)
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
            // Start pushing data. Also update button color to green to indicate running
            repeatTimestamp()
            label.string = "Transmitting..."
            label.backgroundColor = NSColor.green.withAlphaComponent(0.33)

        } else {
            // Stop pushing data and set button color
            timer?.invalidate()
            timer = nil
            label.string = "On hold..."
            label.backgroundColor = NSColor.red.withAlphaComponent(0.33)
        }
    }
}

