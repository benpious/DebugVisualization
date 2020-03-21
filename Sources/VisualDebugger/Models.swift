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
        print(try! String(uInt8: data))
        guard let comma = ("," as Character).asciiValue else {
            throw StringError("This should never happen: a comma isn't convertible to ASCII.")
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
                throw StringError("Message should be of the form \"library location, mangled type name, data\", comma delimited: \(data)")
            }
        } else {
            throw StringError("Message should be of the form \"library location, mangled type name, data\", comma delimited: \(data)")
        }
    }
    
    var mangledAnyViewName: String {
        mangling.moduleName + "_" + mangling.typeName + "ToAnyView"
    }
    
}

class TargetLibrary {
    
    private let lib: UnsafeMutableRawPointer
    
    init(path: String) throws {
        if let lib = dlopen(path, RTLD_NOW) {
            self.lib = lib
        } else {
            if let error = dlerror() {
                throw StringError(String(cString: error))
            } else {
                throw StringError("Couldn't load library at \(path)")
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
                    throw StringError("\(String(describing: view)) couldn't be converted to SwiftUI.AnyView.")
                }
            } else {
                throw StringError("Couldn't find a function named \(message.mangledAnyViewName)")
            }
        } else {
            throw StringError("type \(message.mangling.runtimeUsableName) doesn't conform to Decodable.")
        }
    }
    
    deinit {
        dlclose(lib)
    }
    
}

struct StringError: LocalizedError {
    
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
                    let string = String(utf8String: pointer.advanced(by: bytes.startIndex))  {
                    return string
                } else {
                    throw StringError("Couldn't convert data into UTF-8 encoded String.")
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

struct Visualization: Hashable {
    
    let view: AnyView
    let timeStamp: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(timeStamp)
    }
    
    static func == (lhs: Visualization, rhs: Visualization) -> Bool {
        lhs.timeStamp == rhs.timeStamp
    }
    
}
