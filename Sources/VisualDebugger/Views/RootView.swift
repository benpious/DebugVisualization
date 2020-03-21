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
                WaitingView(message: stream.state.message!)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
            } else if stream.state.error != nil {
                ErrorView(text: stream.state.error!)
            } else if stream.state.views != nil {
                DataView(visualizations: stream.state.views!)
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity,
                               alignment: .topLeading)
            }
        }
    }
    
}
