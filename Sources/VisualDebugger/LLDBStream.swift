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
    
    func handleMessage(_ message: String) {
        do {
            let message = try LLDBMessage(data: message)
            let library = try libraryCache[message.libraryLocation] ?? {
                let library = try TargetLibrary(path: message.libraryLocation)
                libraryCache[message.libraryLocation] = library
                return library
            }()
            let view = try library.deserialize(message: message)
            DispatchQueue.main.async {
                self.sink.add(view: view)
            }
        } catch {
            DispatchQueue.main.async {
                self.state = .error(error.localizedDescription)
            }
        }
    }
    
    private let server: Server
    
    private var libraryCache: [String: TargetLibrary] = [:]
    
    @Published
    private(set) var state: State = .message("Waiting for data 􀇱")
    
    let willChange = PassthroughSubject<LLDBStream, Never>()
    
    private var sink = Sink(capacity: 100) {
        didSet {
            state = .views(sink.pastMessages)
        }
    }
    
    enum State {
        case message(String)
        case error(String)
        case views([AnyView])
        
        // TOOD: delete this garbage. See RootView to understand why this is a thing.
        
        var message: String? {
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

        var views: [AnyView]? {
            if case .views(let message) = self {
                return message
            } else {
                return nil
            }
        }

    }
    
}

struct Sink {
        
    mutating func add(view: AnyView) {
        pastMessages.insert(view,
                            at: 0)
        if pastMessages.count > capacity {
            pastMessages.remove(at: 0)
        }
    }
    
    var capacity: Int
    
    private(set) var pastMessages: [AnyView] = []
    
}
