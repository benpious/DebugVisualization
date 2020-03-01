import SwiftUI

struct E<T> {
     
}

//let metaData: Any.Type = E<Int>.self
//print(mangledName(from: metaData))

let path = "/Users/benpious/Library/Developer/Xcode/DerivedData/TestTarget-fvcihpsjhapikddgzwmubkcewywc/Build/Products/Debug/TestTarget.framework/Versions/A/TestTarget"
let lib = try! TargetLibrary(path: path)
let metadataName = "10TestTarget4DataV"
let view = lib.deserialize(message: .init(mangledDecodeName: metadataName,
                               mangledAnyViewName: "TestTarget_dataToAnyView",
                               data: """
    {
    "a": 5
    }
    """.data(using: .utf8)!))
print(view)

let listener = LLDBListener(port: 700)!
listener.start()
RunLoop.main.run()
print("test")

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = ContentView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        let controller = Controller()
        window.contentView = NSHostingView(rootView: contentView
            .environmentObject(controller))
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
    
}

struct ContentView: View {
    
    @EnvironmentObject
    var controller: Controller

    
    var body: some View {
        controller.view
    }
    
}

fileprivate let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
