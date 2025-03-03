//
//  HoldsControllerRepresentable.swift
//

import SwiftUI
import UIKit

struct HoldsControllerRepresentable: UIViewControllerRepresentable {

  func makeUIViewController(context: Context) -> TPPHoldsNavigationController {
    return TPPHoldsNavigationController()
  }

  func updateUIViewController(
    _ uiViewController: TPPHoldsNavigationController, context: Context
  ) {
    // Päivitä näkymän kontrolleria täällä, jos tarpeen
  }

}
