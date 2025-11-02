//
//  AccessibilityView.swift
//

import Foundation
import SwiftUI

struct AccessibilityView: View {
  
  var book: TPPBook
  @Environment(\.dismiss) var dismiss
  
  
  var body: some View {
    
    VStack(spacing: 0) {
      
      headerView(
        book: book
      )
      
      listView(
        itemGroups: AccessibilityViewBuilder().buildAccessibilityItemGroups(book)
      )
      
    }
    
  }
  
  private func headerView(book: TPPBook) -> some View {
    
    VStack(spacing: 16) {
      closeButtonRowView()
      titleRowView(book: book)
    }
    .padding()
    .border(width: 1, edges: [.bottom], color: .gray)
  }
  
  private func closeButtonRowView() -> some View {
    HStack {
      Spacer()
      closeButtonView()
    }
  }
  
  private func titleRowView(book: TPPBook) -> some View {
    
    HStack {
      Spacer()
      Text("Accessibility for book:")
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 20)))
      Text("\(book.title)")
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 20)))
      Spacer()
    }
  }
  
  private func closeButtonView() -> some View {
    
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark.circle.fill")
        .foregroundColor(.black)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 22)))
    }
    .accessibility(label: Text(Strings.Generic.close))
    .accessibility(hint: Text("Tap to close the accessibility view"))
    
  }
  
  private func listView(itemGroups: [AccessibilityItemGroup]) -> some View {
    // default style is insetGrouped
    List {
      ForEach(itemGroups) { itemGroup in
        itemGroupView(itemGroup: itemGroup)
      }
    }
    
  }
  
  private func itemGroupView(itemGroup: AccessibilityItemGroup) -> some View {
    
    Section(
      header: Text(itemGroup.name)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 14)))
        .foregroundColor(.black)
    ) {
      ForEach(itemGroup.accessibilityItems) { accessibilityItem in
        itemView(item: accessibilityItem)
      }
    }
    
  }
  
  private func itemView(item: AccessibilityItem) -> some View {
    
    VStack(
      alignment: .leading,
      spacing: 3
    ) {
      
      Text(item.name)
        .foregroundColor(.black)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))
      
      // Show item's value only if it exists
      if let value = item.value, !value.isEmpty {
        HStack(spacing: 3) {
          Text(value)
        }
        .foregroundColor(.gray)
      }
      
    }
    
  }
  
}
