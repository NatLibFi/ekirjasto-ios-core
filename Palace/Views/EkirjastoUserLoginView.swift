//
//  EkirjastoUserLoginView.swift
//  Ekirjasto
//
//  Created by Joni Salmela on 8.11.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI
import AuthenticationServices

struct EkirjastoUserLoginView: View {
    
  var dismissView: () -> Void
  var navigationController: UINavigationController?
  
  @State var passKeyLogin : PasskeyManager? = nil
  @State var _loginSuomi = false
  @State var _passKey = 0
  @State var authDoc : OPDS2AuthenticationDocument? = nil
  
  var body: some View {
    
    /*if _loginSuomi {
      SuomiIdentificationWebView(closeWebView: {
        _loginSuomi = false
        self.dismissView()
      }, authenticationDocument: authDoc)
    }else if _passKey != 0 {
      passkeyEmail
    }else{*/
    NavigationView {
      VStack{
        
        /*Text("Sign in with Suomi.fi e-identification").foregroundColor(Color.white).frame(height: 40).onTouchDownUp { down, value in
          if !down {
            loginSuomi()
          }
          
        }*/
        /*if TPPUserAccount.sharedAccount().authToken != nil {
          Text("Register with passkey").foregroundColor(Color.white).frame(height: 40).onTouchDownUp{ down, value in
            if !down {
              showPasskey(1)
            }
          }
        }*/
        if let authDoc = authDoc {
          NavigationLink("Sign in with Suomi.fi e-identification", destination: {
            SuomiIdentificationWebView(closeWebView: {
              _loginSuomi = false
              self.dismissView()
            }, authenticationDocument: authDoc)
          }).foregroundStyle(.white).frame(height: 40)
          if TPPUserAccount.sharedAccount().authToken != nil {
            NavigationLink("Register with passkey",destination: passkeyEmail(1)).foregroundStyle(.white).frame(height: 40)
          }
          
          NavigationLink("Sign in with passkey",destination: passkeyEmail(2)).foregroundStyle(.white).frame(height: 40)
        }else{
          ProgressView()
        }

        
        /*Text("Sign in with passkey").foregroundColor(Color.white).frame(height: 40).onTouchDownUp{ down, value in
          if !down {
            showPasskey(2)
          }
        }*/
        
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("ColorEkirjastoGreen"))
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(false)
      /*.toolbar{
        ToolbarItem(placement: .automatic){
          Text("e-library account").foregroundColor(Color.white)
        }
        
      }*/
    }
    .navigationViewStyle(.stack)
      .onAppear{
        fetchAuthDoc(completion: { doc in
          authDoc = doc
        })
      }

    //}

  }
  
  @State var passkeyUserName = ""
  
  private func passkeyEmail(_ mode : Int) -> some View {
    return VStack{
      TextField("Username", text: $passkeyUserName)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      Button(action: {if mode == 1 { self.registerPasskey() } else if mode == 2 { self.loginPasskey() }}){
        Text("Continue")
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("ColorEkirjastoGreen"))
      .navigationBarBackButtonHidden(false)
      
      /*.navigationBarTitle("abc", displayMode: .inline)
      .background(NavigationConfigurator{ nc in
        nc.navigationBar.barTintColor = UIColor.red//UIColor(named: "ColorEkirjastoGreen")
        nc.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
      })*/
      
  }

  
  
  func fetchAuthDoc(completion: @escaping (_ doc: (OPDS2AuthenticationDocument?))->Void){
    if let currentAccount = AccountsManager.shared.currentAccount {
      if let doc = currentAccount.authenticationDocument {
        completion(doc)
      }else{
        currentAccount.loadAuthenticationDocument(completion: { Bool in
          DispatchQueue.main.async {
            completion(currentAccount.authenticationDocument)
          }
        })
      }
    }else if let account = AccountsManager.shared.accounts().first {
      account.loadAuthenticationDocument(completion: { Bool in
        DispatchQueue.main.async {
          completion(account.authenticationDocument!)
        }
      })
    }else{
      completion(nil)
    }
  }

  
  func showPasskeyLinks(_ mode: Int){
    if authDoc == nil {
      fetchAuthDoc { doc in
        authDoc = doc!
        _passKey = mode
      }
    }else{
      _passKey = mode
    }
  }
  
  
  func loginPasskey(){
    let authentication = authDoc?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    
    self.passKeyLogin = PasskeyManager(authentication!)
    
    self.passKeyLogin!.login(passkeyUserName) { loginToken in
      if let token = loginToken, !token.isEmpty{
        TPPNetworkExecutor.shared.authenticateWithToken(token)
      }
      DispatchQueue.main.async {
        self.dismissView()
      }
    }
    
  }
  
  func registerPasskey(){
    let authentication = authDoc?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    
    self.passKeyLogin = PasskeyManager(authentication!)
    
    if let savedToken = TPPUserAccount.sharedAccount().authToken {
      self.passKeyLogin!.register(passkeyUserName,savedToken) { registerToken in
        if let token = registerToken, !token.isEmpty{
          TPPNetworkExecutor.shared.authenticateWithToken(token)
        }
        DispatchQueue.main.async {
          self.dismissView()
        }
        
      }
    }
    
    
  }
  
  
  func loginSuomi(){
    if authDoc == nil {
      fetchAuthDoc { doc in
        authDoc = doc!
        _loginSuomi = true
      }
    }else{
      _loginSuomi = true
    }
  }
  
}

struct EkirjastoUserLoginView_Previews: PreviewProvider {
    static var previews: some View {
      EkirjastoUserLoginView(dismissView: {
        
      })
    }
}
