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

struct DataControl<Content>: View where Content: View {
    
    init(organization: Binding<Organization>,
         reset: @escaping () -> (),
         @ViewBuilder content: @escaping () -> (Content)) {
        _organization = organization
        self.content = content
        self.reset = reset
    }
    
    @Binding
    var organization: Organization
    
    let content: () -> (Content)
    
    let reset: () -> ()
    
    var body: some View {
        VStack {
            HStack {
                MenuButton("Organization") {
                    ForEach(Organization.allCases) { organization in
                        Button(String(describing: organization).capitalized) {
                            self.organization = organization
                        }
                    }
                }
                .fixedSize()
                Spacer()
                Button("Reset") {
                    reset()
                }
                Spacer()
            }
            content()
        }
        .padding(16)
    }
    
}

struct TabbedVisualizationsView: View {
    
    let sections: [VisualizationSection]
    
    var body: some View {
        TabView {
            ForEach(sections) { section in
                LatestView(visualizations: section.visualizations)
                    .tabItem {
                        Text(section.name)
                    }
            }
        }
    }
    
}

struct LatestView: View {
    
    @State
    var index: Int?
    
    let visualizations: [Visualization]
    
    var body: some View {
        VStack {
            Divider()
            HSplitView {
                List(visualizations
                        .map {  String($0.pid) + ", " + dateFormatter.string(from: $0.timeStamp) }
                        .identified(),
                     selection: $index) { (timeStamp) in
                    Text(timeStamp.element)
                }
                .cornerRadius(8)
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        visualizations[index ?? 0].view
                        Spacer()
                    }
                    Spacer()
                }
                .layoutPriority(1)
                VStack {
                    Spacer()
                    Text(String(describing: visualizations[index ?? 0].mirrorInfo))
                        .lineLimit(nil)
                        .font(.system(.body,
                                      design: .monospaced))
                    Spacer()
                }
                .frame(idealWidth: 100)
            }
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
    }
    
}

fileprivate let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.setLocalizedDateFormatFromTemplate("HH:mm:ss-MMdd")
    return formatter
}()

enum Organization: CaseIterable, Identifiable {
    
    case tabs
    case interleaved
    
    var id: Int {
        switch self {
        case .tabs: return 0
        case .interleaved: return 1
        }
    }
    
}

