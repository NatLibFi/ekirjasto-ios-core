//
//  TPPEPUBViewController.swift
//
//  Created by Alexandre Camilleri on 7/3/17.
//
//  Copyright 2018 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import UIKit
import SwiftUI
import ReadiumShared
import ReadiumNavigator

class TPPEPUBViewController: TPPBaseReaderViewController {

  var popoverUserconfigurationAnchor: UIBarButtonItem?
  private let systemUserInterfaceStyle: UIUserInterfaceStyle
  let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(presentEPUBSearch))

  /// Current preferences, updated when user changes settings
  private var currentPreferences: EPUBPreferences = .empty

  init(publication: Publication,
       book: TPPBook,
       initialLocation: Locator?,
       forSample: Bool = false) {

    systemUserInterfaceStyle = UITraitCollection.current.userInterfaceStyle

    // Vertical space for the reader's overlay labels is reserved via
    // navigatorContentInset(_:) in TPPBaseReaderViewController.

    var config = EPUBNavigatorViewController.Configuration()
    config.preloadPreviousPositionCount = 2
    config.preloadNextPositionCount = 2
    config.debugState = false
    config.decorationTemplates = HTMLDecorationTemplate.defaultTemplates()
    config.editingActions = [.lookup]

    // Load legacy preferences from UserDefaults if available
    let preferences = EPUBPreferences.fromLegacyPreferences(
      fontFamilyValues: TPPReaderFont.allCases.map { $0.rawValue }
    )
    config.preferences = preferences

    let navigator = try! EPUBNavigatorViewController(publication: publication,
                                                initialLocation: initialLocation,
                                                config: config)

    TPPAssociatedColors.shared.currentTheme = preferences.theme

    super.init(navigator: navigator, publication: publication, book: book, forSample: forSample, initialLocation: initialLocation)

    self.currentPreferences = preferences
    navigator.delegate = self
  }

  var epubNavigator: EPUBNavigatorViewController {
    return navigator as! EPUBNavigatorViewController
  }

  override func willMove(toParent parent: UIViewController?) {
    super.willMove(toParent: parent)

    // Restore catalog default UI colors
    if #unavailable(iOS 26) {
      navigationController?.navigationBar.barStyle = .default
      navigationController?.navigationBar.barTintColor = nil
    }
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Apply theme colors
    setUIColor(for: currentPreferences.theme)
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if #unavailable(iOS 26) {
      if let appearance = TPPConfiguration.defaultAppearance() {
        navigationController?.navigationBar.setAppearance(appearance)
        navigationController?.navigationBar.forceUpdateAppearance(style: systemUserInterfaceStyle)
      }
    }

    navigationController?.navigationBar.tintColor = TPPConfiguration.iconColor()
    tabBarController?.tabBar.tintColor = TPPConfiguration.iconColor()
  }

  override func makeNavigationBarButtons() -> [UIBarButtonItem] {
    var buttons = super.makeNavigationBarButtons()

    // User configuration button
    let userSettingsButton = UIBarButtonItem(image: UIImage(named: "Format"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(presentUserSettings))
    userSettingsButton.accessibilityLabel = Strings.TPPEPUBViewController.readerSettings
    buttons.insert(userSettingsButton, at: 1)
    popoverUserconfigurationAnchor = userSettingsButton
    buttons.append(searchButton)

    return buttons
  }

  @objc func presentUserSettings() {
    let vc = TPPReaderSettingsVC.makeSwiftUIView(preferences: currentPreferences, delegate: self)
    vc.modalPresentationStyle = .popover
    vc.popoverPresentationController?.delegate = self
    vc.popoverPresentationController?.barButtonItem = popoverUserconfigurationAnchor
    vc.preferredContentSize = CGSize(width: 320, height: 240)

    present(vc, animated: true) {
      vc.popoverPresentationController?.passthroughViews = nil
    }
  }

  @objc func presentEPUBSearch() {
    let searchViewModel = EPUBSearchViewModel(publication: publication)
    searchViewModel.delegate = self
    let searchView = EPUBSearchView(viewModel: searchViewModel)
    let hostingController = UIHostingController(rootView: searchView, ignoreSafeArea: true)
    self.present(hostingController, animated: true)
  }
}

// MARK: - TPPReaderSettingsDelegate

extension TPPEPUBViewController: TPPReaderSettingsDelegate {

  func getPreferences() -> EPUBPreferences {
    return currentPreferences
  }

  func submitPreferences(_ preferences: EPUBPreferences) {
    currentPreferences = preferences
    epubNavigator.submitPreferences(preferences)
  }

  /// Synchronize the UI appearance to the selected theme.
  func setUIColor(for theme: Theme?) {
    let colors = TPPAssociatedColors.colors(forTheme: theme)

    navigator.view.backgroundColor = colors.backgroundColor
    view.backgroundColor = colors.backgroundColor
    view.tintColor = colors.textColor
    if #unavailable(iOS 26) {
      navigationController?.navigationBar.setAppearance(TPPConfiguration.appearance(withBackgroundColor: colors.backgroundColor))
      navigationController?.navigationBar.forceUpdateAppearance(style: colors.navigationColor == .black ? .light : .dark)
    }
    navigationController?.navigationBar.tintColor = colors.navigationColor
    tabBarController?.tabBar.tintColor = colors.navigationColor
  }
}


// MARK: - EPUBNavigatorDelegate

extension TPPEPUBViewController: EPUBNavigatorDelegate {
}

// MARK: - UIGestureRecognizerDelegate

extension TPPEPUBViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension TPPEPUBViewController: UIPopoverPresentationControllerDelegate {
  func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
  {
    return .none
  }
}

extension TPPEPUBViewController: EPUBSearchDelegate {
  func didSelect(location: Locator) {

    defer {
      presentedViewController?.dismiss(animated: true)
      Task { await navigator.go(to: location) }
    }

    if let navigator = navigator as? DecorableNavigator {

      var decorations: [Decoration] = []
      decorations.append(Decoration(
        id: "search",
        locator: location,
        style: .highlight(tint: .red)))
      navigator.apply(decorations: decorations, in: "search")
    }
  }
}
