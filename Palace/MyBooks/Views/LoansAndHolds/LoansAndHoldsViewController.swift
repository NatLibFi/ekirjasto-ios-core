//
//  LoansAndHoldsViewController.swift
//

import Foundation
import SwiftUI

class LoansAndHoldsViewController: NSObject {

  // Creating and wrapping the Loans+Holds tab view controller
  @MainActor @objc static func makeSwiftUIView(
    dismissHandler: @escaping (() -> Void)
  ) -> UIViewController {

    // We are creating a UIHostingController to integrate the
    // LoansAndHoldsMainView (a SwiftUI view) into the app's UIKit view hierarchy.
    // LoansViewModel and HoldsViewModel contain the main logic for these subviews,
    // and we pass them as parameters for the LoansAndHoldsMainView
    let hostingController = UIHostingController(
      rootView: LoansAndHoldsView(
        loansViewModel: LoansViewModel(),
        holdsViewModel: HoldsViewModel()
      )
    )

    // Icons and title for the tab, displayed in the bottom tab bar
    // on iPhones with all iOS versions and on iPads with iOS 17 or lower.
    // For iPads running iOS 18 or higher with a regular horizontal size class,
    // only the title is displayed in the floating tab bar, and icons are not used.
    hostingController.title = Strings.MyBooksView.loansAndHoldsNavTitle
    hostingController.tabBarItem.image = UIImage(named: "LoansAndHolds")
    hostingController.tabBarItem.selectedImage = UIImage(named: "LoansAndHoldsSelected")
    hostingController.tabBarItem.imageInsets = UIEdgeInsets(
      top: 4.0, left: 0.0, bottom: -4.0, right: 0.0)

    // Title view label is displayed at the top of the view,
    // below the floating tab bar, for iPads running iOS 18 or higher
    // with a regular horizontal size class.
    //The style matches the lane titles of the catalog's ungrouped view.
    let titleViewLabel = UILabel()
    titleViewLabel.text = Strings.MyBooksView.loansAndHoldsNavTitle
    titleViewLabel.font = UIFont.palaceFont(ofSize: 16)
    titleViewLabel.textAlignment = .center
    titleViewLabel.accessibilityTraits = .header
    hostingController.navigationItem.titleView = titleViewLabel

    // Button text for returning to this view.
    // This button is displayed in book detail view and search view,
    // when user can go back to Loans and Holds view.
    hostingController.navigationItem.backButtonTitle = Strings.MyBooksView.loansAndHoldsNavTitle

    // Navigation controllers stack views and allow us to navigate
    // from one view to another and back within the app.
    // Loans+Holds tab has it's own navigation controller,
    // which means that this navigation controller handles
    // navigation specifically for the Loans+Holds section of the app.
    let navigationController = UINavigationController(
      rootViewController: hostingController
    )

    // UINavigationController is subclass of UIViewController.
    return navigationController

  }

}
