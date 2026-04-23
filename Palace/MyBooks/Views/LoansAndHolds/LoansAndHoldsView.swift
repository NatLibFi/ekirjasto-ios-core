//
//  LoansAndHoldsView.swift
//

import SwiftUI

/// Hides the navigation bar background on iPad iOS 26 so Liquid Glass
/// shows through consistently across all tabs.
struct HideNavBarBackgroundOnIPadIOS26: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26, *), UIDevice.current.userInterfaceIdiom == .pad {
      content
        .toolbarBackground(.hidden, for: .navigationBar)
    } else {
      content
    }
  }
}

/// Shared selection state that can be driven from both SwiftUI and UIKit.
class LoansAndHoldsSelection: ObservableObject {
  @Published var selectedSubview = "Loans"
}

struct LoansAndHoldsView: View {

  @State private var orientation: UIDeviceOrientation = UIDevice.current
    .orientation
  @ObservedObject var loansViewModel: LoansViewModel
  @ObservedObject var holdsViewModel: HoldsViewModel
  @ObservedObject var selection: LoansAndHoldsSelection

  var subviews = ["Loans", "Holds"]

  let backgroundColor: Color = Color(TPPConfiguration.backgroundColor())

  var body: some View {

    ContentView
      .navigationBarItems(leading: EKirjastoButton)
      .navigationBarTitle(Strings.MyBooksView.loansAndHoldsNavTitle)
      .modifier(HideNavBarBackgroundOnIPadIOS26())
      .onReceive(
        NotificationCenter.default.publisher(
          for: UIDevice.orientationDidChangeNotification)
      ) { _ in
        self.orientation = UIDevice.current.orientation
      }

  }

  @ViewBuilder private var ContentView: some View {

    // On iPad iOS 26, the segmented control is in the navigation bar titleView,
    // so hide the in-content picker.
    if !useNavBarSegmentedControl {
      SegmentedPicker
    }

    switch selection.selectedSubview {
    case "Loans":
      LoansSubview
    case "Holds":
      HoldsSubview
    default:
      LoansSubview
    }

  }

  private var useNavBarSegmentedControl: Bool {
    if #available(iOS 26, *), UIDevice.current.userInterfaceIdiom == .pad {
      return true
    }
    return false
  }

  @ViewBuilder private var EKirjastoButton: some View {
    Button {
      TPPRootTabBarController.shared().showAndReloadCatalogViewController()
    } label: {
      ImageProviders.MyBooksView.myLibraryIcon
        .accessibilityLabel(
          Strings.MyBooksView.accessibilityShowAndReloadCatalogTab)
    }
  }

  @ViewBuilder private var SegmentedPicker: some View {
    VStack {
      Picker(
        "View list of books on loan or list of books on hold",
        selection: $selection.selectedSubview
      ) {
        //Add the localized title for the holds and loans buttons
        ForEach(subviews, id: \.self) {
          if($0 == "Loans") {
            Text(Strings.MyBooksView.loansNavTitle)
          } else {
            Text(Strings.MyBooksView.holdsNavTitle)
          }
        }
      }
      .pickerStyle(.segmented)
      .background(SwiftUI.Color("ColorEkirjastoFilterButtonBackgroundNormal").cornerRadius(10.0))
      .padding(15)
    }
    .background(backgroundColor)
  }

  @ViewBuilder private var LoansSubview: some View {
    LoansView(loansViewModel: loansViewModel)
  }

  @ViewBuilder private var HoldsSubview: some View {
    HoldsView(holdsViewModel: holdsViewModel)
  }

}
