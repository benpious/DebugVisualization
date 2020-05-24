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

// Based on https://www.objc.io/blog/2019/12/16/drawing-trees/
//
// TODO: as noted in the above article, this is not particulary performant
// *before* the addition of `AnyView`s everywhere. Maybe there's a way to
// optimize it.

struct TreeVisualization: Identifiable, VisualizationType {
    
    let value: AnyView
    let id: Int
    let children: [TreeVisualization]
    fileprivate let direction: Tree.Direction
    
    init(from object: SomeObject) throws {
        var id = 0
        try self.init(from: object,
                      id: &id)
    }
    
    fileprivate init(from object: SomeObject,
                     id: inout Int) throws {
        id += 1
        self.value = try object.root.unwrap()
        self.id = id
        self.direction = try .init(try? object.direction.unwrap())
        children = try (object.children.unwrap() as [AnyObject])
            .map { (object: AnyObject) in
                try TreeVisualization(from: SomeObject(object),
                                      id: &id)
        }
    }
    
    var view: AnyView {
        AnyView(
            Tree(tree: self,
                 direction: direction)
        )
    }
    
}

fileprivate struct CollectDictionary<Key: Hashable, Value>: PreferenceKey {
    
    static var defaultValue: [Key: Value] {
        [:]
    }
    
    static func reduce(value: inout [Key : Value],
                       nextValue: () -> [Key : Value]) {
        value.merge(nextValue(),
                    uniquingKeysWith: { $1 })
    }
    
}

fileprivate struct Tree: View {
    
    enum Direction {
        
        case vertical
        case horizontal
        
        init(_ string: String?) throws {
            switch string {
            case "vertical",
                 nil:
                self = .vertical
            case "horizontal":
                self = .horizontal
            case .some(let string):
                throw ErrorMessage("Found \"\(string)\" as the value of direction, but expected either \"vertical\" or \"horizontal\".")
            }
        }
        
        func parent<Content>(
            spacing: CGFloat? = nil,
            @ViewBuilder content: () -> Content
        ) -> _ConditionalContent<VStack<Content>, HStack<Content>> where Content: View {
            switch self {
            case .vertical:
                return ViewBuilder
                    .buildEither(
                        first: VStack(alignment: .center,
                                      spacing: spacing,
                                      content: content)
                )
            case .horizontal:
                return ViewBuilder
                    .buildEither(
                        second: HStack(alignment: .center,
                                       spacing: spacing,
                                       content: content)
                )
            }
        }
        
        
        func child<Content>(
            spacing: CGFloat? = nil,
            @ViewBuilder content: () -> Content
        ) -> _ConditionalContent<HStack<Content>, VStack<Content>> where Content: View {
            switch self {
            case .vertical:
                return ViewBuilder
                    .buildEither(
                        first: HStack(alignment: .center,
                                      spacing: spacing,
                                      content: content)
                )
            case .horizontal:
                return ViewBuilder
                    .buildEither(
                        second: VStack(alignment: .leading,
                                       spacing: spacing,
                                       content: content)
                )
            }
        }
        
    }
    
    let tree: TreeVisualization
    let direction: Direction
    
    fileprivate typealias Key = CollectDictionary<TreeVisualization.ID, Anchor<CGPoint>>
    
    var body: some View {
        direction.parent(spacing: 10) {
            tree.value
                .anchorPreference(key: Key.self,
                                  value: .center) { (anchor) in
                                    [self.tree.id: anchor]
            }
            direction.child(spacing: 20) {
                ForEach(tree.children) {
                    Tree(tree: $0,
                         direction: self.direction)
                }
            }
        }
        .backgroundPreferenceValue(Key.self) { (centers) in
            GeometryReader { proxy in
                ForEach(self.tree.children) { (child) in
                    Path { path in
                        // TODO: Consider getting rid of these force-unwraps in favor of some sort
                        // of error message. On the other hand, if this crashes this is a good
                        // place to wind up to debug it...
                        path.move(to: proxy[centers[self.tree.id]!])
                        path.addLine(to: proxy[centers[child.id] ?? centers[self.tree.id]!])
                    }
                    .stroke()
                }
            }
        }
    }
    
}
