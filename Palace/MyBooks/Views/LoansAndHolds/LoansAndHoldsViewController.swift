//
//  LoansAndHoldsViewController.swift
//

import Foundation
import SwiftUI

class LoansAndHoldsViewController: NSObject {

  @MainActor @objc static func makeSwiftUIView(
    dismissHandler: @escaping (() -> Void)
  ) -> UIViewController {
    
    let hostingController = UIHostingController(
      rootView: LoansAndHoldsView(
        loansViewModel: LoansViewModel(),
        holdsViewModel: HoldsViewModel()
      )
    )
    
    hostingController.title = Strings.MyBooksView.navTitle
    hostingController.tabBarItem.image = UIImage(named: "MyBooks")
    hostingController.tabBarItem.selectedImage = UIImage(named: "MyBooksSelected")
    hostingController.tabBarItem.imageInsets = UIEdgeInsets(top: 4.0, left: 0.0, bottom: -4.0, right: 0.0)
    hostingController.navigationItem.backButtonTitle = NSLocalizedString("Back", comment: "Back button")
    hostingController.navigationItem.titleView?.tintColor = UIColor(named: "ColorEkirjastoBlack")
    
    let navigationController = UINavigationController(
      rootViewController: hostingController
    )
    
    return navigationController
    
  }
    
}
