//
//  TLButton.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import SwiftUI

struct TLButton: View {
    let title: String
    let background: Color
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(background)
                    .frame(width: 300, height: 40)
                
                Text(title)
                    .foregroundColor(.white)
                    .bold()
            }
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        TLButton(
            title: "Log In",
            background: .blue
        ) {
            print("Login tapped")
        }
        
        TLButton(
            title: "Create Account",
            background: .green
        ) {
            print("Create account tapped")
        }
    }
}
