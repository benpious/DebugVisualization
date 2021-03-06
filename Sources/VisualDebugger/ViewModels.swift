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

struct Visualization: Hashable, Identifiable {
    
    var id: Int {
        hashValue
    }
    
    let pid: Int
    let type: String
    let mirrorInfo: String
    let view: AnyView
    let timeStamp: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(timeStamp)
        hasher.combine(type)
        hasher.combine(pid)
        hasher.combine(mirrorInfo)
    }
    
    static func == (lhs: Visualization,
                    rhs: Visualization) -> Bool {
        lhs.timeStamp == rhs.timeStamp &&
            lhs.pid == rhs.pid &&
            lhs.mirrorInfo == rhs.mirrorInfo
    }
        
}

struct VisualizationSection: Identifiable {
    
    var id: String {
        name
    }
    
    let name: String
    let visualizations: [Visualization]
    
}
