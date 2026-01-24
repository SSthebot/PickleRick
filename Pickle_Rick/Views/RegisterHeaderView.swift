//
//  RegisterHeaderView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import SwiftUI

struct RegisterHeaderView: View {

    var body: some View {
        ZStack {
            // Green background that extends to edges
            Rectangle()
                .fill(Color.green)
                .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 12) {
                Text("PickleRick")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Smartest Pickleball Paddle")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                
                Image("pickle_rick")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .padding(.top, 8)
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        
    }
}

#Preview {
    RegisterHeaderView()
}
