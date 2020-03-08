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

struct LLDBMessage {
    
    let mangledDecodeName: String
    let libraryLocation: String
    //    let channel: String // TODO: support channels
    let data: Data
    
    init(mangledDecodeName: String,
         libraryLocation: String,
         data: Data) {
        self.mangledDecodeName = mangledDecodeName
        self.libraryLocation = libraryLocation
        self.data = data
    }
    
    var mangledAnyViewName: String {
        // HACK: find a good way of doing this.
//        (libraryLocation.components(separatedBy: "/").last ?? "") +
        "TestTarget_dataToAnyView"
    }
    
}


extension LLDBMessage {
    
    init(data: String) throws {
        let data = data.split(separator: ",")
        if data.count < 3 {
            throw "Message should be of the form \"library location, mangled type name, data\", comma delimited: \(data)"
        }
        libraryLocation = String(data[0].dropFirst()) // HACK: the dropfirst 2 is necessary because there's an extra '"\' in my test data. This needs to be investigated and fixed elsewhere
        mangledDecodeName = String(data[1].dropFirst(2).dropLast())
        let str = data
            .dropFirst(2)
            .joined(separator: ",")
            .replacingOccurrences(of: "\\\\", with: "")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .dropLast(3)
        self.data = str
            .data(using: .utf8)!
        print(str)
    }

    
}

class TargetLibrary {
    
    private let lib: UnsafeMutableRawPointer
    
    init(path: String) throws {
        if let lib = dlopen(path, RTLD_NOW) {
            self.lib = lib
        } else {
            if let error = dlerror() {
                throw String(cString: error)
            } else {
                throw "Couldn't load library at \(path)"
            }
        }
    }
    
    private func addressOfFunction(named name: String) -> UnsafeMutableRawPointer? {
        name.withCString { (body) in
            dlsym(lib, body)
        }
    }
    
    func deserialize(message: LLDBMessage) throws -> AnyView {
        // TODO: check to make sure no symbols are in the name
        if let type = _typeByName(message.mangledDecodeName) as? Decodable.Type {
            let data = try type.decode(from: message.data)
            typealias MakeViewFunc = @convention(c) (AnyObject) -> NSObject
            if let makeView = addressOfFunction(named: message.mangledAnyViewName) {
                let makeView = unsafeBitCast(makeView,
                    to: MakeViewFunc.self)
                let view = makeView(data as AnyObject).value(forKey: "view")
                if let view = view as? AnyView {
                    return view
                } else {
                    throw "\(view) couldn't be converted to SwiftUI.AnyView."
                }
            } else {
                throw "Couldn't find a function named \(message.mangledAnyViewName)"
            }
        } else {
            throw "type \(message.mangledDecodeName) doesn't conform to Decodable."
        }
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
