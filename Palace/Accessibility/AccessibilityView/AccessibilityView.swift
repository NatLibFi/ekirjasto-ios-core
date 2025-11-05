//
//  AccessibilityView.swift
//

import Foundation
import SwiftUI

// MARK: - Accessibility view

struct AccessibilityView: View {
  
  var book: TPPBook
  @Environment(\.dismiss) var dismiss
  
  
  var body: some View {
    
    // build accessibility item groups from the book
    let accessibilityItemGroups = AccessibilityViewBuilder().buildAccessibilityItemGroups(book)
    
    VStack(spacing: AccessibilityViewConfiguration.bodyStackSpacing) {
      
      // display header view with the book title and close button
      headerView(book: book)
        .accessibilitySortPriority(AccessibilityViewConfiguration.headerPriority)
      
      Group {
        // check if there are any accessibility item groups to display
        if accessibilityItemGroups.isEmpty {
          // instead of list, show a placeholder text
          emptyListView()
        } else {
          // show list of accessibility items
          listView(itemGroups: accessibilityItemGroups)
        }
      }
    }
    
  }
  
  
  // MARK: - Header view
  
  private func headerView(book: TPPBook) -> some View {
    // create the header view with a close button and book title
    VStack(spacing: AccessibilityViewConfiguration.headerSpacing) {
      closeButtonRowView()
      titleRowView(book: book)
    }
    .padding()
    .border(
      width: AccessibilityViewConfiguration.borderWidth,
      edges: [.bottom],
      color: AccessibilityViewConfiguration.borderColor
    )
    
  }
  
  private func closeButtonRowView() -> some View {
    // create row for the close button
    HStack {
      Spacer()
      closeButtonView()
    }
  }
  
  private func titleRowView(book: TPPBook) -> some View {
    // create title row displaying the header text with book title
    HStack {
      Spacer()
      titleTextView(book: book)
      Spacer()
    }
  }
  
  private func closeButtonView() -> some View {
    // create a close button that dismisses the view
    Button {
      // dismiss the accessibility view
      dismiss()
    } label: {
      closeButtonImage()
    }
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(Strings.Accessibility.closeButtonTitle)
    .accessibilityHint(Strings.Accessibility.closeButtonHint)
  }
  
  private func closeButtonImage() -> some View {
    // create image for the close button
    Image(systemName: AccessibilityViewConfiguration.closeButtonImageName)
      .foregroundColor(AccessibilityViewConfiguration.closeButtonColor)
      .font(AccessibilityViewConfiguration.closeButtonFont)
  }
  
  private func titleTextView(book: TPPBook) -> some View {
    // create a text view for the book title
    Text(
      String.localizedStringWithFormat(
        Strings.Accessibility.headerTitleWithBook,
        book.title
      )
    )
    .font(AccessibilityViewConfiguration.titleFont)
    .padding(.bottom, AccessibilityViewConfiguration.titlePadding)
    .accessibilityAddTraits(.isHeader)
    .accessibilityRemoveTraits(.isStaticText)
  }
  
  
  // MARK: - Empty list view
  
  private func emptyListView() -> some View {
    // create a view to display
    // if there is no accessibility information
    VStack {
      Text(Strings.Accessibility.noAccessibilityInfoLabel)
        .foregroundColor(AccessibilityViewConfiguration.emptyListTextColor)
        .font(AccessibilityViewConfiguration.emptyListFont)
        .multilineTextAlignment(.center)
        .horizontallyCentered()
        .verticallyCentered()
        .padding()
        .accessibilityLabel(Strings.Accessibility.noAccessibilityInfoLabel)
    }
    // take all space that is available
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .background(AccessibilityViewConfiguration.emptyListBackgroundColor)
  }
  
  
  // MARK: - List view
  
