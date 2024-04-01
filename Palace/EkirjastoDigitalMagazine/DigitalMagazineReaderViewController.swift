//
//  DigitalMagazineReaderViewController.swift
//  Palace
//
//  Created by Johannes Ylönen on 13.3.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import UIKit
import WebKit

class DigitalMagazineReaderViewController: UIViewController, WKNavigationDelegate {
  private let webView = WKWebView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupWebView()
  }
  
  private func setupWebView() {
    webView.frame = view.bounds
    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    webView.navigationDelegate = self
    webView.isOpaque = false
    webView.backgroundColor = .clear
    
#if DEBUG
    if #available(iOS 16.4, *) {
      webView.isInspectable = true
    }
#endif
    
    view.addSubview(webView)
  }
  
  func loadURL(_ url: URL) {
    let request = URLRequest(url: url)
    webView.load(request)
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let path = navigationAction.request.url?.path else {
      decisionHandler(.cancel)
      return
    }
    
    if !path.hasPrefix("/read") {
      // User is going away from the reading view.
      decisionHandler(.cancel)
      dismiss(animated: true)
      return
    }
    
    decisionHandler(.allow)
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
}
