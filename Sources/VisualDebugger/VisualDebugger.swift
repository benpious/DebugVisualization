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

//public func startVisualDebugger() {
//    let path = "/Users/benpious/Library/Developer/Xcode/DerivedData/TestTarget-fvcihpsjhapikddgzwmubkcewywc/Build/Products/Debug/TestTarget.framework/Versions/A/TestTarget"
//    let lib = try! TargetLibrary(path: path)
//    let metadataName = "10TestTarget4DataV"
//    let view = lib.deserialize(message: .init(mangledDecodeName: metadataName,
//                                              mangledAnyViewName: "TestTarget_dataToAnyView",
//                                              data: """
//    {
//    "a": 5
//    }
//    """.data(using: .utf8)!))
//}

struct ContentView: View {
    
    @EnvironmentObject
    var stream: LLDBStream

    
    var body: some View {
        stream.view
    }
    
}
