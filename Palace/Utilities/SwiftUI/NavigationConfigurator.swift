//
//  NavigationConfigurator.swift
//  Palace
//
//  Created by Joni Salmela on 12.3.2024.
//  Copyright © 2024 The Palace Project. All rights reserved.
//

import Foundation
import SwiftUI

struct NavigationConfigurator: UIViewControllerRepresentable {
  var configure: (UINavigationController) -> Void = { _ in }
  let navController =  UINavigationController()

  func makeUIViewController(context: UIViewControllerRepresentableContext<NavigationConfigurator>) -> UIViewController {
    let viewController = UIViewController()
    //viewController.
    navController.addChild(viewController)
    return viewController
  }
  func updateUIViewController(_ pageViewController: UINavigationController, context: Context) {
   // if let nc = pageViewController.navigationController {
        self.configure(pageViewController)
   // }
  }
  func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavigationConfigurator>) {
      if let nc = uiViewController.navigationController {
          self.configure(nc)
      }
    self.configure(navController)
  }
}
