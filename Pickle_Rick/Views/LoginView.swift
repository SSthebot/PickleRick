//
//  LoginView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject var viewModel = LoginViewViewModel()
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                LoginHeaderView()
                
                Form {
                    TextField("Email Address", text: $viewModel.email)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(DefaultTextFieldStyle())
                    
                    TLButton(
                        title: "Log In",
                        background: .blue
                    ) {
                        viewModel.login()
                    }
                    .listRowInsets(EdgeInsets())
                    .frame(maxWidth: .infinity)
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundStyle(Color(.systemRed))
                    }
                }
                .scrollContentBackground(.hidden)
                
                VStack(spacing: 8) {
                    Text("New around here?")
                        .foregroundColor(.secondary)
                    NavigationLink("Create an account", destination: RegisterView())
                }
                .padding(.vertical, 20)
                
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    LoginView()
}
