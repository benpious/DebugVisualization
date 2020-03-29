import SwiftUI

struct RootView: View {
    
    @EnvironmentObject
    var stream: LLDBStream
    
    var body: some View {
        ZStack {
            stream.state.view(using: $stream.organization,
                              reset: stream.reset)
        }
    }
    
}

extension LLDBStream.State {
    
    func view(using binding: Binding<Organization>,
              reset: @escaping () -> ()) -> AnyView {
        switch self {
        case .error(let error):
            return AnyView(
                ErrorView(text: error)
            )
        case .message(let message):
            return AnyView(
                WaitingView(message: message)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
            )
        case .interleavedViews(let views):
            return AnyView(
                DataControl(organization: binding,
                            reset: reset) {
                    DataView(visualizations: views)
                }
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .topLeading)
            )
        case .sectionedVisualizations(let sections):
            return AnyView(
                DataControl(organization: binding,
                            reset: reset) {
                    TabbedVisualizationsView(sections: sections)
                }
            )
        }
    }
        
}

