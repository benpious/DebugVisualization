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

typealias S = Lines.Line.Segment

struct Lines: View {
    
    enum Style {
        
        case code
        case title
        case body
        
        var font: Font {
            switch self {
            case .code:
                return .system(size: 16,
                               weight: .regular,
                               design: Font.Design.monospaced)
            case .title:
                return .title
            case .body:
                return .body
            }
        }
    }
    
    struct Line: View {
        
        init(_ segments: [Segment]) {
            self.segments = segments
        }
        
        init(_ text: String,
             style: Style = .body) {
            segments = [
                .init(text,
                      style: style)
            ]
        }
        
        let segments: [Segment]
        
        var body: some View {
            HStack {
                ForEach(segments.identified()) { (element)  in
                    element.body
                }
            }
        }
        
        struct Segment: View {
            
            init(_ text: String,
                 style: Style = .body) {
                self.text = text
                self.style = style
            }
            
            let text: String
            let style: Style
            
            var body: some View {
                Text(text)
                    .font(style.font)
                    .lineLimit(1)
            }
            
        }
        
        
    }
    
    init(_ lines: [Line]) {
        self.lines = lines
    }
    
    let lines: [Line]
    
    func line(_ text: String, style: Style = .body) -> Lines {
        .init(lines + [Line(text, style: style)])
    }
    
    func line(_ segments: [Line.Segment]) -> Lines {
        .init(lines + [Line(segments)])
    }

    
    var body: some View {
        VStack {
            ForEach(lines.identified()) { (line) in
                line.body
            }
        }
    }
    
}

@dynamicMemberLookup
struct Identified<T>: Identifiable {
    
    let element: T
    let id: Int
    
    subscript<U>(dynamicMember member: KeyPath<T, U>) -> U {
        element[keyPath: member]
    }
        
}

extension Identified: Equatable, Hashable where T: Equatable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

extension Array {
            
    func identified() -> [Identified<Element>] {
        enumerated()
            .map {
                Identified(element: $1,
                           id: $0)
        }
    }
    
}
