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
                    self.reset()
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
                DataView(visualizations: section.visualizations)
                    .tabItem {
                        Text(section.name)
                }
            }
        }
    }
    
}

struct DataView: View {
    
    let visualizations: [Visualization]
    
    var body: some View {
        LatestView(visualizations: visualizations)
    }
    
}

struct LatestView: View {
    
    @State
    var index: Int?
    
    let visualizations: [Visualization]
    
    var body: some View {
        VStack {
            Line(.gray)
            HSplitView {
                List(visualizations
                    .map { dateFormatter.string(from: $0.timeStamp) }
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
            }
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
    }
    
}

struct Line: View {
    
    let color: Color
    
    init(_ color: Color) {
        self.color = color
    }
    
    var body: some View {
        color.frame(height: 1)
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

