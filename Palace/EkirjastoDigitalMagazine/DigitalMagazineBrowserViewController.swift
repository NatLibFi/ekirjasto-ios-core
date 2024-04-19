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
  
  private var authRetryTime:DispatchTime = .now()
  private var authRetryCount:TimeInterval = 0
  private var authRetryBackoffFactor:TimeInterval = 2
  private var currentAuthWorkItem: DispatchWorkItem? = nil
  
  private var wasRedirectedToLogin: Bool = false
  
  func resetAuthRetryTimer() {
    authRetryCount = 0
    authRetryTime = .now()
    currentAuthWorkItem?.cancel()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupWebView()
    loadBaseUrl()
  }
  
  private func loadBaseUrl() {
    guard let digitalMagazinesUrl = AccountsManager.shared.currentAccount?.digitalMagazinesUrl
    else {
      return
    }
    
    let webAppLanguage = Bundle.main.preferredLocalizations[0]
    let entryURL = URL(string: "\(digitalMagazinesUrl)\(webAppLanguage)")!
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
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard let path = webView.url?.path else { return }
    
    if path.hasPrefix("/unauthorized") == false && TPPUserAccount.sharedAccount().authToken == nil {
      // This can happend after logout, we should be unauthorized.
      loadBaseUrl()
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if let path = webView.url?.path, path.hasPrefix("/unauthorized") {
      // Wait short time so that TPPUserAccount.sharedAccount().authToken is set.
      DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(500)),
        execute: DispatchWorkItem(block: {
          self.authorize()
        })
      )
    }
  }
  
  func popToRoot() {
    // Call the web app's "popToRoot" method if the user re-selects the current tab to emulate native behavior.
    webView.evaluateJavaScript("__ewl('popToRoot');", completionHandler: nil)
    self.resetAuthRetryTimer()
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
  
  fileprivate func authorize() {
    self.resetAuthRetryTimer()
    
    fetchEkirjastoToken() { ekirjastoToken in
      DispatchQueue.main.async {
        self.webView.evaluateJavaScript("__ewl('login', {token:\"\(ekirjastoToken ?? "")\"});", completionHandler: nil)
      }
    }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard let path = webView.url?.path else { return }
    if path.hasPrefix("/unauthorized") {
      authorize()
    }
  }
  
  private func fetchEkirjastoToken(_ completion: @escaping (String?) -> Void) {
    guard let authenticationDocument = AccountsManager.shared.currentAccount?.authenticationDocument,
      let authentication = authenticationDocument.authentication?.first(where: { $0.type == "http://e-kirjasto.fi/authtype/ekirjasto" }),
      let tokenUrlString = authentication.links?.first(where: { $0.rel == "ekirjasto_token" })?.href,
      let tokenUrl = URL(string: tokenUrlString)
    else {
      return
    }
    
    guard let _ = TPPUserAccount.sharedAccount().authToken else {
      if wasRedirectedToLogin {
        TPPRootTabBarController.shared().changeToPreviousIndex()
        wasRedirectedToLogin = false
      }
      else {
        // Going to show login.
        EkirjastoLoginViewController.show {
          // User is still may not be loggedin. Get back to where they were before this view.
          self.wasRedirectedToLogin = true
        }
      }
      return
    }
    
    TPPNetworkExecutor.shared.GET(tokenUrl) { result in
      switch result {
      case .success(let serverData, _):
        if let responseBody = try? JSONSerialization.jsonObject(with: serverData, options: []) as? [String:Any],
           let ekirjastoToken = responseBody?["token"] as? String {
          completion(ekirjastoToken)
          return
        }
      case .failure(let error, _):
        TPPErrorLogger.logError(
          withCode: .responseFail,
          summary: "Digital Magazine view failed to get ekirjasto token.",
          metadata: ["loadError": error, "url": tokenUrl]
        )
      }
      
      self.authRetryCount += 1
      self.authRetryTime = .now() + self.authRetryBackoffFactor * self.authRetryCount
      self.currentAuthWorkItem?.cancel()
      self.currentAuthWorkItem = DispatchWorkItem(block: {
        self.fetchEkirjastoToken(completion)
      })
      
      DispatchQueue.main.asyncAfter(deadline: self.authRetryTime, execute: self.currentAuthWorkItem!)
    }
  }
  
  deinit {
    currentAuthWorkItem?.cancel()
    webView.removeObserver(self, forKeyPath: "URL")
  }
}
