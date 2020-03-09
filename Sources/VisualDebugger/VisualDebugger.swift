import SwiftUI

public class VisualDebugger {
    
    let lldbStream: LLDBStream
    
    public init() {
        lldbStream = LLDBStream(port: 7000)
    }
    
    public func start() {
        lldbStream.start()
    }
    
    public func makeView() -> some View {
        RootView()
            .environmentObject(lldbStream)
    }
        
}

