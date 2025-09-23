//
//  AccessibilityView.swift
//

import SwiftUI

struct AccessibilityView: View {

  var book: TPPBook

  @Environment(\.dismiss) var dismiss

  struct AccessibilityKey: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let value: String?
  }

  struct AccessibilitySection: Identifiable {
    let id = UUID()
    let name: String
    let accessibilityKeys: [AccessibilityKey]
  }

  // Just some mock data
  private let accessibilitySections: [AccessibilitySection] = [

    AccessibilitySection(
      name: "Access Mode",
      accessibilityKeys: [
        AccessibilityKey(name: "textual", value: nil),
        AccessibilityKey(name: "visual", value: nil),
      ]
    ),

    AccessibilitySection(
      name: "Summary",
      accessibilityKeys: [
        AccessibilityKey(name: "summary text", value: nil)
      ]
    ),

    AccessibilitySection(
      name: "Hazard",
      accessibilityKeys: [
        AccessibilityKey(name: "flashing", value: nil),
        AccessibilityKey(name: "motionSimulation", value: nil),
        AccessibilityKey(name: "sound", value: nil),
      ]
    ),

    AccessibilitySection(
      name: "Legal considerations",
      accessibilityKeys: [
        AccessibilityKey(name: "None", value: nil)
      ]
    ),

    AccessibilitySection(
      name: "Certification",
      accessibilityKeys: [
        AccessibilityKey(name: "certifiedBy", value: "Official Body Name")
      ]
    ),

    AccessibilitySection(
      name: "Feature",
      accessibilityKeys: [
        AccessibilityKey(name: "displayTransformability", value: nil),
        AccessibilityKey(name: "isFixedLayout", value: nil),
        AccessibilityKey(name: "alternativeText", value: nil),
        AccessibilityKey(name: "longDescription", value: nil),
        AccessibilityKey(name: "describedMath", value: nil),
        AccessibilityKey(name: "transcript", value: nil),
        AccessibilityKey(name: "structuralNavigation", value: nil),
        AccessibilityKey(name: "readingOrder", value: nil),
      ]
    ),

    AccessibilitySection(
      name: "Other features",
      accessibilityKeys: [
        AccessibilityKey(name: "tableOfContents", value: nil),
        AccessibilityKey(name: "index", value: nil),
        AccessibilityKey(name: "printPageNumbers", value: nil),
        AccessibilityKey(name: "audioDescription", value: nil),
        AccessibilityKey(name: "openCaptions", value: nil),
        AccessibilityKey(name: "pageBreakSource", value: nil),
        AccessibilityKey(name: "pageNavigation", value: nil),
      ]
    ),

  ]

  var body: some View {

    VStack(spacing: 0) {
      headerView(book: book)
      listView(sections: accessibilitySections)
    }

  }

  private func headerView(
    book: TPPBook
  ) -> some View {

    VStack(spacing: 16) {
      closeButtonRowView()
      titleRowView(book: book)
    }
    .padding()
    .border(width: 1, edges: [.bottom], color: Color("ColorEkirjastoLightGrey"))
  }
  
  private func closeButtonRowView() -> some View {
    HStack {
      Spacer()
      closeButtonView()
    }
  }
  
  private func titleRowView(
    book: TPPBook
  ) -> some View {
    
    HStack {
      Spacer()
      Text("Accessibility for book: \(book.title)")
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 20)))
      Spacer()
    }
  }
  
  private func closeButtonView() -> some View {
    
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark.circle.fill")
        .foregroundColor(Color("ColorEkirjastoBlack"))
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 22)))
    }
    .accessibility(label: Text(Strings.Generic.close))
    .accessibility(hint: Text("Tap to close the accessibility view"))
    
  }

  private func listView(
    sections: [AccessibilitySection]
  ) -> some View {
    // default style is insetGrouped
    List {
      ForEach(sections) { section in
        sectionView(section: section)
      }
    }

  }

  private func sectionView(
    section: AccessibilityView.AccessibilitySection
  ) -> some View {

    Section(
      header: Text(section.name)
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 14)))
        .foregroundColor(Color("ColorEkirjastoBlack"))
    ) {
      ForEach(section.accessibilityKeys) { accessibilityKey in
        keyView(key: accessibilityKey)
      }
    }

  }

  private func keyView(
    key: AccessibilityKey
  ) -> some View {

    VStack(
      alignment: .leading,
      spacing: 3
    ) {

      Text(key.name)
        .foregroundColor(Color("ColorEkirjastoBlack"))
        .font(Font(uiFont: UIFont.palaceFont(ofSize: 16)))

      // Show key value only if it exists
      if let value = key.value, !value.isEmpty {
        HStack(spacing: 3) {
          Text(value)
        }
        .foregroundColor(Color("ColorEkirjastoGrey"))
      }

    }

  }

}
