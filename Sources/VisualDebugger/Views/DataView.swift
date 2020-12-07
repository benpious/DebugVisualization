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
        self.organization = organization
        self.content = content
        self.reset = reset
    }
    
    var organization: Binding<Organization> // TODO: Find a way to use the @Binding annotation
    
    let content: () -> (Content)
    
    let reset: () -> ()
    
    var body: some View {
        VStack {
            HStack {
                MenuButton("Organization") {
                    ForEach(Organization.allCases) { organization in
                        Button(String(describing: organization).capitalized) {
                            self.organization.wrappedValue = organization
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
                LatestView(sections: [section])
                    .tabItem {
                        Text(section.name)
                    }
            }
        }
    }
    
}

struct LatestView: View {
    
    @State
    var selected: Visualization?
    
    let sections: [VisualizationSection]
    
    var body: some View {
        VStack {
            Divider()
            HSplitView {
                List(content: {
                        ForEach(sections) { section in
                            Section(header: Text("PID: \(section.name))")) {
                                ForEach(section.visualizations) { (visualization) in
                                    Cell(visualization: visualization,
                                         selectedVisualization: $selected)
                                }
                            }
                        }
                    }
                )
                .listStyle(SidebarListStyle())
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        if let selected = selected ?? sections.first?.visualizations.first {
                            selected.view
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
    }
    
}

fileprivate struct Cell: View {
    
    let visualization: Visualization
    
    @Binding
    var selectedVisualization: Visualization?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(dateFormatter.string(from: visualization.timeStamp))
            Divider()
        }
        .background({ () -> Color in
            if selectedVisualization == visualization {
                return .accentColor
            } else {
                return .clear
            }
        }())
        .onTapGesture {
            // Selection didn't work in this version of SwiftUI, so I had to do this.
            selectedVisualization = visualization
        }
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

