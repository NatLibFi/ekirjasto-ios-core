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
  
  struct TokenResponse: Codable {
    let token: String
    let exp: Int?
  }
  
  var closeWebView : (() -> Void)?
  var authenticationDocument : OPDS2AuthenticationDocument? = nil
  @Environment(\.presentationMode) var presentationMode
  
  func updateUIView(_ uiView: WKWebView, context: Context) {

    if let closeWebView = closeWebView {
      context.coordinator.closeWebView = closeWebView
    }else{
      context.coordinator.closeWebView = {
        presentationMode.wrappedValue.dismiss()
      }
    }
    
    context.coordinator.authenticationDocument = authenticationDocument
    let authentication = authenticationDocument?.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto"})
    let link = authentication?.links?.first(where: {$0.rel == "tunnistus_start"})
    let start = link

    print("suomi.fi start.href: \(start?.href)")
    uiView.navigationDelegate = context.coordinator
    var request = URLRequest(url: URL(string: "\(start!.href)&state=app")!)
    request.addValue("application/json", forHTTPHeaderField: "accept")
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    
    uiView.load(request)
    
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
    var authenticationDocument : OPDS2AuthenticationDocument? = nil
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      
      print("suomi.fi response url: \(webView.url?.absoluteString)")
      
      if let url = webView.url {
        if url.absoluteString.contains("saml2acs") || url.absoluteString.contains("finish") {
          let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
          let token = urlComponents?.queryItems?.first(where: {$0.name == "token"})?.value
          
          webView.configuration.websiteDataStore.httpCookieStore.getAllCookies() { (cookies) in
            
            for cookie in cookies {
              print("cookie name:\(cookie.name) value:\(cookie.value)")
            }
          }
          //TODO: use regex to exract json object from document.body?
          webView.evaluateJavaScript("document.getElementsByTagName('pre')[0].innerHTML", completionHandler: { (doc: Any?, error: Error?) in
            guard let jsonString = doc as? String else { return }
            
            let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: jsonString.data(using: .utf8)!)
            
            if let tokenResponse = tokenResponse {
              TPPNetworkExecutor.shared.authenticateWithToken(tokenResponse.token)
              
            }
            
            print("doc: \(jsonString)")
            self.closeWebView?()
          })
          
          
        }
      }
    }
  }
}
