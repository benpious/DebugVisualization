import SwiftUI

struct DataControl<Content>: View where Content: View {
    
    init(organization: Binding<Organization>,
         @ViewBuilder content: @escaping () -> (Content)) {
        self.organization = organization
        self.content = content
    }
    
    var organization: Binding<Organization> // TODO: Find a way to use the @Binding annotation
    
    let content: () -> (Content)
    
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

