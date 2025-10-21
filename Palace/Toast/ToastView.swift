//
//  ToastView.swift
//

import SwiftUI


// MARK: - Configuration for ToastView

// We could have several different configurations if needed,
// but this is set as the default appearance for toasts.
struct ToastViewConfig {
  let backgroundColor: Color = Color.black.opacity(0.7)
  let bottomPadding: CGFloat = 25
  let cornerRounding: CGFloat = 50
  let font: Font = Font(uiFont: UIFont.systemFont(ofSize: 16))
  let horizontalFixedSize: Bool = false
  let horizontalPadding: CGFloat = 10
  let textAlignment: TextAlignment = .center
  let textColor: Color = Color.white
  let verticalFixedSize: Bool = true
}


// MARK: - Toast message SwiftUI view

// E-kirjasto iOS custom toast view,
// similar to Android's built-in feature.
struct ToastView: View {
  let toastConfig: ToastViewConfig = ToastViewConfig()  // just use the default look
  let toastMessage: String
  let viewMaxWidth: CGFloat = .infinity

  var body: some View {

    VStack {

      Spacer()  // takes space and pushes the toast to the bottom of the screen

      Text(toastMessage)  // empty messages allowed
        .font(toastConfig.font)
        .multilineTextAlignment(toastConfig.textAlignment)
        .padding()  // add padding around the text
        .foregroundColor(toastConfig.textColor)
        .background(toastConfig.backgroundColor)
        .cornerRadius(toastConfig.cornerRounding)
        .padding(.horizontal, toastConfig.horizontalPadding)
        .padding(.bottom, toastConfig.bottomPadding)
        .fixedSize(  // if the horizontal or vertical size should be fixed
          horizontal: toastConfig.horizontalFixedSize,
          vertical: toastConfig.verticalFixedSize
        )
    }

    .frame(maxWidth: viewMaxWidth)  // toast stretches horizontally

  }

}

/*
 #Preview {
  ToastView(toastMessage: "Hello, Toast!")
 }
*/
