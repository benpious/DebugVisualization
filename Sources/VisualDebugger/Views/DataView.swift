import SwiftUI

struct DataView: View {
    
    @State
    var type: VisualizationType = .latest
    
    enum VisualizationType: CaseIterable, Identifiable {
        
        var id: Int {
            switch self {
            case .latest: return 0
            case .sequence: return 1
            case .list: return 2
            }
        }
        
        case latest
        case sequence
        case list
        
    }
    
    let visualizations: [Visualization]
    
    var body: some View {
        VStack {
            HStack {
                MenuButton(label: Text("Visualization")) {
                    ForEach(VisualizationType.allCases) { (type) in
                        Button(String(describing: type).capitalized) {
                            self.type = type
                        }
                    }
                }
                .fixedSize()
                Spacer()
            }
            if type == .latest {
                LatestView(visualizations: visualizations)
            } else if type == .sequence {
                HorizontallyScrolling(visualizations: visualizations)
            } else if type == .list {
                ListView(views: visualizations)
            }
        }
        .padding(16)
    }
    
}

struct LatestView: View {
    
    @State
    var index: Int?
    
    let visualizations: [Visualization]
        
    var body: some View {
        VStack {
            Line(.gray)
            HStack {
                List(visualizations
                    .map { $0.timeStamp }
                    .identified(),
                     selection: $index) { (timeStamp) in
                        Text(String(describing: timeStamp.element))
                }
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        visualizations[index ?? 0].view
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
    }
    
}

struct ListView: View {
    
    init(views: [Visualization]) {
        self.views = views.identified()
    }
    
    private let views: [Identified<Visualization>]
    
    var body: some View {
        List(views) {
            Spacer()
            $0.view
            Spacer()
        }
    }
    
}

struct HorizontallyScrolling: View {
    
    init(visualizations: [Visualization]) {
        self.visualizations = visualizations.identified()
    }
    
    private let visualizations: [Identified<Visualization>]
    
    var body: some View {
        ScrollView(.horizontal,
                   showsIndicators: true) {
                    HStack {
                        ForEach(visualizations) {
                            $0.view
                        }
                    }
        }
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
