//
//  TPPOnboardingView.swift
//  Palace
//
//  Created by Vladimir Fedorov on 08.12.2021.
//  Copyright © 2021 The Palace Project. All rights reserved.
//

import SwiftUI

struct TPPOnboardingView: View {
  
  // 2 x pan distance to switch between slides
  // (relative to screen width)
  private var activationDistance: CGFloat = 0.8
  
  private var onboardingImageNames : [String]
  @GestureState private var translation: CGFloat = 0
  
  @State private var showLoginView = false
  
  @State private var currentIndex = 0 {
    didSet {
      // Dismiss the view after the user swipes past the last slide.
      if currentIndex == onboardingImageNames.count {
        showLoginView = true
      }
    }
  }
  
  // dismiss handler
  var dismissView: (() -> Void)
  
  init(dismissHandler: @escaping (() -> Void)) {
    
    let langCode = Bundle.main.preferredLocalizations[0]
    
    switch langCode {
    case "sv":
      onboardingImageNames = ["IntroSV1","IntroSV2","IntroSV3","IntroSV4"]
    case "fi":
      onboardingImageNames = ["IntroFI1","IntroFI2","IntroFI3","IntroFI4"]
    case "en":
      onboardingImageNames = ["IntroEN1","IntroEN2","IntroEN3","IntroEN4"]
    default:
      onboardingImageNames = ["IntroEN1","IntroEN2","IntroEN3","IntroEN4"]
    }
    
    
    self.dismissView = dismissHandler
  }
  
  var body: some View {
    ZStack(alignment: .top) {
      if(showLoginView) {
        EkirjastoLoginView(dismissView: self.dismissView)
      } else {
        onboardingSlides()
        pagerDots()
        closeButton()
      }
    }
    .edgesIgnoringSafeArea(.all)
    .statusBar(hidden: true)
  }
  
  @ViewBuilder
  private func onboardingSlides() -> some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        ForEach(onboardingImageNames, id: \.self) { imageName in
          Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: geometry.size.width)
            .accessibility(label: Text(NSLocalizedString(imageName, comment: "Onboarding slide localised description")))
        }
      }
      .contentShape(Rectangle())
      .frame(width: geometry.size.width, alignment: .leading)
      .offset(x: translation - CGFloat(currentIndex) * geometry.size.width)
      .animation(.interactiveSpring(), value: currentIndex)
      .gesture(
        DragGesture()
          .updating($translation) { value, state, _translation in
            state = value.translation.width
          }
          .onEnded { value in
            let offset = value.translation.width / geometry.size.width / activationDistance
            let newIndex = (CGFloat(currentIndex) - offset).rounded()
            // This is intentional, it makes possible swiping past the last slide to dismiss this view.
            let lastIndex = onboardingImageNames.count
            currentIndex = min(max(Int(newIndex), 0), lastIndex)
          }
      )
    }
    // Use system appereance setting for bg color.
    // .background(
    //  Color(UIColor(named: "OnboardingBackground") ?? .systemBackground)
    .background(Color(TPPConfiguration.backgroundColor())
    )
  }
  
  @ViewBuilder
  private func pagerDots() -> some View {
    VStack {
      Spacer()
      TPPPagerDotsView(count: onboardingImageNames.count, currentIndex: $currentIndex)
        .padding()
    }
  }
  
  @ViewBuilder
  private func closeButton() -> some View {
    HStack {
      Spacer()
      Button {
        showLoginView = true
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.title)
          .foregroundColor(.gray)
          .padding(.top, 50)
      }
      .accessibility(label: Text(Strings.Generic.close))
    }
  }
}
