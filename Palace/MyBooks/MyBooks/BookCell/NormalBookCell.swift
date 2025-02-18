//
//  NormalBookCell.swift
//  Palace
//
//  Created by Maurice Carrier on 2/8/23.
//  Copyright © 2023 The Palace Project. All rights reserved.
//


import SwiftUI
import Combine

struct NormalBookCell: View {
  @ObservedObject var model: BookCellModel
  private let cellHeight: CGFloat = 135
  private let imageViewWidth: CGFloat = 100

  var body: some View {
    HStack(alignment: .center) {
      unreadImageView
      titleCoverImageView
      VStack(alignment: .leading) {
        infoView
        Spacer()
        buttons
      }.padding(.leading, 8)
      .alert(item: $model.showAlert) { alert in
        Alert(
          title: Text(alert.title),
          message: Text(alert.message),
          primaryButton: .default(Text(alert.buttonTitle ?? ""), action: alert.primaryAction),
          secondaryButton: .cancel(alert.secondaryAction)
        )
      }
      Spacer()
    }
    .multilineTextAlignment(.leading)
    .padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
    .frame(height: cellHeight)
    .onDisappear { model.isLoading = false }
  }
  
  @ViewBuilder private var titleCoverImageView: some View {
    ZStack {
      Image(uiImage: model.image)
        .resizable()
        .scaledToFit()
        .frame(height: 125, alignment: .center)
        //.padding(.top, 10)
      audiobookIndicator
    }
    .frame(width: imageViewWidth)
    .padding(.trailing, 2)
    
  }

  @ViewBuilder private var audiobookIndicator: some View {
    if model.book.defaultBookContentType == .audiobook {
      ImageProviders.MyBooksView.audiobookBadge
        .resizable()
        .frame(width: 30, height: 30)
        .background(Color(UIColor(named: "ColorEkirjastoIcon")!)) //Edited by Ellibs
        .border(width: 1.5, edges: [.top, .bottom, .leading, .trailing], color: Color.white) //added by Ellibs
        .bottomrRightJustified()
        .padding(.trailing, -6)
        .padding(.bottom, 32)
    }
  }
  
  @ViewBuilder private var infoView: some View {
    VStack(alignment: .leading) {
      Text(model.title)
        .lineLimit(2)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 17)))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(model.book.defaultBookContentType == .audiobook ? "\(model.book.title). Audiobook." : model.book.title)
      Text(model.authors)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 12)))
    }.padding(.leading, 10)
  }
  
  @ViewBuilder private var buttons: some View {
    HStack {
      ForEach(model.buttonTypes, id: \.self) { type in
        ButtonView(
          title: type.localizedTitle,
          indicatorDate: model.indicatorDate(for: type),
          action: { model.callDelegate(for: type) }
        )
        .disabled(type.isDisabled)
        .opacity(type.isDisabled ? 0.5 : 1.0)
      }
    }.padding(.leading, 10)
  }
  
  @ViewBuilder private var unreadImageView: some View {
      VStack {
        ImageProviders.MyBooksView.unreadBadge
          .resizable()
          .frame(width: 10, height: 10)
          .foregroundColor(Color(TPPConfiguration.accentColor()))
        Spacer()
      }
      //.opacity(model.showUnreadIndicator ? 1.0 : 0.0)
      .opacity(0.0)
  }
}
