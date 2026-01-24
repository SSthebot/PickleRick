//
//  MainViewViewModel.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import FirebaseAuth
import Foundation
import Combine

class MainViewViewModel: ObservableObject{
    @Published var currentUserId : String = ""
    @Published var isCheckingAuth = true
    private var handler : AuthStateDidChangeListenerHandle?
    
    init(){
        self.handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUserId = user?.uid ?? ""
                self?.isCheckingAuth = false
            }
        }
    }
    
    public var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
}
