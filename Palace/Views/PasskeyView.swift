//
//  PasskeyView.swift
//  Palace
//
//  Created by Joni Salmela on 28.3.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Foundation

import Foundation
import SwiftUI
import AuthenticationServices

enum PasskeyMode {
  case register
  case login
}

struct PasskeyView: View {
  
  var mode : PasskeyMode
  var passKeyManager : PasskeyManager
  var dismissView: (() -> Void)?
  @State var passkeyUserName = ""
  
  var body: some View {
    return VStack{
      TextField("Username", text: $passkeyUserName)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .textContentType(.username)
      Button(action: {if mode == .register { self.registerPasskey() } else if mode == .login { self.loginPasskey() }}){
        Text("Continue")
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("ColorEkirjastoGreen"))
      .navigationBarBackButtonHidden(false)
  }
  
  func loginPasskey(){
    
    self.passKeyManager.login{ loginToken in
      if let token = loginToken, !token.isEmpty{
        TPPNetworkExecutor.shared.authenticateWithToken(token)
      }
      DispatchQueue.main.async {
        self.dismissView?()
      }
    }
    
  }
  
  func registerPasskey(){
    
    if let savedToken = TPPUserAccount.sharedAccount().authToken {
      self.passKeyManager.register(passkeyUserName,savedToken) { registerToken in
        if let token = registerToken, !token.isEmpty{
          TPPNetworkExecutor.shared.authenticateWithToken(token)
        }
        DispatchQueue.main.async {
          self.dismissView?()
        }
        
      }
    }
  }
  
}
