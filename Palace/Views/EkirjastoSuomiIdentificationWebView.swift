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
  var authenticationDocument : OPDS2AuthenticationDocument? = nil
  
  func updateUIView(_ uiView: WKWebView, context: Context) {

    context.coordinator.closeWebView = closeWebView
      
    let authentication = authenticationDocument?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    let link = authentication?.links?.first(where: {$0.rel == "tunnistus_start"})
    let start = link
    print("suomi.fi start.href: \(start?.href)")
    uiView.navigationDelegate = context.coordinator
    uiView.load(URLRequest(url: URL(string: start!.href + "&state=app")!))
    
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
    
    /*func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
      
      print("suomi.fi response url: \(navigationResponse.response.url?.absoluteString)")
      
      if let url = navigationResponse.response.url {
        if url.absoluteString.contains("saml2acs") || url.absoluteString.contains("finish") {
          let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
          let token = urlComponents?.queryItems?.first(where: {$0.name == "token"})?.value
          
          if let token = token {
            TPPNetworkExecutor.shared.authenticateWithToken(token)
          }
          
          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies() { (cookies) in

            for cookie in cookies {
              print("cookie name:\(cookie.name) value:\(cookie.value)")
            }
          }
          self.closeWebView?()
        }
        decisionHandler(.allow)
      }
    }*/
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      
      print("suomi.fi response url: \(webView.url?.absoluteString)")
      
      if let url = webView.url {
        if url.absoluteString.contains("saml2acs") || url.absoluteString.contains("finish") {
          let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
          let token = urlComponents?.queryItems?.first(where: {$0.name == "token"})?.value
          
          if let token = token {
            TPPNetworkExecutor.shared.authenticateWithToken(token)
          }
          
          /*webView.evaluateJavaScript("document.body.innerHTML", completionHandler: { (doc: Any?, error: Error?) in
              guard let jsonString = doc as? String else { return }
              print("doc: \(jsonString)")
          })*/
          
          
          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies() { (cookies) in
            
            for cookie in cookies {
              print("cookie name:\(cookie.name) value:\(cookie.value)")
            }
          }
          self.closeWebView?()
        }
      }
    }
  }
}