  private func listView(itemGroups: [AccessibilityItemGroup]) -> some View {
    // create a list view that displays accessibility item groups
    List {
      ForEach(itemGroups) { itemGroup in
        itemGroupView(itemGroup: itemGroup)
      }
    }
    
  }
  
  
  // MARK: - Item group view
  
  private func itemGroupView(itemGroup: AccessibilityItemGroup) -> some View {
    // create a view for each item group, and include items
    
    Section(
      header: itemGroupHeader(itemGroup: itemGroup)
    ) {
      
      ForEach(itemGroup.accessibilityItems) { accessibilityItem in
        itemView(item: accessibilityItem)
      }
      
    }
    // use only one constructed accessibility label per group
    .accessibilityLabel(AccessibilityViewBuilder().buildAccessibilityLabel(itemGroup))
    .accessibilityRemoveTraits(.isHeader)
    .accessibilityAddTraits(.isStaticText)
    .accessibilityElement(children: .combine)
  }
  
  private func itemGroupHeader(itemGroup: AccessibilityItemGroup) -> some View {
    // create header view for one item group
    Text(itemGroup.name)
      .font(AccessibilityViewConfiguration.itemGroupHeaderFont)
      .foregroundColor(AccessibilityViewConfiguration.itemGroupHeaderColor)
  }
  
  
  // MARK: - Item view
  
  private func itemView(item: AccessibilityItem) -> some View {
    // create a view for an individual accessibility item
    VStack(
      alignment: .leading,
      spacing: AccessibilityViewConfiguration.itemSpacing
    ) {
      itemNameView(item: item)
      itemValueView(item: item)
    }
    // hiding item from screen readers
    .accessibilityHidden(true)
    
  }
  
  private func itemNameView(item: AccessibilityItem) -> some View {
    // create a view for the item's name
    Text(item.name)
      .foregroundColor(AccessibilityViewConfiguration.itemNameColor)
      .font(AccessibilityViewConfiguration.itemFont)
  }
  
  private func itemValueView(item: AccessibilityItem) -> some View {
    // create a view for the item's value
    Group {
      if let value = item.value, !value.isEmpty {
        // show item's value only if it exists
        HStack(spacing: AccessibilityViewConfiguration.itemValueSpacing) {
          Text(value)
            .foregroundColor(AccessibilityViewConfiguration.itemValueColor)
            .font(AccessibilityViewConfiguration.itemFont)
        }
      } else {
        // return empty view if no value exists
        EmptyView()
      }
    }
    
  }
  
}


// MARK: - Accessibility view configuration

struct AccessibilityViewConfiguration {
  static let bodyStackSpacing: CGFloat = 0
  static let headerPriority: Double = 1.0
  static let headerSpacing: CGFloat = 16
  static let titlePadding: CGFloat = 15
  static let closeButtonColor: Color = Color(.black)
  static let closeButtonImageName: String = "xmark.circle.fill"
  static let borderWidth: CGFloat = 1
  static let borderColor: Color = Color(.systemGray)
  static let emptyListTextColor: Color = Color(.black)
  static let emptyListBackgroundColor: Color = Color(.systemGray6)
  static let itemGroupHeaderColor: Color = Color(.black)
  static let itemSpacing: CGFloat = 3
  static let itemNameColor: Color = Color(.black)
  static let itemValueColor: Color = Color(.systemGray)
  static let itemValueSpacing: CGFloat = 3
  
  static var titleFont: Font {
    Font(uiFont: UIFont.palaceFont(ofSize: 22))
  }
  
  static var closeButtonFont: Font {
    Font(uiFont: UIFont.palaceFont(ofSize: 22))
  }
  
  static var emptyListFont: Font {
    Font(uiFont: UIFont.palaceFont(ofSize: 18))
  }
  
  static var itemGroupHeaderFont: Font {
    Font(uiFont: UIFont.palaceFont(ofSize: 14))
  }
  
  static var itemFont: Font {
    Font(uiFont: UIFont.palaceFont(ofSize:16))
  }
  
}


