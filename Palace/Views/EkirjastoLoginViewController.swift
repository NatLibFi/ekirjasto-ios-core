//
//  EkirjastoLoginViewController.swift
//  Palace
//
//  Created by Joni Salmela on 29.1.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import UIKit
import SwiftUI

class EkirjastoLoginViewController : NSObject {
  
  @objc static func makeSwiftUIView(dismissHandler: @escaping (() -> Void)) -> UIViewController {
    let controller = UIHostingController(rootView: EkirjastoUserLoginView(dismissView: dismissHandler))
    controller.modalPresentationStyle = .fullScreen
    return controller
  }
  
  
  static func show(dismissHandler: @escaping (() -> Void)){
    let vc = TPPRootTabBarController.shared()
    var loginView : UIViewController?
    
    
    if Thread.isMainThread{
      loginView = makeSwiftUIView(dismissHandler: {
        loginView?.dismiss(animated: true)
        dismissHandler()
      })
      
      vc?.safelyPresentViewController(loginView, animated: true, completion: nil)
    }else{
      DispatchSerialQueue.main.async {
        loginView = makeSwiftUIView(dismissHandler: {
          loginView?.dismiss(animated: true)
          dismissHandler()
        })
        
        vc?.safelyPresentViewController(loginView, animated: true, completion: nil)
      }
    }
    
    
  }
  
}
