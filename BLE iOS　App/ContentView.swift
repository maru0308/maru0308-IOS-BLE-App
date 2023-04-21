

import SwiftUI
import CoreBluetooth


//Bluetoothペリフェラルとしてカウントを管理するクラス
class PeripheralManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    
    //     カウントを管理するPublishedプロパティ
    @Published var count = 0
    // Bluetoothペリフェラルマネージャ
    var peripheralManager: CBPeripheralManager!
    // サービスとキャラクタリスティックのUUID
    let serviceUUID = CBUUID(string: "Your ID")
    let characteristicUUID = CBUUID(string: "Your ID")
    
   
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }
    
    
    
    // アドバタイズを開始するメソッド
    func startAdvertising() {
        // サービスとキャラクタリスティックを作成し、ペリフェラルマネージャに追加
        let service = CBMutableService(type: serviceUUID, primary: true)
        let characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: .write, value: nil, permissions: .writeable)
        service.characteristics = [characteristic]
        peripheralManager.add(service)
        // アドバタイズ開始
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
    }
    
    // ペリフェラルマネージャの状態が更新されたときに呼ばれるデリゲートメソッド
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // ペリフェラルマネージャの状態に応じたメッセージを出力
        if peripheral.state == .poweredOn {
            print("Peripheral Manager is powered on.")
        } else {
            print("Peripheral Manager is not powered on.")
        }
    }
    
    // サービスが追加されたときに呼ばれるデリゲートメソッド
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        // エラーがある場合はエラー内容を出力、なければ成功メッセージを出力
        if let error = error {
            print("Error adding service: \(error.localizedDescription)")
        } else {
            print("Service added successfully.")
        }
    }
    
    // 書き込みリクエストを受信したときに呼ばれるデリゲートメソッド
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        // 受信したリクエストを処理
        for request in requests {
            if let value = request.value, value.count == 1 {
                count += Int(value[0])
                peripheralManager.respond(to: request, withResult: .success)
            } else {
                peripheralManager.respond(to: request, withResult: .invalidAttributeValueLength)
            }
        }
    }
}

struct ContentView: View {
    @StateObject var peripheralManager = PeripheralManager()
    
    var body: some View {
        VStack {
            Text("Count: \(peripheralManager.count)")
                .font(.largeTitle)
            Button(action: {
                peripheralManager.startAdvertising()
            }) {
                Text("通信を送る")
                    .font(.title)
            }
        }
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



