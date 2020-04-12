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
    
    init(mangling: MangledName,
         libraryLocation: String,
         data: Data) {
        self.mangling = mangling
        self.libraryLocation = libraryLocation
        self.data = data
    }
    
    init(data: [UInt8]) throws {
        guard let comma = ("," as Character).asciiValue else {
            throw ErrorMessage("This should never happen: a comma isn't convertible to ASCII.")
        }
        if let firstSplit = data.firstIndex(of: comma) {
            let restOfString = data[(firstSplit + 1)...]
            if let secondSplit = restOfString.firstIndex(of: comma) {
                libraryLocation = try String(
                    uInt8: Array(data[0..<firstSplit].dropFirst() + [0])
                ) // HACK:
                mangling = try String(
                    uInt8: Array(data[(firstSplit + 1)..<secondSplit].dropLast()) + [0]
                )
                    .basicDemangle()
                let encodedData = data[(secondSplit + 1)...]
                    .dropLast(3)
                    .removingDoubleEscapedEscapeCharacters()
                self.data = Data(encodedData)
            } else {
                throw ErrorMessage("Message should be of the form \"library location, mangled type name, data\", comma delimited: \(data)")
            }
        } else {
            throw ErrorMessage("Message should be of the form \"library location, mangled type name, data\", comma delimited: \(data)")
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
    
    func deserialize(message: LLDBMessage) throws -> AnyView {
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
    
    let errorDescription: String?
    
    var localizedDescription: String {
        errorDescription!
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

extension String {
    
    init(uInt8 bytes: [UInt8]) throws {
        self = try bytes.withUnsafeBufferPointer { (bytes) in
            try bytes.withMemoryRebound(to: CChar.self) { (bytes) in
                if let pointer = bytes.baseAddress,
                    let string = String(utf8String: pointer)  {
                    return string
                } else {
                    throw ErrorMessage("Couldn't convert data into UTF-8 encoded String.")
                }
            }
        }
    }
    
}

extension Array where Element == UInt8 {
    
    func removingDoubleEscapedEscapeCharacters() -> [UInt8] {
        let backslash = 92
        var new = self
        var removed = 0
        for (index, char) in enumerated() {
            if char == backslash {
                new.remove(at: index - removed)
                removed += 1
            }
        }
        return new
    }
    
}

