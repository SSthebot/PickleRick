//
//  RegisterViewViewModel.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import Combine

class RegisterViewViewModel : ObservableObject{
    @Published var display = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    
    init(){}
    
    func register(){
        guard validate() else{
            return
        }
        
        Auth.auth().createUser(withEmail : email, password : password ) { [weak self] result, error in
            guard let userId = result?.user.uid else{
                return
            }
            self?.insertUserRecord(id: userId)
        }
    }
    
    private func insertUserRecord(id: String){
        let newUser = User(id : id,
                           name: display,
                           email : email,
                           joined: Date().timeIntervalSince1970)
        
        let db = Firestore.firestore()
        
        
        db.collection("users").document(id).setData(newUser.asDictionary())
        
    }
    
    
    private func validate() -> Bool{
        errorMessage = ""
        guard !display.trimmingCharacters(in: .whitespaces).isEmpty,
              !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty
        else{
            errorMessage = "Please fill in all fields."
            return false
            
        }
        guard email.contains("@") && email.contains(".")
                
        else {
            errorMessage = "Please enter a valid email."
            return false
        }
        
        guard password.count >= 6
        
        else{
            errorMessage = "Password must be atleast 6 characters."
            return false
            
        }
        
        return true
        
    }
    
    
    
}
