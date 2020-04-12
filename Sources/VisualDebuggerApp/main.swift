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

import Cocoa
import SwiftUI
import VisualDebugger
import Foundation

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow?
    let debugger = VisualDebugger()
        
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        NSApplication.shared.mainMenu = menu()
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
        // For some reason, SPM apps end up in a state where the activation policy seems to be
        // `prohibited`, so we set this ourselves.
        NSApplication.shared.setActivationPolicy(.regular)
        self.window = window
    }
        
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    private func menu() -> NSMenu {
        let menu = NSMenu()
        let submenuItem = NSMenuItem()
        submenuItem.title = "VisualDebugger"
        let submenu = NSMenu()
        // TODO: add more menu items if necessary. 
        submenu.addItem(.init(title: "Minimize",
                              action: #selector(NSApplication.miniaturizeAll(_:)),
                              keyEquivalent: "m"))
        submenu.addItem(.init(title: "Hide",
                              action: #selector(NSApplication.hide(_:)),
                              keyEquivalent: "h"))
        submenu.addItem(.init(title: "Quit VisualDebugger",
                              action: #selector(NSApplication.terminate(_:)),
                              keyEquivalent: "q"))
        submenuItem.submenu = submenu
        menu.addItem(submenuItem)
        return menu
    }

}

