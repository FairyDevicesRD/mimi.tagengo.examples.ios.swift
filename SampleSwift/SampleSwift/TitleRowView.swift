//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import SwiftUI

struct TitleRowView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Tagengo Example")
                    .foregroundColor(Color.black)
                    .multilineTextAlignment(.center)
                    .font(/*@START_MENU_TOKEN@*/ .title/*@END_MENU_TOKEN@*/)
                    .edgesIgnoringSafeArea(.top)
                Spacer()
            }
            
            Spacer()
            
        }.padding()
            .frame(height: 50)
            .background(LinearGradient(gradient: Gradient(colors: [.white, .blue]), startPoint: .top, endPoint: .bottom))
    }
}

struct TitleRowView_Previews: PreviewProvider {
    static var previews: some View {
        TitleRowView()
    }
}
