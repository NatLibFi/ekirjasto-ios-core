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
    let currentAccount = AccountsManager.shared.currentAccount
    //type "http://e-kirjasto.fi/authtype/ekirjasto"
    
    let accounts = AccountsManager.shared.accounts()
    
    let authentication = currentAccount?.authenticationDocument?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    
    let link = authentication?.links?.first(where: {$0.rel == "tunnistus_start"})
    
    let start = link//currentAccount!.authenticationDocument!.authentication!.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})!.links!.first(where: {$0.rel == "tunnistus_start"})
    //let host = "e-kirjasto.loikka.dev"
    
    
    context.coordinator.closeWebView = closeWebView
    uiView.navigationDelegate = context.coordinator
    DispatchQueue.main.async {
      uiView.load(URLRequest(url: URL(string: start!.href)!))
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
      let currentAccount = AccountsManager.shared.currentAccount
      let authentication = currentAccount?.authenticationDocument?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
      
      let link = authentication?.links?.first(where: {$0.rel == "tunnistus_finish"})
      let finish = link//currentAccount!.authenticationDocument!.authentication!.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})!.links!.first(where: {$0.rel == "tunnistus_finish"})
      
      if let urlString = navigationResponse.response.url?.absoluteString {
        if urlString == finish!.href {
          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies() { (cookies) in
            for cookie in cookies {
              switch cookie.name {
              case "SESSION_FE54":
                print("TOKEN: \(cookie.value)")
              case "SESSION_FE54_EXP":
                print("EXP: \(cookie.value)")
              default:
                break
              }
            }
          }
          self.closeWebView?()
        }
        decisionHandler(.allow)
      }
    }
  }
}
