//
//  Copyright (c) 2020. Ben Pious
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import NIO

final class Server {
    
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
        // TODO: I feel like SwiftNIO can handle this by default somehow
        var accumulation: [UInt8] = []
        
        typealias InboundIn = ByteBuffer
        typealias OutboundOut = ByteBuffer

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            var buffer = unwrapInboundIn(data)
            if let bytes = buffer.readBytes(length: buffer.readableBytes) {
                accumulation += bytes
            }
            context.write(data, promise: nil)
        }

        func channelReadComplete(context: ChannelHandlerContext) {
            onRead?(accumulation)
            accumulation = []
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
                // TODO: Figure out if anything needs to be cleaned up, as the documtation states,
                // and if so, clean it up.
                print(result)
            }
    }

}

