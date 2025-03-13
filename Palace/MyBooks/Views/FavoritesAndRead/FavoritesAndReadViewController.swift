//
//  FavoritesAndReadViewController.swift
//

import Foundation
import SwiftUI

class FavoritesAndReadViewController: NSObject {
  
  @MainActor @objc static func makeSwiftUIView(
    dismissHandler: @escaping (() -> Void)
  ) -> UIViewController {
    
    let hostingController = UIHostingController(
      rootView: FavoritesAndReadView(
        favoritesViewModel: FavoritesViewModel()
        /* Code for future feature: read books
         readViewModel: ReadViewModel()
         */
      )
    )
    
    hostingController.title = Strings.MyBooksView.favoritesAndReadNavTitle
    hostingController.tabBarItem.image = UIImage(named: "Holds")
    hostingController.tabBarItem.selectedImage = UIImage(named: "HoldsSelected")
    hostingController.tabBarItem.imageInsets = UIEdgeInsets(top: 4.0, left: 0.0, bottom: -4.0, right: 0.0)
    hostingController.navigationItem.backButtonTitle = NSLocalizedString("Back", comment: "Back button")
    hostingController.navigationItem.titleView?.tintColor = UIColor(named: "ColorEkirjastoBlack")
    
    let navigationController = UINavigationController(
      rootViewController: hostingController
    )
    
    return navigationController
    
  }
  
}
