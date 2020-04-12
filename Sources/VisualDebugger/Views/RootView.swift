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

struct RootView: View {
    
    @EnvironmentObject
    var stream: LLDBStream
    
    var body: some View {
        ZStack {
            stream.state.view(using: $stream.organization,
                              reset: stream.reset)
        }
    }
    
}

extension LLDBStream.State {
    
    func view(using binding: Binding<Organization>,
              reset: @escaping () -> ()) -> AnyView {
        switch self {
        case .error(let error):
            return AnyView(
                ErrorView(text: error)
            )
        case .message(let message):
            return AnyView(
                WaitingView(message: message)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
            )
        case .interleavedViews(let views):
            return AnyView(
                DataControl(organization: binding,
                            reset: reset) {
                    DataView(visualizations: views)
                }
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .topLeading)
            )
        case .sectionedVisualizations(let sections):
            return AnyView(
                DataControl(organization: binding,
                            reset: reset) {
                    TabbedVisualizationsView(sections: sections)
                }
            )
        }
    }
        
}

