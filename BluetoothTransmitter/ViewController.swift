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

    var statusLabel: NSTextView?
    var subscriberLabel: NSTextView?
    var sendButtonLabel: NSTextView?
    var sendButton: NSButton?

    var streamServiceUuid = CBUUID(string: "D701F42C-49E1-48E9-B6E2-3862FEB2F550")
    var streamService: CBMutableService?
    var streamCharacteristic: CBMutableCharacteristic?

    var peripheralManager : CBPeripheralManager?
    var subscriber: CBCentral?
    var dateFormatter = DateFormatter()
    var streamTimer: Timer?
    let redColor = NSColor.red.withAlphaComponent(0.33)
    let greenColor = NSColor.green.withAlphaComponent(0.33)

    override func viewDidLoad() {
        super.viewDidLoad()

        let statusLabel = NSTextView(frame: NSRect(x: 20, y: 20, width: 120, height: 24))
        statusLabel.isEditable = false
        statusLabel.string = "On hold..."
        statusLabel.backgroundColor = redColor
        view.addSubview(statusLabel)
        self.statusLabel = statusLabel

        let subscriberLabel = NSTextView(frame: NSRect(x: 20, y: 60, width: 120, height: 24))
        subscriberLabel.isEditable = false
        subscriberLabel.string = "No subscriber..."
        subscriberLabel.backgroundColor = redColor
        view.addSubview(subscriberLabel)
        self.subscriberLabel = subscriberLabel

        let sendButton = NSButton()
        sendButton.title = "SEND"
        sendButton.action = #selector(buttonClicked)
        sendButton.target = self
        sendButton.frame.origin = NSPoint(x: 20, y: 100)
        sendButton.sizeToFit()
        sendButton.isEnabled = false
        view.addSubview(sendButton)

        let sendButtonLabel = NSTextView(frame: NSRect(x: sendButton.frame.maxX + 4, y: sendButton.frame.origin.y - 4, width: 600, height: 24))
        sendButtonLabel.isEditable = false
        sendButtonLabel.backgroundColor = NSColor.clear
        sendButtonLabel.string = "(Send button enabled when there is a subscriber.)"
        view.addSubview(sendButtonLabel)

        self.sendButton = sendButton
        self.sendButtonLabel = sendButtonLabel

        self.dateFormatter.dateFormat = "HH:mm:ss"
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        let advertisement = [CBAdvertisementDataServiceUUIDsKey: [self.streamServiceUuid]]
        self.peripheralManager?.startAdvertising(advertisement)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let streamCharacteristic = CBMutableCharacteristic(type: streamServiceUuid, properties: [CBCharacteristicProperties.read, CBCharacteristicProperties.notify], value: nil, permissions: CBAttributePermissions.readable)
        let streamService = CBMutableService(type: streamServiceUuid, primary: true)
        streamService.characteristics = [streamCharacteristic]
        self.peripheralManager?.add(streamService)

        self.streamCharacteristic = streamCharacteristic
        self.streamService = streamService
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print(error)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        subscriberLabel?.backgroundColor = greenColor
        subscriberLabel?.string = "Subscribed!"
        subscriber = central
        sendButton?.isEnabled = true
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("--- !! unsubscribe !! ---")
        // Stop pushing data and set labels appropriately
        streamTimer?.invalidate()
        streamTimer = nil
        statusLabel?.string = "On hold..."
        statusLabel?.backgroundColor = redColor
        subscriberLabel?.string = "No subscriber..."
        subscriberLabel?.backgroundColor = redColor
        sendButton?.isEnabled = false
    }

    func repeatTimestamp() {
        streamTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [unowned self] (timerRef) in
            guard let maybeTimer = self.streamTimer, maybeTimer.isValid else { return }
            guard let subscriber = self.subscriber else { return }
            guard let streamCharacteristic = self.streamCharacteristic else { return }

            let datum = Date()
            let stringFromDate = self.dateFormatter.string(from: datum)
            let data = stringFromDate.data(using: .utf8)

            let didSend = self.peripheralManager?.updateValue(data!, for: streamCharacteristic, onSubscribedCentrals: [subscriber])
            print("stream timed at \(stringFromDate), didSend: \(String(describing: didSend))")
        }
    }

    func buttonClicked() {
        if streamTimer == nil {
            // Start pushing data. Also update label color to green to indicate running
            repeatTimestamp()
            statusLabel?.string = "Transmitting..."
            statusLabel?.backgroundColor = greenColor

        } else {
            // Stop pushing data and set label color
            streamTimer?.invalidate()
            streamTimer = nil
            statusLabel?.string = "On hold..."
            statusLabel?.backgroundColor = redColor
        }
    }
}

