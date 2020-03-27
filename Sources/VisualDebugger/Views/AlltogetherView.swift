import SwiftUI

struct AllAtOnceVisualization: View {
    init(visualization: [Visualization]) {
        self.visualizations = visualization.identified()
    }
    
    private let visualizations: [Identified<Visualization>]

    var body: some View {
        ZStack {
            ForEach(visualizations) { (visualization) in
                visualization.element.view
            }
        }
    }
}
