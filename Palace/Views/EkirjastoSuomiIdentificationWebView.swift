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
    let host = "e-kirjasto.loikka.dev"
    
    context.coordinator.closeWebView = closeWebView
    uiView.navigationDelegate = context.coordinator
    DispatchQueue.main.async {
      uiView.load(URLRequest(url: URL(string: "https://\(host)/v1/auth/tunnistus/start?locale=fi")!))
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
