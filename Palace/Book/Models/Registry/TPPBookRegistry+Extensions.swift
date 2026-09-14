//
//  TPPBookRegistry+Extensions.swift
//  Palace
//
//  Created by Maurice Carrier on 6/17/22.
//  Copyright © 2022 The Palace Project. All rights reserved.
//

import Foundation
import PalaceAudiobookToolkit

@objc extension TPPBookRegistry {
  func syncLocation(for book: TPPBook, trackMapper: AudiobookTrackMapper?, completion: @escaping (ChapterLocation?) -> Void) {
    TPPAnnotations.syncReadingPosition(ofBook: book.identifier, toURL: book.annotationsURL) { readPos in

      guard let bookmark = readPos as? AudioBookmark else {
        completion(nil)
        return
      }

      if let trackMapper = trackMapper {
        completion(trackMapper.chapterLocation(from: bookmark))
      } else {
        completion(ChapterLocation(audioBookmark: bookmark))
      }
    }
  }
}
