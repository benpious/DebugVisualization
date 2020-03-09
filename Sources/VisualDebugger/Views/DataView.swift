import SwiftUI

struct DataView: View {
    
    @State
    var type: Visualization = .latest
    
    enum Visualization: CaseIterable, Identifiable {
        
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
    
    let views: [AnyView]
    
    var body: some View {
        VStack {
            MenuButton(label: Text("Visualization")) {
                ForEach(Visualization.allCases) { (type) in
                    Button(String(describing: type).capitalized) {
                        self.type = type
                    }
                }
            }
            .fixedSize()
            .padding(8)
            if type == .latest {
                LatestView(views: views)
            } else if type == .sequence {
                HorizontallyScrolling(views: views)
            } else if type == .list {
                ListView(views: views)
            }
            
        }
    }
    
}

struct LatestView: View {
    
    @State
    var index: Int = 0

    let views: [AnyView]
    
    var body: some View {
        VStack {
            Stepper("Index",
                    value: $index,
                    in: 0...(views.count - 1))
            views[index]
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
    }
            
}

fileprivate struct IndexedView: Identifiable {
    let id: Int
    let view: AnyView
}

struct ListView: View {
        
    init(views: [AnyView]) {
        self.views = views.enumerated().map { IndexedView(id: $0, view: $1) }
    }
    
    private let views: [IndexedView]
    
    var body: some View {
        List(views) {
            $0.view
        }
    }
}

struct HorizontallyScrolling: View {
    
    init(views: [AnyView]) {
        self.views = views.enumerated().map { IndexedView(id: $0, view: $1) }
    }
    
    private let views: [IndexedView]
    
    var body: some View {
        ScrollView(.horizontal,
                   showsIndicators: true) {
                    HStack {
                        ForEach(views) {
                            $0.view
                        }
                    }
        }
    }
    
}
