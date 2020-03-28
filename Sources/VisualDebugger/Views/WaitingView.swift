import SwiftUI

struct WaitingView: View {
    
    let message: Lines
    
    private let cornerRadius: CGFloat = 8
    
    @State
    var flash: Bool = false
    
    var body: some View {
        message
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .padding(cornerRadius * 2)
            .modifier(PulsingBackground(animatableData: flash ? 1 : 0.2,
                                        cornerRadius: self.cornerRadius))
            .cornerRadius(cornerRadius)
            .onAppear {
                withAnimation(Animation
                    .easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)) {
                        self.flash.toggle()
                }
        }
    }
    
}

fileprivate struct PulsingBackground: AnimatableModifier {
    
    var animatableData: Double
    
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(GeometryReader { [cornerRadius] (proxy) in
                Path { (path: inout Path) in
                    path.addRoundedRect(in: CGRect(origin: .zero, size: proxy.size),
                                        cornerSize: CGSize(width: cornerRadius,
                                                           height: cornerRadius))
                }
                .stroke(lineWidth: 4)
                .background(Color(red: 0, green: 0.4, blue: self.animatableData))
                .foregroundColor(Color.green)
            })
    }
    
}
