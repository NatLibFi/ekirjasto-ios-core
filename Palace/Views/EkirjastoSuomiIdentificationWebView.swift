//
//  EkirjastoSuomiIdentificationWebView.swift
//  Ekirjasto
//
//  Created by Nianzu on 24.10.2023.
//  Copyright © 2023 The Palace Project. All rights reserved.
//
import WebKit
import SwiftUI

struct SuomiIdentificationWebView: UIViewRepresentable {
  var closeWebView : (() -> Void)?
  
  func updateUIView(_ uiView: WKWebView, context: Context) {
    var account = AccountsManager.shared.currentAccount
    if(account == nil){
      account = AccountsManager.shared.accounts().first
      account?.loadAuthenticationDocument(completion: { Bool in
        
        context.coordinator.closeWebView = closeWebView
        
        DispatchQueue.main.async {
          let authentication = account?.authenticationDocument?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
          let link = authentication?.links?.first(where: {$0.rel == "tunnistus_start"})
          let start = link
          uiView.navigationDelegate = context.coordinator
          uiView.load(URLRequest(url: URL(string: start!.href)!))
        }
      })
    }else{
      context.coordinator.closeWebView = closeWebView
      
      DispatchQueue.main.async {
        let authentication = account?.authenticationDocument?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
        let link = authentication?.links?.first(where: {$0.rel == "tunnistus_start"})
        let start = link
        uiView.navigationDelegate = context.coordinator
        uiView.load(URLRequest(url: URL(string: start!.href)!))
      }
    }
    
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  func makeUIView(context: Context) -> WKWebView {
    let view = WKWebView()
    view.configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
    
    return view
  }
  
  class Coordinator : NSObject, WKNavigationDelegate {
    var closeWebView : (() -> Void)?
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
      
      if let urlString = navigationResponse.response.url?.absoluteString {
        if urlString.contains("saml2acs") {
          
          
          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies() { (cookies) in
            let token = cookies.first(where: {$0.name == "SESSION_FE54"})?.value
            let exp = cookies.first(where: {$0.name == "SESSION_FE54_EXP"})?.value
            
            TPPNetworkExecutor.shared.authenticateWithToken(token!)

            /*for cookie in cookies {
              switch cookie.name {
              case "SESSION_FE54":
                print("TOKEN: \(cookie.value)")
              case "SESSION_FE54_EXP":
                print("EXP: \(cookie.value)")
              default:
                break
              }
            }*/
          }
          self.closeWebView?()
        }
        decisionHandler(.allow)
      }
    }
  }
}
