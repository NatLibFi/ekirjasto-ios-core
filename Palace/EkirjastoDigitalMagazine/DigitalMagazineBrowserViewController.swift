//
//  EkirjastoEpaperViewController.swift
//  Ekirjasto
//
//  Created by Johannes Ylönen on 13.3.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import UIKit
import WebKit

class DigitalMagazineBrowserViewController: UIViewController, UITabBarControllerDelegate, WKNavigationDelegate {
  
  private let webView = WKWebView()
  
  private let webAppBaseURL = "https://e-kirjasto-playground.epaper.fi/"
  private let webAppLanguage = "fi"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupWebView()
    
    let entryURL = URL(string: "\(webAppBaseURL)\(webAppLanguage)")!
    let request = URLRequest(url: entryURL)
    webView.load(request)
  }
  
  private func setupWebView() {
    webView.navigationDelegate = self
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
    webView.navigationDelegate = self
    
#if DEBUG
    if #available(iOS 16.4, *) {
      webView.isInspectable = true
    }
#endif
    
    view.addSubview(webView)
    
    // use auto-layout
    webView.translatesAutoresizingMaskIntoConstraints = false
    let lauoutGuide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: lauoutGuide.topAnchor, constant: 0.0),
      webView.leadingAnchor.constraint(equalTo: lauoutGuide.leadingAnchor, constant: 0.0),
      webView.trailingAnchor.constraint(equalTo: lauoutGuide.trailingAnchor, constant: 0.0),
      webView.bottomAnchor.constraint(equalTo: lauoutGuide.bottomAnchor, constant: 0.0),
    ])
  }
  
  func popToRoot() {
    // Call the web app's "popToRoot" method if the user re-selects the current tab to emulate native behavior.
    webView.evaluateJavaScript("__ewl('popToRoot');", completionHandler: nil)
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    
    guard let url = navigationAction.request.url else {
      decisionHandler(.cancel)
      return
    }
    
    if url.path.hasPrefix("/read") {
      
      let vc = DigitalMagazineReaderViewController()
      
      // Pass the url to reader view.
      vc.loadURL(url)
      vc.modalPresentationStyle = .fullScreen
      present(vc, animated: true)
      
      // Cancel loading the url here.
      decisionHandler(.cancel)
      return
      
    }
    
    decisionHandler(.allow)
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    
    guard let path = webView.url?.path else { return }
    
    if path.hasPrefix("/unauthorized") {
      // TODO: Getthe actual token here.
      webView.evaluateJavaScript("__ewl('login', {token:\"foobar\"});", completionHandler: nil)
    }
  }
  
  deinit {
    webView.removeObserver(self, forKeyPath: "URL")
  }
}
