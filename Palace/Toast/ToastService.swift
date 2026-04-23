//
//  ToastService.swift
//

import SwiftUI


// MARK: - Service for showing toast messages

// Class for displaying toast messages on the screen
class ToastService {

  
  // MARK: - Properties

  private var toastWindow: UIWindow?

  // Make this instance of class
  // shared with all app (singleton)
  static let shared = ToastService()


  // MARK: - Configuration

  // Configuration for ToastWindow appearance
  private struct ToastWindowConfig {
    let backgroundColor: UIColor = UIColor.clear
    let bottomOffset: CGFloat = 50
    let height: CGFloat = 100
    let leadingOffset: CGFloat = 20
    let trailingOffset: CGFloat = -20
    let widthOffset: CGFloat = 40
  }

  private let windowConfig = ToastWindowConfig()

  // Configuration for ToastView animations
  private struct ToastViewAnimationConfig {
    let fadeInAnimationOptions: UIView.AnimationOptions = .curveEaseOut
    let fadeInDelay: TimeInterval = 0.1
    let fadeInDuration: TimeInterval = 0.5
    let fadeOutAnimationOptions: UIView.AnimationOptions = .curveEaseInOut
    let fadeOutDelay: TimeInterval = 2.0
    let fadeOutDuration: TimeInterval = 0.5
  }

  private let animationConfig = ToastViewAnimationConfig()


  // MARK: - Initialize ToastService

  // Private initializer
  // (this class cannot be initialised from outside)
  private init() {}


  // MARK: - Show the toast in current view

  func showToast(toastMessage: String) {

    // Make sure we use main thread
    // because we want to update UI in this function
    DispatchQueue.main.async {

      // We must have some text in toast
      guard !toastMessage.isEmpty else {
        printToConsole(.debug, "Toast message cannot be empty.")
        return
      }

      // Try to get the first connected scene as a UIWindowScene.
      // Access app's windows (all the ones in memory)
      // and then get the window where user is currently
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        printToConsole(.debug, "No UIWindowScene found")
        return
      }

      // Setup the toast window with given message
      self.setupToastWindow(
        windowScene: windowScene,
        toastMessage: toastMessage
      )

      // Display the toast with animations
      self.displayToastView()

    }

  }


  // MARK: - Setup ToastWindow with ToastView

  private func setupToastWindow(
    windowScene: UIWindowScene,
    toastMessage: String
  ) {

    let appWidth = windowScene.coordinateSpace.bounds.width
    let toastWidth = appWidth - windowConfig.widthOffset
    let toastHeight = windowConfig.height

    // Create a new UIWindow object
    // This window will be made visible later
    // when we want to show the toast to the user
    self.toastWindow = UIWindow(windowScene: windowScene)

    self.toastWindow?.backgroundColor = windowConfig.backgroundColor

    // Set frame for toast window'
    self.toastWindow?.frame = CGRect(
      x: 0,
      y: windowScene.coordinateSpace.bounds.height,
      width: appWidth,
      height: windowConfig.height
    )

    // Create the toastView
    // Set the frame size for the toast view
    // and some padding around it
    let toastView = ToastView(toastMessage: toastMessage)
      .padding()
      .frame(
        width: toastWidth,
        height: toastHeight
      )
      .padding(
        .horizontal,
        windowConfig.leadingOffset
      )

    // UIHostingController "hosts" the ToastView, which is SwiftUI code
    // ToastView can then be displayed in UIKit views,
    // such as CatalogUngroupedFeedView and BookDetailView
    let toastViewController = UIHostingController(rootView: toastView)

    // Make toastViewController as the main view controller for the toastWindow.
    // ToastViewController will handle what is displayed in the toastWindow.
    self.toastWindow?.rootViewController = toastViewController
    self.toastWindow?.rootViewController = toastViewController

    // Use this color behind the toast view (clear color)
    self.toastWindow?.rootViewController?.view.backgroundColor =
      windowConfig.backgroundColor

    // Make the toast window visible
    // show toast window in front of other windows
    self.toastWindow?.makeKeyAndVisible()
  }


  // MARK: - Display the ToastView

  private func displayToastView() {

    guard let toastWindow = self.toastWindow else {
      printToConsole(.debug, "ToastWindow is not found for animation")
      return
    }

    // Start the fade-in animation for toast
    fadeInToastView(toastWindow) { [weak self] in

      // When the fade-in animation is complete,
      // start the fade-out animation
      self?.fadeOutToastView(toastWindow) {

        // When the fade out animation is complete,
        // and the toast is not visible anymore,
        // hide the toast window
        self?.removeToastWindow(toastWindow)
      }
    }
  }

  // Fade in animation is used when the toast appears in view
  private func fadeInToastView(
    _ toastWindow: UIWindow,
    completion: @escaping () -> Void
  ) {

    // Start the enter animation for the toastView
    UIView.animate(

      // Set the duration of the fade-in animation
      withDuration: animationConfig.fadeInDuration,

      // Set the delay before the animation starts
      delay: animationConfig.fadeInDelay,

      // Define the animation style
      options: animationConfig.fadeInAnimationOptions,

      // Define the actual animation
      animations: {

        // Move the toast upwards into view
        toastWindow.frame.origin.y =
          toastWindow.frame.origin.y
          - self.windowConfig.bottomOffset
          - self.windowConfig.height
      },

      // The fade in animation is done, finish with completion block
      completion: { _ in
        // call the function that was given as completion
        completion()
      }
    )

  }

  // Fade out animation is used when the toast disappears from view
  private func fadeOutToastView(
    _ toastWindow: UIWindow,
    completion: @escaping () -> Void
  ) {

    // Start the exit animation for the toastView
    UIView.animate(

      // Set the duration of the fade-out animation
      withDuration: animationConfig.fadeOutDuration,

      // Set the delay before the fade-out animation starts
      delay: animationConfig.fadeOutDelay,

      // Define the animation style
      options: animationConfig.fadeOutAnimationOptions,

      // Define the actual animation
      animations: {

        // Move the toast out of view downwards
        toastWindow.frame.origin.y =
          toastWindow.frame.origin.y
          + self.windowConfig.bottomOffset
          + self.windowConfig.height

      },

      // The fade out animation is done, finish with completion block
      completion: { _ in
        //call the fucntion that was given as completion
        completion()
      }
    )

  }

  // Hide and remove the toast window after animations
  private func removeToastWindow(_ toastWindow: UIWindow) {

    // Make toast window disappear from view
    // and not receive inputs anymore
    toastWindow.isHidden = true

    // Release the root view controller reference
    // clear it from the app view memory
    toastWindow.rootViewController = nil
  }

}
