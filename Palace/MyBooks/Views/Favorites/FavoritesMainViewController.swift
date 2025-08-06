//
//  FavoritesMainViewController.swift
//

import Foundation
import SwiftUI

class FavoritesMainViewController: NSObject {

  // Creating and wrapping the Favorites tab view controller
  @MainActor @objc static func makeSwiftUIView(
    dismissHandler: @escaping (() -> Void)
  ) -> UIViewController {

    // We are creating a UIHostingController to integrate the
    // FavoritesMainView (a SwiftUI view) into the app's UIKit view hierarchy.
    // FavoritesViewModel contains the main logic for this view,
    // and we pass it as parameter for the FavoritesMainView
    let hostingController = UIHostingController(
      rootView: FavoritesMainView(
        favoritesViewModel: FavoritesViewModel()
      )
    )

    // Icons and title for the tab, displayed in the bottom tab bar
    // on iPhones with all iOS versions and on iPads with iOS 17 or lower.
    // For iPads running iOS 18 or higher with a regular horizontal size class,
    // only the title is displayed in the floating tab bar, and icons are not used.
    hostingController.title = Strings.MyBooksView.favoritesAndReadNavTitle
    hostingController.tabBarItem.image =  UIImage(named: "Favorites")
    hostingController.tabBarItem.selectedImage = UIImage(named: "FavoritesSelected")
    hostingController.tabBarItem.imageInsets = UIEdgeInsets(
      top: 4.0, left: 0.0, bottom: -4.0, right: 0.0
    )

    // Title view label is displayed at the top of the view,
    // below the floating tab bar, for iPads running iOS 18 or higher
    // with a regular horizontal size class.
    //The style matches the lane titles of the catalog's ungrouped view.
    let titleViewLabel = UILabel()
    titleViewLabel.text = Strings.MyBooksView.favoritesAndReadNavTitle
    titleViewLabel.font = UIFont.palaceFont(ofSize: 16)
    titleViewLabel.textAlignment = .center
    titleViewLabel.accessibilityTraits = .header
    hostingController.navigationItem.titleView = titleViewLabel

    // Button text for returning to this view.
    // This button is displayed in book detail view and search view,
    // when user can go back to Favorites view.
    hostingController.navigationItem.backButtonTitle = Strings.MyBooksView.favoritesAndReadNavTitle

    // Navigation controllers stack views and allow us to navigate
    // from one view to another and back within the app.
    // Favorites tab has it's own navigation controller,
    // which means that this navigation controller handles
    // navigation specifically for the Favorites section of the app.
    let navigationController = UINavigationController(
      rootViewController: hostingController
    )

    // UINavigationController is subclass of UIViewController.
    return navigationController

  }

}
