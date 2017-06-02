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
    var myServiceUUID: CBUUID!
    var updateUUID: CBUUID!

    var myCharacteristic: CBCharacteristic!

    var bluetoothController : CBPeripheralManager!

    var subscriber: CBCentral!

    var dateFormatter = DateFormatter()


    override func viewDidLoad() {
        let text = NSTextView(frame: NSRect(x: 20, y: 20, width: 200, height: 24))
        text.isEditable = false
        text.string = "Running..."
        label = text
        view.addSubview(text)

        dateFormatter.dateFormat = "HH:mm:ss"

        let buttonFor = NSButton()
        buttonFor.title = "SEND"
        buttonFor.action = #selector(advertise)
        buttonFor.target = self
        buttonFor.frame.origin = NSPoint(x: 20, y: 60)
        buttonFor.sizeToFit()

        view.addSubview(buttonFor)
        button = buttonFor

        updateUUID = CBUUID(string: "A7AC8453-5A36-45D3-9F18-576B44299DD8")


        super.viewDidLoad()
        bluetoothController = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        myServiceUUID = CBUUID(string: "D701F42C-49E1-48E9-B6E2-3862FEB2F550")


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

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        //
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print(error)
        }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("ready to update")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print(characteristic.uuid)
        subscriber = central
    }


    func advertise() {

        let datum = Date()
        let stringFromDate = dateFormatter.string(from: datum)
        let data = stringFromDate.data(using: .utf8)
        print(data!.count)
//        myCharacteristic.value = data
        let myService = CBMutableService(type: myServiceUUID, primary: true)
        myService.characteristics = [myCharacteristic]
        bluetoothController.updateValue(data!, for: myCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: [subscriber])
    }

}

