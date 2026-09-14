//
//  TPPReaderTOCBusinessLogic.swift
//  The Palace Project
//
//  Created by Ettore Pasquini on 4/23/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import ReadiumShared

typealias TPPReaderTOCLink = (level: Int, link: Link)

/// This class captures the business logic related to the Table Of Contents
/// for a given Readium 2 Publication.
class TPPReaderTOCBusinessLogic {
  var tocElements: [TPPReaderTOCLink] = []
  private let publication: Publication
  private let currentLocation: Locator? // for current chapter

  init(r2Publication: Publication, currentLocation: Locator?) {
    self.publication = r2Publication
    self.currentLocation = currentLocation
    // tableOfContents is async in Readium 3.x; load synchronously via Task
    var toc: [Link] = []
    let semaphore = DispatchSemaphore(value: 0)
    Task {
      if let result = try? await r2Publication.tableOfContents().get() {
        toc = result
      }
      semaphore.signal()
    }
    semaphore.wait()
    self.tocElements = flatten(toc)
  }

  private func flatten(_ links: [Link], level: Int = 0) -> [(level: Int, link: Link)] {
    return links.flatMap { [(level, $0)] + flatten($0.children, level: level + 1) }
  }

  var tocDisplayTitle: String {
    Strings.TPPReaderTOCBusinessLogic.tocDisplayTitle
  }

  func tocLocator(at index: Int) async -> Locator? {
    guard tocElements.indices.contains(index) else {
      return nil
    }
    let link = tocElements[index].link
    // Resolve the TOC link against the publication (the way Readium 3.x expects)
    // rather than hand-building a Locator from the raw href. A hand-built
    // Locator only resolved for same-document jumps — the first chapters —
    // which is why selecting later chapters failed to navigate.
    return await publication.locate(link)
  }

  func shouldSelectTOCItem(at index: Int) -> Bool {
    // Non-link TOC entries (section headers) have href "#".
    guard tocElements.indices.contains(index) else {
      return false
    }
    return tocElements[index].link.href != "#"
  }

  func titleAndLevel(forItemAt index: Int) -> (title: String, level: Int) {
    let item = tocElements[index]
    return (title: (item.link.title ?? item.link.href), level: item.level)
  }

  func isCurrentChapterTitled(_ title: String) -> Bool {
    guard let currentLocationTitle = currentLocation?.title?.lowercased() else {
      return false
    }

    return title.lowercased() == currentLocationTitle
  }
}
