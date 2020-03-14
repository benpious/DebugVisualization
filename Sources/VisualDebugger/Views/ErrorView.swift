import SwiftUI

struct ErrorView: View {
    
    let text: String
    
    var body: some View {
        HStack {
            Text("􀇾")
            Text(text)
                .foregroundColor(Color.white)
        }
        .padding(16)
        .background(Color(red: 224 / 256, green: 119 / 256, blue: 119 / 256))
        .cornerRadius(8)
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
    }
    
}
