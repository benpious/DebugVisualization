import SwiftUI

struct SimpleVisualization: VisualizationType {
    
    let view: AnyView
    
    init(from object: SomeObject) throws {
        view = try object.view.unwrap()
    }
    
}
