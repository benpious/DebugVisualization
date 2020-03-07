import Foundation
import Combine
import SwiftUI

class LLDBStream: ObservableObject {
    
    let inputStream: InputStream
    
    init?(port: UInt16) {
        var inputStream: InputStream?
        Stream.getStreamsToHost(withName: "localhost",
                                port: 7000,
                                inputStream: &inputStream,
                                outputStream: nil)
        if let inputStream = inputStream {
            self.inputStream = inputStream
        } else {
            return nil
        }
    }
    
    func start() {
        inputStream.open()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [inputStream] (_) in
            while inputStream.hasBytesAvailable {
                var buffer = Data(count: 100)
                let result = buffer.withUnsafeMutableBytes { (buffer) in
                    inputStream.read(buffer, maxLength: 100)
                }
                if result > 0 {
                    let string = String(data: buffer, encoding: .utf8)!
                    print(string)
                }
            }
        }
        RunLoop.main.add(timer,
                         forMode: .common)
    }
    
    @Published
    var view: AnyView = AnyView(Text("No Data"))
    
    let willChange = PassthroughSubject<LLDBStream, Never>()

}
