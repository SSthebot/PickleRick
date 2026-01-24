//
//  RegisterView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import SwiftUI

struct RegisterView: View {
    @State var viewModel = RegisterViewViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            RegisterHeaderView()
            
            Form {
                TextField("Display Name", text: $viewModel.display)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .autocapitalization(.words)
                    .autocorrectionDisabled()
                
                TextField("Email Address", text: $viewModel.email)
                    .textFieldStyle(DefaultTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                TLButton(
                    title: "Create Account",
                    background: .blue
                ) {
                    viewModel.register()
                }
                .listRowInsets(EdgeInsets())
                .frame(maxWidth: .infinity)
            }
            .scrollContentBackground(.hidden)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
    }


#Preview {
    RegisterView()
}
