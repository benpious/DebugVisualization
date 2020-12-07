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

final class LLDBStream: ObservableObject {

    init(port: Int) {
        server = Server(port: port)
        server.onRead = { [weak self] message in
            self?.handleMessage(message)
        }
    }
    
    func start() {
        server.start()
    }
    
    func handleMessage(_ message: [UInt8]) {
        do {
            let message = try LLDBMessage(data: message)
            let library = try libraryCache[message.libraryLocation] ?? {
                let library = try TargetLibrary(path: message.libraryLocation)
                libraryCache[message.libraryLocation] = library
                return library
            }()
            let view = try library.deserialize(message: message)
            transferToMain {
                self.sink.add(visualization: Visualization(pid: message.processIdentifier,
                                                           type: message.mangling.typeName,
                                                           view: view,
                                                           timeStamp: Date()))
            }
        } catch {
            transferToMain {
                self.state = .error(error.localizedDescription)
            }
        }
    }
    
    private let server: Server
    
    private var libraryCache: [String: TargetLibrary] = [:]
    
    @Published
    var organization: Organization = .interleaved {
        didSet {
            updateState()
        }
    }
    
    @Published
    private(set) var state: State = startingState
        
    let willChange = PassthroughSubject<LLDBStream, Never>()
    
    private var sink = Sink(capacity: 100) {
        didSet {
            updateState()
        }
    }
    
    private func updateState() {
        switch organization {
        case .interleaved:
            state = .interleavedViews(sink.pastMessages.sectioned(by: \.pid))
        case .tabs:
            state = .sectionedVisualizations(sink.pastMessages.sectioned(by: \.type))
        }
    }
    
    enum State {
        
        case message(Lines)
        case error(String)
        case interleavedViews([VisualizationSection])
        case sectionedVisualizations([VisualizationSection])
                
    }
    
    func reset() {
        sink.reset()
        state = startingState
        libraryCache = [:]
    }
   
}

fileprivate let startingState: LLDBStream.State = .message(Lines([
    .init("Waiting for data...",
          style: .title),
    .init([
        .init("Use"),
        .init("command script import", style: .code),
        .init("to set up the script,")
    ]),
    .init([
        .init("and"),
        .init("send_visual myVarName", style: .code),
        .init("to start sending data")
    ])
]))

fileprivate struct Sink {
        
    mutating func add(visualization: Visualization) {
        pastMessages.insert(visualization,
                            at: 0)
        if pastMessages.count > capacity {
            pastMessages.remove(at: 0)
        }
    }
    
    var capacity: Int
    
    private(set) var pastMessages: [Visualization] = []
    
    mutating func reset() {
        pastMessages = []
    }
    
}

fileprivate extension Array where Element == Visualization {
    
    func sectioned<T>(by path: KeyPath<Element, T>) -> [VisualizationSection] where T: Hashable, T: CustomStringConvertible {
        var buckets: [T: [Visualization]] = [:]
        for element in self {
            let name = element[keyPath: path]
            if var bucket = buckets[name] {
                bucket.append(element)
                buckets[name] = bucket
            } else {
                buckets[name] = [element]
            }
        }
        return buckets.map { (name, visualizations) in
            VisualizationSection(name: name.description,
                                 visualizations: visualizations)
        }
    }
    
}

