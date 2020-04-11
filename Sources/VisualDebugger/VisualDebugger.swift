import SwiftUI

/// Entrypoint to the package.
///
/// You initialize this class with `LLDBStream()`,
/// and must then call `start()` to start listening for
/// debugger messages, and `makeView()` to get a view
/// that you can add to your window hierarchy in an `NSHostingView`.
public final class VisualDebugger {
        
    public init() {
        lldbStream = LLDBStream(port: 7001)
    }
    
    public func start() {
        lldbStream.start()
    }
    
    public func makeView() -> some View {
        RootView()
            .environmentObject(lldbStream)
    }
    
    private let lldbStream: LLDBStream
        
}

