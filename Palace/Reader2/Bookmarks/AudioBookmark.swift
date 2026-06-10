//
//  AudioBookmark.swift
//  Palace
//
//  Created by Maurice Carrier on 6/16/22.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Foundation

/// Wire model for the `LocatorAudioBookTime` annotation selector.
///
/// Two versions of the locator exist:
/// - v1 (no `@version`): position identified by `chapter`/`part` numbers with
///   `time`/`startOffset` offsets. Written by older clients.
/// - v2 (`@version` 2): position identified by `readingOrderItem` (the href of
///   the manifest reading order item, per the mobile-specs
///   audiobook-reading-order-ids spec) and an offset within that item.
///   Written by current Android and iOS clients. `audiobookID` and `duration`
///   are included alongside for compatibility, but are not part of the v2 core.
@objc class AudioBookmark: NSObject, Bookmark, Codable {
  static let locatorType = "LocatorAudioBookTime"

  // v1 fields (zero/nil when version >= 2)
  let title: String
  let chapter: UInt
  let part: UInt
  let startOffset: UInt?
  let time: UInt

  // v2 fields (nil/zero when version == 1)
  let readingOrderItem: String?
  let readingOrderItemOffsetMilliseconds: UInt

  let version: Int
  let duration: UInt
  let type: String
  let audiobookID: String
  var timeStamp: String = Date().iso8601
  var annotationId: String = ""

  enum CodingKeys: String, CodingKey {
    case title
    case chapter
    case part
    case duration
    case startOffset
    case time
    case type = "@type"
    case version = "@version"
    case readingOrderItem
    case readingOrderItemOffsetMilliseconds
    case audiobookID
  }

  init(
    readingOrderItem: String,
    readingOrderItemOffsetMilliseconds: UInt,
    audiobookID: String,
    duration: UInt
  ) {
    self.type = AudioBookmark.locatorType
    self.version = 2
    self.readingOrderItem = readingOrderItem
    self.readingOrderItemOffsetMilliseconds = readingOrderItemOffsetMilliseconds
    self.audiobookID = audiobookID
    self.duration = duration
    self.title = ""
    self.chapter = 0
    self.part = 0
    self.startOffset = nil
    self.time = 0
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    let type = try values.decode(String.self, forKey: .type)
    guard type == AudioBookmark.locatorType else {
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: values,
        debugDescription: "Not a \(AudioBookmark.locatorType) locator"
      )
    }
    self.type = type

    let version = try values.decodeIfPresent(Int.self, forKey: .version) ?? 1
    self.version = version

    if version >= 2 {
      self.readingOrderItem = try values.decode(String.self, forKey: .readingOrderItem)
      self.readingOrderItemOffsetMilliseconds = try values.decode(UInt.self, forKey: .readingOrderItemOffsetMilliseconds)
      self.audiobookID = try values.decodeIfPresent(String.self, forKey: .audiobookID) ?? ""
      self.duration = try values.decodeIfPresent(UInt.self, forKey: .duration) ?? 0
      self.title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
      self.chapter = 0
      self.part = 0
      self.startOffset = nil
      self.time = 0
    } else {
      self.title = try values.decode(String.self, forKey: .title)
      self.chapter = try values.decode(UInt.self, forKey: .chapter)
      self.part = try values.decode(UInt.self, forKey: .part)
      self.duration = try values.decode(UInt.self, forKey: .duration)
      self.startOffset = try values.decodeIfPresent(UInt.self, forKey: .startOffset)
      self.time = try values.decode(UInt.self, forKey: .time)
      self.audiobookID = try values.decode(String.self, forKey: .audiobookID)
      self.readingOrderItem = nil
      self.readingOrderItemOffsetMilliseconds = 0
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(type, forKey: .type)

    if version >= 2 {
      try container.encode(version, forKey: .version)
      try container.encode(readingOrderItem, forKey: .readingOrderItem)
      try container.encode(readingOrderItemOffsetMilliseconds, forKey: .readingOrderItemOffsetMilliseconds)
      try container.encode(audiobookID, forKey: .audiobookID)
      try container.encode(duration, forKey: .duration)
    } else {
      try container.encode(title, forKey: .title)
      try container.encode(chapter, forKey: .chapter)
      try container.encode(part, forKey: .part)
      try container.encode(duration, forKey: .duration)
      try container.encodeIfPresent(startOffset, forKey: .startOffset)
      try container.encode(time, forKey: .time)
      try container.encode(audiobookID, forKey: .audiobookID)
    }
  }
}
