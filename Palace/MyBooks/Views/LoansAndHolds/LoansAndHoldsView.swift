//
//  LoansAndHoldsView.swift
//

import SwiftUI

struct LoansAndHoldsView: View {

  @State private var orientation: UIDeviceOrientation = UIDevice.current
    .orientation
  @ObservedObject var loansViewModel: LoansViewModel
  @ObservedObject var holdsViewModel: HoldsViewModel

  var subviews = ["Loans", "Holds"]
  @State private var selectedSubview = "Loans"

  let backgroundColor: Color = Color(TPPConfiguration.backgroundColor())

  var body: some View {

    ContentView
      .navigationBarItems(leading: EKirjastoButton)
      .navigationBarTitle(Strings.MyBooksView.loansAndHoldsNavTitle)
      .onReceive(
        NotificationCenter.default.publisher(
          for: UIDevice.orientationDidChangeNotification)
      ) { _ in
        self.orientation = UIDevice.current.orientation
      }

  }

  @ViewBuilder private var ContentView: some View {

    SegmentedPicker

    switch selectedSubview {
    case "Loans":
      LoansSubview
    case "Holds":
      HoldsSubview
    default:
      LoansSubview
    }

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
        selection: $selectedSubview
      ) {
        ForEach(subviews, id: \.self) {
          Text($0)
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
