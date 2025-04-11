//
//  CustomGridLayout.swift
//  Palace
//
//  Created by Maurice Carrier on 2/24/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//

import SwiftUI

struct AdaptableGridLayout<Content: View>: View {
  
  private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
  private let gridItemLayout = [
    GridItem(.adaptive(minimum: 300), spacing: .zero)
  ]
  var content: () -> Content
  
  var body: some View {

    if isPad {
      gridViewForPad
    } else {
      stackViewForPhone
    }

  }

  @ViewBuilder private var gridViewForPad: some View {
    LazyVGrid(
      columns: gridItemLayout,
      alignment: .leading, spacing: 10
    ) {
      content()
    }
    .padding(.trailing, 10)
  }

  @ViewBuilder private var stackViewForPhone: some View {
    VStack(
      alignment: .leading,
      spacing: 10
    ) {
      content()
    }
    .padding(.top, 15)
  }

}
