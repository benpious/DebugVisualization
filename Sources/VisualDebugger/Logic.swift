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
    
    let mangling: MangledName
    let libraryLocation: String
    let data: Data
    
    init(mangling: MangledName,
         libraryLocation: String,
         data: Data) {
        self.mangling = mangling
        self.libraryLocation = libraryLocation
        self.data = data
    }
    
    var mangledAnyViewName: String {
        mangling.moduleName + "_" + mangling.typeName + "ToAnyView"
    }
    
}


extension LLDBMessage {
    
    init(data: String) throws {
        let data = data.split(separator: ",")
        if data.count < 3 {
            throw "Message should be of the form \"library location, mangled type name, data\", comma delimited: \(data)"
        }
        libraryLocation = String(data[0].dropFirst()) // HACK: the dropfirst 2 is necessary because there's an extra '"\' in my test data. This needs to be investigated and fixed elsewhere
        mangling = try String(data[1].dropLast()).basicDemangle()
        let str = data
            .dropFirst(2)
            .joined(separator: ",")
            .replacingOccurrences(of: "\\\\", with: "")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .dropLast(3) // More Hacks
        if let data = str.data(using: .utf8) {
            self.data = data
        } else {
            throw "Couldn't convert data from UTF-8. This should never happen."
        }
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
        if let type = _typeByName(message.mangling.runtimeUsableName) as? Decodable.Type {
            let data = try type.decode(from: message.data)
            typealias MakeViewFunc = @convention(c) (AnyObject) -> NSObject
            if let makeView = addressOfFunction(named: message.mangledAnyViewName) {
                let makeView = unsafeBitCast(makeView,
                    to: MakeViewFunc.self)
                let view = makeView(data as AnyObject).value(forKey: "view")
                if let view = view as? AnyView {
                    return view
                } else {
                    throw "\(String(describing: view)) couldn't be converted to SwiftUI.AnyView."
                }
            } else {
                throw "Couldn't find a function named \(message.mangledAnyViewName)"
            }
        } else {
            throw "type \(message.mangling.runtimeUsableName) doesn't conform to Decodable."
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
