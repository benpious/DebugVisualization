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

struct MangledName: Equatable, Codable {
    let runtimeUsableName: String
    let moduleName: String
    let typeName: String
}


extension String {
        
    /// A really really bad demangler.
    ///
    /// This is only tested to work with basic Classes and Structs. I'm not sure how this will fare with generics,
    /// but I'm not optimistic. It'll definitely fail with any builtin types.
    ///
    /// See [here](https://github.com/apple/swift/blob/master/docs/ABI/Mangling.rst) for when this is someday rewritten
    /// to not be awful.
    func basicDemangle() throws -> MangledName {
        // I cannot be bothered to do this with the real string API.
        // Swift name mangling uses punycode anyway, so there should be no ill effects from doing this
        // This could probably be made more efficient though
        let characters: [Character]
        if hasSuffix("VN") {
            // The thing you get from dlAddr for structs is different from what you get for classes for some reason.
            // We want the struct itself, and not its type metadata accessor.
            //
            // This is likely a place where more things will go wrong in future.
            characters = Array(dropFirst(2).dropLast(1))
        } else {
            // The dropfirst is for the "$s" prefix, which the runtime doesn't accept.
            characters = Array(dropFirst(2))
        }
        var current = 0
        while current + 1 < characters.count,
            numbers.contains(characters[current]) {
                current += 1
        }
        if let moduleOffset = Int(String(characters[0..<current])) {
            let moduleName = String(characters[current..<(current + moduleOffset)])
            let nameOffsetStart = current + moduleOffset
            current = nameOffsetStart + 1
            while current + 1 < characters.count,
                numbers.contains(characters[current]) {
                    current += 1
            }
            if let nameOffset = Int(String(characters[nameOffsetStart..<current])) {
                let name = String(characters[current..<(current + nameOffset)])
                return .init(runtimeUsableName: String(characters),
                             moduleName: moduleName,
                             typeName: name)
            } else {
                throw ErrorMessage("Couldn't construct the second offset from \(self)")
            }
        } else {
            throw ErrorMessage("Couldn't construct the first offset from \(self)")
        }
    }
    
}

extension Character {
    
    var isASCIINumber: Bool {
        numbers.contains(self)
    }
    
}

fileprivate let numbers: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ]
