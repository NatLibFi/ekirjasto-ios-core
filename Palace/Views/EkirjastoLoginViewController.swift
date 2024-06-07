//
//  EkirjastoLoginViewController.swift
//  Palace
//
//  Created by Joni Salmela on 29.1.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import UIKit
import SwiftUI
import Foundation

@objc class EkirjastoLoginViewControllerC : NSObject {
  @objc static func show(navController: UINavigationController? = nil ,dismissHandler: (() -> Void)?){
    EkirjastoLoginViewController.show(navController: navController, dismissHandler: dismissHandler)
  }
}

class EkirjastoLoginViewController : UIHostingController<EkirjastoLoginView>{
  
  private var navController: UINavigationController?
  //put inside a mutex?
  private static var savedHandlers: [(() -> Void)] = []
  private static var showLock = NSLock()
  
  init(rootView: EkirjastoLoginView, navController: UINavigationController?) {
    self.navController = navController
    super.init(rootView: rootView)
  }
  override init(rootView: EkirjastoLoginView) {
    super.init(rootView: rootView)
  }
  
  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func getNavController() -> UINavigationController?{
    if let nc = navigationController {
      return nc
    }
    if let nc = navController {
      return nc
    }
    return nil
  }
  
  private static func makeSwiftUIView(navController: UINavigationController? = nil ,dismissHandler: (() -> Void)?) -> EkirjastoLoginViewController {

    let controller = EkirjastoLoginViewController(rootView: EkirjastoLoginView(dismissView: dismissHandler), navController: navController)
    controller.modalPresentationStyle = .fullScreen
    return controller
  }
  
  
  @objc static func show(navController: UINavigationController? = nil ,dismissHandler: (() -> Void)?){
    let vc = TPPRootTabBarController.shared()
    var loginView : EkirjastoLoginViewController?
    
    if Thread.isMainThread{

      if EkirjastoLoginView.active || TPPOnboardingView.active {
        if let handler = dismissHandler {
          savedHandlers.append(handler)
        }
        return
      }
      
      loginView = makeSwiftUIView(dismissHandler: {
        loginView?.dismiss(animated: true)
        
        dismissHandler?()
        if savedHandlers.count > 0 {
          for var handler in savedHandlers {
             handler()
          }
          savedHandlers.removeAll()
        }
      })
      if let nc = loginView?.getNavController() {
        nc.pushViewController(loginView!, animated: true)
      }else{
        vc?.safelyPresentViewController(loginView, animated: true, completion: nil)
      }
      
    }else{
      DispatchSerialQueue.main.async {

        if EkirjastoLoginView.active || TPPOnboardingView.active {
          if let handler = dismissHandler {
            savedHandlers.append(handler)
          }
          return
        }
        
        loginView = makeSwiftUIView(dismissHandler: {
          loginView?.dismiss(animated: true)
          dismissHandler?()
          if savedHandlers.count > 0 {
            for var handler in savedHandlers {
               handler()
            }
            savedHandlers.removeAll()
          }
        })
        if let nc = loginView?.getNavController() {
          nc.pushViewController(loginView!, animated: true)
        }else{
          vc?.safelyPresentViewController(loginView, animated: true, completion: nil)
        }
      }
    }
    
    
  }
  
}
