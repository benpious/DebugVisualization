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

struct ErrorView: View {
    
    let text: String
    
    var body: some View {
        HStack {
            Text("􀇾")
            Text(text)
                .foregroundColor(.white)
        }
        .padding(16)
        .background(Color(red: 224 / 256, green: 119 / 256, blue: 119 / 256))
        .cornerRadius(8)
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
    }
    
}
