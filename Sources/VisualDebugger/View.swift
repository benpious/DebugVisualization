import SwiftUI

struct RootView: View {
    
    @EnvironmentObject
    var stream: LLDBStream
            
    var body: some View {
        ZStack {
            // TODO: switch to switch statement.
            // As far as I'm aware this is the only way to do this in Swift FunctionBuilders,
            // but it's painfully bad. 
            if stream.state.message != nil {
                Text(stream.state.message!)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
            } else if stream.state.error != nil {
                Text(stream.state.error!)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
            } else if stream.state.views != nil {
                LatestView(views: stream.state.views!)
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity,
                               alignment: .topLeading)
            }
        }
    }
    
}

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
                
            } else if type == .list {
                
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
