

import SwiftUI
import CoreBluetooth


// CentralManagerは、セントラル（Apple Watch）の役割を担当するクラスです
class CentralManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isConnected = false
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    let serviceUUID = CBUUID(string: "Your ID")
    let characteristicUUID = CBUUID(string: "Your ID")
    

    @Published var isOneMeterAway = false
    

    var rssiUpdateTimer: Timer?
    
    
    
   
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        
    }
    
    
    
    //startScanningメソッドで、指定されたサービスUUIDを持つペリフェラルをスキャンします。
    func startScanning() {
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    //centralManagerDidUpdateStateメソッドで、セントラルマネージャの状態(central.state)が変更されたことを検知します。
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Central Manager is powered on.")
        } else {
            print("Central Manager is not powered on.")
        }
    }
    
    
    // ペリフェラルを検出したときに呼ばれるメソッドです。
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        
        
        
//        検出されたペリフェラルに接続を試みます。接続が成功した場合、centralManager(_:didConnect:)デリゲートメソッドが呼ばれ、失敗した場合はcentralManager(_:didFailToConnect:error:)が呼ばれます。
        central.connect(peripheral, options: nil)
    }
    
    
    // ペリフェラルに接続が成功した時、呼ばれるメソッドです。
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.delegate = self
        
        
        

        //        リフェラルデバイスのReceived Signal Strength Indicator（RSSI）を読み取るために使用されます
        //        peripheral(_:didReadRSSI:error:)デリゲートメソッドが呼び出されます
        peripheral.readRSSI()
        
        
        
        //         接続されたペリフェラルのサービスを探索します。
        //        サービスが見つかった場合、peripheral(_:didDiscoverServices:)デリゲートメソッドが呼ばれます
        peripheral.discoverServices([serviceUUID])
        
        
        //タイマーが1秒ごとにトリガーされるたびに実行されるクロージャです。このクロージャは、ペリフェラルデバイスのreadRSSI()メソッドを呼び出してRSSIを読み取ります。
        rssiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            peripheral.readRSSI()}
    }
    
    
    
    
    

//  ペリフェラルデバイスからRSSIが読み取られたときに、自動的に呼び出されます。
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            print("Error reading RSSI: \(error.localizedDescription)")
            return
        }
        
        checkDistance(rssi: RSSI)
    }
    
    
    
    
    
    // ペリフェラルへの接続が失敗したときに呼ばれるメソッドです。
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        print("Failed to connect to peripheral")
    }
    
    
    // ペリフェラルから切断されたときに呼ばれるメソッドです。
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        print("Disconnected from peripheral")
        
        
        //       切断時にタイマーを無効化する
        rssiUpdateTimer?.invalidate()
        rssiUpdateTimer = nil
        
    }
    
    
    // ペリフェラルのサービスが見つかったときに呼ばれるメソッドです。
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        //        サービスの検出中に何らかのエラーが発生,エラー内容をログに出力し、メソッドの実行を終了
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        if let services = peripheral.services {
            for service in services {
                //                サービスに関連するcharacteristicを検索するためのメソッド（didDiscoverCharacteristicsForデリゲートメソッド）を呼び出します
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    
    //    キャラクタリスティックが見つかったときに呼ばれるメソッドです。
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == characteristicUUID {
                    print("Found characteristic")
                }
            }
        }
    }
    
    //    カウンターをインクリメントするメソッドです。
    func incrementCounter() {
        guard let peripheral = peripheral, let characteristic = findCharacteristic() else { return }
        let value: UInt8 = 1
        let data = Data([value])
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        
    }
    
    
    //    CentralとPeripheralデバイス間の距離が約1メートルかどうかを判断
    
    func checkDistance(rssi: NSNumber) {
        //             rssi引数を受け取り、rssi.intValueで整数値に変換
        let rssiValue = rssi.intValue
        //           次に、約1メートルの閾値としてoneMeterRSSIThreshold変数に-60を設定
        let oneMeterRSSIThreshold = -60
        
        if rssiValue > oneMeterRSSIThreshold {
            //                 1メートル以内であると判断します
            isOneMeterAway = true
        } else {
            isOneMeterAway = false
        }
    }
    
    
    //    補助関数であり、特定のキャラクタリスティックを検索する、incrementCounter()関数）でキャラクタリスティックを操作するために使用
    func findCharacteristic() -> CBCharacteristic? {
        guard let services = peripheral?.services else { return nil }
        for service in services {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.uuid == characteristicUUID {
                        return characteristic
                    }
                }
            }
        }
        return nil
    }
}


struct ContentView: View {
    @StateObject var centralManager = CentralManager()
    
    var body: some View {
        VStack {
            if centralManager.isConnected {
                Text("接続済み")
                    .font(.largeTitle)
            } else {
                Text("未接続")
                    .font(.largeTitle)
            }
            
            
            
            if centralManager.isOneMeterAway {
                Text("1メートル以内です")
                    .font(.headline)
            } else {
                Text("1メートル以上離れています")
                    .font(.headline)
            }
            
            
            Button(action: {
                if centralManager.isConnected {
                    centralManager.incrementCounter()
                } else {
                    centralManager.startScanning()
                }
            }) {
                Text(centralManager.isConnected ? "CountUP" : "通信を受信する")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



