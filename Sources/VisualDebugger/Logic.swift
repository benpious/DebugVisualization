//
//  File.swift
//  
//
//  Created by Benjamin Pious on 2/22/20.
//

import Foundation
import Combine
import XPC
import Combine
import SwiftUI


final class Controller: ObservableObject {

    @Published
    var view: AnyView = AnyView(Text("No Data"))
    
    let willChange = PassthroughSubject<Controller, Never>()

    let connection: xpc_connection_t
    
    func updateView<T>(to newView: T) where T: View {
        view = AnyView(newView)
    }
    
    func handleMessage(_ message: xpc_object_t) {
        let data = (message as! NSData) as Data
        let message = Message(data: data)
        switch message {
        case .newData(let newData):
            if let library = library {
                view = library.deserialize(message: newData)
            } else {
                fatalError()
            }
        case .loadLibrary(let path):
            do {
                library = try TargetLibrary(path: path)
            } catch {
                fatalError(error.localizedDescription) // TODO
            }
        }
    }
    
    init() {
        let queue = DispatchQueue(label: "ReceiveData")
        connection = xpc_connection_create("benpious.visualDebugger", queue)
        xpc_connection_set_event_handler(connection) { [weak self] (message) in
            self?.handleMessage(message)
        }
    }
    
    var library: TargetLibrary?
    
    func start() {
        xpc_connection_resume(connection)
    }
    
}

enum Message {
    
    init(data: Data) {
        fatalError()
    }
    
    case newData(NewDataMessage)
    case loadLibrary(path: String)
    
}

struct NewDataMessage {
    
    let mangledDecodeName: String
    let mangledAnyViewName: String
    //    let channel: String // TODO: support channels
    let data: Data
    
    init(mangledDecodeName: String,
         mangledAnyViewName: String,
         data: Data) {
        self.mangledDecodeName = mangledDecodeName
        self.mangledAnyViewName = mangledAnyViewName
        self.data = data
    }
    
}


extension NewDataMessage {
    
    init(data: Data) {
        fatalError()
    }

    
}

class TargetLibrary {
    
    let lib: UnsafeMutableRawPointer
    
    init(path: String) throws {
        if let lib = dlopen(path, RTLD_NOW) {
            self.lib = lib
        } else {
            throw "Couldn't load library at \(path)"
        }
    }
    
    func addressOfFunction(named name: String) -> UnsafeMutableRawPointer! {
        name.withCString { (body) in
            dlsym(lib, body)
        }
    }
        
    func deserialize(message: NewDataMessage) -> AnyView {
        // TODO: check to make sure no symbols are in the name
        let type = _typeByName(message.mangledDecodeName) as! Decodable.Type
        let data = try! type.decode(from: message.data)
        typealias MakeViewFunc = @convention(c) (AnyObject) -> NSObject
        let makeView = unsafeBitCast(addressOfFunction(named: message.mangledAnyViewName),
                                     to: MakeViewFunc.self)
        return makeView(data as AnyObject).value(forKey: "view") as! AnyView
    }
    
}

extension String: Error {
    
    public var localizedDescription: String {
        self
    }
    
}

extension Decodable {
        
    static func decode(from data: Data) throws -> Self {
        try JSONDecoder().decode(self, from: data)
    }
    
}

//struct S: Codable {
//    let a: Int
//}
//
//    func callF() {
//        struct Function {
//            let magic1: OpaquePointer
//            let magic2: OpaquePointer
//            let toFunction: OpaquePointer
//        }
//        struct FunctionTrampoline {
//            let trampoline: OpaquePointer
//            let function: OpaquePointer
//            let moreMagic: OpaquePointer
//            let magic3: OpaquePointer
//            let magic4: OpaquePointer
//        }
//        let name = "$s10TestTarget1fyySiF"
//        typealias FType = (Int) -> ()
//        let fAddr = addressOfFunction(named: name)!
////        let f = fAddr.
//        let opaqueF = OpaquePointer(fAddr)
//        let fa = UnsafePointer<FunctionTrampoline>(opaqueF).pointee
////        let f = unsafeBitCast(ftramp, to: FType.self)
//        let f = unsafeBitCast(fa, to: FType.self)
////        let f = opaqueF as! FType
////        let buffF = UnsafeRawBufferPointer(start: fAddr, count: 16)
////        let fP = UnsafePointer<UnsafePointer<FType>>(opaqueF)
////        let layout = MemoryLayout<FType>.size
////        let f = unsafeBitCast(fP.pointee, to: FType.self)
////        let f = fAddr
////            .assumingMemoryBound(to: FType.self)
//////            .bindMemory(to: FType.self,
//////            capacity: 1)
////            .pointee
//        f(5)
//    }
