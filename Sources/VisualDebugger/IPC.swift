import NIO
import Combine
import SwiftUI

class LLDBStream: ObservableObject {
    
    private let port: Int
    
    // TODO: there is an insane amount of indirection going on here, this cannot actually be the way to do it.
    // Actually read SwiftNIO's docs and try again.
    //
    // Also errors need to actually be handled properly here. 
    
    fileprivate class Handler: ChannelInboundHandler {
        
        var onRead: ((String) -> ())? = nil
        
        typealias InboundIn = ByteBuffer
        typealias OutboundOut = ByteBuffer

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            var buffer = unwrapInboundIn(data)
            if let bytes = buffer.readBytes(length: buffer.readableBytes) {
                let message = bytes.withUnsafeBufferPointer { (bytes) in
                    bytes.withMemoryRebound(to: CChar.self) { (bytes) in
                        String(utf8String: bytes.baseAddress!)
                    }
                }
                if let message = message {
                    onRead?(message)
                }
            }
            context.write(data, promise: nil)
        }

        func channelReadComplete(context: ChannelHandlerContext) {
            context.flush()
        }

        public func errorCaught(context: ChannelHandlerContext, error: Error) {
            print("error: ", error)
            context.close(promise: nil)
        }
        
    }
    
    private let handler = Handler()
    
    private let server: ServerBootstrap
    
    init(port: Int) {
        self.port = port
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        server = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
        )
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(BackPressureHandler()).flatMap { v in
                    channel.pipeline.addHandler(Handler())
                }
        }
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
        .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        handler.onRead = { [weak self] message in
            self?.handleMessage(message)
        }
    }
        
    func handleMessage(_ message: String) {
        
    }
    
    func start() {
        server.bind(host: "localhost", port: port)
            .whenComplete { (result) in
                print(result)
            }
    }

    
    @Published
    var view: AnyView = AnyView(Text("No Data"))
    
    let willChange = PassthroughSubject<LLDBStream, Never>()

}
