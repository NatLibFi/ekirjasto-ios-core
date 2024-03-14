//
//  EkirjastoLoginViewController.swift
//  Palace
//
//  Created by Joni Salmela on 29.1.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import UIKit
import SwiftUI

class EkirjastoLoginViewController : UIHostingController<EkirjastoUserLoginView>{
  
  private var navController: UINavigationController?
  
  init(rootView: EkirjastoUserLoginView, navController: UINavigationController?) {
    self.navController = navController
    super.init(rootView: rootView)
  }
  override init(rootView: EkirjastoUserLoginView) {
    super.init(rootView: rootView)
  }
  
  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  static func makeSwiftUIView(navController: UINavigationController? = nil ,dismissHandler: @escaping (() -> Void)) -> EkirjastoLoginViewController {

    let controller = EkirjastoLoginViewController(rootView: EkirjastoUserLoginView(dismissView: dismissHandler), navController: navController)
    controller.modalPresentationStyle = .fullScreen
    return controller
  }
  
  
  static func show(navController: UINavigationController? = nil ,dismissHandler: @escaping (() -> Void)){
    let vc = TPPRootTabBarController.shared()
    var loginView : EkirjastoLoginViewController?
    
    
    if Thread.isMainThread{
      loginView = makeSwiftUIView(dismissHandler: {
        loginView?.dismiss(animated: true)
        dismissHandler()
      })
      //let nc = UINavigationController(rootViewController: loginView!)//loginView?.navigationController
      //if let nc = loginView?.navController {
      //  nc.pushViewController(loginView!, animated: true)
     // }else{
        vc?.safelyPresentViewController(loginView, animated: true, completion: nil)
      //}
      
    }else{
      DispatchSerialQueue.main.async {
        loginView = makeSwiftUIView(dismissHandler: {
          loginView?.dismiss(animated: true)
          dismissHandler()
        })
        let nc = loginView?.navigationController
        vc?.pushViewController(loginView, animated: true)
        //vc?.safelyPresentViewController(loginView, animated: true, completion: nil)
      }
    }
    
    
  }
  
}
