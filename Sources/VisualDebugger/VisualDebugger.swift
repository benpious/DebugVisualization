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

