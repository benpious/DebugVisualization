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
        ContentView()
            .environmentObject(lldbStream)
    }
        
}

struct ContentView: View {
    
    @EnvironmentObject
    var stream: LLDBStream

    
    var body: some View {
        ZStack {
            stream.view
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
    }
    
}
