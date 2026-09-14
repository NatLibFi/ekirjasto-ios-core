//
//  AudiobookTrackMapper.swift
//  Palace
//
//  Copyright © 2026 The Palace Project. All rights reserved.
//

import Foundation
import PalaceAudiobookToolkit

/// Maps between the audiobook toolkit's part/chapter-based `ChapterLocation`
/// and the cross-platform v2 `LocatorAudioBookTime` wire format, which
/// identifies a position by reading order item (track) and an offset within it.
///
/// The reading order item identifier is the item's `href` as written in the
/// manifest, or `urn:org.thepalaceproject:readingOrderItem:<index>` when the
/// item has no href (mobile-specs, audiobook-reading-order-ids). Both clients
/// parse the same manifest, so identifiers match across Android and iOS.
@objc class AudiobookTrackMapper: NSObject {
  private let spine: [SpineElement]
  /// Reading order item identifiers, indexed by reading order position.
  private let readingOrderIDs: [String]

  /// - Parameters:
  ///   - spine: The opened audiobook's spine.
  ///   - manifestJSON: The audiobook `manifest.json` the spine was built from.
  @objc init?(spine: [SpineElement], manifestJSON: [String: Any]) {
    guard let readingOrder = manifestJSON["readingOrder"] as? [[String: Any]],
          !readingOrder.isEmpty
    else {
      return nil
    }
    self.spine = spine
    self.readingOrderIDs = readingOrder.enumerated().map { index, item in
      (item["href"] as? String) ?? "urn:org.thepalaceproject:readingOrderItem:\(index)"
    }
    super.init()
  }

  /// v2 selector value for posting `location` to the annotations server.
  /// Returns `nil` when the location cannot be expressed in the reading order
  /// model, in which case callers should fall back to the v1 format.
  @objc func v2SelectorString(for location: ChapterLocation) -> String? {
    // LCP and open access spine elements number chapters by reading order
    // index with part always 0; other layouts cannot be mapped here.
    let index = Int(location.number)
    guard location.part == 0, readingOrderIDs.indices.contains(index) else {
      return nil
    }
    // playheadOffset is the offset within the audio file, which is the
    // offset within the reading order item.
    let bookmark = AudioBookmark(
      readingOrderItem: readingOrderIDs[index],
      readingOrderItemOffsetMilliseconds: UInt(max(location.playheadOffset, 0) * 1000),
      audiobookID: location.audiobookID,
      duration: UInt(max(location.duration, 0) * 1000)
    )
    guard let data = try? JSONEncoder().encode(bookmark) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  /// `ChapterLocation` for a server bookmark in either v1 or v2 format.
  /// v2 locators pointing at an unknown reading order item resolve to `nil`.
  @objc func chapterLocation(from bookmark: AudioBookmark) -> ChapterLocation? {
    guard bookmark.version >= 2 else {
      return ChapterLocation(audioBookmark: bookmark)
    }
    guard let item = bookmark.readingOrderItem,
          let index = readingOrderIDs.firstIndex(of: item),
          let template = spine.first(where: { $0.chapter.number == UInt(index) })?.chapter
    else {
      return nil
    }
    return ChapterLocation(
      number: template.number,
      part: template.part,
      duration: template.duration,
      startOffset: template.chapterOffset,
      playheadOffset: TimeInterval(bookmark.readingOrderItemOffsetMilliseconds) / 1000,
      title: template.title,
      audiobookID: template.audiobookID,
      lastSavedTimeStamp: bookmark.timeStamp,
      annotationId: bookmark.annotationId
    )
  }
}
