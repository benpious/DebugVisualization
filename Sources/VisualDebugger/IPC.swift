import Foundation

class LLDBListener {
    
    let inputStream: InputStream
    
    init?(port: UInt16) {
        var inputStream: InputStream?
        Stream.getStreamsToHost(withName: "localhost",
                                port: 700,
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
                var buffer: UnsafeMutablePointer<UInt8>?
                var length: Int = 0
                inputStream.getBuffer(&buffer, length: &length)
                let data = Data(buffer: UnsafeBufferPointer(start: buffer, count: length))
                let string = String(data: data, encoding: .utf8)!
                print(string)
            }
        }
        RunLoop.main.add(timer,
                         forMode: .common)
    }
        
}
