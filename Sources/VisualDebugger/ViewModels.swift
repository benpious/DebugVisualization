import SwiftUI

struct Visualization: Hashable {
    
    let type: String
    let view: AnyView
    let timeStamp: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(timeStamp)
    }
    
    static func == (lhs: Visualization, rhs: Visualization) -> Bool {
        lhs.timeStamp == rhs.timeStamp
    }
        
}

struct VisualizationSection: Identifiable {
    
    var id: String {
        name
    }
    
    let name: String
    let visualizations: [Visualization]
    
}
