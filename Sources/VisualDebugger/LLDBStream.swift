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
                self.sink.add(visualization: Visualization(type: message.mangling.typeName,
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
    private(set) var state: State = .message(Lines([
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
    
    let willChange = PassthroughSubject<LLDBStream, Never>()
    
    private var sink = Sink(capacity: 100) {
        didSet {
            updateState()
        }
    }
    
    private func updateState() {
        switch organization {
        case .interleaved:
            state = .interleavedViews(sink.pastMessages)
        case .tabs:
            state = .sectionedVisualizations(sink.pastMessages.sectioned())
        }
    }
    
    enum State {
        
        case message(Lines)
        case error(String)
        case interleavedViews([Visualization])
        case sectionedVisualizations([VisualizationSection])
                
    }
    
}

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
    
}

fileprivate extension Array where Element == Visualization {
    
    func sectioned() -> [VisualizationSection] {
        var buckets: [String: [Visualization]] = [:]
        for element in self {
            let name = element.type
            if var bucket = buckets[name] {
                bucket.append(element)
                buckets[name] = bucket
            } else {
                buckets[name] = [element]
            }
        }
        return buckets.map { (name, visualizations) in
            VisualizationSection(name: name,
                                 visualizations: visualizations)
        }
    }
    
}
