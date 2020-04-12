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

import SwiftUI

extension TargetLibrary {
    
    func makeVisualization(from object: AnyObject) throws -> AnyView {
        let object = SomeObject(object)
        let types: [VisualizationType.Type] = [SimpleVisualization.self, TreeVisualization.self]
        var errors: [String] = []
        for type in types {
            do {
                return try type.init(from: object).view
            } catch {
                errors.append(String(describing: type) + " " + error.localizedDescription)
            }
        }
        throw ErrorMessage("""
            No compatible visualization was found for the Objective-C wrapper you returned.
            The errors were:
            \(errors.joined(separator: "\n")))
            """)
    }
    
}

protocol VisualizationType {
        
    init(from: SomeObject) throws
    
    var view: AnyView { get }
    
}

@dynamicMemberLookup
final class SomeObject {
    
    let wrapped: AnyObject
    
    init(_ wrapped: AnyObject) {
        self.wrapped = wrapped
    }
    
    subscript<T>(dynamicMember member: String) -> Cast<T> {
        if wrapped.responds(to: NSSelectorFromString(member)) {
            return Cast(source: member,
                        wrapped.value(forKey: member))
        } else {
            return Cast(source: member,
                        nil)
        }
    }
    
    struct Cast<T> {
        
        let unwrap: () throws -> (T)
        
        init(source: String,
             _ instance: Any?) {
            unwrap = {
                if let wrapped = instance {
                    if let wrapped = wrapped as? T {
                        return wrapped
                    } else {
                        throw ErrorMessage("\\.\(source) must be of type `\(T.self)`, found \(type(of: wrapped))")
                    }
                } else {
                    throw ErrorMessage("No property named \"\(source)\" found.")
                }
            }
        }
        
    }
    
}
