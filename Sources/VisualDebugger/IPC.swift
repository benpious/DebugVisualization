import NIO

class Server {
    
    var onRead: (([UInt8]) -> ())? {
        get {
            handler.onRead
        }
        set {
            handler.onRead = newValue
        }
    }
    
    private let port: Int
        
    // TODO: there is an insane amount of indirection going on here, this cannot actually be the way to do it.
    // Actually read SwiftNIO's docs and try again.
    //
    // Also errors need to actually be handled properly here.
    
    fileprivate class Handler: ChannelInboundHandler {
        
        var onRead: (([UInt8]) -> ())? = nil
        
        typealias InboundIn = ByteBuffer
        typealias OutboundOut = ByteBuffer

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            var buffer = unwrapInboundIn(data)
            if let bytes = buffer.readBytes(length: buffer.readableBytes) {
                onRead?(bytes)
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
        let handler = self.handler
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        server = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
        )
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(BackPressureHandler()).flatMap { v in
                    channel.pipeline.addHandler(handler)
                }
        }
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
        .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
            
    func start() {
        server.bind(host: "localhost", port: port)
            .whenComplete { (result) in
                // TODO:
                print(result)
            }
    }

}
