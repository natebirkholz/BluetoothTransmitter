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

    var streamTimer: Timer?
    let streamServiceUuid = CBUUID(string: "D701F42C-49E1-48E9-B6E2-3862FEB2F550")
    var streamService: CBMutableService!
    var streamCharacteristic: CBMutableCharacteristic!

    var annouceDataTimer: Timer?
    let announceServiceUuid = CBUUID(string: "5D191DA6-2F35-4CEB-AC41-993307328DD4")
    var announceService: CBMutableService?
    var announceCharacteristic: CBMutableCharacteristic?

    let dataServiceUuid = CBUUID(string: "B9E7620E-76A7-4A2A-BFB5-C2CD34072743")
    var dataService: CBMutableService?
    var dataCharacteristic: CBMutableCharacteristic?

    var peripheralManager : CBPeripheralManager!
    var subscriber: CBCentral!
    var dateFormatter = DateFormatter()

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
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        let advertisement = [CBAdvertisementDataServiceUUIDsKey: [streamServiceUuid, announceServiceUuid]]
        peripheralManager.startAdvertising(advertisement)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            streamCharacteristic = CBMutableCharacteristic(type: streamServiceUuid, properties: [CBCharacteristicProperties.read, CBCharacteristicProperties.notify], value: nil, permissions: CBAttributePermissions.readable)
            streamService = CBMutableService(type: streamServiceUuid, primary: true)
            streamService.characteristics = [streamCharacteristic]
            peripheralManager.add(streamService)

            announceCharacteristic = CBMutableCharacteristic(type: announceServiceUuid, properties: [CBCharacteristicProperties.read, CBCharacteristicProperties.notify], value: nil, permissions: CBAttributePermissions.readable)
            announceService = CBMutableService(type: announceServiceUuid, primary: true)
            if let announceChar = announceCharacteristic {
                announceService?.characteristics = [announceChar]
            }
            if let annouceSvc = announceService {
                peripheralManager.add(annouceSvc)
            }

            dataCharacteristic = CBMutableCharacteristic(type: dataServiceUuid, properties: [CBCharacteristicProperties.read], value: nil, permissions: CBAttributePermissions.readable)
            dataService = CBMutableService(type: dataServiceUuid, primary: true)
            if let dataChar = dataCharacteristic {
                dataService?.characteristics = [dataChar]
            }
            if let dataSvc = dataService {
                peripheralManager.add(dataSvc)
            }
        }
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
        streamTimer?.invalidate()
        annouceDataTimer?.invalidate()
        streamTimer = nil
        annouceDataTimer = nil
        statusLabel.string = "On hold..."
        statusLabel.backgroundColor = redColor
        subscriberLabel.string = "No subscriber..."
        subscriberLabel.backgroundColor = redColor
        button.isEnabled = false
    }

    func repeatTimestamp() {
        streamTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [unowned self] (timerRef) in
            guard let maybeTimer = self.streamTimer, maybeTimer.isValid else { return }
            let datum = Date()
            let stringFromDate = self.dateFormatter.string(from: datum)
            let data = stringFromDate.data(using: .utf8)

            let didSend = self.peripheralManager.updateValue(data!, for: self.streamCharacteristic, onSubscribedCentrals: [self.subscriber])
            print("stream timed at \(stringFromDate), didSend: \(didSend)")
        }

        annouceDataTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [unowned self] (timerRef) in
            guard let maybeTimer = self.annouceDataTimer, maybeTimer.isValid else { return }

            let datum =  Date()
            let stringFromDate = self.dateFormatter.string(from: datum)

            let dictionary = ["DataForCharacteristic": stringFromDate]
            let dataForData = NSKeyedArchiver.archivedData(withRootObject: dictionary)
            self.dataCharacteristic?.value = dataForData

            if let announceData = stringFromDate.data(using: .utf8), let announceCharacteristic = self.announceCharacteristic {
                let didSend = self.peripheralManager.updateValue(announceData, for: announceCharacteristic, onSubscribedCentrals: [self.subscriber])
                print("announce timed at \(stringFromDate), didSend: \(didSend)")
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic == dataCharacteristic {
            print("reading: ", dataCharacteristic?.value?.count as Any)
        }

        peripheral.respond(to: request, withResult: .success)
    }

    func buttonClicked() {
        if streamTimer == nil {
            // Start pushing data. Also update label color to green to indicate running
            repeatTimestamp()
            statusLabel.string = "Transmitting..."
            statusLabel.backgroundColor = greenColor

        } else {
            // Stop pushing data and set label color
            streamTimer?.invalidate()
            annouceDataTimer?.invalidate()
            streamTimer = nil
            annouceDataTimer = nil
            statusLabel.string = "On hold..."
            statusLabel.backgroundColor = redColor
        }
    }
}

