import Combine
import SwiftUI

class LLDBStream: ObservableObject {

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
                self.sink.add(visualization: Visualization(view: view,
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
            state = .views(sink.pastMessages)
        }
    }
    
    enum State {
        case message(Lines)
        case error(String)
        case views([Visualization])
        
        // TOOD: delete this garbage. See RootView to understand why this is a thing.
        
        var message: Lines? {
            if case .message(let message) = self {
                return message
            } else {
                return nil
            }
        }
        
        var error: String? {
            if case .error(let message) = self {
                return message
            } else {
                return nil
            }
        }

        var views: [Visualization]? {
            if case .views(let message) = self {
                return message
            } else {
                return nil
            }
        }

    }
    
}

struct Sink {
        
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
