//
//  TestLoginViewController.swift
//  Palace
//
//  Created by Joni Salmela on 26.4.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import UIKit
import SwiftUI
import Foundation


class TestLoginViewController : UIHostingController<TestLoginUI>{
  
  private var navController: UINavigationController?
  
  override init(rootView: TestLoginUI) {
    super.init(rootView: rootView)
  }
  
  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  private static func makeSwiftUIView(completion: @escaping (Bool) -> Void) -> TestLoginViewController {

    let controller = TestLoginViewController(rootView: TestLoginUI(completion: completion))
    controller.modalPresentationStyle = .fullScreen
    return controller
  }
  
  
  @objc static func show(completion: @escaping (Bool) -> Void){
    let vc = TPPRootTabBarController.shared()
    var loginView : TestLoginViewController?
    
    
    if Thread.isMainThread{
      loginView = makeSwiftUIView(completion: { success in
        completion(success)
        loginView?.dismiss(animated: true)
      })

      vc?.safelyPresentViewController(loginView, animated: true, completion: nil)
      
    }else{
      DispatchSerialQueue.main.async {
        loginView = makeSwiftUIView(completion: { success in
          completion(success)
          loginView?.dismiss(animated: true)
        })

        vc?.safelyPresentViewController(loginView, animated: true, completion: nil)
      }
    }
    
    
  }
  
}
