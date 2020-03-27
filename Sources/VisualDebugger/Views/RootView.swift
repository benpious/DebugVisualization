import SwiftUI

struct RootView: View {
    
    @EnvironmentObject
    var stream: LLDBStream
            
    var body: some View {
        ZStack {
            stream.state.view
        }
    }
    
}

extension LLDBStream.State {
    
    var view: AnyView {
        switch self {
        case .error(let error):
            return AnyView(ErrorView(text: error))
        case .message(let message):
            return AnyView(WaitingView(message: message)
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity))
        case .views(let views):
            return AnyView(DataView(visualizations: views)
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .topLeading))
        }
    }
    
}

