//
//  Copyright (c) 2020. Ben Pious
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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
                                        cornerRadius: cornerRadius))
            .cornerRadius(cornerRadius)
            .onAppear {
                withAnimation(Animation
                    .easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)) {
                        flash.toggle()
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
                .background(Color(red: 0, green: 0.4, blue: animatableData))
                .foregroundColor(Color.green)
            })
    }
    
}
