//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import SwiftUI

struct SwiftUIView: View {
    @State var selection1: String = ""
    @State var selection2: String = ""
    
    var integers: [String] = ["0", "1", "2", "3", "4", "5"]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Picker(selection: self.$selection1, label: Text("numbers 1")) {
                    ForEach(0 ..< self.integers.count) { index in
                        Text(String(self.integers[index]))
                    }
                }
                .frame(maxWidth: geometry.size.width / 2)
                .clipped()
                .border(Color.red)
                
                Picker("Options", selection: self.$selection2) {
                    ForEach(0 ..< self.integers.count) { index in
                        Text(String(self.integers[index]))
                    }
                }
                .frame(maxWidth: geometry.size.width / 2)
                .clipped()
                .border(Color.red)
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
