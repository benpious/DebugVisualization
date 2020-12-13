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

import Combine
import SwiftUI

struct LLDBMessage: Codable {
    
    let mangling: MangledName
    let libraryLocation: String
    let data: Data
    let processIdentifier: Int
    
    init(mangling: MangledName,
         libraryLocation: String,
         data: Data,
         processIdentifier: Int) {
        self.mangling = mangling
        self.libraryLocation = libraryLocation
        self.data = data
        self.processIdentifier = processIdentifier
    }
    
    init(data: [UInt8]) throws {
        let data = Data(data.removingDoubleEscapedEscapeCharacters())
        let dictionary: [String: String]
        do {
        dictionary = try JSONDecoder()
            .decode([String: String].self,
                    from: data)
        } catch {
            // try-catch this code isn't strictly necessary,
            // but it's very useful for debugging to keep it around, because I'm not sure how
            // (or if it's possible) to print the swift error directly from a swift-error breakpoint.
//            print(error)
            throw error
        }
        if let processIdentifierString = dictionary["pid"],
           let processIdentifier = Int(processIdentifierString) {
            if let fileName = dictionary["fileName"] {
                if let mangledName = dictionary["mangledName"] {
                    if let dataString = dictionary["data"],
                       let data = dataString.data(using: .utf8) {
                        self.processIdentifier = processIdentifier
                        self.libraryLocation = fileName
                        self.data = data
                        self.mangling = try mangledName.basicDemangle()
                    } else {
                        throw ErrorMessage("Couldn't find or deserialize data in dictionary \(dictionary)")
                    }
                } else {
                    throw ErrorMessage("Couldn't find mangled name in dictionary \(dictionary)")
                }
            } else {
                throw ErrorMessage("Couldn't find file name in dictionary \(dictionary)")
            }
        } else {
            throw ErrorMessage("Couldn't find a pid in dictionary: \(dictionary)")
        }
    }
    
    var mangledAnyViewName: String {
        mangling.moduleName + "_" + mangling.typeName + "ToAnyView"
    }
    
}

final class TargetLibrary {
    
    private let lib: UnsafeMutableRawPointer
    
    init(path: String) throws {
        if let lib = dlopen(path, RTLD_NOW) {
            self.lib = lib
        } else {
            if let error = dlerror() {
                throw ErrorMessage(String(cString: error))
            } else {
                throw ErrorMessage("Couldn't load library at \(path)")
            }
        }
    }
    
    private func addressOfFunction(named name: String) -> UnsafeMutableRawPointer? {
        name.withCString { (body) in
            dlsym(lib, body)
        }
    }
    
    func deserialize(message: LLDBMessage) throws ->  AnyView {
        // TODO: check to make sure no symbolic references in the name
        if let type = _typeByName(message.mangling.runtimeUsableName) as? Decodable.Type {
            let data = try type.decode(from: message.data)
            typealias MakeObjcWrapper = @convention(c) (AnyObject) -> NSObject
            if let makeObjcWrapper = addressOfFunction(named: message.mangledAnyViewName) {
                let makeObjcWrapper = unsafeBitCast(makeObjcWrapper,
                                                    to: MakeObjcWrapper.self)
                return try makeVisualization(from: makeObjcWrapper(data as AnyObject))
            } else {
                throw ErrorMessage("Couldn't find a function named \(message.mangledAnyViewName)")
            }
        } else {
            throw ErrorMessage("type \(message.mangling.runtimeUsableName) doesn't conform to Decodable.")
        }
    }
    
    deinit {
        dlclose(lib)
    }
    
}

struct ErrorMessage: LocalizedError {
    
    let errorDescription: String
    
    var localizedDescription: String {
        errorDescription
    }
    
    init(_ value: String) {
        errorDescription = value
    }
    
}

fileprivate extension Decodable {
    
    static func decode(from data: Data) throws -> Self {
        try JSONDecoder().decode(self, from: data)
    }
    
}

extension Array where Element == UInt8 {
    
    func removingDoubleEscapedEscapeCharacters() -> [UInt8] {
        // We send the output of an llbd `expr` command, *not* the actual data. So lldb
        // and (maybe) Swift Strings do their own formatting and stuff that we have to
        // get rid of turn the string into valid JSON again.
        let backslash = 92
        // messages begin with a quote, and some other garbage that has to be removed
        var new = Array(dropFirst().dropLast(3))
        var removed = 0
        var shouldSkipNext = false
        for (index, char) in Array(dropFirst().dropLast(3)).enumerated() {
            if shouldSkipNext {
                // if we encounter a string like '\\\\"' we want the output to be '\\"', so we
                // skip the next character.
                shouldSkipNext = false
                continue
            }
            if char == backslash {
                new.remove(at: index - removed)
                removed += 1
                shouldSkipNext = true
            }
        }
        return new
    }
    
}

