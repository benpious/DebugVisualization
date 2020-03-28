# VisualDebugger

`VisualDebugger` aims to let you write SwiftUI code inside your existing Swift Package/Xcode Project to visualize state or processes inside your app.

This project is currently a prototype. Many features have limitations which are discussed at the bottom of this file. 

## Installation

`VisualDebugger` is currently available as a Swift Package that you can integrate into a MacOS App. Due to limitations of SPM, it's currently impossible to provide the full app as a package. 

1. Press Command-Shift-N to make a new Project in Xcode, and choose single-view MacOS app. 
2. File>Swift Packages>Add Package Dependency. Enter `https://github.com/benpious/DebugVisualization` as the URL, and click "next." Pick the version you want, or simply pick `master`. 
3.  Replace the contents of  `AppDelegate.swift` with
```
import Cocoa
import SwiftUI
import VisualDebugger

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow?
    let debugger = VisualDebugger()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: debugger.makeView())
        window.makeKeyAndOrderFront(nil)
        debugger.start()
        self.window = window
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

```
4. Turn of the application sandbox for the new app. Thsi is necessary so that it can listen on a socket, and read the contents of your application under debug. 

You're now ready to run the app. 

## Setup and Usage

Once you've built and run the app, you need to prepare the application you wish to debug.

### Preparing the target application

First, you need to load a python script into `lldb`.  In your application's launch sequence add a breakpoint with an action like the following;

`command script import $path_to_visual_debugger_installation/send_command.py`

You should set this breakpoint to automatically continue after evaluating the actions.

If you find `VisualDebugger` useful, you might consider adding this command to your `.lldbinit` file. 

Once the preceding breakpoint is hit, the `send_visual` comand will be availabe to invoke from `lldb`. 

### An Example Usage

Suppose that you want to visualize an `[Int]` as a bar chart. Inside of the target application, perhaps even in the file with the variable you want, declare a struct as follows: 
```
#if canimport(SwiftUI)
import SwiftUI

struct MyVisualization: View, Codable {

    let data: [Int]
    
    var body: some View {
        HStack(spacing: 2.0) {
            ForEach(data.enumerated(), id: \.0) { (_, magnitude)
                Color.red.frame(height: 10 * magnitude)
            }
        }
    }
    
}

// the rest of the code will also be in the #if directive

#endif
```

Now, you must create a specially formed function that will be used by `VisualDebugger` as the entry point to your program. This function has a few requirements: 
-  The name must be of the form "[moduleName]_[TypeName]ToAnyView"
- The function's type must be `@convention(c) (AnyObject) -> NSObject`
- The function returns an class that can have the Objective-C `value(for:)`   function called on it; in short, you should inherit from `NSObject`

```
@_cdecl("MyTargetName_MyVisualizationToAnyView") 
func MyVisualizationToAnyView(data: AnyObject) -> AnyObject {
    class O: NSObject {
        
        init(view: AnyView) {
            self.view = view
        }
        
        @objc
        let view: Any 
    }
    let data = data as! MyVisualization
    return O(view: AnyView(data.body))
}

```

And with this done, you can add a breakpoint in the spot you want to send the variable, and type `send_visual` followed by your variable name. If you want this to behave more like a log, set the breakpoint to automatically continue after evaluating the action. 

`send_visual myVariableName`

## How does it work?

`VisualDebugger` loads your framework into its own process, and runs code directly from it. How it accomplishes that is fairly straightforward: 

1. The input to `send_visual` is encoded using the standard `JSONEncoder` functions fromt the standard library
2. `send_visual` gets a pointer to the type metadata for your type, and calls `Dl_info` to get the manged name of the type, and `dladdr` to get the file it needs to load in `VisualDebugger` itself.
3. This data is sent to `VisualDebugger` over a socket using `asyncio`.
4. Meanwhile, in `VisualDebugger`, the message is decoded.
5. `VisualDebugger` loads the library that contains the code using `dlopen`.
6. `VisualDebugger` attempts to demangle the name it got from step 2, and calls `_typeByName` from the stdlib to get a pointer to the metadata, which it then casts to `Decodable.Type`.
7. `VisualDebugger` gets a pointer to the `ToAnyView` function using `dlsym`
8. The data is deserialized, passed to the `ToAnyView ` function, and displayed onscreen.

## Limitations

`VisualDebugger` has only been tested with frameworks dynamically  linked to MacOS or iOS Simulator targets. Of course, builds directly to the simulator will not work because the binaries will not run on x86. 

### Unsupported Types

The only types that are officially supported to send are non-generic structs and classes, with builtins like `Int` excepted. 

As of this writing, `VisualDebugger` doesn't have a good enough understanding of the Swift runtime/name mangling system implemented to successfully deserialize any Swift Type. 

Calling `dlsym` on a generic type might not work because the type may not have been constructed yet in the debugger process (I have yet to test this).  

The Name demangler also only supports certain types; any type name with "symbolic references" in it will probbaly not work. 

### Ergonomics Issues

Working entirely in your project can be a double-edged sword. If you need a complex visualization, you can find your project is polluted with quick-and-dirty test code.  [Flipper](https://github.com/facebook/flipper) could be a good alternative if you want to keep test code out of your app, and it'll let you leverage the Javascript ecosystem by taking advantage of libraries like [D3](https://d3js.org).

The performance of lldb may also become an issue if you call `send_visual` in a tight loop. A potential solution to this would be to offer a `VisualDebugger` SDK. 
